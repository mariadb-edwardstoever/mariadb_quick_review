-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- METADATA_LOCK_INFO

set @PROCEED_WITH_METADATA_LOCK_INFO_1='NO';
set @PROCEED_WITH_METADATA_LOCK_INFO_2='NO';


select 'YES' INTO @PROCEED_WITH_METADATA_LOCK_INFO_1
FROM information_schema.PLUGINS
where PLUGIN_NAME='METADATA_LOCK_INFO' and PLUGIN_LIBRARY='metadata_lock_info.so' limit 1;

select 'YES' INTO @PROCEED_WITH_METADATA_LOCK_INFO_2 
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='information_schema' and TABLE_NAME='METADATA_LOCK_INFO';

 
delimiter //
begin not atomic
  if @PROCEED_WITH_METADATA_LOCK_INFO_1='YES' AND @PROCEED_WITH_METADATA_LOCK_INFO_2='YES'    then 
  
    select '$SUBROUTINE',now() as TICK, @@HOSTNAME,
    THREAD_ID,
    LOCK_MODE,
    LOCK_DURATION,
    LOCK_TYPE,
    TABLE_SCHEMA,
    TABLE_NAME
    from information_schema.METADATA_LOCK_INFO;

  ELSE
  
  select '$SUBROUTINE',now() as TICK, @@HOSTNAME, NULL as THREAD_ID,
  NULL as LOCK_MODE,
  NULL as LOCK_DURATION,
  NULL as LOCK_TYPE,
  NULL as TABLE_SCHEMA,
  'METADATA_LOCK_INFO PLUGIN IS NOT INSTALLED' as `TABLE_NAME`
  from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' limit 1;

  end if;
end;
//
delimiter ;
