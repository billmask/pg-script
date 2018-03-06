CREATE OR REPLACE FUNCTION proc_table_partition (p_schema varchar, p_table varchar, p_column varchar, p_date1 varchar, p_date2 varchar)
RETURNS VOID AS 
$BODY$
DECLARE

_date_begin varchar := p_date1;
_date_end varchar := p_date2;
_months int;
_indexes record;
_constraintfk record;
_schema varchar := p_schema;
_date varchar;
_column varchar := p_column;
_table varchar := p_table;
_i integer := 0;
_part_begin date;
_part_end date;
_owner varchar;
_table_son varchar;
_tbs varchar;

BEGIN


IF length(p_date1) <> 6 OR length(p_date2) <> 6 THEN
  /*RETORNA ERRO*/
  raise exception 'Execution Error - size p_date';
ELSIF p_date1 >= p_date2 THEN
  /*RETORNA ERRO*/
  raise exception 'Execution Error - p_date1 >= p_date2';
END IF;

PERFORM 1
from pg_attribute a inner join pg_tables t on a.attrelid = t.tablename::regclass  
where t.schemaname = _schema
and t.tablename = _table
and a.attname = _column;
IF NOT FOUND THEN
  raise exception 'Table Name or Column Name not found';
END IF;
  

_months := extract(month from age(to_date(_date_end, 'YYYYMM'),to_date(_date_begin, 'YYYYMM'))) + (extract(year from age(to_date(_date_end, 'YYYYMM'),to_date(_date_begin, 'YYYYMM'))) * 12);
_date := _date_begin;
_owner := (select tableowner from pg_catalog.pg_tables where tablename = _table);
_tbs := (select tablespace from pg_catalog.pg_tables where schemaname = _schema and tablename = _table);

  IF _tbs is null THEN
    _tbs := ' ';
  ELSE
    _tbs := 'TABLESPACE ' || _tbs;
  END IF;

WHILE (_i <= _months) LOOP
  _part_begin := to_date(_date, 'YYYYMM');
  _part_end := to_date(_date, 'YYYYMM') + INTERVAL '1 month';
  _table_son := _table ||'_'||_date;

<< label_create_partition >>
BEGIN
PERFORM 1
from pg_tables
where schemaname = _schema
and tablename = _table_son;
EXIT label_create_partition WHEN FOUND;


  EXECUTE 'CREATE TABLE '|| _schema || '.' || _table_son || ' (CHECK ( '|| _column || ' >= ''' || _part_begin || ''' AND '|| _column || ' < ''' || _part_end || ''')) INHERITS ( '|| _schema || '.' || _table || ') ' || _tbs;

  FOR _indexes IN
  select replace(replace(indexdef,indexname,indexname||'_'||_date),' '||tablename||' ',' '||tablename||'_'||_date||' ') as createindex from pg_indexes where schemaname||'.'||tablename = _schema||'.'||_table
  LOOP
    EXECUTE _indexes.createindex;
  END LOOP;

  FOR _constraintfk IN
  SELECT 'ALTER TABLE ' || _table_son  || ' ADD CONSTRAINT '|| conname || '_' || _date || ' ' || pg_catalog.pg_get_constraintdef(oid, true) as createfk 
  FROM pg_catalog.pg_constraint WHERE conrelid = (_schema || '.' || _table)::regclass AND contype = 'f'
  LOOP
    EXECUTE _constraintfk.createfk;
  END LOOP;

  EXECUTE 'ALTER TABLE ' || _schema || '.' || _table_son || ' OWNER TO ' || _owner ||'';

  END; 

  raise debug 'BEFORE _date: %',_date;
  _date := (select to_char(to_date(_date, 'YYYYMM') + INTERVAL '1 month', 'YYYYMM'));
  raise debug 'AFTER _date: %',_date;

  _i := _i + 1;
  raise debug 'VALUE OF I:%',_i;

END LOOP;
END;
$BODY$
LANGUAGE plpgsql;