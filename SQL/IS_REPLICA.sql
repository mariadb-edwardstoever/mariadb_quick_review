-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- IS_REPLICA
select if(sum(VARIABLE_VALUE)>0,'YES','NO') 
  from information_schema.global_status 
  where VARIABLE_NAME in ('SLAVE_RECEIVED_HEARTBEATS','RPL_SEMI_SYNC_SLAVE_SEND_ACK','SLAVES_RUNNING')

