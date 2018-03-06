######################################
### Queries to check Database Size ###
######################################


SELECT pg_database_size(current_database());

SELECT pg_database_size('<DB_NAME>');

select pg_size_pretty(pg_database_size(current_database()));

select datname, pg_size_pretty(pg_database_size(datname)) from pg_database order by pg_database_size(datname) desc;