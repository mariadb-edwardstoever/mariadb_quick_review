-- Create schema for Support ticket to review customer provided data.
-- mariadb_quick_review, by Edward Stoever for MariaDB Support

drop schema if exists $SCHEMA_NAME;
create schema $SCHEMA_NAME;
use $SCHEMA_NAME;

CREATE TABLE `CURRENT_RUN` (
  `ID` int(11) NOT NULL DEFAULT 1,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `RUN_BY` varchar(385) DEFAULT NULL,
  `RUN_ON` varchar(256) DEFAULT NULL,
  `RUN_START` datetime DEFAULT NULL,
  `CLIENT_HOST` varchar(256) DEFAULT NULL,
  `CLIENT_DT` datetime DEFAULT NULL,
  `CLIENT_OS_ACCT` varchar(64) DEFAULT NULL,
  `IS_PRIMARY` varchar(10) DEFAULT NULL,
  `IS_REPLICA` varchar(10) DEFAULT NULL,
  `IS_GALERA` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci COMMENT='The CURRENT_RUN table should never have more than 1 row.';

CREATE TABLE `SERVER_PERFORMANCE` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` timestamp NOT NULL DEFAULT current_timestamp(),
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `REDO_LOG_OCCUPANCY_PCT` decimal(8,2) DEFAULT NULL,
  `THREADS_CONNECTED` int(11) DEFAULT NULL,
  `HANDLER_READ_RND_NEXT` bigint(20) DEFAULT NULL,
  `COM_SELECT` bigint(20) DEFAULT NULL,
  `COM_INSERT` bigint(20) DEFAULT NULL,
  `COM_UPDATE` bigint(20) DEFAULT NULL,
  `COM_DELETE` bigint(20) DEFAULT NULL,
  `COM_XA_COMMIT` bigint(20) DEFAULT NULL,
  `SLOW_QUERIES` bigint(20) DEFAULT NULL,
  `INNODB_ROW_LOCK_CURRENT_WAITS` bigint(20) DEFAULT NULL,
  `INNODB_BUFFER_POOL_READS` bigint(20) DEFAULT NULL,
  `INNODB_BUFFER_POOL_READ_REQUESTS` bigint(20) DEFAULT NULL,
  `MEMORY_USED` bigint(20) DEFAULT NULL,
  `BINLOG_COMMITS` bigint(20) DEFAULT NULL,
  `INNODB_BUFFER_POOL_BYTES_DATA` bigint(20) DEFAULT NULL,
  `INNODB_DATA_WRITES` bigint(20) DEFAULT NULL,
  `INNODB_OS_LOG_WRITTEN` bigint(20) DEFAULT NULL,
  `INNODB_HISTORY_LIST_LENGTH` bigint(20) DEFAULT NULL,
  `COM_STMT_PREPARE` bigint(20) DEFAULT NULL,
  `COM_STMT_EXECUTE` bigint(20) DEFAULT NULL,
  `QCACHE_QUERIES_IN_CACHE` bigint(20) DEFAULT NULL,
  `QCACHE_FREE_MEMORY` bigint(20) DEFAULT NULL,
  `QCACHE_HITS` bigint(20) DEFAULT NULL,
  `QCACHE_INSERTS` bigint(20) DEFAULT NULL,
  `QCACHE_LOWMEM_PRUNES` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `LOW_CARDINALITY_IDX` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TICK` datetime DEFAULT NULL,
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `ITEM` varchar(100) DEFAULT NULL,
  `STATUS` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `PERFORMANCE_WARNINGS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` datetime DEFAULT NULL,
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `ITEM` varchar(100) DEFAULT NULL,
  `STATUS` varchar(150) DEFAULT NULL,
  `INFO` longtext DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `REVIEW_WARNINGS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` datetime DEFAULT NULL,
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `ITEM` varchar(100) DEFAULT NULL,
  `STATUS` varchar(150) DEFAULT NULL,
  `INFO` longtext DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `GALERA_WARNINGS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` datetime DEFAULT NULL,
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `ITEM` varchar(100) DEFAULT NULL,
  `STATUS` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB   DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `GTID_POSITIONS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` timestamp NOT NULL DEFAULT current_timestamp(),
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `GTID_BINLOG_POS` varchar(200) comment 'The last event written to the binary log',
  `GTID_BINLOG_STATE` varchar(200) comment 'The last sequence per combination of domain_id and server_id in binary log history',
  `GTID_CURRENT_POS` varchar(200) comment 'The last transaction applied to the database',
  `GTID_SLAVE_POS` varchar(200) comment 'The last transaction applied to the database by the replica threads',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `TABLE_KEY_COUNTS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TABLE_SCHEMA` varchar(64) DEFAULT NULL,
  `TABLE_NAME` varchar(64) DEFAULT NULL,
  `ENGINE` varchar(64) DEFAULT NULL,
  `PRIMARY_KEY_COUNT` int(11) DEFAULT NULL,
  `UNIQUE_KEY_COUNT` int(11) DEFAULT NULL,
  `NON_UNIQUE_KEY_COUNT` int(11) DEFAULT NULL,
  `ROW_FORMAT` varchar(32) DEFAULT NULL,
  `TABLE_ROWS` bigint(21) DEFAULT NULL,
  `AVG_ROW_LENGTH` bigint(21) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `SERVER_STATE` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `SECTION_ID` int(11) NOT NULL,
  `ITEM` varchar(72) NOT NULL,
  `STATUS` varchar(72) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `PROCESSLIST` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` datetime DEFAULT NULL,
  `CONNECTION_ID` bigint(20) DEFAULT NULL,
  `USER` varchar(256) DEFAULT NULL,
  `HOST` varchar(128) DEFAULT NULL,
  `DB` varchar(128) DEFAULT NULL,
  `COMMAND` varchar(64) DEFAULT NULL,
  `TIME` int(11) DEFAULT NULL,
  `STATE` varchar(128) DEFAULT NULL,
  `INFO` longtext DEFAULT NULL,
  `TIME_MS` decimal(24,3) DEFAULT NULL,
  `STAGE` tinyint(4) DEFAULT NULL,
  `MAX_STAGE` tinyint(4) DEFAULT NULL,
  `PROGRESS` decimal(8,3) DEFAULT NULL,
  `MEMORY_USED` bigint(20) DEFAULT NULL,
  `MAX_MEMORY_USED` bigint(20) DEFAULT NULL,
  `EXAMINED_ROWS` int(11) DEFAULT NULL,
  `QUERY_ID` bigint(20) DEFAULT NULL,
  `TID` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `GLOBAL_VARIABLES` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `VARIABLE_NAME` varchar(64) NOT NULL,
  `VARIABLE_VALUE` varchar(2048) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `GLOBAL_STATUS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `VARIABLE_NAME` varchar(64) NOT NULL,
  `VARIABLE_VALUE` varchar(2048) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `SECTION_TITLES` (
  `SECTION_ID` int(11) NOT NULL,
  `TITLE` varchar(72) NOT NULL,
  PRIMARY KEY (`SECTION_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `SECTION_TITLES` VALUES (1,'SERVER'),(2,'TOPOLOGY'),(3,'SCHEMAS'),(4,'PERFORMANCE'),(5,'GLOBALS'),(6,'WARNINGS'),(7,'GALERA');

CREATE TABLE IF NOT EXISTS `GALERA_MARIADB_VERSIONS` (
  `galera_version` varchar(20) NOT NULL,
  `mariadb_version` varchar(20) NOT NULL,
  PRIMARY KEY (`galera_version`,`mariadb_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT IGNORE INTO `GALERA_MARIADB_VERSIONS` VALUES ('26.4.0','10.4.2'),('26.4.1','10.4.3'),('26.4.11','10.4.22'),
  ('26.4.11','10.4.23'),('26.4.11','10.4.24'),('26.4.11','10.4.25'),('26.4.11','10.5.14'),('26.4.11','10.5.15'),
  ('26.4.11','10.5.16'),('26.4.11','10.6.6'),('26.4.11','10.7.2'),('26.4.11','10.7.3'),('26.4.11','10.7.4'),
  ('26.4.11','10.8.1'),('26.4.11','10.8.2'),('26.4.11','10.8.3'),('26.4.12','10.10.1'),('26.4.12','10.4.26'),
  ('26.4.12','10.5.17'),('26.4.12','10.6.10'),('26.4.12','10.6.9'),('26.4.12','10.7.5'),('26.4.12','10.7.6'),
  ('26.4.12','10.8.4'),('26.4.12','10.8.5'),('26.4.12','10.9.2'),('26.4.12','10.9.3'),('26.4.13','10.10.2'),
  ('26.4.13','10.4.27'),('26.4.13','10.5.18'),('26.4.13','10.6.11'),('26.4.13','10.7.7'),('26.4.13','10.8.6'),
  ('26.4.13','10.9.4'),('26.4.14','10.10.3'),('26.4.14','10.4.28'),('26.4.14','10.4.29'),('26.4.14','10.4.30'),
  ('26.4.14','10.5.19'),('26.4.14','10.5.20'),('26.4.14','10.5.21'),('26.4.14','10.6.12'),('26.4.14','10.6.13'),
  ('26.4.14','10.6.14'),('26.4.14','10.7.8'),('26.4.14','10.8.7'),('26.4.14','10.9.5'),('26.4.2','10.4.4'),
  ('26.4.2','10.4.5'),('26.4.2','10.4.6'),('26.4.2','10.4.7'),('26.4.2','10.4.8'),('26.4.3','10.4.9'),
  ('26.4.3','10.5.0'),('26.4.4','10.4.13'),('26.4.4','10.5.1'),('26.4.4','10.5.2'),('26.4.4','10.5.3'),
  ('26.4.5','10.4.14'),('26.4.5','10.4.15'),('26.4.5','10.5.4'),('26.4.5','10.5.5'),('26.4.6','10.4.16'),
  ('26.4.6','10.4.17'),('26.4.6','10.5.7'),('26.4.6','10.5.8'),('26.4.7','10.4.18'),('26.4.7','10.5.9'),
  ('26.4.8','10.4.19'),('26.4.8','10.4.20'),('26.4.8','10.5.10'),('26.4.8','10.5.11'),('26.4.8','10.6.1'),
  ('26.4.8','10.6.2'),('26.4.8','10.6.3'),('26.4.9','10.4.20'),('26.4.9','10.4.21'),('26.4.9','10.5.12'),
  ('26.4.9','10.5.13'),('26.4.9','10.6.4'),('26.4.9','10.6.5');

CREATE TABLE `GALERA_PERFORMANCE` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` timestamp NOT NULL DEFAULT current_timestamp(),
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `WSREP_APPLIER_THREAD_COUNT` bigint(20) DEFAULT NULL,
  `WSREP_APPLY_OOOE` decimal(20,10) DEFAULT NULL,
  `WSREP_APPLY_OOOL` decimal(20,10) DEFAULT NULL,
  `WSREP_APPLY_WAITS` bigint(20) DEFAULT NULL,
  `WSREP_APPLY_WINDOW` decimal(20,10) DEFAULT NULL,
  `WSREP_CAUSAL_READS` bigint(20) DEFAULT NULL,
  `WSREP_CERT_DEPS_DISTANCE` decimal(20,10) DEFAULT NULL,
  `WSREP_CERT_INDEX_SIZE` bigint(20) DEFAULT NULL,
  `WSREP_CERT_INTERVAL` decimal(20,10) DEFAULT NULL,
  `WSREP_DESYNC_COUNT` bigint(20) DEFAULT NULL,
  `WSREP_EVS_DELAYED` varchar(256) DEFAULT NULL,
  `WSREP_EVS_EVICT_LIST` varchar(256) DEFAULT NULL,
  `WSREP_EVS_REPL_LATENCY` varchar(256) DEFAULT NULL,
  `WSREP_FLOW_CONTROL_ACTIVE` varchar(20) DEFAULT NULL,
  `WSREP_FLOW_CONTROL_PAUSED` decimal(20,10) DEFAULT NULL,
  `WSREP_FLOW_CONTROL_PAUSED_NS` bigint(20) DEFAULT NULL,
  `WSREP_FLOW_CONTROL_RECV` bigint(20) DEFAULT NULL,
  `WSREP_FLOW_CONTROL_REQUESTED` varchar(20) DEFAULT NULL,
  `WSREP_FLOW_CONTROL_SENT` bigint(20) DEFAULT NULL,
  `WSREP_LAST_COMMITTED` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_BF_ABORTS` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_CACHED_DOWNTO` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_CERT_FAILURES` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_COMMITS` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_INDEX` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_RECV_QUEUE` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_RECV_QUEUE_AVG` decimal(20,10) DEFAULT NULL,
  `WSREP_LOCAL_RECV_QUEUE_MAX` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_RECV_QUEUE_MIN` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_REPLAYS` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_SEND_QUEUE` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_SEND_QUEUE_AVG` decimal(20,10) DEFAULT NULL,
  `WSREP_LOCAL_SEND_QUEUE_MAX` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_SEND_QUEUE_MIN` bigint(20) DEFAULT NULL,
  `WSREP_LOCAL_STATE_COMMENT` varchar(50) DEFAULT NULL,
  `WSREP_OPEN_CONNECTIONS` bigint(20) DEFAULT NULL,
  `WSREP_OPEN_TRANSACTIONS` bigint(20) DEFAULT NULL,
  `WSREP_RECEIVED` bigint(20) DEFAULT NULL,
  `WSREP_RECEIVED_BYTES` bigint(20) DEFAULT NULL,
  `WSREP_REPLICATED` bigint(20) DEFAULT NULL,
  `WSREP_REPLICATED_BYTES` bigint(20) DEFAULT NULL,
  `WSREP_REPL_DATA_BYTES` bigint(20) DEFAULT NULL,
  `WSREP_REPL_KEYS` bigint(20) DEFAULT NULL,
  `WSREP_REPL_KEYS_BYTES` bigint(20) DEFAULT NULL,
  `WSREP_REPL_OTHER_BYTES` bigint(20) DEFAULT NULL,
  `WSREP_ROLLBACKER_THREAD_COUNT` bigint(20) DEFAULT NULL,
  `WSREP_THREAD_COUNT` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `SLAVE_STATUS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `TICK` datetime DEFAULT NULL,
  `HOSTNAME` varchar(128) DEFAULT NULL,
  `SECONDS_BEHIND_MASTER` bigint(20) DEFAULT NULL,
  `GTID_IO_POS` varchar(250) DEFAULT NULL,
  `GTID_SLAVE_POS` varchar(250) DEFAULT NULL,
  `SLAVE_SQL_RUNNING_STATE` varchar(500) DEFAULT NULL,
  `LAST_SQL_ERROR` varchar(700) DEFAULT NULL,
  `LAST_IO_ERROR` varchar(700) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE TABLE `PLUGINS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `PLUGIN_NAME` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_VERSION` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_STATUS` varchar(16) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_TYPE` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_TYPE_VERSION` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_LIBRARY` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `PLUGIN_LIBRARY_VERSION` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `LOAD_OPTION` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_MATURITY` varchar(12) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `PLUGIN_AUTH_VERSION` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE `ENGINE_INNODB_STATUS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `RUN_ID` varchar(16) DEFAULT NULL,
  `STATUS` longtext DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

CREATE VIEW IF NOT EXISTS V_SERVER_PERFORMANCE_PER_MIN as
select ID, RUN_ID, TICK, HOSTNAME, REDO_LOG_OCCUPANCY_PCT, THREADS_CONNECTED, 
INNODB_ROW_LOCK_CURRENT_WAITS AS LOCK_CURRENT_WAITS, MEMORY_USED, INNODB_BUFFER_POOL_BYTES_DATA as INNODB_BUFFER_POOL_DATA,
HANDLER_READ_RND_NEXT - (LAG(HANDLER_READ_RND_NEXT,1) OVER (ORDER BY ID)) as RND_NEXT_PER_MIN,
COM_SELECT - (LAG(COM_SELECT,1) OVER (ORDER BY ID)) as COM_SELECT_PER_MIN,
COM_INSERT - (LAG(COM_INSERT,1) OVER (ORDER BY ID)) as COM_INSERT_PER_MIN,
COM_UPDATE - (LAG(COM_UPDATE,1) OVER (ORDER BY ID)) as COM_UPDATE_PER_MIN,
COM_DELETE - (LAG(COM_DELETE,1) OVER (ORDER BY ID)) as COM_DELETE_PER_MIN,
(COM_INSERT + COM_UPDATE + COM_DELETE) - (LAG(COM_INSERT + COM_UPDATE + COM_DELETE,1) OVER (ORDER BY ID)) as COM_DML_PER_MIN,
COM_STMT_PREPARE - (LAG(COM_STMT_PREPARE,1) OVER (ORDER BY ID)) as COM_STMT_PREPARE_PER_MIN,
COM_STMT_EXECUTE - (LAG(COM_STMT_EXECUTE,1) OVER (ORDER BY ID)) as COM_STMT_EXECUTE_PER_MIN,
COM_XA_COMMIT - (LAG(COM_XA_COMMIT,1) OVER (ORDER BY ID)) as COM_XA_COMMIT_PER_MIN,
SLOW_QUERIES - (LAG(SLOW_QUERIES,1) OVER (ORDER BY ID)) as SLOW_QUERIES_PER_MIN,
INNODB_BUFFER_POOL_READS - (LAG(INNODB_BUFFER_POOL_READS,1) OVER (ORDER BY ID)) as IBP_READS_PER_MIN,
INNODB_BUFFER_POOL_READ_REQUESTS - (LAG(INNODB_BUFFER_POOL_READ_REQUESTS,1) OVER (ORDER BY ID)) as IBP_READ_REQUESTS_PER_MIN,
BINLOG_COMMITS - (LAG(BINLOG_COMMITS,1) OVER (ORDER BY ID)) as BINLOG_COMMITS_PER_MIN,
INNODB_DATA_WRITES - (LAG(INNODB_DATA_WRITES,1) OVER (ORDER BY ID)) as DATA_WRITES_PER_MIN,
INNODB_OS_LOG_WRITTEN - (LAG(INNODB_OS_LOG_WRITTEN,1) OVER (ORDER BY ID)) as OS_LOG_WRITTEN_PER_MIN,
INNODB_HISTORY_LIST_LENGTH,
QCACHE_QUERIES_IN_CACHE, 
QCACHE_FREE_MEMORY,
QCACHE_HITS - (LAG(QCACHE_HITS,1) OVER (ORDER BY ID)) as QCACHE_HITS_PER_MIN,
QCACHE_INSERTS - (LAG(QCACHE_INSERTS,1) OVER (ORDER BY ID)) as QCACHE_INSERTS_PER_MIN,
QCACHE_LOWMEM_PRUNES - (LAG(QCACHE_LOWMEM_PRUNES,1) OVER (ORDER BY ID)) as QCACHE_LOWMEM_PRUNES_PER_MIN
from SERVER_PERFORMANCE
where cast(date_format(TICK,'%S') as integer)=(select cast(date_format(RUN_START,'%S') as integer) from CURRENT_RUN where ID=1 limit 1);

CREATE VIEW IF NOT EXISTS V_SERVER_PERFORMANCE_PER_TICK as
select ID, RUN_ID, TICK, HOSTNAME, REDO_LOG_OCCUPANCY_PCT, THREADS_CONNECTED, 
INNODB_ROW_LOCK_CURRENT_WAITS AS LOCK_CURRENT_WAITS, MEMORY_USED, INNODB_BUFFER_POOL_BYTES_DATA as INNODB_BUFFER_POOL_DATA,
HANDLER_READ_RND_NEXT - (LAG(HANDLER_READ_RND_NEXT,1) OVER (ORDER BY ID)) as RND_NEXT_PER_TICK,
COM_SELECT - (LAG(COM_SELECT,1) OVER (ORDER BY ID)) as COM_SELECT_PER_TICK,
COM_INSERT - (LAG(COM_INSERT,1) OVER (ORDER BY ID)) as COM_INSERT_PER_TICK,
COM_UPDATE - (LAG(COM_UPDATE,1) OVER (ORDER BY ID)) as COM_UPDATE_PER_TICK,
COM_DELETE - (LAG(COM_DELETE,1) OVER (ORDER BY ID)) as COM_DELETE_PER_TICK,
(COM_INSERT + COM_UPDATE + COM_DELETE) - (LAG(COM_INSERT + COM_UPDATE + COM_DELETE,1) OVER (ORDER BY ID)) as COM_DML_PER_TICK,
COM_STMT_PREPARE - (LAG(COM_STMT_PREPARE,1) OVER (ORDER BY ID)) as COM_STMT_PREPARE_PER_TICK,
COM_STMT_EXECUTE - (LAG(COM_STMT_EXECUTE,1) OVER (ORDER BY ID)) as COM_STMT_EXECUTE_PER_TICK,
COM_XA_COMMIT - (LAG(COM_XA_COMMIT,1) OVER (ORDER BY ID)) as COM_XA_COMMIT_PER_TICK,
SLOW_QUERIES - (LAG(SLOW_QUERIES,1) OVER (ORDER BY ID)) as SLOW_QUERIES_PER_TICK,
INNODB_BUFFER_POOL_READS - (LAG(INNODB_BUFFER_POOL_READS,1) OVER (ORDER BY ID)) as IBP_READS_PER_TICK,
INNODB_BUFFER_POOL_READ_REQUESTS - (LAG(INNODB_BUFFER_POOL_READ_REQUESTS,1) OVER (ORDER BY ID)) as IBP_READ_REQUESTS_PER_TICK,
BINLOG_COMMITS - (LAG(BINLOG_COMMITS,1) OVER (ORDER BY ID)) as BINLOG_COMMITS_PER_TICK,
INNODB_DATA_WRITES - (LAG(INNODB_DATA_WRITES,1) OVER (ORDER BY ID)) as DATA_WRITES_PER_TICK,
INNODB_OS_LOG_WRITTEN - (LAG(INNODB_OS_LOG_WRITTEN,1) OVER (ORDER BY ID)) as OS_LOG_WRITTEN_PER_TICK,
INNODB_HISTORY_LIST_LENGTH,
QCACHE_QUERIES_IN_CACHE, 
QCACHE_FREE_MEMORY,
QCACHE_HITS - (LAG(QCACHE_HITS,1) OVER (ORDER BY ID)) as QCACHE_HITS_PER_TICK,
QCACHE_INSERTS - (LAG(QCACHE_INSERTS,1) OVER (ORDER BY ID)) as QCACHE_INSERTS_PER_TICK,
QCACHE_LOWMEM_PRUNES - (LAG(QCACHE_LOWMEM_PRUNES,1) OVER (ORDER BY ID)) as QCACHE_LOWMEM_PRUNES_PER_TICK
from SERVER_PERFORMANCE;


create view IF NOT EXISTS V_SERVER_STATE as
select A.ID as ID, B.TITLE as SECTION, A.ITEM as ITEM, 
  if(A.STATUS REGEXP '^-?[0-9]+$' = 1,format(A.STATUS,0),A.STATUS) as STATUS
from SERVER_STATE A inner join SECTION_TITLES B 
ON A.SECTION_ID=B.SECTION_ID;

create view IF NOT EXISTS `V_GALERA_PERFORMANCE_PER_MIN` as
SELECT ID, RUN_ID, TICK, HOSTNAME,
WSREP_FLOW_CONTROL_PAUSED_NS - (LAG(WSREP_FLOW_CONTROL_PAUSED_NS,1) OVER (ORDER BY ID)) as WSREP_FLOW_CONTROL_PAUSED_NS_PER_MIN,
WSREP_FLOW_CONTROL_RECV - (LAG(WSREP_FLOW_CONTROL_RECV,1) OVER (ORDER BY ID)) as WSREP_FLOW_CONTROL_RECV_PER_MIN,
WSREP_FLOW_CONTROL_SENT - (LAG(WSREP_FLOW_CONTROL_SENT,1) OVER (ORDER BY ID)) as WSREP_FLOW_CONTROL_SENT_PER_MIN,
WSREP_LAST_COMMITTED - (LAG(WSREP_LAST_COMMITTED,1) OVER (ORDER BY ID)) as WSREP_LAST_COMMITTED_PER_MIN,
WSREP_LOCAL_COMMITS - (LAG(WSREP_LOCAL_COMMITS,1) OVER (ORDER BY ID)) as WSREP_LOCAL_COMMITS_PER_MIN,
WSREP_RECEIVED - (LAG(WSREP_RECEIVED,1) OVER (ORDER BY ID)) as WSREP_RECEIVED_PER_MIN,
WSREP_RECEIVED_BYTES - (LAG(WSREP_RECEIVED_BYTES,1) OVER (ORDER BY ID)) as WSREP_RECEIVED_BYTES_PER_MIN,
WSREP_REPLICATED - (LAG(WSREP_REPLICATED,1) OVER (ORDER BY ID)) as WSREP_REPLICATED_PER_MIN,
WSREP_REPLICATED_BYTES - (LAG(WSREP_REPLICATED_BYTES,1) OVER (ORDER BY ID)) as WSREP_REPLICATED_BYTES_PER_MIN,
WSREP_REPL_DATA_BYTES - (LAG(WSREP_REPL_DATA_BYTES,1) OVER (ORDER BY ID)) as WSREP_REPL_DATA_BYTES_PER_MIN,
WSREP_REPL_KEYS - (LAG(WSREP_REPL_KEYS,1) OVER (ORDER BY ID)) as WSREP_REPL_KEYS_PER_MIN,
WSREP_REPL_KEYS_BYTES - (LAG(WSREP_REPL_KEYS_BYTES,1) OVER (ORDER BY ID)) as WSREP_REPL_KEYS_BYTES_PER_MIN
from `GALERA_PERFORMANCE`
where cast(date_format(TICK,'%S') as integer)=(select cast(date_format(RUN_START,'%S') as integer) from CURRENT_RUN where ID=1 limit 1);

create view IF NOT EXISTS `V_GALERA_PERFORMANCE_PER_TICK` as
SELECT ID, RUN_ID, TICK, HOSTNAME,
WSREP_FLOW_CONTROL_PAUSED_NS - (LAG(WSREP_FLOW_CONTROL_PAUSED_NS,1) OVER (ORDER BY ID)) as WSREP_FLOW_CONTROL_PAUSED_NS_PER_TICK,
WSREP_FLOW_CONTROL_RECV - (LAG(WSREP_FLOW_CONTROL_RECV,1) OVER (ORDER BY ID)) as WSREP_FLOW_CONTROL_RECV_PER_TICK,
WSREP_FLOW_CONTROL_SENT - (LAG(WSREP_FLOW_CONTROL_SENT,1) OVER (ORDER BY ID)) as WSREP_FLOW_CONTROL_SENT_PER_TICK,
WSREP_LAST_COMMITTED - (LAG(WSREP_LAST_COMMITTED,1) OVER (ORDER BY ID)) as WSREP_LAST_COMMITTED_PER_TICK,
WSREP_LOCAL_COMMITS - (LAG(WSREP_LOCAL_COMMITS,1) OVER (ORDER BY ID)) as WSREP_LOCAL_COMMITS_PER_TICK,
WSREP_RECEIVED - (LAG(WSREP_RECEIVED,1) OVER (ORDER BY ID)) as WSREP_RECEIVED_PER_TICK,
WSREP_RECEIVED_BYTES - (LAG(WSREP_RECEIVED_BYTES,1) OVER (ORDER BY ID)) as WSREP_RECEIVED_BYTES_PER_TICK,
WSREP_REPLICATED - (LAG(WSREP_REPLICATED,1) OVER (ORDER BY ID)) as WSREP_REPLICATED_PER_TICK,
WSREP_REPLICATED_BYTES - (LAG(WSREP_REPLICATED_BYTES,1) OVER (ORDER BY ID)) as WSREP_REPLICATED_BYTES_PER_TICK,
WSREP_REPL_DATA_BYTES - (LAG(WSREP_REPL_DATA_BYTES,1) OVER (ORDER BY ID)) as WSREP_REPL_DATA_BYTES_PER_TICK,
WSREP_REPL_KEYS - (LAG(WSREP_REPL_KEYS,1) OVER (ORDER BY ID)) as WSREP_REPL_KEYS_PER_TICK,
WSREP_REPL_KEYS_BYTES - (LAG(WSREP_REPL_KEYS_BYTES,1) OVER (ORDER BY ID)) as WSREP_REPL_KEYS_BYTES_PER_TICK
from `GALERA_PERFORMANCE`;

CREATE TABLE IF NOT EXISTS `TABLE_KEY_COUNTS` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TABLE_SCHEMA` VARCHAR(64) DEFAULT NULL,
  `TABLE_NAME` VARCHAR(64) DEFAULT NULL,
  `ENGINE` VARCHAR(64) DEFAULT NULL,
  `PRIMARY_KEY_COUNT` INTEGER(11) DEFAULT NULL,
  `UNIQUE_KEY_COUNT` INTEGER(11) DEFAULT NULL,
  `NON_UNIQUE_KEY_COUNT` INTEGER(11) DEFAULT NULL,
  `ROW_FORMAT` VARCHAR(32) DEFAULT NULL,
  `TABLE_ROWS` BIGINT(21) DEFAULT NULL,
  `AVG_ROW_LENGTH` BIGINT(21) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

create view IF NOT EXISTS `V_TABLE_KEY_COUNTS` as
SELECT `TABLE_SCHEMA`, `TABLE_NAME`, `PRIMARY_KEY_COUNT` as PKs,
        `UNIQUE_KEY_COUNT` as UKs, `NON_UNIQUE_KEY_COUNT` as NON_UKs, 
        `ROW_FORMAT`, `TABLE_ROWS`, `AVG_ROW_LENGTH`, 
        (`TABLE_ROWS` * `AVG_ROW_LENGTH`) AS `TOTAL_ROW_BYTES`, `ENGINE`
from TABLE_KEY_COUNTS;

-- -----------------------------------------------------------------------------------------------------
-- select * from V_EXPECTED_RAM_DEMAND to estimate the expected RAM that will be used as the number of 
-- connections rises. The formula is:
-- EXPECTED_WORKING_MEMORY = maximum Innodb_buffer_pool_bytes_data from STATUS 
--                           + KEY_BUFFER_SIZE + QUERY_CACHE_SIZE + INNODB_LOG_BUFFER_SIZE
-- EXPECTED_MEMORY_PER_SESSION = maximum MEMORY_USED / THREADS_CONNECTED from STATUS
-- SESSION_COUNT = an increasing sequence from 50 to 2000 (edit the last line to narrow the scope)
-- EXPECTED_DEMAND_BYTES = EXPECTED_WORKING_MEMORY + (EXPECTED_MEMORY_PER_SESSION * SESSION_COUNT)
-- KEEP IN MIND: The estimate will prove most accurate when performance data was collected on an
-- instance with many active sessions.
-- -----------------------------------------------------------------------------------------------------
create view IF NOT EXISTS `V_EXPECTED_RAM_DEMAND` as
WITH EXPECTED_MEMORY_USE AS (
SELECT * FROM
(SELECT SUM(V) AS `EXPECTED_WORKING_MEMORY` FROM (
SELECT VARIABLE_VALUE AS `V` FROM GLOBAL_VARIABLES 
WHERE VARIABLE_NAME IN ('KEY_BUFFER_SIZE','QUERY_CACHE_SIZE','INNODB_LOG_BUFFER_SIZE')
UNION ALL 
SELECT  max(INNODB_BUFFER_POOL_DATA) from V_SERVER_PERFORMANCE_PER_MIN
) AS x ) AS `EXPECTED_WORKING_MEMORY`,
(SELECT   round(max(MEMORY_USED/THREADS_CONNECTED)) AS `EXPECTED_MEMORY_PER_SESSION`
from V_SERVER_PERFORMANCE_PER_MIN)  AS `EXPECTED_MEMORY_PER_SESSION`)
SELECT EXPECTED_WORKING_MEMORY, EXPECTED_MEMORY_PER_SESSION, seq AS `SESSION_COUNT`, 
EXPECTED_WORKING_MEMORY + (EXPECTED_MEMORY_PER_SESSION * seq)  AS `EXPECTED_DEMAND_BYTES`,
ROUND((EXPECTED_WORKING_MEMORY + (EXPECTED_MEMORY_PER_SESSION * seq))/1024/1024)  AS `EXPECTED_DEMAND_MB`,
ROUND((EXPECTED_WORKING_MEMORY + (EXPECTED_MEMORY_PER_SESSION * seq))/1024/1024/1024)  AS `EXPECTED_DEMAND_GB`
FROM EXPECTED_MEMORY_USE
JOIN seq_50_to_2000;

CREATE VIEW IF NOT EXISTS `V_INNODB_REDO_STATUS` AS
WITH STS
AS (
    SELECT (
            select ifnull(max(REDO_LOG_OCCUPANCY_PCT),'Incompatible Release') from SERVER_PERFORMANCE
            ) AS MAX_REDO_OCCUPANCY_PCT
        ,(
            SELECT VARIABLE_VALUE
            FROM GLOBAL_VARIABLES
            WHERE VARIABLE_NAME = 'INNODB_LOG_FILE_SIZE'
            ) AS INNODB_LOG_FILE_SIZE
        ,(        
            SELECT VARIABLE_VALUE
            FROM GLOBAL_VARIABLES
            WHERE VARIABLE_NAME = 'INNODB_MAX_DIRTY_PAGES_PCT_LWM'
            ) AS INNODB_MAX_DIRTY_PAGES_PCT_LWM
        ,(
            SELECT VARIABLE_VALUE
            FROM GLOBAL_VARIABLES
            WHERE VARIABLE_NAME = 'INNODB_MAX_DIRTY_PAGES_PCT'
            ) AS INNODB_MAX_DIRTY_PAGES_PCT
    )
SELECT MAX_REDO_OCCUPANCY_PCT, 
INNODB_LOG_FILE_SIZE/1024/1024 as INNODB_LOG_FILE_MB,
INNODB_MAX_DIRTY_PAGES_PCT_LWM, INNODB_MAX_DIRTY_PAGES_PCT
FROM STS;

CREATE VIEW IF NOT EXISTS `V_MEMORY_REVIEW` AS
select concat('INNODB_BUFFER_POOL_SIZE') as `ITEM`, 
if((VARIABLE_VALUE/1024/1024/1024)<1,
    concat(VARIABLE_VALUE/1024/1024,' MB'),
    concat(VARIABLE_VALUE/1024/1024/1024,' GB')) as `STATUS`, 
concat('') as `TYPICAL`,
concat('Typically 60% to 80% of total system memory. Not related to session count.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='INNODB_BUFFER_POOL_SIZE'
UNION ALL
select concat('MAX INNODB BUFFER POOL DATA') as `ITEM`,
if((max(INNODB_BUFFER_POOL_BYTES_DATA)/1024/1024/1024)<1,
    concat(format(max(INNODB_BUFFER_POOL_BYTES_DATA)/1024/1024,2),' MB'),
    concat(format(max(INNODB_BUFFER_POOL_BYTES_DATA)/1024/1024/1024,2),' GB'))as `STATUS`, 
concat('') as `TYPICAL`,
concat('Memory actually allocated for innodb buffer pool during stats colleciton.') as `INFO`
from SERVER_PERFORMANCE
UNION ALL
select concat('LOWEST BUFFER CACHE HIT PCT') as `ITEM`,
concat(format(min((1 - (IBP_READS_PER_TICK / IBP_READ_REQUESTS_PER_TICK)) * 100),2),'%') as `STATUS`,
concat('99.9%') as `TYPICAL`,
concat('Percent that data is found in memory instead of loading from disk. Should be at least 99%.') as `INFO`
from V_SERVER_PERFORMANCE_PER_TICK
UNION ALL
select concat('INNODB_LOG_BUFFER_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024/1024)<1,concat(VARIABLE_VALUE/1024/1024,' MB'),concat(VARIABLE_VALUE/1024/1024/1024,' GB')) as `STATUS`,
concat('16 MB') as `TYPICAL`,
concat('Buffer for writing InnoDB redo to disk. Not related to session count.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='INNODB_LOG_BUFFER_SIZE'
UNION ALL
select concat('KEY_BUFFER_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024/1024)<1,concat(VARIABLE_VALUE/1024/1024,' MB'),concat(VARIABLE_VALUE/1024/1024/1024,' GB')) as `STATUS`,
concat('128 MB') as `TYPICAL`,
concat('Variable to support MyIsam tables. Not related to session count.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='KEY_BUFFER_SIZE'
UNION ALL
select concat('QUERY_CACHE_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024/1024)<1,concat(VARIABLE_VALUE/1024/1024,' MB'),concat(VARIABLE_VALUE/1024/1024/1024,' GB')) as `STATUS`,
concat('1 MB') as `TYPICAL`,
concat('Variable to support query cache. Not related to session count.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='QUERY_CACHE_SIZE'
UNION ALL
select concat('READ_BUFFER_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('128 KB') as `TYPICAL`,
concat('A buffer for each MyISAM, Aria and MERGE table scanned, per session.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='READ_BUFFER_SIZE'
UNION ALL
select concat('READ_RND_BUFFER_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('256 KB') as `TYPICAL`,
concat('A buffer for reading rows from a MyISAM table after a key sort, per session.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='READ_RND_BUFFER_SIZE'
UNION ALL
select concat('SORT_BUFFER_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('2 MB') as `TYPICAL`,
concat('Sort buffer per session. Not specific to any engine.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='SORT_BUFFER_SIZE'
UNION ALL
select concat('JOIN_BUFFER_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('256 KB') as `TYPICAL`,
concat('Join buffer per session, for joins requiring FTS. Not specific to any engine.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='JOIN_BUFFER_SIZE'
UNION ALL
select concat('BINLOG_CACHE_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('32 KB') as `TYPICAL`,
concat('Cache holding a record of binary log changes during a transaction per session.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='BINLOG_CACHE_SIZE'
UNION ALL
select concat('THREAD_STACK') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('292 KB') as `TYPICAL`,
concat('Stack size per session.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='THREAD_STACK'
UNION ALL
select concat('TMP_TABLE_SIZE') as `ITEM`,
if((VARIABLE_VALUE/1024/1024)<1,concat(VARIABLE_VALUE/1024,' KB'),concat(VARIABLE_VALUE/1024/1024,' MB')) as `STATUS`,
concat('1 KB') as `TYPICAL`,
concat('The largest size for temporary tables in memory per session.') as `INFO`
from GLOBAL_VARIABLES where VARIABLE_NAME='TMP_TABLE_SIZE'
UNION ALL
select concat('MAX SESSION MEMORY USED') as `ITEM`,
if((max(MEMORY_USED)/1024/1024/1024)<1,
    concat(format(max(MEMORY_USED)/1024/1024,2),' MB'),
    concat(format(max(MEMORY_USED)/1024/1024/1024,2),' GB')) as `STATUS`, 
concat('') as `TYPICAL`,
concat('Memory actually allocated for sessions during stats colleciton.') as `INFO`
from SERVER_PERFORMANCE;

CREATE VIEW IF NOT EXISTS V_POTENTIAL_RAM_DEMAND as
WITH RAM_GLOBAL_VARIABLES AS (
SELECT
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='KEY_BUFFER_SIZE' limit 1) AS `KEY_BUFFER_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='QUERY_CACHE_SIZE' limit 1)AS `QUERY_CACHE_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='INNODB_BUFFER_POOL_SIZE' limit 1) AS `INNODB_BUFFER_POOL_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='INNODB_LOG_BUFFER_SIZE' limit 1) AS `INNODB_LOG_BUFFER_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='MAX_CONNECTIONS' limit 1) AS `MAX_CONNECTIONS`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='READ_BUFFER_SIZE' limit 1) AS `READ_BUFFER_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='READ_RND_BUFFER_SIZE' limit 1) AS `READ_RND_BUFFER_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='SORT_BUFFER_SIZE' limit 1) AS `SORT_BUFFER_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='JOIN_BUFFER_SIZE' limit 1) AS `JOIN_BUFFER_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='BINLOG_CACHE_SIZE' limit 1) AS `BINLOG_CACHE_SIZE`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='THREAD_STACK' limit 1) AS `THREAD_STACK`,
(select VARIABLE_VALUE from GLOBAL_VARIABLES where VARIABLE_NAME='TMP_TABLE_SIZE' limit 1) AS `TMP_TABLE_SIZE`)
 SELECT ( KEY_BUFFER_SIZE
+ QUERY_CACHE_SIZE
+ INNODB_BUFFER_POOL_SIZE
+ INNODB_LOG_BUFFER_SIZE
+ MAX_CONNECTIONS * ( 
    READ_BUFFER_SIZE
    + READ_RND_BUFFER_SIZE
    + SORT_BUFFER_SIZE
    + JOIN_BUFFER_SIZE
    + BINLOG_CACHE_SIZE
    + THREAD_STACK
    + TMP_TABLE_SIZE )
) AS MAX_RAM_USAGE FROM RAM_GLOBAL_VARIABLES;


