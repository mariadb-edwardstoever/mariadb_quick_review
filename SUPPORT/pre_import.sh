#!/usr/bin/env bash
# pre_import.sh
# file distributed with mariadb_quick_review
# By Edward Stoever for MariaDB Support

SCHEMA_NAME='mariadb_quick_review' #DEFAULT
MARIADB_PROCESS_OWNER="$(ps -ef | grep -E '(mariadbd|mysqld)' | grep -v "grep" | head -1 |awk '{print $1}')"
TEMPDIR="/tmp"
TOOL="mariadb_quick_review"

function ensure_media_file(){
  COUNT_IMPORT_MEDIA=$(ls $SCRIPT_DIR/QK-*tar.gz 2>/dev/null |wc -l)
  if [ "$COUNT_IMPORT_MEDIA" == "0" ]; then die "Import file not found."; fi
  if [ ! "$COUNT_IMPORT_MEDIA" == "1" ]; then die "Multiple potential import files found. Must be only one."; fi
}


function uncompress_media_file(){
  tar -zvxf $SCRIPT_DIR/QK-*.tar.gz -C $PT_TMPDIR 1>/dev/null || die "Failed to untar import media file."
  chown -R ${MARIADB_PROCESS_OWNER}:${MARIADB_PROCESS_OWNER} $PT_TMPDIR
}

function set_runid(){
  local FILE=$(basename $(ls $SCRIPT_DIR/QK-*tar.gz))
  RUNID=$(echo $FILE | cut -d _ -f 1)
}

function mk_tmpdir() {
  local subdir="${TEMPDIR}/${TOOL}"
  PT_TMPDIR="${subdir}/${RUNID}"
  mkdir -p $PT_TMPDIR 2>/dev/null
  chown -R ${MARIADB_PROCESS_OWNER}:${MARIADB_PROCESS_OWNER} ${subdir}
  rm -f $PT_TMPDIR/*.out $PT_TMPDIR/*.tsv $PT_TMPDIR/*.csv
}


function ts() {
   TS=$(date +%F-%T | tr ':-' '_')
   echo "$TS $*"
}


function die() {
   ts "$*" >&2
   exit 1
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
  SQL_FILE="$SCRIPT_DIR/SQL/CREATE_SCHEMA.sql"

  export SCHEMA_NAME
  SQL=$(envsubst < $SQL_FILE)
  
  mariadb -e "$SQL"
}

function import_from_file(){
  TABLE_NAME=$1

# .out
local EXIST_OUT=$(find $PT_TMPDIR/ -name "${TABLE_NAME}*.out" ! -size 0 |head -1)
if [ $EXIST_OUT ]; then
  TEMP_COLOR=lcyan; print_color "Importing out file(s): $TABLE_NAME\n"; unset TEMP_COLOR;
fi
for IMPORTFILE in $(find $PT_TMPDIR/ -name "${TABLE_NAME}*.out" ! -size 0 | sort)
do
  mariadb-import --defaults-file=$SCRIPT_DIR/OPT/$TABLE_NAME.out.cnf $SCHEMA_NAME $IMPORTFILE
done

if [ ! "$TSV2CSV" == 'TRUE' ]; then
  # .tsv
  local EXIST_TSV=$(find $PT_TMPDIR/ -name "${TABLE_NAME}*.tsv" ! -size 0 |head -1)
  if [ $EXIST_TSV ]; then
    TEMP_COLOR=lmagenta; print_color "Importing tsv file(s): $TABLE_NAME\n"; unset TEMP_COLOR;
  fi
  for IMPORTFILE in $(find $PT_TMPDIR/ -name "${TABLE_NAME}*.tsv" ! -size 0 | sort)
  do
    mariadb-import --defaults-file=$SCRIPT_DIR/OPT/$TABLE_NAME.tsv.cnf $SCHEMA_NAME $IMPORTFILE
  done
else
  # .csv
  
  find $PT_TMPDIR -type f -name "${TABLE_NAME}*.tsv" -exec sh -c 'BN=$(basename {});DN=$(dirname {});FN="$DN/$BN"; NEWFILE="$(echo $FN | sed "s/.\{4\}$//").csv"; cp {} "$NEWFILE"' \;
  
  local EXIST_CSV=$(find $PT_TMPDIR/ -name "${TABLE_NAME}*.csv" ! -size 0 | head -1)
  if [ $EXIST_CSV ]; then
    TEMP_COLOR=lmagenta; print_color "Converting from tsv to csv and importing: $TABLE_NAME\n"; unset TEMP_COLOR;
  fi
  for IMPORTFILE in $(find $PT_TMPDIR/ -name "${TABLE_NAME}*.csv" ! -size 0 | sort)
  do
  
    # sed commands to transform client-side output tsv to csv which is similar output of typlical "INTO OUTFILE":
    sed -i 's/\(.*\)/"\1"/g' $IMPORTFILE # ENCLOSE EACH LINE WITH DOUBLE-QUOTES
    sed -i "s/\t/\",\"/g"    $IMPORTFILE # REPLACE TAB WITH \",\"
    sed -i 's/\"NULL\"/\\\\N/g'  $IMPORTFILE  # REPLACE \"NULL\" with \\N
		
    mariadb-import --defaults-file=$SCRIPT_DIR/OPT/$TABLE_NAME.csv.cnf $SCHEMA_NAME $IMPORTFILE
  done
fi
}