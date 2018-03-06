SELECT
        *
FROM
(
SELECT
    t.tablename,
    indexname,
    c.reltuples AS num_rows,
    CASE WHEN indisunique THEN 'Y'
       ELSE 'N'
    END AS UNIQUE,
    idx_scan AS number_of_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM
        pg_tables t
LEFT OUTER JOIN
        (select * from pg_class class inner join pg_namespace spc on class.relnamespace=spc.oid)  c ON t.tablename=c.relname AND t.schemaname=c.nspname
LEFT OUTER JOIN
    ( SELECT c.relname AS ctablename, ipg.relname AS indexname, x.indnatts AS number_of_columns, idx_scan, idx_tup_read, idx_tup_fetch, indexrelname, indisunique FROM pg_index x
           JOIN pg_class c ON c.oid = x.indrelid
           JOIN pg_class ipg ON ipg.oid = x.indexrelid
           JOIN pg_stat_all_indexes psai ON x.indexrelid = psai.indexrelid )
    AS foo
        ON t.tablename = foo.ctablename
WHERE
        t.schemaname='public'
        AND indisunique = false
) tabela
ORDER BY
        number_of_scans ASC,
        num_rows DESC
LIMIT
        50;
