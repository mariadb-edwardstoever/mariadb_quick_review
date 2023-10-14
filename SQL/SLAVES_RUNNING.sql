-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- SLAVES_RUNNING
select VARIABLE_VALUE
  from information_schema.global_status 
  where VARIABLE_NAME='SLAVES_RUNNING'
