/*1) No Oracle SQL Developer, abra uma nova janela de script vazio.

2) Use a conexão user_dev para criar os sinônimos das procedures e a tabela CLIENTE:*/

CREATE PUBLIC SYNONYM incluir_cliente FOR user_dev.incluir_cliente;

CREATE PUBLIC SYNONYM atualizar_cli_seg_mercado FOR user_dev.atualizar_cli_seg_mercado;

CREATE PUBLIC SYNONYM atualizar_faturamento_previsto FOR user_dev.atualizar_faturamento_previsto;

CREATE PUBLIC SYNONYM excluir_cliente FOR user_dev.excluir_cliente;

CREATE PUBLIC SYNONYM cliente FOR user_dev.cliente;

-- 3) Mostre a tabela CLIENTE, usando o sinônimo:

SELECT
    *
FROM
    cliente;

/* 4) Crie uma nova janela de script usando o usuário user_app.

5) Crie a procedure APP_INCLUIR_CLIENTE:*/

CREATE OR REPLACE PROCEDURE app_incluir_cliente (
    p_id          IN cliente.id%TYPE,
    p_razao       IN cliente.razao_social%TYPE,
    p_cnpj        IN cliente.cnpj%TYPE,
    p_segmercado  IN cliente.segmercado_id%TYPE,
    p_faturamento IN cliente.faturamento_previsto%TYPE
) IS
BEGIN
    incluir_cliente(p_id, p_razao, p_cnpj, p_segmercado, p_faturamento);
END;

/* 6) Compile a procedure e verifique sua criação.

7) Execute a procedure APP_INCLUIR_CLIENTE:*/

EXECUTE APP_INCLUIR_CLIENTE (6, 'SEGUNDO CLIENTE INCLUIDO POR USER_APP', '23456', 2, 100000);

-- 8) Mostre o resultado, usando o sinônimo da tabela:

SELECT
    *
FROM
    cliente;

/* 9) Caso você ainda não tenha feito, faça o download do script utldtree.sql e copie o seu conteúdo.

10) Abra uma nova janela de script com o usuário user_dev e cole o conteúdo do script baixado:*/

Rem 
Rem $Header: rdbms/admin/utldtree.sql /main/5 2020/07/20 02:45:39 dgoddard Exp $ 
Rem 
Rem  Copyright (c) 1991 by Oracle Corporation 
Rem    NAME
Rem      deptree.sql - Show objects recursively dependent on given object
Rem    DESCRIPTION
Rem      This procedure, view and temp table will allow you to see all
Rem      objects that are (recursively) dependent on the given object.
Rem      Note: you will only see objects for which you have permission.
Rem      Examples:
Rem        execute deptree_fill('procedure', 'scott', 'billing');
Rem        select * from deptree order by seq#;
Rem
Rem        execute deptree_fill('table', 'scott', 'emp');
Rem        select * from deptree order by seq#;
Rem
Rem        execute deptree_fill('package body', 'scott', 'accts_payable');
Rem        select * from deptree order by seq#;
Rem
Rem        A prettier way to display this information than
Rem        select * from deptree order by seq#;
Rem       is
Rem             select * from ideptree;
Rem        This shows the dependency relationship via indenting.  Notice
Rem        that no order by clause is needed with ideptree.
Rem    RETURNS
Rem 
Rem    NOTES
Rem      Run this script once for each schema that needs this utility.
Rem      
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: rdbms/admin/utldtree.sql
Rem    SQL_SHIPPED_FILE: rdbms/admin/utldtree.sql
Rem    SQL_PHASE: UTILITY
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem    
Rem    MODIFIED   (MM/DD/YY)
Rem     rkooi      10/26/92 -  owner -> schema for SQL2 
Rem     glumpkin   10/20/92 -  Renamed from DEPTREE.SQL 
Rem     rkooi      09/02/92 -  change ORU errors 
Rem     rkooi      06/10/92 -  add rae errors 
Rem     rkooi      01/13/92 -  update for sys vs. regular user 
Rem     rkooi      01/10/92 -  fix ideptree 
Rem     rkooi      01/10/92 -  Better formatting, add ideptree view 
Rem     rkooi      12/02/91 -  deal with cursors 
Rem     rkooi      10/19/91 -  Creation 

DROP SEQUENCE deptree_seq
/

CREATE SEQUENCE deptree_seq CACHE 200 /* cache 200 to make sequence faster */
/

DROP TABLE deptree_temptab
/

CREATE TABLE deptree_temptab (
    object_id            NUMBER,
    referenced_object_id NUMBER,
    nest_level           NUMBER,
    seq#                 NUMBER
)
/

CREATE OR REPLACE PROCEDURE deptree_fill (
    type   CHAR,
    schema CHAR,
    name   CHAR
) IS
    obj_id NUMBER;
BEGIN
    DELETE FROM deptree_temptab;

    COMMIT;
    SELECT
        object_id
    INTO obj_id
    FROM
        all_objects
    WHERE
            owner = upper(deptree_fill.schema)
        AND object_name = upper(deptree_fill.name)
        AND object_type = upper(deptree_fill.type);

    INSERT INTO deptree_temptab VALUES (
        obj_id,
        0,
        0,
        0
    );

    INSERT INTO deptree_temptab
        SELECT
            object_id,
            referenced_object_id,
            level,
            deptree_seq.NEXTVAL
        FROM
            public_dependency
        CONNECT BY
            PRIOR object_id = referenced_object_id
        START WITH referenced_object_id = deptree_fill.obj_id;

EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20000, 'ORU-10013: '
                                        || type
                                        || ' '
                                        || schema
                                        || '.'
                                        || name
                                        || ' was not found.');
END;
/

DROP VIEW deptree
/

set echo on

REM This view will succeed if current user is sys.  This view shows 
REM which shared cursors depend on the given object.  If the current
REM user is not sys, then this view get an error either about lack
REM of privileges or about the non-existence of table x$kglxs.

set echo off

CREATE VIEW sys.deptree ( nested_level,
type,
schema,
name,
seq# ) AS
    SELECT
        d.nest_level,
        o.object_type,
        o.owner,
        o.object_name,
        d.seq#
    FROM
        deptree_temptab d,
        dba_objects     o
    WHERE
        d.object_id = o.object_id (+)
    UNION ALL
    SELECT
        d.nest_level + 1,
        'CURSOR',
        '<shared>',
        '"'
        || c.kglnaobj
        || '"',
        d.seq# +.5
    FROM
        deptree_temptab d,
        x$kgldp         k,
        x$kglob         g,
        obj$            o,
        user$           u,
        x$kglob         c,
        x$kglxs         a
    WHERE
            d.object_id = o.obj#
        AND o.name = g.kglnaobj
        AND o.owner# = u.user#
        AND u.name = g.kglnaown
        AND g.kglhdadr = k.kglrfhdl
        AND k.kglhdadr = a.kglhdadr   /* make sure it is not a transitive */
        AND k.kgldepno = a.kglxsdep   /* reference, but a direct one */
        AND k.kglhdadr = c.kglhdadr
        AND c.kglhdnsp = 0 /* a cursor */
/

set echo on

REM This view will succeed if current user is not sys.  This view
REM does *not* show which shared cursors depend on the given object.
REM If the current user is sys then this view will get an error 
REM indicating that the view already exists (since prior view create
REM will have succeeded).

set echo off

CREATE VIEW deptree ( nested_level,
type,
schema,
name,
seq# ) AS
    SELECT
        d.nest_level,
        o.object_type,
        o.owner,
        o.object_name,
        d.seq#
    FROM
        deptree_temptab d,
        all_objects     o
    WHERE
        d.object_id = o.object_id (+)
/

DROP VIEW ideptree
/

CREATE VIEW ideptree ( dependencies ) AS
    SELECT
        lpad(' ',
             3 *(MAX(nested_level)))
        || MAX(nvl(type, '<no permission>')
               || ' '
               || schema
               || decode(type, NULL, '', '.')
               || name)
    FROM
        deptree
    GROUP BY
        seq# /* So user can omit sort-by when selecting from ideptree */
/

/* 11) Execute o script. Podem acontecer erros.

12) Verifique se os componentes foram criados.

13) Foram criados tabelas, views e procedures.

14) Crie mais um script associado ao user_dev.

15) Rode o comando:*/

SELECT
    *
FROM
    deptree_temptab;

-- 16) Execute o comando:

EXECUTE DEPTREE_FILL('table','user_dev','CLIENTE');

-- 17) Rode a consulta:

SELECT
    nested_level,
    schema,
    type,
    name,
    seq#
FROM
    deptree
ORDER BY
    seq#;

-- 18) Rode o comando:

EXECUTE DEPTREE_FILL('procedure','user_dev','INCLUIR_CLIENTE');

-- 19) Para conferir o resultado das interdependências,use o comando:

SELECT
    nested_level,
    schema,
    type,
    name,
    seq#
FROM
    deptree
ORDER BY
    seq#;

/* 20) Acompanhe as explicações.

21) Para rodar as dependências baseadas em uma procedure, execute o comando:*/

EXECUTE DEPTREE_FILL('procedure','user_dev','INCLUIR_CLIENTE');