-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- LOW_CARDINALITY_IDX 
-- RUN ONE TIME

SET @WARN_LOW_CARDINALITY_PCT=2;

SELECT @RUNID, now() as TICK, @@hostname,
substr(concat('LOW CARDIN IDX: ',A.TABLE_SCHEMA,'.',A.TABLE_NAME),1,100) as ITEM,
substr(concat('Index ',A.INDEX_NAME,': ',format(A.CARDINALITY,0),' unique values'),1,150) as STATUS, NULL
FROM information_schema.STATISTICS A 
INNER JOIN information_schema.TABLES B 
on (A.TABLE_SCHEMA=B.TABLE_SCHEMA and A.TABLE_NAME=B.TABLE_NAME) 
WHERE A.NON_UNIQUE != 0 
AND (A.CARDINALITY/B.TABLE_ROWS)*100 < @WARN_LOW_CARDINALITY_PCT
AND B.TABLE_ROWS >= @MIN_ROWS_TO_CHECK_INDEX_CARDINALITY
and A.TABLE_SCHEMA not in ('information_schema','performance_schema','sys','mysql','mariadb_review')
and B.TABLE_TYPE='BASE TABLE'

