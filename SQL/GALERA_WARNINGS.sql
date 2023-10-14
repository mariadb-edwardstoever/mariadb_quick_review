-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- GALERA_WARNINGS
-- RUN MULTIPLE TIMES

SET @GALERA_LONG_RUNNING_TXN_MS=330;

  select '$SUBROUTINE',now() as TICK, @@HOSTNAME, 
  'GALERA FLOW CONTROL IS ACTIVE' as ITEM,
  'Verify that tables have required keys' as STATUS
  from information_schema.GLOBAL_STATUS 
  where VARIABLE_NAME='WSREP_FLOW_CONTROL_ACTIVE'
  and VARIABLE_VALUE='true'
UNION ALL
  select '$SUBROUTINE',now() as TICK, @@HOSTNAME, 
  substr(concat('LONG RUNNING TXN, QUERY_ID: ',QUERY_ID),1,100) as ITEM,
  substr(concat('USER: ',if(USER='system user',USER,concat('`',USER,'`@`',HOST,'`')),', TIME_MS: ',TIME_MS),1,150) as STATUS
  from information_schema.processlist
  where TIME_MS > @GALERA_LONG_RUNNING_TXN_MS
  and INFO is not null
  and STATE in ('Commit','Updating','Sending data')
UNION ALL
  select '$SUBROUTINE',now() as TICK, @@HOSTNAME, 
  substr(concat('REPLICATING TXN NO INDEX, QUERY_ID: ',QUERY_ID),1,100) as ITEM,
  substr(concat(`DB`,'.',SUBSTRING_INDEX(SUBSTRING_INDEX(`STATE`,'`',2),'`',-1)),1,150) as `STATUS`
  from information_schema.processlist
  where `STATE` like '%rows_log_event::find_row(%) on table%'
  and USER='system user'

