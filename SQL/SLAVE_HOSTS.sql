-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- SLAVE_HOSTS

select 'YES' INTO @PROCEED_WITH_SHOW_SLAVE_HOSTS 
FROM information_schema.USER_PRIVILEGES 
where replace(GRANTEE,'''','')=current_user() 
AND PRIVILEGE_TYPE='REPLICATION MASTER ADMIN';

delimiter //
begin not atomic
  if @PROCEED_WITH_SHOW_SLAVE_HOSTS='YES' then 
    SHOW SLAVE HOSTS; 
  else
  select NULL as `Server_id`,concat('Requires REPLICATION MASTER ADMIN privilege.') as `Host`, NULL as `PORT`, NULL as `Master_id`;
  end if;
end;
//

