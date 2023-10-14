-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- PROCESSLIST
-- RUN ONE TIME WITH OPTION TO RUN MULTIPLE TIMES

select '$RUNID' as RUN_ID, now() as TICK, `ID` as CONNECTION_ID,`USER`,`HOST`,`DB`,`COMMAND`,`TIME`,`STATE`,`INFO`,`TIME_MS`,`STAGE`,`MAX_STAGE`,`PROGRESS`,`MEMORY_USED`,`MAX_MEMORY_USED`,`EXAMINED_ROWS`,`QUERY_ID`,`TID` 
from information_schema.PROCESSLIST
where ID != connection_id()
AND COMMAND != 'Sleep'
AND STATE != 'User sleep'
AND STATE != 'Waiting on empty queue'
AND STATE != 'Waiting for next activation'

