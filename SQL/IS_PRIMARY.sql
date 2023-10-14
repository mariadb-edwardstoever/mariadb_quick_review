-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- IS_PRIMARY
select if(VARIABLE_VALUE>0,'YES','NO')
  from information_schema.global_status 
  where VARIABLE_NAME='SLAVES_CONNECTED'
