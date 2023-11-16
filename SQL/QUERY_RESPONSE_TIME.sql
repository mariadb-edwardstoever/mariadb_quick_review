-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- QUERY_RESPONSE_TIME

set @PROCEED_WITH_QUERY_RESPONSE_TIME_1='NO';
set @PROCEED_WITH_QUERY_RESPONSE_TIME_2='NO';

select 'YES' INTO @PROCEED_WITH_QUERY_RESPONSE_TIME_1 
FROM information_schema.PLUGINS
where PLUGIN_NAME='QUERY_RESPONSE_TIME' and PLUGIN_LIBRARY='query_response_time.so';

select 'YES' INTO @PROCEED_WITH_QUERY_RESPONSE_TIME_2
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='information_schema' and TABLE_NAME='QUERY_RESPONSE_TIME';

 
delimiter //
begin not atomic
  if @PROCEED_WITH_QUERY_RESPONSE_TIME_1='YES' AND @PROCEED_WITH_QUERY_RESPONSE_TIME_2='YES'  then 
  
    select '$SUBROUTINE', now() as TICK, @@HOSTNAME as `HOSTNAME`,
	`TIME`, `COUNT`, `TOTAL`
    from information_schema.QUERY_RESPONSE_TIME;

  ELSE
  
  select '$SUBROUTINE', now() as TICK, @@HOSTNAME as `HOSTNAME`, 
  'QUERY_RESPONSE_TIME INFORMATION IS UNAVAILABLE' as `TIME`, NULL as `COUNT`, NULL as `TOTAL`
  from information_schema.SCHEMATA where SCHEMA_NAME='information_schema' limit 1;

  end if;
end;
//
delimiter ;
