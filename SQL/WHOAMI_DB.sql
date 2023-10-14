-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- WHOAMI_DB
select CONCAT('\'',REPLACE(REPLACE(CURRENT_USER(),'@','\'@\''),'%','%%'),'\'') as WHOAMI

