-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- SLAVE_STATUS
-- RUN MULTIPLE TIMES

    SHOW SLAVE STATUS\G
    select concat ('Gtid_Slave_Pos: ',VARIABLE_VALUE) as TXT from information_schema.GLOBAL_VARIABLES where VARIABLE_NAME='GTID_SLAVE_POS'
	UNION ALL
	select concat('DB_Time: ',now()) as TXT from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
	UNION ALL
	select concat('Hostname: ',@@hostname) as TXT from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'

