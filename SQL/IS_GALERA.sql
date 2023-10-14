-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- IS_GALERA
select if(VARIABLE_VALUE > 0,'YES','NO') 
  from information_schema.global_status 
  where VARIABLE_NAME='WSREP_THREAD_COUNT'

