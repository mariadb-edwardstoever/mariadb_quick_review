-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- GLOBAL_STATUS
-- RUN ONE TIME

select VARIABLE_NAME, VARIABLE_VALUE from information_schema.GLOBAL_STATUS order by VARIABLE_NAME asc

