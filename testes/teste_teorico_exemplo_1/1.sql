CREATE OR REPLACE FUNCTION DURACAO_ULTIMO_INTERNAMENTO
(
    nif_utente NUMBER,
    especialidade VARCHAR2,
    ano NUMBER
)
RETURN NUMBER
IS
    duracao NUMBER := 0;
    total_utentes NUMBER:=0;
    utente_internado NUMBER:=0;
    codigo_ultimo_internamento NUMBER:=0;
    ultimo_internamento_terminou NUMBER:=0;
BEGIN
    SELECT  COUNT(*)  INTO total_utentes FROM UTENTE
    WHERE nif=nif_utente;

    SELECT COUNT(*) into utente_internado FROM INTERNAMENTO i
        inner join UTENTE u on i.codUtente=u.codUtente
        where i.Especialidade=especialidade and u.nif=nif_utente and extract(year from i.dataIntern)=ano) = 0
        group by i.codIntern desc;

    -- vamos buscar o codigo do ultimo internamento
    SELECT i.codIntern into codigo_ultimo_internamento FROM INTERNAMENTO i
        inner join UTENTE u on i.codUtente=u.codUtente
        where i.Especialidade=especialidade and u.nif=nif_utente and extract(year from i.dataIntern)=ano
        order by i.codIntern desc; --ultimo internamento

    -- agora as exceptions
    IF(total_utentes = 0) THEN
        RAISE_APPLICATION_ERROR(-20003, 'O utente com o nif ' || nif_utente || ' nao existe.');
    END IF;

    -- verficar se o utente já esteve internado na especialidade no ano
    IF(utente_internado = 0) THEN
        RAISE_APPLICATION_ERROR(-20001, 'O utente com o nif ' || nif_utente || ' nao esteve internado na especialidade ' || especialidade || ' no ano ' || ano || '.');
    END IF;

    -- dado que temos o codigo do ultimo internamento so vai entrar aqui se o utente estiver internado senao tinha falhado em cima
    -- vamos ver se o ultimo internamento ja terminou e se sim atualizamos ultimo_internamento_terminou para 1

    SELECT COUNT(*) into ultimo_internamento_terminou FROM TERMINO t
        inner join INTERNAMENTO i on i.codIntern=t.codIntern
        inner join UTENTE u on i.codUtente=u.codUtente
        where i.Especialidade=especialidade and u.nif=nif_utente and extract(year from t.dataIntern)=ano
        order by i.codIntern desc --ultimo internamento

    IF(ultimo_internamento_terminou = 0) THEN
        RAISE_APPLICATION_ERROR(-20002, 'O utente com o nif ' || nif_utente || ' ainda se encontra internado na especialidade ' || especialidade || ' no ano ' || ano || ' (nao terminou ainda).');
    END IF;

    -- retornar a duracao deste internamento
    SELECT (t.data - i.dataIntern) INTO duracao
    FROM INTERNAMENTO i
    inner join TERMINO t on i.codIntern = t.codINtern
    inner join UTENTE u on i.codUtente=u.codUtente
    where i.Especialidade=especialidade and u.nif=nif_utente and extract(year from t.dataIntern)=ano
    order by i.codIntern desc --ultimo internamento
    RETURN duracao;
END;
