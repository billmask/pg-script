# Physical Size of Table

select pg_size_pretty(pg_relation_size('<table_name>')) as "Physical Size";


# 20 biggest Table (+ Indexes + TOAST)

SELECT                                  
   schemaname,
   relname,
   pg_total_relation_size(relid) As "Size Bytes",
   pg_size_pretty(pg_total_relation_size(relid)) As "Full Size"
FROM
   pg_catalog.pg_statio_user_tables
GROUP BY
  1,2,relid
ORDER BY
        3 DESC
LIMIT 20;


# Size of Tables

SELECT 
	schemaname as "Schema",
	relname as "Table",
	pg_size_pretty(pg_total_relation_size(relid)) As "Full Size",
	pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as "Physical Size"
FROM 
	pg_catalog.pg_statio_user_tables 
-- WHERE relname = '<table_name>' 
ORDER BY 
	pg_total_relation_size(relid) DESC;



# File Path for specific Table

SELECT pg_relation_filepath(oid), relpages FROM pg_class WHERE relname = '<table_name>';

SELECT pg_relation_filepath('<schema>.<table>');



# Size of Table, Index, Toast and Total


SELECT 
*, 
pg_size_pretty(total_bytes) AS Total, 
pg_size_pretty(index_bytes) AS Index, 
pg_size_pretty(toast_bytes) AS Toast, 
pg_size_pretty(table_bytes) AS Table
FROM 
(SELECT *, 
  total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes 
  FROM (
    SELECT 
    c.oid,nspname AS table_schema, 
    relname AS TABLE_NAME, 
    c.reltuples AS row_estimate, 
    pg_total_relation_size(c.oid) AS total_bytes, 
    pg_indexes_size(c.oid) AS index_bytes, 
    pg_total_relation_size(reltoastrelid) AS toast_bytes 
    FROM pg_class c 
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE 
    relkind = 'r' 
    and relname = '<table_name>') 
  a ) 
a;