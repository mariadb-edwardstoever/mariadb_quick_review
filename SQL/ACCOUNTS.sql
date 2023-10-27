-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- ACCOUNTS

SELECT '$RUNID' as RUN_ID, `USER`, `HOST`, `CURRENT_CONNECTIONS`, `TOTAL_CONNECTIONS`
from performance_schema.accounts
limit 100000
