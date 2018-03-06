# Daily Checklst

Script for daily check of PostgreSQL environment, where client is now able to install Zabbix or any monitoring tool.


File:

prod_checklist.sh
client_name.prod.properties


How to run:


/home/postgres/checklist/prod_checklist.sh client_name prod


Or


#### Daily Checklist
00  07 	*   *  	*   /home/postgres/checklist/prod_checklist.sh client_name prod >/dev/null 2>&1

