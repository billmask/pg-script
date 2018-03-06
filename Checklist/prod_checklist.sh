#!/bin/bash

CLI=${1}
ENV=${2}

file=$(dirname $0)/"${CLI}.${ENV}.properties"

if [ ! -f "$file" ]; then
    echo "File -- $file -- not found."
    exit 0
fi

function check {
    value=`grep "^${1}=" $file|cut -d'=' -f2`

    if [ -z "$value" ]; then
        echo 0
    fi

    echo $value
}


### Log File ###

function log_checklist {
    param=$(check "${CLI}.${ENV}.log_file")
    echo $param
}

log_file=$(dirname $0)/log/`log_checklist`

echo "" > $log_file

### How long Database is up ###

function db_uptime { 
    param=$(check "${CLI}.${ENV}.query_uptime")
    if [ ${#param} -eq 1 ]; then
        query="Parameter (query_uptime) not found on Config File"
    else
        query=$(psql -U postgres -t -c "$param")
    fi
    echo $query
}

echo -e "\n#### Database Uptime: #### \n\n`db_uptime`" >> $log_file


### Check How many sessions in Database ###

function check_db_sessions {
    param=$(check "${CLI}.${ENV}.db_sessions")
    if [ ${#param} -eq 1 ]; then
        echo "Parameter (db_sessions) not found on Config File"
    else
        query=$(psql -U postgres -t -c "$param")
        echo "$query"
    fi
}

echo -e "\n#### Database Sessions: #### \n\n`check_db_sessions` \n" >> $log_file


### Check Server Free Space ###

function server_space { 
    i=$(df -h)
    echo "$i"
}

echo -e "\n#### Server Device Size: #### \n\n`server_space`" >> $log_file



### Check log errors ###

function pg_log_error { 
    log_dir=$(psql -AXqtc "show log_directory;")
    log_name=$(psql -AXqtc "show log_filename;" | awk -F '%' '{print $1}')
    log_file=$(ls -ltr $log_dir | grep -i "$log_name" | tail -1 | awk '{print $9}')
    log=`egrep -i $(check "${CLI}.${ENV}.search_log") $log_dir/$log_file | egrep -v $(check "${CLI}.${ENV}.ignore_log")`
    count_error=`echo "$log" | wc -l`
    if [ $count_error -gt 30 ]; then
        echo "LOG FILE HIGHER THAN 30 LINES, ***CHECK***\n Total of lines contain errors:"
    elif [ -z "$log" ]; then
        echo "Sem Errors no Log"
    else
        echo "$log"
    fi
}

echo -e "\n#### Errors Found: #### \n\n`pg_log_error`" >> $log_file



### Send E-mail of Checklist ###

function send_mail {
    title=$(check "${CLI}.${ENV}.mail_title")
    list=$(check "${CLI}.${ENV}.mail_list")
    mail -s "$title" $list < $log_file
}

send_mail

exit
