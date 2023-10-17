-- Post Import script 
-- mariadb_quick_review, by Edward Stoever for MariaDB Support

use $SCHEMA_NAME;

delimiter //
begin not atomic
select PLUGIN_LIBRARY into @AUDIT_PLUGIN from PLUGINS where PLUGIN_NAME='SERVER_AUDIT';
if @AUDIT_PLUGIN='server_audit.so' then -- MariaDB Community audit
  select if(length(VARIABLE_VALUE)=0,0,
  (LENGTH(VARIABLE_VALUE) - LENGTH(REPLACE(VARIABLE_VALUE, ',', '')) + 1)) as RULE_COUNT into @AUDIT_RULE_COUNT
  from GLOBAL_VARIABLES where VARIABLE_NAME='SERVER_AUDIT_EVENTS';

  if @AUDIT_RULE_COUNT is null then set @AUDIT_RULE_COUNT = 0; end if; -- in theory, cannot happen. Just in case.

  insert into `SERVER_STATE` (`SECTION_ID`,`ITEM`,`STATUS`)
    select 1 as `SECTION_ID`, 'AUDIT PLUGIN INSTALLED' as `ITEM`,
    concat(format(@AUDIT_RULE_COUNT,0), if(@AUDIT_RULE_COUNT=1,' event audited',' events audited')) as `STATUS`
    from GLOBAL_VARIABLES where VARIABLE_NAME='SERVER_AUDIT_EVENTS';
end if;
end;
//


select count(*) into @PERFORMANCE_SAMPLES from SERVER_PERFORMANCE;
insert into `SERVER_STATE` (`SECTION_ID`,`ITEM`,`STATUS`)
select 4, 'PERFORMANCE SAMPLES COLLECTED',@PERFORMANCE_SAMPLES;
