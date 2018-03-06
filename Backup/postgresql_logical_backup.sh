#!/bin/bash

# Environment Variables
PATH="/usr/local/pgsql/bin:$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Log
LOG_DIR="/backup/log"
LOG_FILE="PostgreSQL_Backup_Dump_`date +%a`.log"
LOG_BKP=$LOG_DIR/$LOG_FILE

# Erase log file
echo "" > $LOG_BKP

# E-mail list
EMAIL_LIST=dba@site.com
EMAIL_BODY="$LOG_DIR/PostgreSQL_Backup_Email.txt"

# Backup dir
BKP_DIR="/backup/dump"
BKP_DATE=$(date +%Y%m%d)
BKP_DIR_DAILY="$BKP_DIR/postgres_$BKP_DATE"
mkdir -p $BKP_DIR_DAILY

# Erase old backups
find $BKP_DIR -maxdepth 1 -iname "postgres_*" -exec rm -rf {} \;

# List of Database for backup
#DATABASES=$(psql -U postgres -Atc "select t1.datname from pg_database t1 where t1.datname not in ('postgres', 'template1', 'template0') order by pg_database_size(t1.datname) desc")
DATABASES=$(psql -U postgres -l -t -A | awk -F"|" '{print $1}' | egrep -v '(postgres|template)')

# Backup Databases
for DTB in $DATABASES ; do
	echo -e "Start Time: " `date` >> $LOG_BKP
	echo -e "Backup Database: " $DTB  >> $LOG_BKP
	psql -U postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$DTB'"
	LOG_DB="$LOG_DIR/Database_Backup_$DTB.log"
	pg_dump -N backup -N temporario -N hist -f "$BKP_DIR/$DTB" -Fd -j6 -b -v -C -U postgres $DTB 2> $LOG_DB
	echo -e "End Time: " `date` >> $LOG_BKP
done

# Backup of Globals
pg_dumpall -U postgres -g -f "$BKP_DIR_DAILY/db_globals.sql"

# Backup Config Files
CONFIG_DIR=/pgdata/config
cp $CONFIG_DIR/*.conf $BKP_DIR_DAILY

# Backup Files Status:
echo "Backup file list:" > $EMAIL_BODY
ls -ltrh $BKP_DIR_DAILY >> $EMAIL_BODY
echo " " >> $EMAIL_BODY
echo "Size of backup files:" >> $EMAIL_BODY
du -sh $BKP_DIR_DAILY/* >> $EMAIL_BODY

# Send e-mail
cat $EMAIL_BODY | mail -s "Backup List of Server <Server_name>" $EMAIL_LIST

exit 0