/* 1) Crie um script através do user_dev.

2) Use os comandos para criar o pacote:*/

CREATE OR REPLACE PACKAGE cliente_pac IS
    PROCEDURE incluir_cliente (
        p_id                   IN cliente.id%TYPE,
        p_razao_social         IN cliente.razao_social%TYPE,
        p_cnpj                 cliente.cnpj%TYPE,
        p_segmercado_id        cliente.segmercado_id%TYPE,
        p_faturamento_previsto cliente.faturamento_previsto%TYPE
    );

END;

/* 3) Execute os comandos e verifique que o pacote foi criado.

4) Para criar o corpo do pacote, execute os comandos:*/

CREATE OR REPLACE PACKAGE BODY cliente_pac IS

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
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

END;

/* 5) Verifique a criação do corpo do pacote.

6) Para garantir o privilégio de execução ao user_app, execute:*/

GRANT EXECUTE ON cliente_pac TO user_app;

-- 7) Crie um script como user_app e execute o comando:

EXECUTE user_dev.CLIENTE_PAC.INCLUIR_CLIENTE(10, 'PRIMEIRO CLIENTE INCLUIDO POR USER_APP VIA PACKAGE', '455564', 2, 120000);

-- 8) Mostre o conteúdo da tabela:

SELECT
    *
FROM
    cliente;

-- 9) Crie um sinônimo para o pacote na conexão user_dev:

CREATE PUBLIC SYNONYM cliente_pac FOR user_dev.cliente_pac;

-- 10) Em user_app, rode o comando:

EXECUTE CLIENTE_PAC.INCLUIR_CLIENTE(11, 'SEGUNDO CLIENTE INCLUIDO POR USER_APP VIA PACKAGE', '455564', 2, 120000);

-- 11) Crie um novo script associado à user_dev e execute os comandos para criar o cabeçalho do pacote:

CREATE OR REPLACE PACKAGE cliente_pac IS
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

END;

-- 12) Agora, execute os comandos:

-- ================================================

CREATE OR REPLACE PACKAGE BODY cliente_pac IS

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

END;

-- 13) Crie um novo script com o user_app e verifique o conteúdo da tabela CLIENTE:

SELECT
    *
FROM
    cliente;

-- 14) Para excluir o cliente, execute o comando:

EXECUTE CLIENTE_PAC.EXCLUIR_CLIENTE(10);