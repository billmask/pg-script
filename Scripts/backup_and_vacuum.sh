#!/bin/bash
PATH="/usr/local/pgsql/bin:$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# Log Dir
LOG_DIR=/backup/logs

# Create backup dir
BKP_DIR=/backup/dump/
BKP_DATE=$(date +%Y%m%d)
BKP_DIR_DAILY="$BKP_DIR/postgres_$BKP_DATE"
mkdir -p $BKP_DIR_DAILY

# E-mail list
EMAIL_LIST=dba@site.com
EMAIL_BODY="$LOG_DIR/email.txt"

# Erase old backups
find $BKP_DIR -maxdepth 1 -iname "postgres_*" -exec rm -rf {} \;

# List of Database for Backup
#DATABASES=$(psql -U postgres -Atc "select t1.datname from pg_database t1 where t1.datname not in ('postgres', 'template1', 'template0') order by pg_database_size(t1.datname) desc")
DATABASES=$(psql -U postgres -l -t -A | awk -F"|" '{print $1}' | egrep -v '(postgres|template)')

#Faz o backup dos bancos de dados
for DTB in $DATABASES ; do
    psql -U postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$DTB'" > $LOG_DIR/backup_kill_session.log
    pg_dump -f $BKP_DIR_DAILY"/"$DTB -Fd -j6 -v -b -U postgres $DTB > $LOG_DIR/backup_postgres.log
done

# Backup Config Files
CONFIG_DIR1=/pgdata/config
cp $CONFIG_DIR1/*.conf $BKP_DIR_DAILY

# Backup of Globals
pg_dumpall -U postgres -g -f $BKP_DIR_DAILY/db_globals.sql

# Backup Files Status:
echo "Backup file list:" > $EMAIL_BODY
ls -lh $BKP_DIR_DAILY >> $EMAIL_BODY
echo " " >> $EMAIL_BODY
echo "Size of backup files:" >> $EMAIL_BODY
du -sh $BKP_DIR_DAILY/* >> $EMAIL_BODY

# Send e-mail
cat $EMAIL_BODY | mail -s "Backup List of Server <Server_name>" $EMAIL_LIST

exit 0
