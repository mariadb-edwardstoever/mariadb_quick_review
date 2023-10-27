#!/usr/bin/env bash
# import_quick_review.sh
# By Edward Stoever for MariaDB Support

### This file is used by a Support team member to import generated files into database tables
### FOR FULL INSTRUCTIONS: README.md
### FOR BRIEF INSTRUCTIONS: ./import_quick_review.sh --help

# Establish working directory and source pre_import.sh
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source ${SCRIPT_DIR}/current_import_vsn.sh
source ${SCRIPT_DIR}/pre_import.sh
test_dependencies
ensure_media_file;
set_runid;
mk_tmpdir;
uncompress_media_file;
if [ -f ${QK_TMPDIR}/vsn.sh ]; then source ${QK_TMPDIR}/vsn.sh; fi

display_title;
can_connect;
is_db_localhost;
whoami_db;
check_required_privs;
if [ "$DISPLAY_VERSION" ]; then exit 0; fi

interactive_schema_exists;
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
import_from_file OPEN_TABLES
import_from_file SLAVE_HOSTS
import_from_file MYSQL_TOP
import_from_file DF
import_from_file MACHINE_ARCHITECTURE
import_from_file CPU_INFO
import_from_file MEMORY_INFO
import_from_file DISKS
import_from_file USER_STATISTICS
import_from_file CLIENT_STATISTICS
import_from_file INDEX_STATISTICS
import_from_file TABLE_STATISTICS
import_from_file RECENT_ERRORS
import_from_file FILE_SUMMARY_BY_INSTANCE
import_from_file TABLE_IO_WAITS_SUMMARY_BY_INDEX_USAGE
import_from_file TABLE_IO_WAITS_SUMMARY_BY_TABLE
import_from_file ACCOUNTS
import_from_file EVENTS_STATEMENTS_SUMMARY_BY_USER_BY_EVENT_NAME
import_from_file EVENTS_WAITS_SUMMARY_BY_USER_BY_EVENT_NAME
import_from_file EVENTS_WAITS_SUMMARY_GLOBAL_BY_EVENT_NAME

post_import;
log_files_provided;

echo 

exit 0

