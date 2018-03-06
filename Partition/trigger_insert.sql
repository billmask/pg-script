CREATE OR REPLACE FUNCTION PROC_TRIGGER_INSERT_TABLE_<TABELA>()
RETURNS TRIGGER AS $BODY$
DECLARE

/* EDITAR O NOME DA COLUNA*/
_column timestamp := NEW.<COLUNA>;

/* Não editar daqui pra baixo */
_table varchar := TG_TABLE_NAME;
_date varchar;
_date_part varchar;
_table_part varchar;

BEGIN

_date := _column;
_date_part := (select (to_char(to_date(_date, 'YYYY-MM-DD'), 'YYYYMM')));
_table_part := _table || '_' || _date_part;

EXECUTE 'INSERT INTO ' || _table_part ||  ' VALUES ( $1.* )' USING NEW;

RETURN NULL;

EXCEPTION WHEN undefined_table THEN
RAISE EXCEPTION 'Date out of range. Check Insert!';

END;
$BODY$ LANGUAGE PLPGSQL;


CREATE TRIGGER TRIGGER_INSERT_TABLE_<TABELA>
BEFORE INSERT ON <TABELA>
FOR EACH ROW EXECUTE PROCEDURE PROC_TRIGGER_INSERT_TABLE_<TABELA>();