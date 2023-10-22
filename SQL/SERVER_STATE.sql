-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- SERVER_STATE
-- RUN ONE TIME

set @GB_THRESHOLD = (5 * 1024 * 1024 * 1024); -- BELOW THIS NUMBER DISPLAY IN MB ELSE GB

select if(VARIABLE_VALUE>0,'YES','NO') into @IS_PRIMARY
  from information_schema.global_status 
  where VARIABLE_NAME='SLAVES_CONNECTED';

select if(sum(VARIABLE_VALUE)>0,'YES','NO') into @IS_REPLICA
  from information_schema.global_status 
  where VARIABLE_NAME in ('SLAVE_RECEIVED_HEARTBEATS','RPL_SEMI_SYNC_SLAVE_SEND_ACK','SLAVES_RUNNING');

select if(VARIABLE_VALUE > 0,'YES','NO') into @IS_GALERA 
  from information_schema.global_status 
  where VARIABLE_NAME='WSREP_THREAD_COUNT';

select VARIABLE_VALUE into @DB_UPTIME 
  from information_schema.global_status 
  where VARIABLE_NAME='UPTIME';

select if(VARIABLE_VALUE>0,'YES','NO') into @REPLICA_RUNNING 
  from information_schema.global_status 
  where VARIABLE_NAME='SLAVES_RUNNING';

select VARIABLE_VALUE into @SEMI_SYNC_SLAVE 
  from information_schema.global_status 
  where VARIABLE_NAME='RPL_SEMI_SYNC_SLAVE_STATUS';

select VARIABLE_VALUE into @SEMI_SYNC_MASTER 
  from information_schema.global_status 
  where VARIABLE_NAME='RPL_SEMI_SYNC_MASTER_STATUS'; 

select VARIABLE_VALUE into @CONFIGURED_SLAVE_WORKERS
  from information_schema.global_variables 
  where VARIABLE_NAME = 'SLAVE_PARALLEL_THREADS';

select count(*) into @RUNNING_SLAVE_WORKERS
  from information_schema.processlist 
  where COMMAND='Slave_worker';

select VARIABLE_VALUE into @BINARY_LOGGING 
  from information_schema.GLOBAL_VARIABLES 
  where variable_name='LOG_BIN';

select VARIABLE_VALUE into @THREAD_HAND 
  from information_schema.GLOBAL_VARIABLES 
  where VARIABLE_NAME='THREAD_HANDLING';
  
select VARIABLE_VALUE into @GEN_LOG 
  from information_schema.GLOBAL_VARIABLES 
  where VARIABLE_NAME='GENERAL_LOG';

select VARIABLE_VALUE into @EVENT_SCHED 
  from information_schema.GLOBAL_VARIABLES 
  where VARIABLE_NAME='EVENT_SCHEDULER';


SELECT 1 as `SECTION`, concat('MARIADB QUICK REVIEW VERSION') as `ITEM`, concat('$SCRIPT_VERSION') as `STATUS` from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
SELECT 1 as `SECTION`, concat('REVIEW STARTS'), cast(now() as char) from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
SELECT 1 as `SECTION`, concat('HOSTNAME'), @@hostname as STATUS from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
SELECT 1, concat('DATABASE UPTIME'),concat('Since ',date_format(now() - interval @DB_UPTIME second,'%d-%b-%Y %H:%i:%S')) from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
select 1, 'CURRENT USER',current_user() from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
select 1, 'SOFTWARE VERSION', version() from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
select 1, 'DATADIR',@@datadir from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
select 1, 
if(
  sum(DATA_LENGTH + INDEX_LENGTH + DATA_FREE) < @GB_THRESHOLD,
  'ESTIMATED DATA FILES MB',
  'ESTIMATED DATA FILES GB'
  ),
if(
  sum(DATA_LENGTH + INDEX_LENGTH + DATA_FREE) < @GB_THRESHOLD,
    concat(format(sum(DATA_LENGTH + INDEX_LENGTH + DATA_FREE)/1024/1024,2),'M'),  
    concat(format(sum(DATA_LENGTH + INDEX_LENGTH + DATA_FREE)/1024/1024/1024,2),'G')
  )
from information_schema.TABLES
where TABLE_TYPE != 'VIEW' 
and DATA_LENGTH is not null and INDEX_LENGTH is not null and DATA_FREE is not null
UNION ALL
select 2, 'IS A PRIMARY', @IS_PRIMARY from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
select 2, 'IS A REPLICA', @IS_REPLICA from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
UNION ALL
select 2, 'SEMISYNCHRONOUS PRIMARY',@SEMI_SYNC_MASTER from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @SEMI_SYNC_MASTER !='OFF'
UNION ALL
select 2, 'SLAVE IS RUNNING',@REPLICA_RUNNING from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @IS_REPLICA='YES'
UNION ALL
select 2, 'SEMISYNCHRONOUS REPLICA',@SEMI_SYNC_SLAVE from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @IS_REPLICA='YES' and @REPLICA_RUNNING='YES'
UNION ALL
select 2, 'SEMISYNCHRONOUS REPLICA', if(VARIABLE_VALUE='ON','ENABLED','DISABLED') 
    from information_schema.global_variables where variable_name='RPL_SEMI_SYNC_SLAVE_ENABLED' and @IS_REPLICA = 'YES' and @REPLICA_RUNNING!='YES'
UNION ALL
select 2, 'CONFIGURED SLAVE WORKERS',@CONFIGURED_SLAVE_WORKERS from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @CONFIGURED_SLAVE_WORKERS > 0
UNION ALL
select 2, 'RUNNING SLAVE WORKERS',@RUNNING_SLAVE_WORKERS  from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @CONFIGURED_SLAVE_WORKERS > 0
UNION ALL
select 5, VARIABLE_NAME, VARIABLE_VALUE from information_schema.global_variables where VARIABLE_NAME='SLAVE_PARALLEL_MODE' and @CONFIGURED_SLAVE_WORKERS > 0
UNION ALL
SELECT 2,'PARALLEL REPLICATION','OFF' from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @CONFIGURED_SLAVE_WORKERS = 0 and @IS_REPLICA='YES'
UNION ALL
 select 5, VARIABLE_NAME, VARIABLE_VALUE from information_schema.global_variables where VARIABLE_NAME='BINLOG_FORMAT' and @BINARY_LOGGING='ON'
UNION ALL
select 5, 'LOG_BIN (BINARY LOGGING)','OFF' from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' and @BINARY_LOGGING='OFF'
UNION ALL
select 5, 
if(VARIABLE_VALUE < @GB_THRESHOLD,
  concat(VARIABLE_NAME,' (MB)'), 
  concat(VARIABLE_NAME,' (GB)')
  ),  
if(VARIABLE_VALUE < @GB_THRESHOLD,
  concat(format(VARIABLE_VALUE/1024/1024,2),'M'),
  concat(format(VARIABLE_VALUE/1024/1024/1024,2),'G')
  )
from information_schema.GLOBAL_VARIABLES where VARIABLE_NAME='INNODB_BUFFER_POOL_SIZE'
UNION ALL
select 5, VARIABLE_NAME, VARIABLE_VALUE from information_schema.GLOBAL_VARIABLES 
  where VARIABLE_NAME IN ('THREAD_HANDLING','THREAD_POOL_SIZE') and @THREAD_HAND !='one-thread-per-connection' 
UNION ALL
select 5, VARIABLE_NAME, VARIABLE_VALUE from information_schema.GLOBAL_VARIABLES 
  where VARIABLE_NAME IN ('GENERAL_LOG','GENERAL_LOG_FILE','LOG_OUTPUT') and @GEN_LOG != 'OFF'
UNION ALL
select 5, VARIABLE_NAME as `ITEM`, concat('Not set') as `STATUS` 
from information_schema.GLOBAL_VARIABLES 
where VARIABLE_NAME='LOG_ERROR' 
and (VARIABLE_VALUE='' or VARIABLE_VALUE is null)
UNION ALL
select 3, 'USER CREATED SCHEMAS', count(*) from information_schema.schemata where SCHEMA_NAME not in
('information_schema','performance_schema','sys','mysql','mariadb_review') having count(*) > 0
UNION ALL
select 3, 'USER CREATED BASE TABLES', count(*) from information_schema.tables where TABLE_SCHEMA not in
('information_schema','performance_schema','sys','mysql','mariadb_review') and TABLE_TYPE = 'BASE TABLE'
having count(*) > 0
UNION ALL
select 3, 'USER CREATED SEQUENCES', count(*) from information_schema.tables where TABLE_SCHEMA not in
('information_schema','performance_schema','sys','mysql','mariadb_review') and TABLE_TYPE = 'SEQUENCE' 
having count(*) > 0
UNION ALL
select 3, 'USER CREATED VIEWS', count(*) from information_schema.tables where TABLE_SCHEMA not in
('information_schema','performance_schema','sys','mysql','mariadb_review') and TABLE_TYPE = 'VIEW' 
having count(*) > 0
UNION ALL
select 3, 'USER CREATED ROUTINES', count(*) from information_schema.routines where ROUTINE_SCHEMA not in
('information_schema','performance_schema','sys','mysql','mariadb_review') 
having count(*) > 0
UNION ALL
select 3, 'USER CREATED PARTITIONED TABLES', count(distinct TABLE_SCHEMA,TABLE_NAME) as partitioned_table_count 
FROM information_schema.partitions 
WHERE PARTITION_NAME is not null
AND TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review') 
having count(distinct TABLE_SCHEMA,TABLE_NAME) > 0
UNION ALL
  select 3, 'USER CREATED EVENTS', count(*) from information_schema.EVENTS 
  WHERE EVENT_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review') 
  AND @EVENT_SCHED='ON'
  having count(*) > 0
UNION ALL
select 3, concat('USER CREATED ',INDEX_TYPE,' INDEXES') as `ITEM`, count(*) as `STATUS`
from information_schema.`STATISTICS`
where INDEX_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
group by INDEX_TYPE 
having count(*) > 0
UNION ALL
select 3, 'USER CREATED TRIGGERS', count(*) 
from information_schema.`TRIGGERS`
where TRIGGER_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
having count(*) > 0
UNION ALL
select 3, 'STORED GENERATED COLUMNS', count(*) 
from information_schema.`COLUMNS`
where TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
and EXTRA='STORED GENERATED' having count(*) > 0
UNION ALL
select 3, 'VIRTUAL GENERATED COLUMNS', count(*) 
from information_schema.`COLUMNS`
where TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
and EXTRA='VIRTUAL GENERATED' having count(*) > 0
UNION ALL
select 3, concat('TABLES ',ENGINE,' ENGINE'), count(*) from information_schema.tables 
where ENGINE is not null 
and TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
group by  ENGINE having count(*) > 0
UNION ALL 
select 3 as SECTION_ID, concat('TABLES INNODB ROW_FORMAT ',upper(row_format)) as ITEM, count(*) as STATUS
from information_schema.tables 
where engine='InnoDB' 
and TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
group by row_format
having count(*) > 0
UNION ALL
select 3, 'TABLES WITH PAGE COMPRESSION', count(*) 
from information_schema.tables 
where CREATE_OPTIONS like '%PAGE_COMPRESSED%ON%'
having count(*) > 0
UNION ALL
select 3, 'TABLESPACES WITH DATA-AT-REST ENCRYPTION', count(NAME) 
from information_schema.INNODB_TABLESPACES_ENCRYPTION
having count(*) > 0
UNION ALL
select 3, 'SYSTEM VERSIONED TABLES', count(*) 
from information_schema.tables where TABLE_TYPE='SYSTEM VERSIONED' having count(*) > 0
UNION ALL
select 3, 'ALT DATA DIR DEFINED TABLES', count(*) from information_schema.tables 
where CREATE_OPTIONS like '%DATA DIRECTORY%' having count(*) > 0
UNION ALL
select 3, 'ALT INDEX DIR DEFINED TABLES', count(*) from information_schema.tables 
where CREATE_OPTIONS like '%INDEX DIRECTORY%' having count(*) > 0
UNION ALL
select 4, 'PERFORMANCE RUN ID','$RUNID'

