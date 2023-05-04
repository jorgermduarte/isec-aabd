
CREATE OR REPLACE TRIGGER UPDATE_INTERNAMENTOS
AFTER UPDATE OF data ON TERMINO
FOR EACH ROW
DECLARE
    v_duracao NUMBER;
    ex20002 EXCEPTION;
    cod number;
    prgram exception_init(-20002, ex20002);
BEGIN
    IF(:new.data IS NOT NULL) THEN
        -- vamos buscar a duracao do internamento
        v_duracao := DURACAO_ULTIMO_INTERNAMENTO(:new.codIntern);
        UPDATE TEMP SET col2=v_duracao WHERE col2=:new.codIntern;
    END IF;
EXCEPTION
    WHEN ex20002 THEN
        cod := sqlcode;
        -- se o internamento ainda nao terminou vamos atualizar a tabela TEMP com o col2 a -1 (internamento ainda nao terminou)
        UPDATE TEMP SET col2=-1 WHERE col2=:new.codIntern;
    WHEN OTHERS THEN
        NULL
    END;
END;