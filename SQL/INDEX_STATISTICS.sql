-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- INDEX_STATISTICS

SELECT '$RUNID' as RUN_ID,
TABLE_SCHEMA,
TABLE_NAME,
INDEX_NAME,
ROWS_READ
from information_schema.INDEX_STATISTICS

