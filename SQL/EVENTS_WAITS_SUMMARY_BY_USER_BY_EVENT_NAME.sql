-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- EVENTS_WAITS_SUMMARY_BY_USER_BY_EVENT_NAME

SELECT '$RUNID' as RUN_ID,
`USER`,
`EVENT_NAME`,
`COUNT_STAR`,
`SUM_TIMER_WAIT`,
`MIN_TIMER_WAIT`,
`AVG_TIMER_WAIT`,
`MAX_TIMER_WAIT`
from performance_schema.events_waits_summary_by_user_by_event_name
limit 100000
