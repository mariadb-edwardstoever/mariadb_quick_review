-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- IS_DB_LOCALHOST

  select VARIABLE_VALUE from information_schema.GLOBAL_VARIABLES where VARIABLE_NAME='HOSTNAME' limit 1
