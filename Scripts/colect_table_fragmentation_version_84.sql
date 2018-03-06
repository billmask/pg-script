SELECT 'DROPPING TABLE IF EXISTS PERF_TABLE_BLOAT_JOB_ANALYZE';
DROP TABLE IF EXISTS PERF_TABLE_BLOAT_JOB_ANALYZE;
SELECT 'CREATING TABLE PERF_TABLE_BLOAT_JOB_ANALYZE';
CREATE TABLE PERF_TABLE_BLOAT_JOB_ANALYZE AS
select schemaname,relname as tblname, ( ( n_dead_tup::numeric / ( n_live_tup::numeric + n_dead_tup::numeric ) ) * 100 ) as bloat_ratio, n_dead_tup as bloat_size from pg_stat_user_tables where (n_live_tup + n_dead_tup) > 0 order by 3 desc;
