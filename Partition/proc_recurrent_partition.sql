CREATE OR REPLACE FUNCTION proc_recurrent_partition (p_schema varchar, p_table varchar, p_column varchar)
RETURNS VOID AS 
$BODY$
DECLARE

_date_begin varchar;
_date_end varchar;
_schema varchar := p_schema;
_column varchar := p_column;
_table varchar := p_table;

BEGIN

PERFORM 1
from pg_attribute a inner join pg_tables t on a.attrelid = t.tablename::regclass  
where t.schemaname = _schema
and t.tablename = _table
and a.attname = _column;
IF NOT FOUND THEN
  raise exception 'Table Name, Column os Schema not found';
END IF;
  
_date_begin := (select to_char(current_date, 'YYYYMM'));
_date_end := (select to_char(to_date(_date_begin, 'YYYYMM') + INTERVAL '3 month', 'YYYYMM'));

PERFORM proc_table_partition (_schema, _table, _column, _date_begin, _date_end);

END;
$BODY$
LANGUAGE plpgsql;