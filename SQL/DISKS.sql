-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- DISKS

set @PROCEED_WITH_DISKS_1='NO';
set @PROCEED_WITH_DISKS_2='NO';
set @PROCEED_WITH_DISKS_3='NO';

select 'YES' INTO @PROCEED_WITH_DISKS_1 
FROM information_schema.USER_PRIVILEGES 
where replace(GRANTEE,'''','')=current_user() 
AND PRIVILEGE_TYPE='FILE';

select 'YES' INTO @PROCEED_WITH_DISKS_2 
FROM information_schema.PLUGINS
where PLUGIN_NAME='DISKS' and PLUGIN_LIBRARY='disks.so';

select 'YES' INTO @PROCEED_WITH_DISKS_3 
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='information_schema' and TABLE_NAME='DISKS';

 
delimiter //
begin not atomic
  if @PROCEED_WITH_DISKS_1='YES' AND @PROCEED_WITH_DISKS_2='YES'  AND @PROCEED_WITH_DISKS_3='YES'  then 
  
    select `Disk` as `DISK`, `Path` as `PATH`, `Total` as `TOTAL`, `Used` as `USED`, `Available` as `AVAILABLE`
    from information_schema.DISKS;

  ELSE
  
  select 'DISK INFORMATION IS UNAVAILABLE' as `DISK`, NULL as `PATH`, NULL as `TOTAL`, NULL as `USED`, NULL as `AVAILABLE`
  from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' limit 1;

  end if;
end;
//
delimiter ;
