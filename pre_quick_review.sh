#!/usr/bin/env bash
# pre_quick_review.sh
# file distributed with mariadb_quick_review 
# By Edward Stoever for MariaDB Support

TEMPDIR="/tmp"
CONFIG_FILE="$SCRIPT_DIR/quick_review.cnf"
SQL_DIR="$SCRIPT_DIR/SQL"
TOOL="mariadb_quick_review"
QK_TMPDIR="/PATH/TO"
SLAVES_RUNNING=0; # DEFAULT
OUT_TO_FILES='TRUE' # DEFAULT
MINS=5 #DEFAULT
RUNID=$(echo $(echo $(($RANDOM * $RANDOM +100000))| base64 | sed 's/\=//g' | head -c 6 2>/dev/null || echo 'NOTRND')  | awk '{print "QK-" substr($0,1,6)}')
MARIADB_PROCESS_OWNER="$(ps -ef | grep -E '(mariadbd|mysqld)' | grep -v "grep" | head -1 |awk '{print $1}')"

function ts() {
   TS=$(date +%F-%T | tr ':-' '_')
   echo "$TS $*"
}

function die() {
   ts "$*" >&2
   exit 1
}

if [ ! $SCRIPT_VERSION ]; then  die "Do not run this script directly. Read the file README.md for help."; fi

function display_help_message() {
printf "This script can be run without options. Not indicating an option value will use the default.
  --minutes=10         # indicate the number of minutes to collect performance statistics, default 5
  --stats_per_min=2    # indicate the number of times per minute to collect performance statistics, default 1
                       # Valid values for stats_per_min: 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60
  --logs               # Include database error logs and system logs in archive for support ticket.
  --multi_processlist  # Turns on collecting processlist with each statistics collection. Turned off by default.
  --logs               # Collect database error logs and system logs and include in generated file.
  --redirect_to_files  # Force a redirect of output to files instead of SELECT INTO OUTFILE.
  --test               # Test connect to database and display script version
  --version            # Test connect to database and display script version
  --help               # Display the help menu

  ### THE BELOW OPTIONS ARE INTENDED FOR SOFTWARE DEVELOPMENT ###
  --debug_sql             # Instead of running SQL commands, display the SQL commands that will be run
  --debug_outfiles        # view the outfiles as each is created
  --bypass_priv_check     # Bypass the check that the database user has sufficient privileges.
  --no_outfiles           # Output to stdout instead of to files

Read the file README.md for more information.\n"
}

function display_title(){
  local BLANK='  │                                                         │'
  printf "  ┌─────────────────────────────────────────────────────────┐\n"
  printf "$BLANK\n"
  printf "  │                  MARIADB QUICK REVIEW                   │\n"
  printf '%-62s' "  │                      Version $SCRIPT_VERSION"; printf "│\n"
  printf "$BLANK\n"
  printf "  │      Script by Edward Stoever for MariaDB Support       │\n"
  printf "$BLANK\n"
  printf "  └─────────────────────────────────────────────────────────┘\n"
}

function is_primary(){
  local SQL_FILE="$SQL_DIR/IS_PRIMARY.sql"
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else
    IS_PRIMARY=$($CMD_MARIADB $CLOPTS -ABNe "$SQL");
    if [ "$IS_PRIMARY" == "YES" ]; then
      printf "IS PRIMARY: "; TEMP_COLOR=lcyan; print_color "YES\n"; unset TEMP_COLOR;
    else
      printf "IS PRIMARY: "; TEMP_COLOR=lmagenta; print_color "NO\n"; unset TEMP_COLOR;
    fi
  fi
}

function stop_here_if_necessary(){
if [ $INVALID_INPUT ]; then display_help_message; die "Invalid option: $INVALID_INPUT"; fi
if [ $HELP ]; then display_help_message; exit 0; fi
if [ ! $CAN_CONNECT ]; then 
  TEMP_COLOR=lred; print_color "Failing command: ";unset TEMP_COLOR; 
  TEMP_COLOR=lyellow; print_color "$CMD_MARIADB $CLOPTS\n";unset TEMP_COLOR; 
  local SQL_FILE="$SQL_DIR/NOW.sql"
  local SQL=$(cat $SQL_FILE)
  ERRTEXT=$($CMD_MARIADB $CLOPTS -e "$SQL" 2>&1); TEMP_COLOR=lcyan; print_color "$ERRTEXT\n";unset TEMP_COLOR;
  die "Database connection failed. Read the file README.md. Edit the file quick_review.cnf."; 
fi
}

function whoami_db(){
  local SQL_FILE="$SQL_DIR/WHOAMI_DB.sql"
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else
    WHOAMI_DB=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
    printf "DB account:    "; TEMP_COLOR=lmagenta; print_color "$WHOAMI_DB\n"; unset TEMP_COLOR;
  fi
}

function is_replica(){
  local SQL_FILE="$SQL_DIR/IS_REPLICA.sql"
  local SQL=$(cat $SQL_FILE)
    if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else
    IS_REPLICA=$($CMD_MARIADB $CLOPTS -ABNe "$SQL");
    if [ "$IS_REPLICA" == "YES" ]; then
      printf "IS REPLICA: "; TEMP_COLOR=lcyan; print_color "YES\n"; unset TEMP_COLOR;
    else
      printf "IS REPLICA: "; TEMP_COLOR=lmagenta; print_color "NO\n"; unset TEMP_COLOR;
    fi
  fi
}

function slaves_running(){
  local SQL_FILE="$SQL_DIR/SLAVES_RUNNING.sql"
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
  echo "$SQL"; echo; echo;
  else
    SLAVES_RUNNING=$($CMD_MARIADB $CLOPTS -ABNe "$SQL");
  fi
}

function is_galera(){
  local SQL_FILE="$SQL_DIR/IS_GALERA.sql"
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo; 
  else
    IS_GALERA=$($CMD_MARIADB $CLOPTS -ABNe "$SQL");
    if [ "$IS_GALERA" == "YES" ]; then
      printf "IS GALERA: "; TEMP_COLOR=lcyan; print_color "YES\n"; unset TEMP_COLOR;
    else
      printf "IS GALERA:  "; TEMP_COLOR=lmagenta; print_color "NO\n"; unset TEMP_COLOR;
    fi
  fi
}

function display_stats_collection() {
if [ ! $PER_MIN ]; then PER_MIN=1; STATS_ON_SEC=("00"); fi # DEFAULT, ALSO USED BY display_stats_collection
if [ ! $DISPLAY_VERSION ]; then
  printf "PERF STATS: "; TEMP_COLOR=lmagenta; print_color "Will collect $((MINS * PER_MIN)) times during $MINS $(singular_plural minute $MINS)."; unset TEMP_COLOR;
fi
}

function check_required_privs() {
  if [ "$CLIENT_SIDE" == 'TRUE' ]; then
   local SQL_FILE="$SQL_DIR/CLIENT_OUTFILE_PRIVS.sql"
  else
   local SQL_FILE="$SQL_DIR/SERVER_OUTFILE_PRIVS.sql"
  fi
  if [ ! "$BYPASS_PRIV_CHECK" == "TRUE" ]; then
    if [ "$DEBUG_SQL" == "TRUE" ] ; then
      cat $SQL_FILE; echo; echo; 
    else
      ERR=$($CMD_MARIADB $CLOPTS -e "source $SQL_FILE")
      if [ "$ERR" ]; then die "$ERR"; fi
	fi
  fi
}

function is_db_localhost(){
  local SQL_FILE="$SQL_DIR/IS_DB_LOCALHOST.sql"
  local SQL=$(cat $SQL_FILE)
  # YOU CANNOT DEBUG_SQL HERE BECAUSE THIS EFFECTS SQL TEXT, SO IT MUST BE RUN
    local DBHOST=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
    local CLIENTHOST=$(hostname)
    if [ ! "$DBHOST" == "$CLIENTHOST" ]; then CLIENT_SIDE='TRUE'; else DB_IS_LOCAL='TRUE'; fi
      printf "Database Host: "; TEMP_COLOR=lmagenta; print_color "$DBHOST\n"; unset TEMP_COLOR;
      printf "Client Host:   "; TEMP_COLOR=lmagenta; print_color "$CLIENTHOST\n"; unset TEMP_COLOR;
	  if [ ! $DB_IS_LOCAL ]; then
         printf "Notice:        ";TEMP_COLOR=lred;  print_color "Database is remote. Data regarding host will not be collected.\n";unset TEMP_COLOR;
		 if [ $COLLECT_LOGS ]; then die "It is not possible to collect logs on a remote host."; fi
	  fi
}


function start_message() {
  if [ "$(id -u)" -eq 0 ]; then
    if [ -n "$SUDO_USER" ]; then
      RUNAS="$(whoami) (sudo)"
    else 
      RUNAS="$(whoami)"
    fi
  else 
    RUNAS="$(whoami)"
  fi
  local SQL_FILE="$SQL_DIR/NOW.sql"
  local SQL=$(cat $SQL_FILE)
  $CMD_MARIADB $CLOPTS -s -e "$SQL" 1>/dev/null 2>/dev/null && CAN_CONNECT=true || unset CAN_CONNECT
  if [ $CAN_CONNECT ]; then
    TEMP_COLOR=lgreen; print_color "Can connect to database.\n"; unset TEMP_COLOR;
  else
    TEMP_COLOR=lred;   print_color "Cannot connect to database.\n"; unset TEMP_COLOR;
  fi
  printf "OS account:    "; TEMP_COLOR=lmagenta; print_color "$RUNAS\n"; unset TEMP_COLOR;

}

function display_file_written_message(){
  # IN THEORY, THERE DOES NOT EXIST A CASE IN WHICH REMOTE DB CREATES AN INACCESSIBLE OUTFILE.
  # SO THIS MESSAGE SHOULD NEVER APPEAR BECAUSE IF REMOTE, CLIENT_SIDE='TRUE':
  if [ "$OUT_TO_FILES" == "TRUE" ] && [ ! "$CLIENT_SIDE" == 'TRUE' ] && [ ! -f "$OUTFILE" ] && [ ! "$DEBUG_SQL" == 'TRUE' ]; then echo "FILE WRITTEN ON DATABASE HOST: $OUTFILE"; fi
  if [ "$OUT_TO_FILES" == "TRUE" ] && [ -f "$OUTFILE" ]; then echo "FILE WRITTEN: $OUTFILE"; fi

  if [ "$DEBUG_OUTFILE" == "TRUE" ] && [ -f "$OUTFILE" ]; then
    cat $OUTFILE
  fi 
}

function run_sql() {
  local SQL_FILE="$SQL_DIR/$1.sql"
  if [ ! "$CLIENT_SIDE" == 'TRUE' ]; then
    if [ ! $2 ]; then
      OUTFILE="$QK_TMPDIR/$1.out"; ENCLOSURE='';
    else
      OUTFILE="$QK_TMPDIR/$2.out"; ENCLOSURE=''; 
    fi
  else
    if [ ! $2 ]; then
      OUTFILE="$QK_TMPDIR/$1.tsv"; ENCLOSURE='"'; 
    else
      OUTFILE="$QK_TMPDIR/$2.tsv"; ENCLOSURE='"'; 
    fi
  fi
  CLIENT_DT="$(date +"%Y-%m-%d %H:%M:%S")"; CLIENT_HOST="$(hostname)"; CLIENT_OS_ACCT=$(whoami)
  if [ ! $SUBROUTINE ]; then SUBROUTINE=${RUNID}; fi # SUPPORTS PROCESSLIST RUN ONCE OR MULTIPLE TIMES 
  INTO_OUTFILE="INTO OUTFILE '$OUTFILE' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' ESCAPED BY '\\\\'"
  export OUTFILE SCRIPT_VERSION RUNID SUBROUTINE CLIENT_HOST CLIENT_DT CLIENT_OS_ACCT ENCLOSURE
  local SQL=$(envsubst < $SQL_FILE)
  
  if [ "$OUT_TO_FILES" == "TRUE" ] && [ ! "$CLIENT_SIDE" == 'TRUE' ]; then
    SQL="$SQL $INTO_OUTFILE"
  fi

  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else
    if [ ! "$CLIENT_SIDE" == 'TRUE' ]; then
      $CMD_MARIADB $CLOPTS -e "$SQL"
    else
	  if [ ! "$OUT_TO_FILES" == "TRUE" ]; then
	    $CMD_MARIADB $CLOPTS -ABNe "$SQL" 
	  else
	    $CMD_MARIADB $CLOPTS -ABNe "$SQL" > $OUTFILE
	  fi
	fi
  fi
  display_file_written_message 
}

function record_disks (){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
local SQL_FILE="$SQL_DIR/DISKS.sql"
  local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv because logic in SQL prevents SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local DISKS=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
    while IFS= read -r line; do
      if [ ! -z "$line" ]; then printf "$RUNID\t$line\n" >> $OUTFILE; else touch $OUTFILE; fi
    done <<< "$DISKS"
    display_file_written_message
  fi
}

function record_mysql_top(){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv 
if [ "$(id --user $MARIADB_PROCESS_OWNER  2>/dev/null)" ] && [ "$DB_IS_LOCAL" == 'TRUE' ]; then
  TOP="$(top -b -n1 -u ${MARIADB_PROCESS_OWNER} 2>/dev/null)"
  if [ ! -z "$TOP" ]; then 
    printf '%b\n' "\"$SUBROUTINE\"\t\"$TOP\"" > $OUTFILE
  else
	printf "\"$SUBROUTINE\"\t\"NO top ACTIVITY for $MARIADB_PROCESS_OWNER\"\n" > $OUTFILE
  fi
  display_file_written_message
fi
}

function record_df(){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv 
if [ "$DB_IS_LOCAL" == 'TRUE' ]; then
  local DF="$(df -h 2>/dev/null)"
  if [ ! -z "$DF" ]; then 
    printf '%b\n' "\"$RUNID\"\t\"$DF\"" > $OUTFILE
  else
	printf "\"$RUNID\"\t\"df not available\"\n" > $OUTFILE
  fi
  display_file_written_message
fi
}

function record_memory_info(){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv 
if [ "$DB_IS_LOCAL" == 'TRUE' ]; then
  local MEMINFO=$(free -h 2>/dev/null)

  if [ ! -z "$MEMINFO" ]; then 
    printf '%b\n' "\"$RUNID\"\t\"$MEMINFO\"" > $OUTFILE
  else
	printf "\"$RUNID\"\t\"Memory info is not available\"\n" > $OUTFILE
  fi
  display_file_written_message
fi
}

function record_cpu_info(){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv 
if [ "$DB_IS_LOCAL" == 'TRUE' ]; then
  local CPUINFO=$(lscpu | grep -E "(op-mode|ddress|hread|ocket|name|MHz|vendor|cache)" 2>/dev/null)

  if [ ! -z "$CPUINFO" ]; then 
    printf '%b\n' "\"$RUNID\"\t\"$CPUINFO\"" > $OUTFILE
  else
	printf "\"$RUNID\"\t\"CPU info is not available\"\n" > $OUTFILE
  fi
  display_file_written_message
fi
}

function record_machine_architecture(){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv 
if [ "$DB_IS_LOCAL" == 'TRUE' ]; then
   if [ "$(grep docker /proc/1/cgroup 2>/dev/null)" ]; then
     local ARCH="Docker Container"
   elif [ "$(grep kube /proc/1/cgroup 2>/dev/null)" ]; then
     local ARCH="Kubernetes"
   else
     local ARCH=$(hostnamectl | grep -E "(Static|Chassis|Virtualization|Operat|Kernel|Arch)" 2>/dev/null)
   fi

  if [ ! -z "$ARCH" ]; then 
    printf '%b\n' "\"$RUNID\"\t\"$ARCH\"" > $OUTFILE
  else
	printf "\"$RUNID\"\t\"Machine architecture not available\"\n" > $OUTFILE
  fi
  display_file_written_message
fi
}

function record_recent_errors(){
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ ! "$DB_IS_LOCAL" == 'TRUE' ]; then return; fi
if [ ! -f "$LOG_ERROR" ] ; then return; fi
local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv 
RECENT=$(tail -200000 $LOG_ERROR | grep -i "\[ERROR\]")
 while IFS= read -r line; do
   if [ ! -z "$line" ]; then line=$(echo ${line} | sed 's|["'\'']||g'); printf "$RUNID\t\"$line\"\n" >> $OUTFILE; else touch $OUTFILE; fi
 done <<< "$RECENT"
 display_file_written_message
}

function record_slave_hosts (){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
local SQL_FILE="$SQL_DIR/SLAVE_HOSTS.sql"
  local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local SLAVE_HOSTS=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
    while IFS= read -r line; do
      if [ ! -z "$line" ]; then printf "$RUNID\t$line\n" >> $OUTFILE; else touch $OUTFILE; fi
    done <<< "$SLAVE_HOSTS"
    display_file_written_message
  fi
}

function record_open_tables (){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
local SQL_FILE="$SQL_DIR/OPEN_TABLES.sql"
  local OUTFILE="$QK_TMPDIR/$2.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local OPEN_TABLES=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
    while IFS= read -r line; do
      if [ ! -z "$line" ]; then printf "$SUBROUTINE\t$line\n" >> $OUTFILE; else touch $OUTFILE; fi
    done <<< "$OPEN_TABLES"
    display_file_written_message
  fi
}

function record_engine_innodb_status (){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
local SQL_FILE="$SQL_DIR/ENGINE_INNODB_STATUS.sql"
  local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local STATUS=$($CMD_MARIADB $CLOPTS -Ae "$SQL")
    printf "\"$RUNID\"\t\"$STATUS\"" > $OUTFILE
    display_file_written_message 
  fi
}

function record_slave_status(){
  local SQL_FILE="$SQL_DIR/SLAVE_STATUS.sql"
  local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local STATUS=$($CMD_MARIADB $CLOPTS -Ae "$SQL"| grep -i -E '(Slave_SQL_Running_State|Seconds_Behind_Master|Gtid_IO_Pos|Gtid_Slave_Pos|DB_Time|Hostname|Last_SQL_Error|Last_IO_Error)')
    local DT=$(printf "$STATUS\n" | grep -i DB_Time | awk '{print $2 " " $3}')
    local GTID_IO_POS=$(printf "$STATUS\n" | grep -i Gtid_IO_Pos | awk '{print $2}')
    local GTID_SLAVE_POS=$(printf "$STATUS\n" | grep -i Gtid_Slave_Pos | awk '{print $2}')
	local HOSTNAME=$(printf "$STATUS\n" | grep -i Hostname | awk '{print $2}')
    local RUNNING_STATE=$(printf "$STATUS\n" | grep -i Slave_SQL_Running_State | sed 's/.*\://' |xargs)
	local LAST_SQL_ERROR=$(printf "$STATUS\n" | grep -i Last_SQL_Error | sed 's/.*Last_SQL_Error://' | sed 's|["'\'']||g')
	local LAST_IO_ERROR=$(printf "$STATUS\n" | grep -i Last_IO_Error | sed 's/.*Last_IO_Error://' | sed 's|["'\'']||g')
    local BEHIND_MASTER=$(printf "$STATUS\n" | grep -i Seconds_Behind_Master | awk '{print $2}')
	if [ "$BEHIND_MASTER" == "" ]; then touch $OUTFILE; display_file_written_message; return; fi
    printf "$SUBROUTINE\t$DT\t$HOSTNAME\t$BEHIND_MASTER\t$GTID_IO_POS\t$GTID_SLAVE_POS\t$RUNNING_STATE\t$LAST_SQL_ERROR\t$LAST_IO_ERROR\n" > $OUTFILE
    display_file_written_message
  fi
}

function record_all_slaves_status(){
  local SQL_FILE="$SQL_DIR/ALL_SLAVES_STATUS.sql"
  local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local ALL_STATUS=$($CMD_MARIADB $CLOPTS -Ae "$SQL"| grep -i -E '(Connection_name|Slave_SQL_Running_State|Seconds_Behind_Master|Gtid_IO_Pos|Gtid_Slave_Pos|DB_Time|Hostname|Last_SQL_Error|Last_IO_Error)')
    local COUNT_SLAVES=$(printf "$ALL_STATUS\n" | grep -i Connection_name |wc -l)
	if [ "$COUNT_SLAVES" == "0" ]; then touch $OUTFILE; display_file_written_message; return; fi
    for (( ix=1; ix<=${COUNT_SLAVES}; ix++))
    do
      local CONN_NAME=$(printf "$ALL_STATUS\n" | grep -i Connection_name | head -${ix} | tail -1 | awk '{print $2}')
      local DT=$(printf "$ALL_STATUS\n" | grep -i DB_Time | awk '{print $2 " " $3}')
      local GTID_IO_POS=$(printf "$ALL_STATUS\n" | grep -i Gtid_IO_Pos  | head -${ix} | tail -1 | awk '{print $2}')
      local GTID_SLAVE_POS=$(printf "$ALL_STATUS\n" | grep -i Gtid_Slave_Pos | head -${ix} | tail -1  | awk '{print $2}')
      local HOSTNAME=$(printf "$ALL_STATUS\n" | grep -i Hostname | awk '{print $2}')
      local RUNNING_STATE=$(printf "$ALL_STATUS\n" | grep -i Slave_SQL_Running_State  | head -${ix} | tail -1| sed 's/.*\://' |xargs)
      local LAST_SQL_ERROR=$(printf "$ALL_STATUS\n" | grep -i Last_SQL_Error  | head -${ix} | tail -1 | sed 's/.*Last_SQL_Error://' | sed 's|["'\'']||g')
      local LAST_IO_ERROR=$(printf "$ALL_STATUS\n" | grep -i Last_IO_Error  | head -${ix} | tail -1 | sed 's/.*Last_IO_Error://' | sed 's|["'\'']||g')
      local BEHIND_MASTER=$(printf "$ALL_STATUS\n" | grep -i Seconds_Behind_Master  | head -${ix} | tail -1 | awk '{print $2}')
      printf "$SUBROUTINE\t$DT\t$HOSTNAME\t$CONN_NAME\t$BEHIND_MASTER\t$GTID_IO_POS\t$GTID_SLAVE_POS\t$RUNNING_STATE\t$LAST_SQL_ERROR\t$LAST_IO_ERROR\n" >> $OUTFILE
    done
    display_file_written_message
  fi
}

function record_page_all_slaves_status (){
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
local SQL_FILE="$SQL_DIR/PAGE_ALL_SLAVES_STATUS.sql"
  local OUTFILE="$QK_TMPDIR/$1.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$SQL"; echo; echo;
  else  
    local STATUS=$($CMD_MARIADB $CLOPTS -Ae "$SQL")
	if [ "$STATUS" == "" ]; then local STATUS="No output from command SHOW ALL SLAVES STATUS."; fi
    printf "\"$RUNID\"\t\"$STATUS\"" > $OUTFILE
    display_file_written_message 
  fi
}

function set_log_error() {
  unset DATADIR LOG_ERROR 
  if [ ! "$DB_IS_LOCAL" == 'TRUE' ]; then return; fi
  if [ $CAN_CONNECT ]; then
  local SQL_FILE="$SQL_DIR/LOG_ERROR.sql"
  local SQL=$(cat $SQL_FILE)  
    LOG_ERROR=$($CMD_MARIADB $CLOPTS  -ABNe "$SQL")
  local SQL_FILE="$SQL_DIR/DATADIR.sql"
  local SQL=$(cat $SQL_FILE)
    DATADIR=$($CMD_MARIADB $CLOPTS  -ABNe "$SQL" | sed 's:/*$::')
  else
    LOG_ERROR=$(my_print_defaults --mysqld| grep log_error | tail -1 | cut -d "=" -f2)
    DATADIR=$(my_print_defaults --mysqld| grep datadir | tail -1 | cut -d "=" -f2 | sed 's:/*$::')
  fi
  if [ -z "$LOG_ERROR" ]; then unset LOG_ERROR; return; fi;
  if [[ $LOG_ERROR =~ ^/.* ]]; then local FULL_PATH=true; fi

  if [ ! $FULL_PATH ]; then
    LOG_ERROR=$(basename $LOG_ERROR)
    LOG_ERROR=$DATADIR/$LOG_ERROR
  fi
}

function collect_logs() {
if [ ! $COLLECT_LOGS ]; then return; fi
if [ ! $LOG_ERROR ]; then return; fi
  mkdir -p $QK_TMPDIR/logs/system
  mkdir -p $QK_TMPDIR/logs/mariadb
  mkdir -p $QK_TMPDIR/logs/systemd

    OUTFILE=$QK_TMPDIR/logs/mariadb/$(hostname)_$(date +"%Y-%m-%d-%H-%M-%S")_$(basename $LOG_ERROR)
    FILTEREDFILE=$QK_TMPDIR/logs/mariadb/$(hostname)_$(date +"%Y-%m-%d-%H-%M-%S")_filtered_$(basename $LOG_ERROR)
    if [ -f $LOG_ERROR ]; then
      tail -100000 $LOG_ERROR > $OUTFILE
    fi
    if [ -f $LOG_ERROR ]; then
      tail -1000000 $LOG_ERROR | grep -iv "\[warning\]"|grep -iv "\[note\]"  > $FILTEREDFILE
    fi

  cp /var/log/messages* $QK_TMPDIR/logs/system
  find /var/log/syslog -name syslog -type f -exec tail -10000 {} > $QK_TMPDIR/logs/system/syslog \;
  find /var/log/daemon.log -name daemon.log -type f -exec tail -10000 {} > $QK_TMPDIR/logs/system/daemon.log \;

  find /usr/lib -name "mariadb*service" -exec cp {} $QK_TMPDIR/logs/systemd \;

  my_print_defaults --mysqld > $QK_TMPDIR/logs/mariadb/$(hostname)_my_print_defaults.txt 2>/dev/null 
  if [ -f $OUTFILE ]; then printf "LOGS COLLECTED\n"; fi
}

function post_version() {
if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
# to inform importer script which script version was used to create the data
  cp ${SCRIPT_DIR}/vsn.sh ${QK_TMPDIR}/vsn.sh
}

function is_userstat_enabled (){
  local SQL_FILE="$SQL_DIR/IS_USERSTAT_ENABLED.sql"
  local SQL=$(cat $SQL_FILE)
  # YOU CANNOT DEBUG_SQL HERE BECAUSE THIS EFFECTS SQL TEXT, SO IT MUST BE RUN
  local USERSTAT=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
  if [ "$USERSTAT" == 'YES' ]; then USERSTAT_ENABLED='TRUE'; fi
}

function is_performance_schema_enabled (){
  local SQL_FILE="$SQL_DIR/IS_PERFORMANCE_SCHEMA_ENABLED.sql"
  local SQL=$(cat $SQL_FILE)
  # YOU CANNOT DEBUG_SQL HERE BECAUSE THIS EFFECTS SQL TEXT, SO IT MUST BE RUN
  local PERFSTAT=$($CMD_MARIADB $CLOPTS -ABNe "$SQL"); 
  if [ "$PERFSTAT" == 'YES' ]; then PERFORMANCE_SCHEMA_ENABLED='TRUE'; fi
}

function mk_tmpdir() {
  if [ ! "$OUT_TO_FILES" == "TRUE" ]; then return; fi
  local subdir="${TEMPDIR}/${TOOL}"
  if [ ! $DEBUG_SQL ]; then  mkdir -p ${subdir} 2>/dev/null; fi
  if [ ! $DEBUG_SQL ]; then 
    QK_TMPDIR="${subdir}/${RUNID}"
	if [ -d $QK_TMPDIR ]; then die "Directory $QK_TMPDIR already exists."; fi
    mkdir -p $QK_TMPDIR || die "Cannot make tmpdir"
  fi
  if [ "$(id --user $MARIADB_PROCESS_OWNER  2>/dev/null)" ] && [ ! "$CLIENT_SIDE" == 'TRUE' ]; then
    chown -R ${MARIADB_PROCESS_OWNER}:${MARIADB_PROCESS_OWNER} ${subdir}
  fi
}

function _which() {
   if [ -x /usr/bin/which ]; then
      /usr/bin/which "$1" 2>/dev/null | awk '{print $1}'
   elif which which 1>/dev/null 2>&1; then
      which "$1" 2>/dev/null | awk '{print $1}'
   else
      echo "$1"
   fi
}

function dependency(){
  if [ ! $(_which $1) ]; then die "The linux program $1 is unavailable. Check PATH or install."; fi
}

function test_dependencies(){
  dependency which
  dependency tar
  dependency df 
  dependency top
  dependency free
  dependency awk
  dependency sed
  dependency envsubst
  dependency cut
  dependency base64
  dependency head
  dependency id
  dependency whoami
}

function compress_file(){
  if [ "$DEBUG_SQL" == "TRUE" ]; then return; fi
  if [ "$OUT_TO_FILES" == "FALSE" ]; then return; fi
  if [ ! -d $QK_TMPDIR ]; then die "Directory $QK_TMPDIR does not exist."; fi
  COMPRESSFILE=$(dirname $QK_TMPDIR)/${RUNID}_$(hostname)_$(date +"%b-%d").tar.gz
  cd $QK_TMPDIR
  tar -czf /$COMPRESSFILE ./*
 TEMP_COLOR=lmagenta; print_color "Attach file $COMPRESSFILE to your support ticket.\n"; unset TEMP_COLOR;
}

function print_color () {
  if [ -z "$COLOR" ] && [ -z "$TEMP_COLOR" ]; then printf "$1"; return; fi
  case "$COLOR" in
    default) i="0;36" ;;
    red)  i="0;31" ;;
    blue) i="0;34" ;;
    green) i="0;32" ;;
    yellow) i="0;33" ;;
    magenta) i="0;35" ;;
    cyan) i="0;36" ;;
    lred) i="1;31" ;;
    lblue) i="1;34" ;;
    lgreen) i="1;32" ;;
    lyellow) i="1;33" ;;
    lmagenta) i="1;35" ;;
    lcyan) i="1;36" ;;
    *) i="0" ;;
  esac
if [ $TEMP_COLOR ]; then
  case "$TEMP_COLOR" in
    default) i="0;36" ;;
    red)  i="0;31" ;;
    blue) i="0;34" ;;
    green) i="0;32" ;;
    yellow) i="0;33" ;;
    magenta) i="0;35" ;;
    cyan) i="0;36" ;;
    lred) i="1;31" ;;
    lblue) i="1;34" ;;
    lgreen) i="1;32" ;;
    lyellow) i="1;33" ;;
    lmagenta) i="1;35" ;;
    lcyan) i="1;36" ;;
    *) i="0" ;;
  esac
fi
  printf "\033[${i}m${1}\033[0m"

}

function singular_plural () {
  local noun=$1;
  local count=$2;
  if (( $count != 1 )); then
    noun+="s"
  fi
  printf "%s" "$noun"  
}


for params in "$@"; do
unset VALID; #REQUIRED
# echo "PARAMS: $params"
if [ $(echo "$params"|sed 's,=.*,,') == '--minutes' ]; then 
  MINS=$(echo "$params" | sed 's/.*=//g'); 
  if [ ! $(echo $MINS | awk '{ if(int($1)==$1) print $1}') ]; then 
   INVALID_INPUT="$params"; 
  else 
   VALID=TRUE; 
  fi
fi
if [ $(echo "$params"|sed 's,=.*,,') == '--stats_per_min' ]; then 
  PER_MIN=$(echo "$params" | sed 's/.*=//g'); 
  if [ ! $(echo $PER_MIN | awk '{ if(int($1)==$1) print $1}') ]; then 
   INVALID_INPUT="$params"; 
  else 
  # stats_per_min valid values: 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60
   if [ $PER_MIN -eq 1 ]; then STATS_ON_SEC=("00"); fi
   if [ $PER_MIN -eq 2 ]; then STATS_ON_SEC=("00" "30"); fi
   if [ $PER_MIN -eq 3 ]; then STATS_ON_SEC=("00" "20" "40"); fi
   if [ $PER_MIN -eq 4 ]; then STATS_ON_SEC=("00" "15" "30" "45"); fi
   if [ $PER_MIN -eq 5 ]; then STATS_ON_SEC=("00" "12" "24" "36" "48"); fi
   if [ $PER_MIN -eq 6 ]; then STATS_ON_SEC=("00" "10" "20" "30" "40" "50"); fi
   if [ $PER_MIN -eq 10 ]; then STATS_ON_SEC=("00" "06" "12" "18" "24" "30" "36" "42" "48" "54"); fi
   if [ $PER_MIN -eq 12 ]; then STATS_ON_SEC=("00" "05" "10" "15" "20" "25" "30" "35" "40" "45" "50" "55"); fi
   if [ $PER_MIN -eq 15 ]; then STATS_ON_SEC=("00" "04" "08" "12" "16" "20" "24" "28" "32" "36" "40" "44" "48" "52" "56"); fi
   if [ $PER_MIN -eq 20 ]; then STATS_ON_SEC=("00" "03" "06" "09" "12" "15" "18" "21" "24" "27" "30" "33" "36" "39" "42" "45" "48" "51" "54" "57"); fi
   if [ $PER_MIN -eq 30 ]; then STATS_ON_SEC=("00" "02" "04" "06" "08" "10" "12" "14" "16" "18" "20" "22" "24" "26" "28" "30" "32" "34" "36" "38" "40" "42" "44" "46" "48" "50" "52" "54" "56" "58"); fi
   if [ $PER_MIN -eq 60 ]; then STATS_ON_SEC=("00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24" "25" "26" "27" "28" "29" "30" "31" "32" "33" "34" "35" "36" "37" "38" "39" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59"); fi
   if [ ! $STATS_ON_SEC ]; then INVALID_INPUT="$params"; else VALID=TRUE; fi
  fi
fi
  if [ "$params" == '--multi_processlist' ]; then MULTI_PROCESSLIST='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--no_outfiles' ]; then OUT_TO_FILES='FALSE'; VALID=TRUE; fi
  if [ "$params" == '--redirect_to_files' ]; then CLIENT_SIDE='TRUE'; VALID=TRUE; fi  
  if [ "$params" == '--logs' ]; then COLLECT_LOGS=TRUE; VALID=TRUE; fi
  if [ "$params" == '--debug_sql' ]; then DEBUG_SQL='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--debug_outfiles' ]; then DEBUG_OUTFILE='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--bypass_priv_check' ]; then BYPASS_PRIV_CHECK='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--version' ]; then DISPLAY_VERSION=TRUE; VALID=TRUE; fi
  if [ "$params" == '--test' ]; then DISPLAY_VERSION=TRUE; VALID=TRUE; fi
  if [ "$params" == '--help' ]; then HELP=TRUE; VALID=TRUE; fi
  if [ ! $VALID ] && [ ! $INVALID_INPUT ];  then  INVALID_INPUT="$params"; fi
done

if [ $(_which mariadb 2>/dev/null) ]; then
  CMD_MARIADB="${CMD_MARIADB:-"$(_which mariadb)"}"
else
  CMD_MARIADB="${CMD_MYSQL:-"$(_which mysql)"}"
fi

CMD_MY_PRINT_DEFAULTS="${CMD_MY_PRINT_DEFAULTS:-"$(_which my_print_defaults)"}"

if [ -z $CMD_MARIADB ]; then
  die "mariadb client command not available."
fi

if [ -z $CMD_MY_PRINT_DEFAULTS ]; then
  die "my_print_defaults command not available."
fi

CLOPTS=$($CMD_MY_PRINT_DEFAULTS --defaults-file=$CONFIG_FILE mariadb_quick_review | sed -z -e "s/\n/ /g")
