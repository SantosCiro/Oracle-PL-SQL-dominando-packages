/* 1) Clique sobre o cabeçalho do pacote.

2) Altere o código para:*/

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

END;

/* 3) Clique no ícone de Compilar para Depuração.

4) Para corrigir o erro, altere o código:*/

CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY cliente_pac IS

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
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

END;

-- 5) Para passar 5 parâmetros, use o código:

EXECUTE CLIENTE_PAC.INCLUIR_CLIENTE(15,'INCLUIR CLIENTE COM 5 PARAMETROS','99999',2,90000);

-- 6) Mostre o conteúdo da tabela CLIENTE:

SELECT
    *
FROM
    cliente;

-- 7) Passe somente 3 parâmetros no pacote:

EXECUTE CLIENTE_PAC.INCLUIR_CLIENTE(16,'INCLUIR CLIENTE COM 3 PARAMETROS',2);

-- 8) Veja o que aconteceu com a tabela CLIENTE:

SELECT
    *
FROM
    cliente;

-- 9) Altere o código para colocar as funções internas ao pacote:

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
        WHEN OTHERS THEN
            v_codigo_erro := sqlcode;
            v_mensagem_erro := sqlerrm;
            raise_application_error(-20000, to_char(v_codigo_erro)
                                            || v_mensagem_erro);
    END;

END;

-- 10) Inclua o cliente usando o pacote:

SET SERVEROUTPUT ON;
EXECUTE CLIENTE_PAC.INCLUIR_CLIENTE(18,'INCLUIR CLIENTE PELO PACOTE USANDO PROC INTERNA','22222',2,50000);

-- 11) Execute a procedure INCLUIR_CLIENTE sem chamar o pacote:

EXECUTE INCLUIR_CLIENTE(19,'INCLUIR CLIENTE FORA DO PACOTE','22222',2,50000);

-- 12) Mostre o resultado na tabela CLIENTE:

SELECT
    *
FROM
    cliente;

/* 13) Crie um novo script associado ao usuário user_dev.

14) Para verificar a dependência de INCLUIR_CLIENTE, execute o comando:*/

EXECUTE DEPTREE_FILL('procedure','user_dev','INCLUIR_CLIENTE');

-- 15) Veja as dependências com o comando:

SELECT
    nested_level,
    schema,
    type,
    name
FROM
    deptree
ORDER BY
    seq#;

-- 16) Vá na área do user_app e use o comando:

CREATE OR REPLACE NONEDITIONABLE PROCEDURE app_incluir_cliente (
    p_id          IN cliente.id%TYPE,
    p_razao       IN cliente.razao_social%TYPE,
    p_cnpj        IN cliente.cnpj%TYPE,
    p_segmercado  IN cliente.segmercado_id%TYPE,
    p_faturamento IN cliente.faturamento_previsto%TYPE
) IS
BEGIN
    cliente_pac.incluir_cliente(p_id, p_razao, p_cnpj, p_segmercado, p_faturamento);
END;

-- 17) Agora, para verificar a dependência de ATUALIZAR_CLI_SEG_MERCADO, execute o comando:

EXECUTE DEPTREE_FILL('procedure','user_dev','ATUALIZAR_CLI_SEG_MERCADO');

-- 18) Veja as dependências da procedure:

SELECT
    nested_level,
    schema,
    type,
    name
FROM
    deptree
ORDER BY
    seq#;

-- 19) Veja as dependências de ATUALIZAR_FATURAMENTO_PREVISTO, executando o comando:

EXECUTE DEPTREE_FILL('procedure','user_dev','ATUALIZAR_FATURAMENTO_PREVISTO');

-- 20) A procedure têm as dependências:

SELECT
    nested_level,
    schema,
    type,
    name
FROM
    deptree
ORDER BY
    seq#;

-- 21) Para verificar as dependências de EXCLUIR_CLIENTE, execute o comando:

EXECUTE DEPTREE_FILL('procedure','user_dev','EXCLUIR_CLIENTE');

-- 22) Veja as dependências, executando o comando:

SELECT
    nested_level,
    schema,
    type,
    name
FROM
    deptree
ORDER BY
    seq#;

-- 23) Para verificar as dependências da procedure FORMAT_CNPJ, execute o comando:

EXECUTE DEPTREE_FILL('procedure','user_dev','FORMAT_CNPJ');

-- 24) Veja as dependências com o comando:

SELECT
    nested_level,
    schema,
    type,
    name
FROM
    deptree
ORDER BY
    seq#;

-- 25) Para verificar as dependências da função OBTER_CATEGORIA_CLIENTE, execute o comando:

EXECUTE DEPTREE_FILL('function','user_dev','OBTER_CATEGORIA_CLIENTE');

-- 26) Veja as dependências com o comando:

SELECT
    nested_level,
    schema,
    type,
    name
FROM
    deptree
ORDER BY
    seq#;

-- 27) Para verificar a dependência da função VERIFICA_SEGMENTO_MERCADO, execute o comando:

EXECUTE DEPTREE_FILL('function','user_dev','VERIFICA_SEGMENTO_MERCADO');

-- 28) Para excluir as procedures, execute os comandos:

DROP PROCEDURE incluir_cliente;

DROP PROCEDURE atualizar_cli_seg_mercado;

DROP PROCEDURE atualizar_faturamento_previsto;

DROP PROCEDURE excluir_cliente;

-- 29) Agora, apague o restante:

DROP PROCEDURE format_cnpj;

DROP FUNCTION obter_categoria_cliente;

DROP FUNCTION verifica_segmento_mercado;