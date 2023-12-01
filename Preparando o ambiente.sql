/* 1)Descompacte o arquivo baixado em um diretório.

3) Abra o Oracle SQL Developer.

4) Faça a conexão default (conexão MAQUINA LOCAL).

5) Abra o script 01_Criar_Usuarios.sql no bloco de notas.

6) Crie dois novos usuários, usando os comandos:*/

ALTER SESSION SET "_oracle_script" = true;

CREATE USER user_dev IDENTIFIED BY user_dev
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp;

GRANT connect, resource TO user_dev;

GRANT
    CREATE PUBLIC SYNONYM
TO user_dev;

GRANT
    CREATE VIEW
TO user_dev;

GRANT
    EXECUTE ANY PROCEDURE
TO user_dev;

GRANT
    CREATE ANY DIRECTORY
TO user_dev;

CREATE USER user_app IDENTIFIED BY user_app
    DEFAULT TABLESPACE users
    TEMPORARY TABLESPACE temp;

GRANT connect, resource TO user_app;

ALTER USER user_dev
    QUOTA UNLIMITED ON users;

ALTER USER user_app
    QUOTA UNLIMITED ON users;

/* 7) Crie duas novas conexões.

8) Clique no botão com o + e crie a conexão user_dev, usando esse mesmo nome para o nome do usuário e a senha.

9) Teste a conexão e clique em Conectar.

10) Clique no botão com o + e crie a conexão user_app, usando esse mesmo nome para o nome do usuário e a senha.

11) Teste a conexão e clique em Conectar.

12) Conecte ao user_dev, copie e use os comandos do script 02_Criar_Tabelas.sql para criar as tabelas:*/

--13) Conectar-se ao usuario: user_dev e criar as tabelas

CREATE TABLE segmercado (
    id        NUMBER(5),
    descricao VARCHAR2(100)
);

ALTER TABLE segmercado ADD CONSTRAINT segmercado_id_pk PRIMARY KEY ( id );

CREATE TABLE cliente (
    id                   NUMBER(5),
    razao_social         VARCHAR2(100),
    cnpj                 VARCHAR2(20),
    segmercado_id        NUMBER(5),
    data_inclusao        DATE,
    faturamento_previsto NUMBER(10, 2),
    categoria            VARCHAR2(20)
);

ALTER TABLE cliente ADD CONSTRAINT cliente_id_pk PRIMARY KEY ( id );

ALTER TABLE cliente
    ADD CONSTRAINT cliente_segmercado_fk FOREIGN KEY ( segmercado_id )
        REFERENCES segmercado ( id );
    
    
    
-- 14) Abra o arquivo 03_Incluir_Dados_Tabelas.sql, copie e cole os comandos em uma nova janela no ambiente user_dev:

BEGIN

    -- Incluir segmentos de mercado
    INSERT INTO segmercado VALUES (
        1,
        'VAREJISTA'
    );

    INSERT INTO segmercado VALUES (
        2,
        'ATACADISTA'
    );

    INSERT INTO segmercado VALUES (
        3,
        'FARMACEUTICO'
    );

    INSERT INTO segmercado VALUES (
        4,
        'INDUSTRIAL'
    );

    INSERT INTO segmercado VALUES (
        5,
        'AGROPECUARIA'
    );    

    -- incluir clientes
    INSERT INTO cliente VALUES (
        1,
        'SUPERMERCADO XYZ',
        '12/345',
        5,
        sysdate,
        150000,
        'GRANDE'
    );

    INSERT INTO cliente VALUES (
        2,
        'SUPERMERCADO IJK',
        '67/890',
        1,
        sysdate,
        90000,
        'MEDIO GRANDE'
    );

    INSERT INTO cliente VALUES (
        3,
        'SUPERMERCADO IJK',
        '89/012',
        3,
        sysdate,
        80000,
        'MEDIO GRANDE'
    );

    INSERT INTO cliente VALUES (
        4,
        'FARMACIA AXZ',
        '12/378',
        3,
        sysdate,
        80000,
        'MEDIO GRANDE'
    );

    COMMIT;
END;


-- Confira as tabelas criadas

SELECT
    *
FROM
    segmercado;

SELECT
    *
FROM
    cliente;

/*15) Abra o arquivo 04_Criar_Ambiente_Curso.sql, copie e cole os comandos em uma nova janela no ambiente user_dev.

16) Selecione e execute todos os comandos:*/

-- No Oracle SQL Developer ir para: Menu Superior -> Ferramentas -> Preferencias
-- Banco de Dados -> Planilha 
-- Em SELECIONAR CAMINHO PADRÃO PARA PROCURA DE SCRIPTS colocar o local do script do curso. 

CREATE OR REPLACE FUNCTION obter_categoria_cliente (
    p_faturamento_previsto IN cliente.faturamento_previsto%TYPE
) RETURN cliente.categoria%TYPE IS
BEGIN
    IF p_faturamento_previsto <= 10000 THEN
        RETURN 'PEQUENO';
    ELSIF p_faturamento_previsto <= 50000 THEN
        RETURN 'MEDIO';
    ELSIF p_faturamento_previsto <= 100000 THEN
        RETURN 'MEDIO GRANDE';
    ELSE
        RETURN 'GRANDE';
    END IF;
END;
/

CREATE OR REPLACE FUNCTION obter_descricao_segmento (
    p_id IN segmercado.id%TYPE
) RETURN segmercado.descricao%TYPE IS
    v_descricao segmercado.descricao%TYPE;
BEGIN
    SELECT
        descricao
    INTO v_descricao
    FROM
        segmercado
    WHERE
        id = p_id;

    RETURN v_descricao;
EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(-20002, 'Segmento de Mercado    Inexistente');
END;
/

CREATE OR REPLACE FUNCTION verifica_segmento_mercado (
    p_id IN segmercado.id%TYPE
) RETURN BOOLEAN IS
    v_dummy NUMBER(1);
BEGIN
    SELECT
        1
    INTO v_dummy
    FROM
        segmercado
    WHERE
        id = p_id;

    RETURN TRUE;
EXCEPTION
    WHEN no_data_found THEN
        RETURN FALSE;
END;
/

CREATE OR REPLACE PROCEDURE format_cnpj (
    p_cnpj IN OUT VARCHAR2
) IS
BEGIN
    p_cnpj := substr(p_cnpj, 1, 2)
              || '/'
              || substr(p_cnpj, 3);
END;
/

CREATE OR REPLACE PROCEDURE atualizar_cli_seg_mercado (
    p_id            cliente.id%TYPE,
    p_segmercado_id cliente.segmercado_id%TYPE
) IS
    e_fk EXCEPTION;
    PRAGMA exception_init ( e_fk, -2291 );
    e_no_update EXCEPTION;
BEGIN
    UPDATE cliente
    SET
        segmercado_id = p_segmercado_id
    WHERE
        id = p_id;

    IF SQL%notfound THEN
        RAISE e_no_update;
    END IF;
    COMMIT;
EXCEPTION
    WHEN e_fk THEN
        raise_application_error(-20001, 'Segmento de Mercado Inexistente');
    WHEN e_no_update THEN
        raise_application_error(-20002, 'Cliente Inexistente');
END;
/

CREATE OR REPLACE PROCEDURE atualizar_faturamento_previsto (
    p_id                   IN cliente.id%TYPE,
    p_faturamento_previsto IN cliente.faturamento_previsto%TYPE
) IS
    v_categoria cliente.categoria%TYPE;
    e_error_id EXCEPTION;
BEGIN
    v_categoria := obter_categoria_cliente(p_faturamento_previsto);
    UPDATE cliente
    SET
        categoria = v_categoria,
        faturamento_previsto = p_faturamento_previsto
    WHERE
        id = p_id;

    IF SQL%notfound THEN
        RAISE e_error_id;
    END IF;
    COMMIT;
EXCEPTION
    WHEN e_error_id THEN
        raise_application_error(-20010, 'Cliente inexistente');
END;
/

CREATE OR REPLACE PROCEDURE excluir_cliente (
    p_id IN cliente.id%TYPE
) IS
    e_error_id EXCEPTION;
BEGIN
    DELETE FROM cliente
    WHERE
        id = p_id;

    IF SQL%notfound THEN
        RAISE e_error_id;
    END IF;
    COMMIT;
EXCEPTION
    WHEN e_error_id THEN
        raise_application_error(-20010, 'Cliente inexistente');
END;
/

CREATE OR REPLACE PROCEDURE incluir_cliente (
    p_id                   IN cliente.id%TYPE,
    p_razao_social         IN cliente.razao_social%TYPE,
    p_cnpj                 cliente.cnpj%TYPE,
    p_segmercado_id        cliente.segmercado_id%TYPE,
    p_faturamento_previsto cliente.faturamento_previsto%TYPE
) IS

    v_categoria         cliente.categoria%TYPE;
    v_cnpj              cliente.cnpj%TYPE := p_cnpj;
    v_codigo_erro       NUMBER(5);
    v_mensagem_erro     VARCHAR2(200);
    v_dummy             NUMBER;
    v_verifica_segmento BOOLEAN;
    e_segmento EXCEPTION;
BEGIN
    v_verifica_segmento := verifica_segmento_mercado(p_segmercado_id);
    IF v_verifica_segmento = false THEN
        RAISE e_segmento;
    END IF;
    v_categoria := obter_categoria_cliente(p_faturamento_previsto);
    format_cnpj(v_cnpj);
    INSERT INTO cliente VALUES (
        p_id,
        upper(p_razao_social),
        v_cnpj,
        p_segmercado_id,
        sysdate,
        p_faturamento_previsto,
        v_categoria
    );

    COMMIT;
EXCEPTION
    WHEN dup_val_on_index THEN
        raise_application_error(-20010, 'Cliente já cadastrado');
    WHEN e_segmento THEN
        raise_application_error(-20011, 'Segmento de mercado inexistente');
    WHEN OTHERS THEN
        v_codigo_erro := sqlcode;
        v_mensagem_erro := sqlerrm;
        raise_application_error(-20000, to_char(v_codigo_erro)
                                        || v_mensagem_erro);
END;
/

CREATE OR REPLACE PROCEDURE incluir_segmercado (
    p_id        IN segmercado.id%TYPE,
    p_descricao IN segmercado.descricao%TYPE
) IS
BEGIN
    INSERT INTO segmercado VALUES (
        p_id,
        upper(p_descricao)
    );

    COMMIT;
EXCEPTION
    WHEN dup_val_on_index THEN
        raise_application_error(-20001, 'Segmento de Mercado já Cadastrado');
END;
/

CREATE OR REPLACE FUNCTION verifica_segmento_mercado (
    p_id IN segmercado.id%TYPE
) RETURN BOOLEAN IS
    v_dummy NUMBER(1);
BEGIN
    SELECT
        1
    INTO v_dummy
    FROM
        segmercado
    WHERE
        id = p_id;

    RETURN TRUE;
EXCEPTION
    WHEN no_data_found THEN
        RETURN FALSE;
END;


/* 17) Verifique se ocorreu tudo como o esperado, seguindo os passos do vídeo.
18) Para permitir que o user_app execute as procedures, crie um novo script usando o use_dev e use os comandos:*/

GRANT EXECUTE ON atualizar_cli_seg_mercado TO user_app;

GRANT EXECUTE ON atualizar_faturamento_previsto TO user_app;

GRANT EXECUTE ON excluir_cliente TO user_app;

GRANT EXECUTE ON incluir_cliente TO user_app;

-- 19) Como user_dev, inclua um registro:

INSERT INTO cliente (
    id,
    razao_social,
    cnpj,
    segmercado_id,
    data_inclusao,
    faturamento_previsto,
    categoria
) VALUES (
    5,
    'PADARIA XYZW',
    '22/222',
    1,
    TO_DATE('15/01/2022', 'DD/MM/YYYY'),
    80000,
    'MEDIO GRANDE'
);

/*20) Verifique a inclusão do registro.
21) Para desfazer a inclusão, execute o comando:*/

ROLLBACK;

/* 22) Conectado como user_app, execute a inclusão do registro.
23) Tente a inclusão do cliente, usando os dois comandos:*/

INSERT INTO cliente (
    id,
    razao_social,
    cnpj,
    segmercado_id,
    data_inclusao,
    faturamento_previsto,
    categoria
) VALUES (
    5,
    'PADARIA XYZW',
    '22/222',
    1,
    TO_DATE('15/01/2022', 'DD/MM/YYYY'),
    80000,
    'MEDIO GRANDE'
);

INSERT INTO user_dev.cliente (
    id,
    razao_social,
    cnpj,
    segmercado_id,
    data_inclusao,
    faturamento_previsto,
    categoria
) VALUES (
    5,
    'PADARIA XYZW',
    '22/222',
    1,
    TO_DATE('15/01/2022', 'DD/MM/YYYY'),
    80000,
    'MEDIO GRANDE'
);

/* 24) Verifique que não tem acesso à tabela.
25) Conectado como user_app, use a procedure INCLUIR_CLIENTE para incluir o cliente e verifique sua inclusão:*/

EXECUTE USER_DEV.incluir_cliente(5, 'PADARIA XYZW', '22222', 1, 80000);

SELECT
    *
FROM
    user_dev.cliente;

-- 26) Dê acesso de seleção à tabela para o user_app :

GRANT SELECT ON cliente TO user_app;