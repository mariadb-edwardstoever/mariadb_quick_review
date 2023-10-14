#!/bin/bash
# mariadb_quick_review.sh
# By Edward Stoever for MariaDB Support

### DO NOT EDIT SCRIPT. 
### FOR FULL INSTRUCTIONS: README.md
### FOR BRIEF INSTRUCTIONS: ./mariadb_quick_review.sh --help

SCRIPT_VERSION='1.0.0'
# Establish working directory and source pre_quick_review.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/pre_quick_review.sh


start_message;


if [ $INVALID_INPUT ]; then display_help_message; die "Invalid option: $INVALID_INPUT"; fi
if [ $DISPLAY_VERSION ]; then exit 0; fi
if [ $HELP ]; then display_help_message; exit 0; fi
if [ ! $CAN_CONNECT ]; then die "Database connection failed. Read the file README.md. Edit the file quick_review.cnf."; fi
whoami_db;


# force CLIENT_SIDE OUTFILES if DB HOSTNAME IS NOT SAME AS CLIENT HOSTNAME
is_db_localhost;
echo

if [ "$OUT_TO_FILES" == "TRUE" ]; then
  mk_tmpdir
fi

is_primary;
is_replica;
is_galera;
check_required_privs;
slaves_running; # How many slaves are running?
echo "";

# QUERIES RUN ONE TIME
run_sql SERVER_STATE
run_sql GLOBAL_VARIABLES
run_sql GLOBAL_STATUS
run_sql TABLE_KEY_COUNTS
run_sql REVIEW_WARNINGS
run_sql LOW_CARDINALITY_IDX
if [ ! "$MULTI_PROCESSLIST" == 'TRUE' ]; then
  run_sql PROCESSLIST
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

if [ ! $PER_MIN ]; then PER_MIN=1; STATS_ON_SEC=("00"); fi # DEFAULT
INDEX=0;
MAX_INDEX=$(( PER_MIN - 1))
MINS_REMAINING=$MINUTES_TO_COLLECT_PERF_STATS
for (( ii=1; ii<=$((MINUTES_TO_COLLECT_PERF_STATS * PER_MIN)); ii++))
 do
   while [[ ! "$(date +%S)" == "${STATS_ON_SEC[${INDEX}]}" ]]  && [ ! "$DEBUG_SQL" == 'TRUE' ]; do sleep 0.2; done
   if [ $INDEX -lt $MAX_INDEX ]; then INDEX=$(( INDEX + 1 )); else INDEX=0; fi
   SUBROUTINE="$RUNID-$(printf "%04d" $ii)"

#
# QUERIES RUN MULTIPLE TIMES
#
if [ "$MULTI_PROCESSLIST" == 'TRUE' ]; then
  run_sql PROCESSLIST "PROCESSLIST.$SUBROUTINE"
fi
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

if [ $INDEX -eq $MAX_INDEX ]; then MINS_REMAINING=$((MINS_REMAINING - 1)); fi
# echo "DEBUG: $(date +%S) ${STATS_ON_SEC[${MAX_INDEX}]} $MINS_REMAINING $ii $DEBUG_SQL"

if  [ "$(date +%S)" == "${STATS_ON_SEC[${MAX_INDEX}]}" ] && [ $MINS_REMAINING -ne 0 ] && [ ! "$DEBUG_SQL" == 'TRUE' ]; then 
  TEMP_COLOR=lcyan; print_color "Performance statistics collection will complete in $MINS_REMAINING $(singular_plural minute $MINS_REMAINING).\n"; unset TEMP_COLOR 
fi 

if [ $MAX_INDEX -eq 0 ] && [ $MINS_REMAINING -ne 0 ]; then 
  sleep 50; 
fi # NO PER-MINUTE PERFORMANCE STAT COLLECTION MUST SLEEP OR LOOP WILL HAPPEN MULTIPLE TIMES IN FIRST SECOND

done

compress_file;
