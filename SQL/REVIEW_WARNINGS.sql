-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- REVIEW_WARNINGS
-- RUN ONE TIME

set @GB_THRESHOLD = (5 * 1024 * 1024 * 1024); -- BELOW THIS NUMBER DISPLAY IN MB ELSE GB
set @ROW_FORMAT_COMPRESSED_THRESHOLD =(512 * 1024 * 1024);
SET @LOW_QUERY_CACHE_HITS_THRESHOLD=10000;
set @LARGE_EMPTY_LOW_ROWCOUNT = 1000;
set @LARGE_EMPTY_DATAFILE_THRESHOLD = (100 * 1024 * 1024); 
SET @MIN_ROWS_NO_PK_THRESHOLD=10000;

select VARIABLE_VALUE into @QUERY_CACHE_ENABLED 
from information_schema.GLOBAL_VARIABLES 
where VARIABLE_NAME='QUERY_CACHE_TYPE';

select if(VARIABLE_VALUE > 0,'YES','NO') into @IS_GALERA 
  from information_schema.global_status 
  where VARIABLE_NAME='WSREP_THREAD_COUNT';

WITH TABLE_KEY_COUNTS as
    (SELECT C.`TABLE_SCHEMA`, C.`TABLE_NAME`, T.`ENGINE`,
    IF(SUM(case when C.COLUMN_KEY = 'PRI' then 1 else 0 END)>=1,1,0) AS `PRIMARY_KEY_COUNT`,
    SUM(case when C.COLUMN_KEY = 'UNI' then 1 else 0 END) AS `UNIQUE_KEY_COUNT`,
    SUM(case when C.COLUMN_KEY = 'MUL' then 1 else 0 END) AS `NON_UNIQUE_KEY_COUNT`,
    T.`ROW_FORMAT`, T.`TABLE_ROWS`, T.`AVG_ROW_LENGTH`
    FROM information_schema.`COLUMNS` C
    INNER JOIN information_schema.`TABLES` T
    ON (C.`TABLE_SCHEMA`=T.`TABLE_SCHEMA` AND C.`TABLE_NAME`=T.`TABLE_NAME`)
    WHERE C.`TABLE_SCHEMA` NOT IN ('information_schema','performance_schema','sys','mysql','mariadb_review')
    AND T.TABLE_TYPE='BASE TABLE'
    AND T.`ENGINE` != 'Columnstore'
    GROUP BY C.`TABLE_SCHEMA`, C.`TABLE_NAME`
)
  select '$RUNID',now() as TICK, @@HOSTNAME,
  substr(concat('BIG TABLE NO PK: ', t.TABLE_SCHEMA,'.',t.TABLE_NAME),1,100) as `ITEM`,
  concat(format(t.TABLE_ROWS,0),if(t.TABLE_ROWS=1,' row',' rows')), NULL
  from TABLE_KEY_COUNTS t
  where `TABLE_ROWS` >= @MIN_ROWS_NO_PK_THRESHOLD
  and PRIMARY_KEY_COUNT=0 
UNION ALL
select '$RUNID',now() as TICK, @@HOSTNAME,
substr(concat('ROW_FORMAT=COMPRESSED: ',TABLE_SCHEMA,'.',TABLE_NAME),1,100) as `ITEM`,
  if(DATA_LENGTH+INDEX_LENGTH+DATA_FREE < @GB_THRESHOLD,
    concat(format((DATA_LENGTH+INDEX_LENGTH+DATA_FREE)/1024/1024,0),'M on disk needs ',format(((DATA_LENGTH+INDEX_LENGTH+DATA_FREE)*3)/1024/1024,0),'M of buffer pool'),
    concat(format((DATA_LENGTH+INDEX_LENGTH+DATA_FREE)/1024/1024/1024,2),'G on disk needs ',format(((DATA_LENGTH+INDEX_LENGTH+DATA_FREE)*3)/1024/1024/1024,2),'G of buffer pool')
  ) as `STATUS`,
  concat('ROW_FORMAT compressed tables require additional pages of buffer pool memory. InnoDB tries to keep both compressed and uncompressed pages in the buffer pool.') as `INFO`
from information_schema.TABLES 
where TABLE_SCHEMA NOT IN ('information_schema','performance_schema','sys','mysql','mariadb_review') 
and ROW_FORMAT='Compressed'
and DATA_LENGTH+INDEX_LENGTH+DATA_FREE > @ROW_FORMAT_COMPRESSED_THRESHOLD
and DATA_LENGTH is not null and INDEX_LENGTH is not null and DATA_FREE is not null
and TABLE_TYPE='BASE TABLE'
and ENGINE='InnoDB'
UNION ALL
select '$RUNID',now() as TICK, @@HOSTNAME,
concat('QUERY CACHE HITS IS LOW') as ITEM,
concat(format(VARIABLE_VALUE,0), if(VARIABLE_VALUE=1,' hit',' hits')) as `STATUS`, NULL as `INFO`
from information_schema.GLOBAL_STATUS
where VARIABLE_NAME='QCACHE_HITS'
and VARIABLE_VALUE < @LOW_QUERY_CACHE_HITS_THRESHOLD
and @QUERY_CACHE_ENABLED !='OFF'
UNION ALL
select '$RUNID',now() as TICK, @@HOSTNAME,
substr(concat('LARGE DATAFILE, FEW ROWS: ', TABLE_SCHEMA,'.',TABLE_NAME),1,100) as `ITEM`,
concat(format(((DATA_LENGTH + INDEX_LENGTH + DATA_FREE) / 1024 / 1024),0),'M, ',format(TABLE_ROWS,0),if(TABLE_ROWS=1,' ROW',' ROWS')), NULL
from information_schema.tables
where TABLE_ROWS < @LARGE_EMPTY_LOW_ROWCOUNT
and (DATA_LENGTH + INDEX_LENGTH + DATA_FREE) > @LARGE_EMPTY_DATAFILE_THRESHOLD
and DATA_LENGTH is not null and INDEX_LENGTH is not null and DATA_FREE is not null
and TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
and TABLE_TYPE='BASE TABLE'
UNION ALL
select '$RUNID',now() as TICK, @@HOSTNAME, 
if(count(*)=1, concat('THERE IS ',format(count(*),0),' MyISAM TABLE'),
               concat('THERE ARE ',format(count(*),0),' MyISAM TABLES')) as `ITEM`,
concat('MyISAM tables are not crash safe') as `STATUS`,
concat('MyISAM engine is non-transactional which means it does not support commit/rollback.') as `INFO`
from information_schema.tables 
where ENGINE='MyISAM'
and TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
and TABLE_TYPE='BASE TABLE'
group by ENGINE 
having count(*) > 0
UNION ALL
  select '$RUNID',now() as TICK, @@HOSTNAME, 
  concat(if(count(*)=1,'THERE IS ','THERE ARE '),count(*),' table',if(count(*)=1,'','s'),' ENGINE NOT InnoDB') as ITEM,
  concat('Galera only supports InnoDB tables') as STATUS,
  NULL as INFO
  from information_schema.TABLES 
  where ENGINE !='InnoDB'
  AND TABLE_SCHEMA NOT IN ('information_schema','performance_schema','sys','mysql','mariadb_review')
  AND TABLE_TYPE='BASE TABLE'
  AND @IS_GALERA='YES'
  having count(*) > 0

