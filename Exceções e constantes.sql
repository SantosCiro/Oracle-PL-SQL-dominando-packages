/* 1) Crie uma conexão usando o user_dev.

2) Na janela de script, escreva:*/

CREATE OR REPLACE PACKAGE exception_pac IS
    e_null EXCEPTION;
    PRAGMA exception_init ( e_null, -1400 );
    e_fk EXCEPTION;
    PRAGMA exception_init ( e_fk, -2291 );
END;

/* 3) Compile o pacote.

4) Execute as inserções, forçando os erros:*/

INSERT INTO cliente VALUES (
    NULL,
    'TESTE',
    '22222',
    2,
    sysdate,
    10000,
    'AAA'
);

INSERT INTO cliente VALUES (
    30,
    'TESTE',
    '22222',
    10,
    sysdate,
    10000,
    'AAA'
);

-- 5) Mostre a tabela SEGMERCADO:

SELECT
    *
FROM
    segmercado;

-- 6) Abra o código do pacote e inclua a exceção de erro:

CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY cliente_pac IS

    FUNCTION verifica_segmento_mercado (
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

    FUNCTION obter_categoria_cliente (
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

    PROCEDURE format_cnpj (
        p_cnpj IN OUT VARCHAR2
    ) IS
    BEGIN
        p_cnpj := substr(p_cnpj, 1, 2)
                  || '/'
                  || substr(p_cnpj, 3);

        dbms_output.put_line('CHAMEI A ROTINA FORMAT_CNPJ DO PACOTE !!!!');
    END;

    PROCEDURE incluir_cliente (
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
        WHEN exception_pac.e_null THEN
            raise_application_error(-20020, 'Preenchimento do valor do campo é obrigatório. Favor incluir este valor !!!');
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

    PROCEDURE atualizar_cli_seg_mercado (
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

    PROCEDURE atualizar_faturamento_previsto (
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

    PROCEDURE excluir_cliente (
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

    PROCEDURE incluir_cliente (
        p_id            IN cliente.id%TYPE,
        p_razao_social  IN cliente.razao_social%TYPE,
        p_segmercado_id cliente.segmercado_id%TYPE
    ) IS

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
        INSERT INTO cliente (
            id,
            razao_social,
            segmercado_id,
            data_inclusao
        ) VALUES (
            p_id,
            upper(p_razao_social),
            p_segmercado_id,
            sysdate
        );

        COMMIT;
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20010, 'Cliente já cadastrado');
        WHEN e_segmento THEN
            raise_application_error(-20011, 'Segmento de mercado inexistente');
        WHEN exception_pac.e_null THEN
            raise_application_error(-20020, 'Preenchimento do valor do campo é obrigatório. Favor incluir este valor !!!');
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

END;

/* 7) Compile o pacote acima.

8) Execute o pacote como user_app:*/

EXECUTE APP_INCLUIR_CLIENTE (NULL, 'INCLUIDO POR USER_APP PARA TESTAR VALOR NULO','12222',1,100);

/* 9) Foi apresentado o erro customizado.

10) Crie um script novo associado ao user_app.

11) Execute o código para criar a procedure:*/

CREATE OR REPLACE PROCEDURE incluir_segmento (
    p_id        segmercado.id%TYPE,
    p_descricao segmercado.descricao%TYPE
) IS
BEGIN
    INSERT INTO segmercado (
        id,
        descricao
    ) VALUES (
        p_id,
        p_descricao
    );

END;

/* 12) Compile a procedure e veja o erro.

13) Abra uma janela de script associada ao user_dev.

14) Dê o GRANT e crie o sinônimo:*/

GRANT SELECT, INSERT ON segmercado TO user_app;

CREATE PUBLIC SYNONYM segmercado FOR user_dev.segmercado;

-- 15) Para incluir um novo segmento de mercado, execute:

EXECUTE INCLUIR_SEGMENTO (7, 'COMERCIAL');

-- 16) Mostre SEGMERCADO:

SELECT
    *
FROM
    segmercado;

-- 17) Inclua um segmento com NULL:

EXECUTE INCLUIR_SEGMENTO (NULL, 'TRANSPORTES');

-- 18) Aparece um erro, como era esperado. Altere a procedure para tratar o erro quando a entrada for NULL:

CREATE OR REPLACE PROCEDURE incluir_segmento (
    p_id        segmercado.id%TYPE,
    p_descricao segmercado.descricao%TYPE
) IS
BEGIN
    INSERT INTO segmercado (
        id,
        descricao
    ) VALUES (
        p_id,
        p_descricao
    );

EXCEPTION
    WHEN exception_pac.e_null THEN
        raise_application_error(-20030, 'CAMPO DO SEGMENTO COM PREENCHIMENTO OBRIGATÓRIO');
END;

-- 19) Em user_dev, dê privilégios e associe à PUBLIC:

GRANT EXECUTE ON exception_pac TO PUBLIC;

CREATE PUBLIC SYNONYM exception_pac FOR user_dev.exception_pac;

-- 20) Tente incluir o segmento com NULL:

EXECUTE INCLUIR_SEGMENTO (NULL, 'TRANSPORTES');

/* Agora, aparece o erro tratado como exceção.

21) Dê um duplo clique na função OBTER_CATEGORIA_CLIENTE e observe o código fonte para determinar a classificação do cliente.

22) Crie o pacote com as constantes:*/

CREATE OR REPLACE NONEDITIONABLE PACKAGE cliente_pac IS
    PROCEDURE incluir_cliente (
        p_id                   IN cliente.id%TYPE,
        p_razao_social         IN cliente.razao_social%TYPE,
        p_cnpj                 cliente.cnpj%TYPE,
        p_segmercado_id        cliente.segmercado_id%TYPE,
        p_faturamento_previsto cliente.faturamento_previsto%TYPE
    );

    PROCEDURE atualizar_cli_seg_mercado (
        p_id            cliente.id%TYPE,
        p_segmercado_id cliente.segmercado_id%TYPE
    );

    PROCEDURE atualizar_faturamento_previsto (
        p_id                   IN cliente.id%TYPE,
        p_faturamento_previsto IN cliente.faturamento_previsto%TYPE
    );

    PROCEDURE excluir_cliente (
        p_id IN cliente.id%TYPE
    );

    PROCEDURE incluir_cliente (
        p_id            IN cliente.id%TYPE,
        p_razao_social  IN cliente.razao_social%TYPE,
        p_segmercado_id cliente.segmercado_id%TYPE
    );

    c_pequeno NUMBER(10) := 10000;
    c_medio NUMBER(10) := 50000;
    c_medio_grande NUMBER(10) := 90000;
END;

/* 23) Compile o cabeçalho do pacote.

24) Substitua no corpo do pacote:*/

CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY cliente_pac IS

    FUNCTION verifica_segmento_mercado (
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

    FUNCTION obter_categoria_cliente (
        p_faturamento_previsto IN cliente.faturamento_previsto%TYPE
    ) RETURN cliente.categoria%TYPE IS
    BEGIN
        IF p_faturamento_previsto <= c_pequeno THEN
            RETURN 'PEQUENO';
        ELSIF p_faturamento_previsto <= c_medio THEN
            RETURN 'MEDIO';
        ELSIF p_faturamento_previsto <= c_medio_grande THEN
            RETURN 'MEDIO GRANDE';
        ELSE
            RETURN 'GRANDE';
        END IF;
    END;

    PROCEDURE format_cnpj (
        p_cnpj IN OUT VARCHAR2
    ) IS
    BEGIN
        p_cnpj := substr(p_cnpj, 1, 2)
                  || '/'
                  || substr(p_cnpj, 3);

        dbms_output.put_line('CHAMEI A ROTINA FORMAT_CNPJ DO PACOTE !!!!');
    END;

    PROCEDURE incluir_cliente (
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
        WHEN exception_pac.e_null THEN
            raise_application_error(-20020, 'Preenchimento do valor do campo é obrigatório. Favor incluir este valor !!!');
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

    PROCEDURE atualizar_cli_seg_mercado (
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

    PROCEDURE atualizar_faturamento_previsto (
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

    PROCEDURE excluir_cliente (
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

    PROCEDURE incluir_cliente (
        p_id            IN cliente.id%TYPE,
        p_razao_social  IN cliente.razao_social%TYPE,
        p_segmercado_id cliente.segmercado_id%TYPE
    ) IS

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
        INSERT INTO cliente (
            id,
            razao_social,
            segmercado_id,
            data_inclusao
        ) VALUES (
            p_id,
            upper(p_razao_social),
            p_segmercado_id,
            sysdate
        );

        COMMIT;
    EXCEPTION
        WHEN dup_val_on_index THEN
            raise_application_error(-20010, 'Cliente já cadastrado');
        WHEN e_segmento THEN
            raise_application_error(-20011, 'Segmento de mercado inexistente');
        WHEN exception_pac.e_null THEN
            raise_application_error(-20020, 'Preenchimento do valor do campo é obrigatório. Favor incluir este valor !!!');
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

END;

/* 25) Crie um novo script associado ao user_app.

26) Mostre o conteúdo de CLIENTE:*/

SELECT
    *
FROM
    cliente;

-- 27) Execute o código para incluir um novo cliente:

EXECUTE APP_INCLUIR_CLIENTE (31, 'CLIENTE INCLUIDO PELO PACOTE', '23333', 2, 100000);

-- 28) Mostre o cliente com ID 31:

SELECT
    *
FROM
    cliente
WHERE
    id = 31;

/* 29) Para mudar o limite, vá no cabeçalho e altere-o.

30) Compile o cabeçalho e o corpo do pacote.

31) Inclua o novo cliente:*/

EXECUTE APP_INCLUIR_CLIENTE (32, 'CLIENTE INCLUIDO PELO PACOTE', '23333', 2, 100000);

-- 32) Mostre como foi a classificação dos clientes:

SELECT
    *
FROM
    cliente
WHERE
    id = 31
    OR id = 32;

-- 33) Para saber o limite das categorias, execute os comandos:

SET SERVEROUTPUT ON;
EXEC dbms_output.put_line(CLIENTE_PAC.c_MEDIO_GRANDE);