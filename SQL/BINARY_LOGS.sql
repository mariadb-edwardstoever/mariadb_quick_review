-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- BINARY_LOGS

set @PROCEED_WITH_BINARY_LOGS_1='NO';
set @PROCEED_WITH_BINARY_LOGS_2='NO';


select 'YES' INTO @PROCEED_WITH_BINARY_LOGS_1
FROM information_schema.GLOBAL_VARIABLES
where VARIABLE_NAME='LOG_BIN' and VARIABLE_VALUE='ON' limit 1;

select 'YES' INTO @PROCEED_WITH_BINARY_LOGS_2
FROM information_schema.USER_PRIVILEGES
where replace(GRANTEE,'''','')=current_user()
AND (PRIVILEGE_TYPE='BINLOG MONITOR' OR PRIVILEGE_TYPE='REPLICATION CLIENT') limit 1;


 
delimiter //
begin not atomic
  if @PROCEED_WITH_BINARY_LOGS_1='YES' AND @PROCEED_WITH_BINARY_LOGS_2='YES'    then 
  
    show binary logs;

ELSE
  
  SELECT
  'BINARY LOG INFORMATION IS NOT AVAILABLE.' as `Log_name`, 
  NULL as `File_size`
  from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' limit 1;

  end if;
end;
//
delimiter ;
