#!/bin/bash
# import_quick_review.sh
# By Edward Stoever for MariaDB Support

### This file is used by a Support team member to import generated files into database tables
### FOR FULL INSTRUCTIONS: README.md
### FOR BRIEF INSTRUCTIONS: ./import_quick_review.sh --help

SCRIPT_VERSION='1.0.2'
# Establish working directory and source pre_import.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/pre_import.sh


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
  if [ "$params" == '--tsv2csv' ]; then TSV2CSV='TRUE'; VALID=TRUE; fi
  if [ "$params" == '--version' ]; then DISPLAY_VERSION=TRUE; VALID=TRUE; fi
  if [ "$params" == '--help' ]; then HELP=TRUE; VALID=TRUE; fi
  if [ ! $VALID ] && [ ! $INVALID_INPUT ];  then  INVALID_INPUT="$params"; fi
done
if [ $INVALID_INPUT ]; then display_help_message; die "Invalid parameter: $INVALID_INPUT"; fi
if [ $DISPLAY_VERSION ]; then exit 0; fi
if [ $HELP ]; then display_help_message; exit 0; fi


# mkdir -p $SCRIPT_DIR/INPUT
# rm -f $SCRIPT_DIR/INPUT/*.out $SCRIPT_DIR/INPUT/*.tsv $SCRIPT_DIR/INPUT/*.csv || die "Failed to remove old input files in $SCRIPT_DIR/INPUT/"

ensure_media_file;
set_runid;
mk_tmpdir;
uncompress_media_file;
create_schema;
import_from_file CURRENT_RUN
import_from_file GLOBAL_STATUS
import_from_file GLOBAL_VARIABLES
import_from_file GTID_POSITIONS
import_from_file LOW_CARDINALITY_IDX
import_from_file PERFORMANCE_WARNINGS
import_from_file PROCESSLIST
import_from_file REVIEW_WARNINGS
import_from_file SERVER_PERFORMANCE
import_from_file SERVER_STATE
import_from_file SLAVE_STATUS
import_from_file TABLE_KEY_COUNTS
import_from_file PLUGINS
import_from_file ENGINE_INNODB_STATUS

post_import

exit 0

