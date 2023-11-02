-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- CURRENT_RUN
select if(VARIABLE_VALUE>0,'YES','NO') into @IS_PRIMARY
  from information_schema.global_status
  where VARIABLE_NAME='SLAVES_CONNECTED';

select if(sum(VARIABLE_VALUE)>0,'YES','NO') into @IS_REPLICA
  from information_schema.global_status
  where VARIABLE_NAME in ('SLAVE_RECEIVED_HEARTBEATS','RPL_SEMI_SYNC_SLAVE_SEND_ACK','SLAVES_RUNNING');

select if(VARIABLE_VALUE > 0,'YES','NO') into @IS_GALERA
  from information_schema.global_status
  where VARIABLE_NAME='WSREP_THREAD_COUNT';

select VARIABLE_VALUE into @SLAVES_RUNNING
  from information_schema.global_status
  where VARIABLE_NAME = 'SLAVES_RUNNING';

select '$RUNID' as RUN_ID, current_user() as RUN_BY, @@hostname as RUN_ON, now() as RUN_START, '$CLIENT_HOST' as CLIENT_HOST, '$CLIENT_DT' as CLIENT_DT, '$CLIENT_OS_ACCT' as CLIENT_OS_ACCOUNT, @IS_PRIMARY as IS_PRIMARY, @IS_REPLICA as IS_REPLICA, @SLAVES_RUNNING as SLAVES_RUNNING, @IS_GALERA as IS_GALERA

