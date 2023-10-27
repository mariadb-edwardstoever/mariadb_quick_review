#!/usr/bin/env bash
# mariadb_quick_review.sh
# By Edward Stoever for MariaDB Support

### DO NOT EDIT SCRIPT. 
### FOR FULL INSTRUCTIONS: README.md
### FOR BRIEF INSTRUCTIONS: ./mariadb_quick_review.sh --help

# Establish working directory and source pre_quick_review.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/vsn.sh
source ${SCRIPT_DIR}/pre_quick_review.sh


display_title;
start_message;
test_dependencies;
stop_here_if_necessary;
whoami_db;
is_db_localhost;
echo
mk_tmpdir
is_primary;
is_replica;
is_galera;
display_stats_collection;
echo
check_required_privs;
slaves_running; # How many slaves are running?
if [ $DISPLAY_VERSION ]; then exit 0; fi
echo

# QUERIES RUN ONE TIME
run_sql SERVER_STATE
run_sql GLOBAL_VARIABLES
run_sql GLOBAL_STATUS
run_sql TABLE_KEY_COUNTS
run_sql REVIEW_WARNINGS
run_sql LOW_CARDINALITY_IDX
run_sql PLUGINS
if [ ! "$MULTI_PROCESSLIST" == 'TRUE' ]; then
  run_sql PROCESSLIST
fi
if [ "$IS_PRIMARY" == 'YES' ]; then
  record_slave_hosts SLAVE_HOSTS
fi

is_userstat_enabled
if [ "$USERSTAT_ENABLED" == 'TRUE' ]; then
  run_sql CLIENT_STATISTICS
  run_sql USER_STATISTICS
  run_sql INDEX_STATISTICS
  run_sql TABLE_STATISTICS
fi

is_performance_schema_enabled
if [ "$PERFORMANCE_SCHEMA_ENABLED" == 'TRUE' ]; then 
  run_sql ACCOUNTS
  run_sql FILE_SUMMARY_BY_INSTANCE
  run_sql TABLE_IO_WAITS_SUMMARY_BY_INDEX_USAGE
  run_sql TABLE_IO_WAITS_SUMMARY_BY_TABLE
  run_sql EVENTS_STATEMENTS_SUMMARY_BY_USER_BY_EVENT_NAME
  run_sql EVENTS_WAITS_SUMMARY_BY_USER_BY_EVENT_NAME
  run_sql EVENTS_WAITS_SUMMARY_GLOBAL_BY_EVENT_NAME
fi

record_engine_innodb_status ENGINE_INNODB_STATUS
record_disks DISKS
record_df DF
record_machine_architecture MACHINE_ARCHITECTURE
record_cpu_info CPU_INFO
record_memory_info MEMORY_INFO

# CURRENT_RUN is collected just one time, and in the PERF STATS loop. If no perf stats loop, collect it here:
if [ "$MINS" == "0" ]; then
  run_sql CURRENT_RUN
fi

#
# PERFORMANCE STATISTICS WILL LOOP THE NUMBER OF TIMES REQUESTED BY ( --minutes * --stats_per_min )
#

SECONDS_TO_BEGIN_PERF_STATS=$(date +%S)
SECONDS_TO_BEGIN_PERF_STATS=$(expr $SECONDS_TO_BEGIN_PERF_STATS + 0)
MINUTES_TO_COLLECT_PERF_STATS=$MINS
if [ "$DEBUG_SQL" == 'TRUE' ]; then MINUTES_TO_COLLECT_PERF_STATS=1; fi
if [ "$SECONDS_TO_BEGIN_PERF_STATS" != "0" ] && [ "$MINUTES_TO_COLLECT_PERF_STATS" != "0" ] && [ ! "$DEBUG_SQL" == 'TRUE' ]; then
  SCNDS=$((60 - $SECONDS_TO_BEGIN_PERF_STATS))
  TEMP_COLOR=lcyan; print_color "Performance statistics collection will begin in $SCNDS $(singular_plural second $SCNDS).\n"; unset TEMP_COLOR
fi


INDEX=0;
MAX_INDEX=$(( PER_MIN - 1))
MINS_REMAINING=$MINUTES_TO_COLLECT_PERF_STATS
for (( ii=1; ii<=$((MINUTES_TO_COLLECT_PERF_STATS * PER_MIN)); ii++))
 do
   while [[ ! "$(date +%S)" == "${STATS_ON_SEC[${INDEX}]}" ]]  && [ ! "$DEBUG_SQL" == 'TRUE' ]; do sleep 0.2; done
   if [ $INDEX -lt $MAX_INDEX ]; then INDEX=$(( INDEX + 1 )); else INDEX=0; fi
   SUBROUTINE="$RUNID-$(printf "%04d" $ii)"

   #### WE NEED THE DB HOST TIMESTAMP FOR FIRST LOOP
   if [ $ii -eq 1 ]; then
     run_sql CURRENT_RUN
   fi

   #
   # QUERIES RUN MULTIPLE TIMES
   #
   if [ "$MULTI_PROCESSLIST" == 'TRUE' ]; then
     run_sql PROCESSLIST "PROCESSLIST.$SUBROUTINE"
   fi
   record_open_tables OPEN_TABLES "OPEN_TABLES.$SUBROUTINE"
   run_sql GTID_POSITIONS "GTID_POSITIONS.$SUBROUTINE"
   run_sql SERVER_PERFORMANCE "SERVER_PERFORMANCE.$SUBROUTINE"
   run_sql PERFORMANCE_WARNINGS "PERFORMANCE_WARNINGS.$SUBROUTINE"
   if [ "$IS_GALERA" == "YES" ]; then
     run_sql GALERA_PERFORMANCE "GALERA_PERFORMANCE.$SUBROUTINE"
     run_sql GALERA_WARNINGS "GALERA_WARNINGS.$SUBROUTINE"
   fi

   if [ "$IS_REPLICA" == "YES" ] && [ "$SLAVES_RUNNING" == "1" ]; then # can only do this if there is only one slave running
     record_slave_status "SLAVE_STATUS.$SUBROUTINE"
   fi

   record_mysql_top "MYSQL_TOP.$SUBROUTINE"

   if [ $INDEX -eq $MAX_INDEX ]; then MINS_REMAINING=$((MINS_REMAINING - 1)); fi
   # echo "DEBUG: $(date +%S) ${STATS_ON_SEC[${MAX_INDEX}]} $MINS_REMAINING $ii $DEBUG_SQL"

   if  [ "$(date +%S)" == "${STATS_ON_SEC[${MAX_INDEX}]}" ] && [ $MINS_REMAINING -ne 0 ] && [ ! "$DEBUG_SQL" == 'TRUE' ]; then 
     TEMP_COLOR=lcyan; print_color "Performance statistics collection will complete in $MINS_REMAINING $(singular_plural minute $MINS_REMAINING).\n"; unset TEMP_COLOR 
   fi 

   if [ $MAX_INDEX -eq 0 ] && [ $MINS_REMAINING -ne 0 ]; then 
     sleep 50; 
   fi # NO PER-MINUTE PERFORMANCE STAT COLLECTION MUST SLEEP OR LOOP WILL HAPPEN MULTIPLE TIMES IN FIRST SECOND

done

## FINAL STEPS AFTER PERFORMANCE STATISTICS LOOP
set_log_error;
record_recent_errors RECENT_ERRORS;
collect_logs;
post_version;
compress_file;
