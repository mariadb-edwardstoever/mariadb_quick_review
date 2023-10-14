-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- PERFORMANCE_WARNINGS
-- RUN MULTIPLE TIMES

set @LONG_RUNNING_TRX_THRESHOLD_MINUTES = 10;
set @REDO_WARNING_PCT_THRESHOLD=50;

select if(VARIABLE_VALUE>0,'YES','NO') into @REPLICA_RUNNING 
  from information_schema.global_status 
  where VARIABLE_NAME='SLAVES_RUNNING';

select VARIABLE_VALUE into @LOG_FILE_CAPACITY
    from information_schema.global_variables
    where VARIABLE_NAME='INNODB_LOG_FILE_SIZE';

SELECT VARIABLE_VALUE INTO @CHECKPOINT_AGE
  FROM information_schema.GLOBAL_STATUS
  WHERE VARIABLE_NAME='INNODB_CHECKPOINT_AGE';

SET @OCCUPANCY=format((@CHECKPOINT_AGE/@LOG_FILE_CAPACITY)*100,2);

  WITH `BLOCKERS` AS (
  SELECT r.trx_id AS WAITING_TRX_ID, 
  r.trx_mysql_thread_id AS WAITING_THREAD, 
  pl1.USER AS WAITING_USER, pl1.HOST AS WAITING_HOST,
  r.trx_query AS WAITING_QUERY,
  b.trx_id AS BLOCKING_TRX_ID, 
  pl2.USER AS BLOCKING_USER, pl2.HOST AS BLOCKING_HOST,
  b.trx_mysql_thread_id AS BLOCKING_THREAD
  FROM information_schema.innodb_lock_waits w
  INNER JOIN information_schema.innodb_trx b
  ON b.trx_id = w.blocking_trx_id
  INNER JOIN information_schema.innodb_trx AS r
  ON r.trx_id = w.requesting_trx_id
  INNER JOIN information_schema.processlist pl1
  ON r.trx_mysql_thread_id = pl1.ID
  INNER JOIN information_schema.processlist pl2
  ON b.trx_mysql_thread_id =pl2.ID) 
  SELECT '$SUBROUTINE',now() as TICK, @@HOSTNAME, 
  substr(CONCAT(BLOCKING_USER,'@',SUBSTRING_INDEX(BLOCKING_HOST,':',1),' (PID:',BLOCKING_THREAD,') BLOCKING TXN'),1,100) AS `ITEM`,
  substr(CONCAT(WAITING_USER,'@',SUBSTRING_INDEX(WAITING_HOST,':',1),' (PID:',WAITING_THREAD,') WAITING'),1,150) AS `STATUS`,
  CONCAT('WAITING QUERY: ',WAITING_QUERY) AS `INFO`
  FROM `BLOCKERS`
UNION ALL
  select '$SUBROUTINE',now() as TICK, @@HOSTNAME, 
  substr(concat('MULTI-ROW UPDATE FROM MASTER, NO INDEX, QUERY_ID: ',QUERY_ID),1,100),
  concat(`DB`,'.',SUBSTRING_INDEX(SUBSTRING_INDEX(`STATE`,'`',2),'`',-1)),`INFO`
  from information_schema.processlist
  where `USER` = 'system user' 
  and `COMMAND` in ('Slave_SQL','Slave_worker')
  and `STATE` like 'Update_rows_log_event::find_row(%) on table%' 
  and @REPLICA_RUNNING = 'YES' 
UNION ALL
  select '$SUBROUTINE',now() as TICK, @@HOSTNAME, 
  substr(concat('MULTI-ROW DELETE FROM MASTER, NO INDEX, QUERY_ID: ',QUERY_ID),1,100),
  concat(`DB`,'.',SUBSTRING_INDEX(SUBSTRING_INDEX(`STATE`,'`',2),'`',-1)),`INFO`
  from information_schema.processlist
  where `USER` = 'system user' 
  and `COMMAND` in ('Slave_SQL','Slave_worker')
  and `STATE` like 'Delete_rows_log_event::find_row(%) on table%' 
  and @REPLICA_RUNNING = 'YES'
UNION ALL
   SELECT '$SUBROUTINE',now() as TICK, @@HOSTNAME, 'REDO OCCUPANCY IS HIGH',concat(@OCCUPANCY,'%'), @OCCUPANCY
   from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
  and @OCCUPANCY is not null and @OCCUPANCY >= @REDO_WARNING_PCT_THRESHOLD
UNION ALL
  select '$SUBROUTINE',now() as TICK, @@HOSTNAME,
  concat('LONG RUNNING TRX QUERY_ID: ',B.QUERY_ID) as ITEM,
  if(B.USER='system user',concat(B.USER,', trx started ',date_format(A.trx_started,'%b %d %H:%i')),concat(B.USER,'@',SUBSTRING_INDEX(B.HOST,':',1),', trx started ',date_format(A.trx_started,'%b %d %H:%i'))) as STATUS,
  trx_query as INFO
  from information_schema.INNODB_TRX A
  INNER JOIN information_schema.PROCESSLIST B on (A.trx_mysql_thread_id = B.ID)
  WHERE A.trx_started < now() - interval @LONG_RUNNING_TRX_THRESHOLD_MINUTES minute
UNION ALL
  SELECT '$SUBROUTINE',now() as TICK, @@HOSTNAME,
  substr(concat('TXID ', LW1.blocking_trx_id,' is in a DEADLOCK with ', LW2.blocking_trx_id),1,100) as ITEM, 
  substr(concat('DEADLOCKED USER: ',PL.USER,'@',PL.HOST,' is stuck for ',format(TIME_MS/1000,2), ' seconds.'),1,150) as STATUS,
  TRX.trx_query as INFO
  FROM information_schema.INNODB_LOCK_WAITS LW1
  INNER JOIN information_schema.INNODB_LOCK_WAITS LW2
  ON (LW1.requesting_trx_id = LW2.blocking_trx_id AND LW2.requesting_trx_id = LW1.blocking_trx_id)
  INNER JOIN information_schema.INNODB_TRX TRX
  ON LW1.blocking_trx_id=TRX.trx_id
  INNER JOIN information_schema.PROCESSLIST PL
  ON TRX.trx_mysql_thread_id = PL.ID

