#!/usr/bin/env bash
# pre_quick_review.sh
# file distributed with mariadb_quick_review 
# By Edward Stoever for MariaDB Support

TEMPDIR="/tmp"
CONFIG_FILE="$SCRIPT_DIR/quick_review.cnf"
SQL_DIR="$SCRIPT_DIR/SQL"
TOOL="mariadb_quick_review"
PT_TMPDIR=""
SLAVES_RUNNING=0; # DEFAULT
OUT_TO_FILES='TRUE' # DEFAULT
MINS=5 #DEFAULT
RUNID=$(echo $(echo $(($RANDOM * $RANDOM +100000))| base64 | sed 's/\=//g' | head -c 6 2>/dev/null || echo 'NOTRND')  | awk '{print "QK-" substr($0,1,6)}')
SUBROUTINE="$RUNID-0000"
MARIADB_PROCESS_OWNER="$(ps -ef | grep -E '(mariadbd|mysqld)' | grep -v "grep" | head -1 |awk '{print $1}')"

function display_help_message() {
printf "This script can be run without options. Not indicating an option value will use the default.
  --minutes=10         # indicate the number of minutes to collect performance statistics, default 5
  --stats_per_min=2    # indicate the number of times per minute to collect performance statistics, default 1
                       # Valid values for stats_per_min: 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60
  --multi_processlist  # Turns on collecting processlist with each statistics collection. Turned off by default.
  --version            # Test connect to database and display script version
  --help               # Display the help menu

  ### THE BELOW OPTIONS ARE INTEDED FOR SOFTWARE DEVELOPMENT ###
  --debug_sql             # Instead of running SQL commands, display the SQL commands that will be run
  --debug_outfiles        # view the outfiles as each is created
  --client_side_outfiles  # Force a redirect of output to files instead of SELECT INTO OUTFILE.
  --bypass_priv_check     # Bypass the check that the database user has sufficient privileges.
  --no_outfiles           # Output to stdout instead of to files

Read the file README.md for more information.\n"
}

function is_primary(){
  local SQL_FILE="$SQL_DIR/IS_PRIMARY.sql"
  local QSQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$QSQL"; echo; echo;
  else
    IS_PRIMARY=$($CMD_MARIADB $CLOPTS -ABNe "$QSQL");
    if [ "$IS_PRIMARY" == "YES" ]; then
      printf "IS PRIMARY: "; TEMP_COLOR=lcyan; print_color "YES\n"; unset TEMP_COLOR;
    else
      printf "IS PRIMARY: "; TEMP_COLOR=lmagenta; print_color "NO\n"; unset TEMP_COLOR;
    fi
  fi
}

function whoami_db(){
  local SQL_FILE="$SQL_DIR/WHOAMI_DB.sql"
  local QSQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$QSQL"; echo; echo;
  else
    WHOAMI_DB=$($CMD_MARIADB $CLOPTS -ABNe "$QSQL")
    printf "DB account:    "; TEMP_COLOR=lmagenta; print_color "$WHOAMI_DB\n"; unset TEMP_COLOR;
  fi
}

function is_replica(){
  local SQL_FILE="$SQL_DIR/IS_REPLICA.sql"
  local QSQL=$(cat $SQL_FILE)
    if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$QSQL"; echo; echo;
  else
    IS_REPLICA=$($CMD_MARIADB $CLOPTS -ABNe "$QSQL");
    if [ "$IS_REPLICA" == "YES" ]; then
      printf "IS REPLICA: "; TEMP_COLOR=lcyan; print_color "YES\n"; unset TEMP_COLOR;
    else
      printf "IS REPLICA: "; TEMP_COLOR=lmagenta; print_color "NO\n"; unset TEMP_COLOR;
    fi
  fi
}

function slaves_running(){
  local SQL_FILE="$SQL_DIR/SLAVES_RUNNING.sql"
  local QSQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
  echo "$QSQL"; echo; echo; exit 0
  else
    SLAVES_RUNNING=$($CMD_MARIADB $CLOPTS -ABNe "$QSQL");
  fi
}

function is_galera(){
  local SQL_FILE="$SQL_DIR/IS_GALERA.sql"
  local QSQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$QSQL"; echo; echo; 
  else
    IS_GALERA=$($CMD_MARIADB $CLOPTS -ABNe "$QSQL");
    if [ "$IS_GALERA" == "YES" ]; then
      printf "IS GALERA: "; TEMP_COLOR=lcyan; print_color "YES\n"; unset TEMP_COLOR;
    else
      printf "IS GALERA:  "; TEMP_COLOR=lmagenta; print_color "NO\n"; unset TEMP_COLOR;
    fi
  fi
}


function check_required_privs() {
  if [ "$CLIENT_SIDE" == 'TRUE' ]; then
   SQL_FILE="$SQL_DIR/CLIENT_OUTFILE_PRIVS.sql"
  else
   SQL_FILE="$SQL_DIR/SERVER_OUTFILE_PRIVS.sql"
  fi
  if [ ! "$BYPASS_PRIV_CHECK" == "TRUE" ]; then
    ERR=$($CMD_MARIADB $CLOPTS -e "source $SQL_FILE")
    if [ "$ERR" ]; then die "$ERR"; fi
  fi
}

function is_db_localhost(){
  local SQL_FILE="$SQL_DIR/IS_DB_LOCALHOST.sql"
  local QSQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$QSQL"; echo; echo; 
  else
    DBHOST=$($CMD_MARIADB $CLOPTS -ABNe "$QSQL")
    CLIENTHOST=$(hostname)
    if [ ! "$DBHOST" == "$CLIENTHOST" ]; then CLIENT_SIDE='TRUE'; fi
      printf "Database Host: "; TEMP_COLOR=lmagenta; print_color "$DBHOST\n"; unset TEMP_COLOR;
      printf "Client Host:   "; TEMP_COLOR=lmagenta; print_color "$CLIENTHOST\n"; unset TEMP_COLOR;
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

  OUTP="MariaDB Quick Review version $SCRIPT_VERSION. Script by Edward Stoever for MariaDB Support. Script started at: "
  HDR=$($CMD_MARIADB $CLOPTS -s -e "select concat('$OUTP', now()) as NOTE" 2>/dev/null || echo "$OUTP$(date +'%Y-%m-%d %H:%M:%S - No DB connection.')")
  if [[ ! "$HDR" =~ .*"No DB connection".* ]]; then CAN_CONNECT=true; fi
  printf "$HDR\n"
  if [ $CAN_CONNECT ]; then
    TEMP_COLOR=lgreen; print_color "Can connect to database.\n"; unset TEMP_COLOR;
  else
    TEMP_COLOR=lred;   print_color "Cannot connect to database.\n"; unset TEMP_COLOR;
  fi
  printf "OS account:    "; TEMP_COLOR=lmagenta; print_color "$RUNAS\n"; unset TEMP_COLOR;

}

function run_sql() {
  SQL_FILE="$SQL_DIR/$1.sql"
  if [ ! "$CLIENT_SIDE" == 'TRUE' ]; then
    if [ ! $2 ]; then
      OUTFILE="$PT_TMPDIR/$1.out"
    else
      OUTFILE="$PT_TMPDIR/$2.out"
    fi
  else
    if [ ! $2 ]; then
      OUTFILE="$PT_TMPDIR/$1.tsv"
    else
      OUTFILE="$PT_TMPDIR/$2.tsv"
    fi
  fi


  INTO_OUTFILE="INTO OUTFILE '$OUTFILE' FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"' ESCAPED BY '\\\\'"
  export OUTFILE SCRIPT_VERSION RUNID SUBROUTINE
  SQL=$(envsubst < $SQL_FILE)
  
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
  # IN THEORY, THERE DOES NOT EXIST A CASE IN WHICH REMOTE DB CREATES AN INACCESSIBLE OUTFILE.
  # SO THIS MESSAGE SHOULD NEVER APPEAR BECAUSE IF REMOTE, CLIENT_SIDE='TRUE':
  if [ "$OUT_TO_FILES" == "TRUE" ] && [ ! "$CLIENT_SIDE" == 'TRUE' ] && [ ! -f "$OUTFILE" ] && [ ! "$DEBUG_SQL" == 'TRUE' ]; then echo "FILE WRITTEN ON DATABASE HOST: $OUTFILE"; fi
  if [ "$OUT_TO_FILES" == "TRUE" ] && [ -f "$OUTFILE" ]; then echo "FILE WRITTEN: $OUTFILE"; fi

  if [ "$DEBUG_OUTFILE" == "TRUE" ] && [ -f "$OUTFILE" ]; then
    cat $OUTFILE
  fi 
}

function record_slave_status(){
  SQL_FILE="$SQL_DIR/SLAVE_STATUS.sql"
  OUTFILE="$PT_TMPDIR/$1.tsv" # Always a .tsv because there is no SELECT INTO OUTFILE
  SQL=$(cat $SQL_FILE)
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
    printf "$SUBROUTINE\t$DT\t$HOSTNAME\t$BEHIND_MASTER\t$GTID_IO_POS\t$GTID_SLAVE_POS\t$RUNNING_STATE\t$LAST_SQL_ERROR\t$LAST_IO_ERROR\n" > $OUTFILE
    # IN THEORY, THERE DOES NOT EXIST A CASE IN WHICH REMOTE DB CREATES AN INACCESSIBLE OUTFILE.
    # SO THIS MESSAGE SHOULD NEVER APPEAR BECAUSE IF REMOTE, CLIENT_SIDE='TRUE':
    if [ "$OUT_TO_FILES" == "TRUE" ] && [ ! "$CLIENT_SIDE" == 'TRUE' ] && [ ! -f "$OUTFILE" ] && [ ! "$DEBUG_SQL" == 'TRUE' ]; then echo "FILE WRITTEN ON DATABASE HOST: $OUTFILE"; fi
    if [ "$OUT_TO_FILES" == "TRUE" ] && [ -f "$OUTFILE" ]; then echo "FILE WRITTEN: $OUTFILE"; fi

    if [ "$DEBUG_OUTFILE" == "TRUE" ] && [ -f "$OUTFILE" ]; then
      cat $OUTFILE
    fi 
  fi
}

function mk_tmpdir() {
  local subdir="${TEMPDIR}/${TOOL}"
  if [ ! $DEBUG_SQL ]; then  mkdir -p ${subdir} 2>/dev/null; fi
  if [ ! $DEBUG_SQL ]; then 
    PT_TMPDIR="${subdir}/${RUNID}"
	if [ -d $PT_TMPDIR ]; then die "Directory $PT_TMPDIR already exists."; fi
    mkdir -p $PT_TMPDIR || die "Cannot make tmpdir"
  fi
  if [ "$(id --user $MARIADB_PROCESS_OWNER  2>/dev/null)" ] && [ ! "$CLIENT_SIDE" == 'TRUE' ]; then
    chown -R ${MARIADB_PROCESS_OWNER}:${MARIADB_PROCESS_OWNER} ${subdir}
  fi
}

function ts() {
   TS=$(date +%F-%T | tr ':-' '_')
   echo "$TS $*"
}

function die() {
   ts "$*" >&2
   exit 1
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

function compress_file(){
  if [ "$DEBUG_SQL" == "TRUE" ] ; then return; fi
  if [ ! -d $PT_TMPDIR ]; then die "Directory $PT_TMPDIR does not exist."; fi
  COMPRESSFILE=$(dirname $PT_TMPDIR)/${RUNID}_$(hostname)_$(date +"%b-%d").tar.gz
  cd $PT_TMPDIR
  tar -czf /$COMPRESSFILE ./*
 TEMP_COLOR=lmagenta; print_color "Attach file $COMPRESSFILE to your support ticket.\n"; unset TEMP_COLOR;
}

# print_color is borrowed from columnstore_review.sh
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

if [ $(which mariadb 2>/dev/null) ]; then
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
  if [ "$params" == '--client_side_outfiles' ]; then CLIENT_SIDE='TRUE'; VALID=TRUE; fi  
  if [ "$params" == '--debug_sql' ]; then DEBUG_SQL='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--debug_outfiles' ]; then DEBUG_OUTFILE='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--bypass_priv_check' ]; then BYPASS_PRIV_CHECK='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--version' ]; then DISPLAY_VERSION=TRUE; VALID=TRUE; fi
  if [ "$params" == '--help' ]; then HELP=TRUE; VALID=TRUE; fi
  if [ ! $VALID ] && [ ! $INVALID_INPUT ];  then  INVALID_INPUT="$params"; fi
done