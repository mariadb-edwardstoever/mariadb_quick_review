-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support

select if(sum(VARIABLE_VALUE)>0,'YES','NO') into @IS_REPLICA
  from information_schema.global_status
  where VARIABLE_NAME in ('SLAVE_RECEIVED_HEARTBEATS','RPL_SEMI_SYNC_SLAVE_SEND_ACK','SLAVES_RUNNING');

delimiter //
begin not atomic
set @MISSING_PRIVS='NONE';
select GROUP_CONCAT(`PRIVILEGE` SEPARATOR ', ') into @MISSING_PRIVS from (
select 1 as `ONE`, `PRIVILEGE` FROM(
WITH REQUIRED_PRIVS as (
select 'SELECT' as PRIVILEGE UNION ALL
select 'PROCESS' as PRIVILEGE UNION ALL
select 'FILE'  as PRIVILEGE UNION ALL
select 'SLAVE MONITOR' as PRIVILEGE  where @IS_REPLICA='YES' )
SELECT A.PRIVILEGE , B.TABLE_CATALOG
from REQUIRED_PRIVS A
LEFT OUTER JOIN 
information_schema.USER_PRIVILEGES B
ON (A.PRIVILEGE=B.PRIVILEGE_TYPE AND replace(B.GRANTEE,'''','')=current_user())
) as X where TABLE_CATALOG is null) as Y group by `ONE`;
 IF @MISSING_PRIVS != 'NONE' THEN
 
  SELECT concat('Insufficient privileges. Grant ',@MISSING_PRIVS,' on *.* to ',CONCAT('\'',REPLACE(CURRENT_USER(),'@','\'@\''),'\'')) as NOTE; 
   
 END IF;
end;
//
delimiter ;

