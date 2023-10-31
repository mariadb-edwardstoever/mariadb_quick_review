# Mariadb Quick Review

To download the mariadb_quick_review script direct to your linux server, you may use git or wget:
```
git clone https://github.com/mariadb-edwardstoever/mariadb_quick_review.git
```
```
wget https://github.com/mariadb-edwardstoever/mariadb_quick_review/archive/refs/heads/main.zip
```

## Overview
This script is for initial review of MariaDB server for MariaDB Support tickets. 

### What will this script do on the database?
The Mariadb Quick Review script will perform the following operations on the database:
* SELECTs on tables in the information_schema and performance_schema. 
* SHOW SLAVE STATUS, SHOW SLAVE HOSTS, SHOW ENGINE INNODB STATUS, SHOW OPEN TABLES

All of the database commands the script runs can be found in the SQL directory. Table names and column names will be collected. Active queries will be collected. _No row data from user created tables will be collected._

### Examples of running the script on the command line
```
./mariadb_quick_review.sh 
./mariadb_quick_review.sh --test
./mariadb_quick_review.sh --help
./mariadb_quick_review.sh --minutes=10 --logs
./mariadb_quick_review.sh --minutes=10 --stats_per_min=4
```

### Available Options
```
This script can be run without options. Not indicating an option value will use the default value.
  --minutes=10         # indicate the number of minutes to collect performance statistics, default 5
  --stats_per_min=2    # indicate the number of times per minute to collect performance statistics, default 1
                       # Valid values for stats_per_min: 1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60
  --multi_processlist  # Turns on collecting processlist with each statistics collection. Turned off by default.
  --logs               # Collect database error logs and system logs and include in generated file.
  --redirect_to_files  # Force a redirect of output to files instead of SELECT INTO OUTFILE.
  --test               # Test connect to database and display script version
  --version            # Test connect to database and display script version
  --help               # Display the help menu

  ### THE BELOW OPTIONS ARE INTEDED FOR SOFTWARE DEVELOPMENT ###
  --debug_sql             # Instead of running SQL commands, display the SQL commands that will be run
  --debug_outfiles        # view the outfiles as each is created
  --bypass_priv_check     # Bypass the check that the database user has sufficient privileges.
  --no_outfiles           # Output to stdout instead of to files
```

### Connecting from the database host
The most simple method for running Mariadb Quick Review is via unix_socket as root on the database host. If you want another user to connect to the database, add a user and password to the file `quick_review.cnf`.

### Connecting over the network
The mariadb_quick_review.sh will check whether the hostname for the bash shell is the same as the hostname for the database. If they are different, the script will save files on the client machine by redirect. 

You can define  a connection for any user and using any method that is supported by mariadb client. Edit the file `quick_review.cnf`. For example, a user connecting to a remote database might look like this:
```
[mariadb_quick_review]
user = mindapp
password = "NDQeJ0hA13zGtM2O$$f4haKDu"
host = mindapp.ha.db7.mariadb.com
port = 5305
ssl-ca = /etc/ssl/certs/mariadb_chain_2024.pem
```
* Do not define a connection through maxscale.
* It is best to run the script on the host of the database so that information from the operating system and database errors can be collected.

Once the configuration in `quick_review.cnf` is correct, just run the script with the desired options.

### Required Privileges
```SQL
-- GRANTS REQUIRED FOR SELECT INTO OUTFILE (SCRIPT IS RUN ON HOST OF THE DATABASE).
GRANT SELECT, PROCESS, FILE on *.* to 'adminuser'@'%';
-- IF INSTANCE IS A REPLICATION SLAVE, AN ADDITIONAL PRIVILEGE IS REQUIRED:
GRANT SLAVE MONITOR on *.* to 'adminuser'@'%';
```

```SQL
-- GRANTS REQUIRED FOR REDIRECT TO FILES
GRANT SELECT, PROCESS on *.* to 'adminuser'@'%';
-- IF INSTANCE IS A REPLICATION SLAVE, AN ADDITIONAL PRIVILEGE IS REQUIRED:
GRANT SLAVE MONITOR on *.* to 'adminuser'@'%';
```

### Sharing Results With MariaDB Support
When the script completes, it will archive all the output into one compressed file. The script will indictate the name of the file. It will be found in the directory /tmp/mariadb_quick_review . An example of the file name:
```
/tmp/mariadb_quick_review/QK-MjA3OD_logs_Oct-14.tar.gz
```

***
## What information will Mariadb Quick Review script provide to MariaDB Support team?
This script will provide the following to **MariaDB support**:
- General information about the server
- Topology information such as whether a server is a primary, a replica or a member of a Galera cluster
- A full list of global variables
- Information about user created objects
- Basic performance data that can be used as a baseline
- A list of tables and counts of primary key, unique, and non-unique indexes

This script will provide WARNINGS when they occur while collecting performance data, such as:
- A list of empty tables with large datafiles
- A list of indexes with low cardinality
- Statistics for tuning Galera cluster
- Long-running transactions that do not commit
- Blocking transactions and waiting transactions
- Deadlocks
- Transactions that cause seconds-behind-master in a replica
- Transactions that cause flow-control in Galera cluster
- High redo occupancy
- Increasing undo

