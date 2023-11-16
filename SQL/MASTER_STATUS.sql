-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- MASTER_STATUS

set @PROCEED_WITH_MASTER_STATUS_1='NO';
set @PROCEED_WITH_MASTER_STATUS_2='NO';


select 'YES' INTO @PROCEED_WITH_MASTER_STATUS_1
FROM information_schema.GLOBAL_VARIABLES
where VARIABLE_NAME='LOG_BIN' and VARIABLE_VALUE='ON' limit 1;

select 'YES' INTO @PROCEED_WITH_MASTER_STATUS_2
FROM information_schema.USER_PRIVILEGES
where replace(GRANTEE,'''','')=current_user()
AND (PRIVILEGE_TYPE='BINLOG MONITOR' OR PRIVILEGE_TYPE='REPLICATION CLIENT') limit 1;


 
delimiter //
begin not atomic
  if @PROCEED_WITH_MASTER_STATUS_1='YES' AND @PROCEED_WITH_MASTER_STATUS_2='YES' then 

    show master status;

ELSE
  
  SELECT
  'MASTER STATUS INFORMATION IS NOT AVAILABLE.' as `File`, 
  NULL as `Position`, NULL as `Binlog_Do_DB`, NULL as `Binlog_Ignore_DB`
  from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' limit 1;

  end if;
end;
//
delimiter ;
