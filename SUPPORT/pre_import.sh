#!/usr/bin/env bash
# pre_import.sh
# file distributed with mariadb_quick_review
# By Edward Stoever for MariaDB Support

SCHEMA_NAME='mariadb_quick_review' #DEFAULT
MARIADB_PROCESS_OWNER="$(ps -ef | grep -E '(mariadbd|mysqld)' | grep -v "grep" | head -1 |awk '{print $1}')"
TEMPDIR="/tmp"
TOOL="mariadb_quick_review"
SQL_DIR="$SCRIPT_DIR/SQL"
CONFIG_FILE="$SCRIPT_DIR/quick_import.cnf"


function display_title(){
local COMPAT='FALSE'
if [ ! $SCRIPT_VERSION ]; then SCRIPT_VERSION='UNKNOWN'; fi 

for vs in "${COMPATIBLE[@]}"; do
  if [[ $vs == $IMPORT_SCRIPT_VERSION ]]
  then
    local COMPAT='TRUE'
  fi
done

if [ $NO_IMPORT_FILE ]; then local COMPAT='NOFILE'; fi
if [ $TOO_MANY_IMPORT_FILES ]; then local COMPAT='TOOMANY'; fi

  local BLANK='  │                                                         │'
  printf "  ┌─────────────────────────────────────────────────────────┐\n"
  printf "$BLANK\n"
  printf "  │               MARIADB QUICK REVIEW IMPORT               │\n"
  printf '%-62s' "  │                      Version $IMPORT_SCRIPT_VERSION"; printf "│\n"
  printf "$BLANK\n"
  printf "  │      Script by Edward Stoever for MariaDB Support       │\n"
  printf "$BLANK\n"
  printf '%-62s' "  │             Export Created with Version $SCRIPT_VERSION"; printf "│\n"
  if [ "$COMPAT" == 'TRUE' ]; then
    printf "  │                        ";TEMP_COLOR='lgreen'; print_color "Compatible"; unset TEMP_COLOR;  printf "                       |\n";
  elif [ "$COMPAT" == 'NOFILE' ]; then
    printf "  │                      ";TEMP_COLOR='lred'; print_color "No Import File"; unset TEMP_COLOR; printf "                     |\n"
  elif [ "$COMPAT" == 'TOOMANY' ]; then
    printf "  │                   ";TEMP_COLOR='lred'; print_color "Too Many Import Files"; unset TEMP_COLOR; printf "                 |\n"
  else
    printf "  │                   ";TEMP_COLOR='lred'; print_color "May not be compatible"; unset TEMP_COLOR; printf "                 |\n"
  fi
  printf "$BLANK\n"
  printf "  └─────────────────────────────────────────────────────────┘\n"
 

 if [ $INVALID_INPUT ]; then display_help_message; die "Invalid option: $INVALID_INPUT"; fi
 if [ $HELP ]; then display_help_message; exit 0; fi
 if [ "$ERR_MSG" ] && [ ! "$DISPLAY_VERSION" ]; then die "$ERR_MSG"; fi 
 
  if [ "$COMPAT" == 'FALSE' ]; then 
    TEMP_COLOR=lcyan; print_color "The export may not be compatible.\n"; unset TEMP_COLOR;
	printf "Type y to continue anyway or type any other key to cancel.\n"; 
    read -s -n 1 RESPONSE
    if [ ! "$RESPONSE" = "y" ]; then die "operation cancelled";  fi 
  fi


}

function display_help_message() {
printf "This script can be run without options. Not indicating an option value will use the default.
  --schema=CS0999999   # create a schema, default mariadb_quick_review
  --version            # Test connect to database and display script version
  --test               # Test connect to database and display script version
  --help               # Display the help menu

Read the file README.md for more information.\n"
}

function is_db_localhost(){
  local SQL_FILE="$SQL_DIR/IS_DB_LOCALHOST.sql"
  local SQL=$(cat $SQL_FILE)
  local DBHOST=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
  CLIENTHOST=$(hostname)
  if [ ! "$DBHOST" == "$CLIENTHOST" ]; then die "Database is remote. Database must be running locally to import files."; fi
}


function ensure_media_file(){
  local COUNT_IMPORT_MEDIA=$(ls $SCRIPT_DIR/QK-*tar.gz 2>/dev/null |wc -l)
  if [ "$COUNT_IMPORT_MEDIA" == "0" ]; then ERR_MSG="Import file not found."; NO_IMPORT_FILE='TRUE'; return; fi
  if [ "$COUNT_IMPORT_MEDIA" -gt "1" ]; then ERR_MSG="Multiple potential import files found. Must be only one."; TOO_MANY_IMPORT_FILES='TRUE'; fi
}

function uncompress_media_file(){ 
  if [ "$ERR_MSG" ]; then return; fi 
  tar -zvxf $SCRIPT_DIR/QK-*.tar.gz -C $QK_TMPDIR 1>/dev/null || die "Failed to untar import media file."
  chown -R ${MARIADB_PROCESS_OWNER}:${MARIADB_PROCESS_OWNER} $QK_TMPDIR
}

function set_runid(){
  if [ "$ERR_MSG" ]; then return; fi 
  local FILE=$(basename $(ls $SCRIPT_DIR/QK-*tar.gz 2>/dev/null) 2>/dev/null| head -1)
  if [ $FILE ]; then RUNID=$(echo $FILE | cut -d _ -f 1); fi
}

function mk_tmpdir() {
  local subdir="${TEMPDIR}/${TOOL}"
  QK_TMPDIR="${subdir}/${RUNID}"
  mkdir -p $QK_TMPDIR 2>/dev/null
  chown -R ${MARIADB_PROCESS_OWNER}:${MARIADB_PROCESS_OWNER} ${subdir}
  rm -f $QK_TMPDIR/*.out $QK_TMPDIR/*.tsv $QK_TMPDIR/*.csv
}


function ts() {
   local TS=$(date +%F-%T | tr ':-' '_')
   echo "$TS $*"
}


function die() {
   ts "$*" >&2
   exit 1
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
  dependency mariadb-import
  dependency my_print_defaults
}


function check_required_privs() {
  local SQL_FILE="$SQL_DIR/IMPORT_PRIVS.sql"
  local ERR=$($CMD_MARIADB $CLOPTS -e "source $SQL_FILE")
  if [ "$ERR" ]; then die "$ERR"; fi
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

function create_schema() {
  local SQL_FILE="$SQL_DIR/CREATE_SCHEMA.sql"
  export SCHEMA_NAME
  local SQL=$(envsubst < $SQL_FILE)
  
  $CMD_MARIADB $CLOPTS -e "$SQL"
}
 
function interactive_schema_exists(){
  local SQL_FILE="$SQL_DIR/SCHEMA_EXISTS.sql"
  export SCHEMA_NAME
  local SQL=$(envsubst < $SQL_FILE)
  local SCHEMA_EXISTS=$($CMD_MARIADB $CLOPTS  -ABNe "$SQL")
  if [ "$SCHEMA_EXISTS" == "YES" ]; then 
  TEMP_COLOR=lred; print_color "Important: "; unset TEMP_COLOR;
  printf "The schema "; TEMP_COLOR=lcyan; print_color "$SCHEMA_NAME"; printf " already exists.\n"; unset TEMP_COLOR;
  printf "Type y to drop and create the schema or type any other key to cancel.\n"; 
  read -s -n 1 RESPONSE
    if [ ! "$RESPONSE" = "y" ]; then
      die "operation cancelled";  
    fi 
  fi
}

function post_import() {
  local SQL_FILE="$SCRIPT_DIR/SQL/POST_IMPORT.sql"
  export SCHEMA_NAME
  local SQL=$(envsubst < $SQL_FILE)
  $CMD_MARIADB $CLOPTS  -e "$SQL" && local SUCCESS='TRUE' 
  if [ $SUCCESS ]; then 
    TEMP_COLOR=lcyan; print_color "Post Import Script Completed.\n"; unset TEMP_COLOR;
  else
    TEMP_COLOR=lred; print_color "Post Import Script Failed.\n"; unset TEMP_COLOR;
  fi
}

function log_files_provided() {
  if [ ! -d "$QK_TMPDIR/logs" ]; then return; fi
  local LOG_COUNT=$(find "$QK_TMPDIR/logs" -type f|wc -l)
  if [ "$LOG_COUNT" -gt "0" ]; then
    printf "\nThere are $LOG_COUNT log files in the directory: "; TEMP_COLOR=lcyan; print_color "$QK_TMPDIR/logs\n\n"; unset TEMP_COLOR;
  fi
}

function import_from_file(){
  local TABLE_NAME=$1
# echo $1
# .out
local EXIST_OUT=$(find $QK_TMPDIR/ -name "${TABLE_NAME}*.out" ! -size 0 |head -1)
if [ $EXIST_OUT ]; then
    TEMP_COLOR=lcyan; print_color "Importing "; 
	TEMP_COLOR=lgreen; print_color "out"; 
	TEMP_COLOR=lcyan; print_color " file(s): $TABLE_NAME\n"; unset TEMP_COLOR;
fi
for IMPORTFILE in $(find $QK_TMPDIR/ -name "${TABLE_NAME}*.out" ! -size 0 | sort)
do
  mariadb-import --defaults-file=$SCRIPT_DIR/OPT/$TABLE_NAME.out.cnf $CLOPTS $SCHEMA_NAME $IMPORTFILE
done

if [ ! "$TSV2CSV" == 'TRUE' ]; then
  # .tsv
  local EXIST_TSV=$(find $QK_TMPDIR/ -name "${TABLE_NAME}*.tsv" ! -size 0 |head -1)
  if [ $EXIST_TSV ]; then
    TEMP_COLOR=lcyan; print_color "Importing "; 
	TEMP_COLOR=lyellow; print_color "tsv"; 
	TEMP_COLOR=lcyan; print_color " file(s): $TABLE_NAME\n"; unset TEMP_COLOR;
  fi
  for IMPORTFILE in $(find $QK_TMPDIR/ -name "${TABLE_NAME}*.tsv" ! -size 0 | sort)
  do
    mariadb-import --defaults-file=$SCRIPT_DIR/OPT/$TABLE_NAME.tsv.cnf $CLOPTS $SCHEMA_NAME $IMPORTFILE
  done
else
  # .csv -- THIS SECTION WAS INCLUDED IN CASE I COULD NOT MAKE tsv FILES WORK.
  
  find $QK_TMPDIR -type f -name "${TABLE_NAME}*.tsv" -exec sh -c 'BN=$(basename {});DN=$(dirname {});FN="$DN/$BN"; NEWFILE="$(echo $FN | sed "s/.\{4\}$//").csv"; cp {} "$NEWFILE"' \;
  
  local EXIST_CSV=$(find $QK_TMPDIR/ -name "${TABLE_NAME}*.csv" ! -size 0 | head -1)
  if [ $EXIST_CSV ]; then
    TEMP_COLOR=lmagenta; print_color "Converting from tsv to csv and importing: $TABLE_NAME\n"; unset TEMP_COLOR;
  fi
  for IMPORTFILE in $(find $QK_TMPDIR/ -name "${TABLE_NAME}*.csv" ! -size 0 | sort)
  do
  
    # sed commands to transform client-side output tsv to csv which is similar output of typlical "INTO OUTFILE":
    sed -i 's/\(.*\)/"\1"/g' $IMPORTFILE # ENCLOSE EACH LINE WITH DOUBLE-QUOTES
    sed -i "s/\t/\",\"/g"    $IMPORTFILE # REPLACE TAB WITH \",\"
    sed -i 's/\"NULL\"/\\\\N/g'  $IMPORTFILE  # REPLACE \"NULL\" with \\N
		
    mariadb-import --defaults-file=$SCRIPT_DIR/OPT/$TABLE_NAME.csv.cnf $CLOPTS $SCHEMA_NAME $IMPORTFILE
  done
fi
}

function can_connect(){
  $CMD_MARIADB $CLOPTS  -s -e "select now()" 1>/dev/null 2>/dev/null && CAN_CONNECT=true || unset CAN_CONNECT
  if [ $CAN_CONNECT ]; then
    TEMP_COLOR=lgreen; print_color "Can connect to database.\n"; unset TEMP_COLOR;
  else
    TEMP_COLOR=lred;   print_color "Cannot connect to database.\n"; unset TEMP_COLOR;
    TEMP_COLOR=lred; print_color "Failing command: ";unset TEMP_COLOR; 
    TEMP_COLOR=lyellow; print_color "$CMD_MARIADB $CLOPTS\n";unset TEMP_COLOR; 
    ERRTEXT=$($CMD_MARIADB $CLOPTS -e "select now();" 2>&1); TEMP_COLOR=lcyan; print_color "$ERRTEXT\n";unset TEMP_COLOR;
    die "Database connection failed. Read the file README.md. Edit the file quick_import.cnf."; 
  fi
  printf "OS account:    "; TEMP_COLOR=lmagenta; print_color "$(whoami)\n"; unset TEMP_COLOR;
}

function whoami_db(){
  local SQL_FILE="$SQL_DIR/WHOAMI_DB.sql"
  local SQL=$(cat $SQL_FILE)
  if [ "$DEBUG_SQL" == "TRUE" ] ; then
    echo "$QSQL"; echo; echo;
  else
    WHOAMI_DB=$($CMD_MARIADB $CLOPTS -ABNe "$SQL")
    printf "DB account:    "; TEMP_COLOR=lmagenta; print_color "$WHOAMI_DB\n"; unset TEMP_COLOR;
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

for params in "$@"; do
unset VALID; #REQUIRED
# echo "PARAMS: $params"
if [ $(echo "$params"|sed 's,=.*,,') == '--schema' ]; then 
  SCHEMA_NAME=$(echo "$params" | sed 's/.*=//g'); 
  if [ $(echo $SCHEMA_NAME | awk '{ if(int($1)==$1) print $1}') ]; then 
   INVALID_INPUT="$params"; 
  else 
   VALID=TRUE; 
  fi
fi
  if [ "$params" == '--tsv2csv' ]; then TSV2CSV='TRUE'; VALID=TRUE; fi # THIS OPTION WILL BE REMOVED SOON
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

CLOPTS=$($CMD_MY_PRINT_DEFAULTS --defaults-file=$CONFIG_FILE quick_review_import | sed -z -e "s/\n/ /g")
