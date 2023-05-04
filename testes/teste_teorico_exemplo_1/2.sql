CREATE OR REPLACE PROCEDURE INTERNAMENTOS_CIDADE
(
    cidade VARCHAR2,
    ano NUMBER,
)
IS
    -- vai buscar os utentes que residem na cidade e que estiveram internados no ano
    CURSOR c1 IS
        SELECT u.nome, i.especialidade
        FROM UTENTE u
        inner join INTERNAMENTO i on u.codUtente=i.codUtente
        inner join MEDICO m on i.codMedico=m.codMedico
        where
        -- formato morada nome da rua cod postal, cidade
        substr(u.morada, instr(u.morada, ',')+2, length(u.morada))=cidade
        and
        extract(year from i.dataIntern)=ano
        group by u.nome, i.especialidade;

    v_nome UTENTE.NOME%TYPE;
    v_especialidade INTERNAMENTO.Especialidade%TYPE;
    v_duracao NUMBER;
    ex20002 EXCEPTION;
    cod number;
    prgram exception_init(-20002, 'erro que queremos captar');
BEGIN

    -- apagar o conteudo da tabela TEMP
    DELETE FROM TEMP;

    FOR reg IN c1 LOOP
        BEGIN
            v_duracao := DURACAO_ULTIMO_INTERNAMENTO(reg.nome, reg.especialidade, ano);
            INSERT INTO TEMP VALUES(ano, reg.nome, reg.especialidade, v_duracao);
        EXCEPTION
            WHEN ex20002 THEN
                cod := sqlcode;
               INSERT INTO TEMP(col1,col2,message1,message2) VALUES(ano, cod, reg.nome, reg.especialidade);
            WHEN OTHERS THEN
                NULL
            END;
    END LOOP;
END;