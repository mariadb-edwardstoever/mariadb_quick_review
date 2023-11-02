-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- ALL_SLAVES_STATUS
-- RUN MULTIPLE TIMES

    SHOW ALL SLAVES STATUS\G
	select concat('DB_Time: ',now()) as TXT from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'
	UNION ALL
	select concat('Hostname: ',@@hostname) as TXT from information_schema.SCHEMATA where SCHEMA_NAME='information_schema'

