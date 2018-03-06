#!/bin/bash

set -o pipefail

#Parallel jobs
JOBS=8

#Temp filename
FILENAME=/tmp/vacuum_tables.txt

#Process timeout = 18000 sec ( 5 hours )
PROCESS_TIMEOUT_SEC=18000

#Bloat ratio = 10%
BLOAT_RATIO=10

#Bloat Size = 100 MB
#NOT IN USE
#BLOAT_SIZE=100000000

START_TIME_EPOCH=$( date +%s )
END_TIMEOUT_EPOCH=$(( ${START_TIME_EPOCH} + ${PROCESS_TIMEOUT_SEC} ))

log() {
        echo "`date +'%F %T %Z'` LOG: $@"
}

get_timeout() {
        now_epoch=$( date +%s )
        echo $(( ( ${END_TIMEOUT_EPOCH} - ${now_epoch} ) * 1000 ))
}

vacuum_relation() {
        local rel="$1"
        log "VACUUMING (ANALYZE) $rel"
        statement_timeout=$( get_timeout )
        if [ ${statement_timeout} -lt 10000 ]; then
                log "Timeout reached."
                exit 0
        fi
	{
                echo "RESET ALL;"
                echo "SET statement_timeout TO ${statement_timeout};"
                echo "\\timing on"
                echo "VACUUM ANALYZE ${rel};"  
        } | psql --set=ON_ERROR_STOP=ON "${db}" -AXqt >&2
        ret=$?
        if [ $ret -ne 0 ]; then
                statement_timeout=$( get_timeout )
                if [ ${statement_timeout} -le 0 ]; then
                        log "Timeout reached. Last relation (${rel}) canceled"
                        exit 0
                else
                        log "Error $ret for relation $rel"
                        return 1
                fi
        fi
        return $ret
}

for db in $( psql -AXtqc "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres','template0','template1') ORDER BY 1;"); do
	#Creates vacuum matrix for this DB
        log "Processing database ${db}"
        log "Analyzing table bloat for database ${db}"
	psql -AXtqf /storage/config/bin/vacuum_analyze_selective.sql "${db}"
	log "Selecting tables with bloat percentage greater than ${BLOAT_RATIO}%"

	#Deletes temp file if it exists
	if [ -f $FILENAME ]; then
		rm -f $FILENAME
	fi

	#Creates temp file for looping execution
	touch  $FILENAME

	#Gets tables for this DB
        for rel in $( psql "${db}" -AXtqc "SELECT schemaname || '.' || tblname as relname FROM PERF_TABLE_BLOAT_JOB_ANALYZE WHERE bloat_ratio > ${BLOAT_RATIO} ORDER BY bloat_ratio desc;" ); do
		echo ${rel} >> $FILENAME
        done
	
	#Vacuums selected tables for this DB
	log "Executing VACUUM ANALYZE in parallel mode"
	cat $FILENAME | xargs -P ${JOBS} -n1 -I {} bash -c 'echo "`date`: {} - started"; vacuum_relation "$rel" && echo "`date`: {} - succeeded" || echo "`date`: {} - failed"'
	log "Done database ${db}"
done

log "Done with no timeout"
