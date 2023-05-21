
CREATE OR REPLACE TRIGGER i_atualiza_saldo
AFTER INSERT ON CLIENT_PHONE_NUMBER_CALL
FOR EACH ROW
DECLARE
    v_balance NUMBER(10);
    v_new_balance NUMBER(10);
BEGIN
    -- Obtenha o saldo atual do número de telefone do contrato
    SELECT VALUE INTO v_balance
    FROM PHONE_NUMBER_BALANCE
    WHERE ID_PHONE_NUMBER_CONTRACT = :NEW.ID_PHONE_NUMBER_CONTRACT;

    -- Calcule o novo saldo
    v_new_balance := v_balance - :NEW.COST_VALUE;

    -- Atualize o saldo na tabela PHONE_NUMBER_BALANCE
    UPDATE PHONE_NUMBER_BALANCE
    SET VALUE = v_new_balance,
        UPDATED_AT = SYSDATE
    WHERE ID_PHONE_NUMBER_CONTRACT = :NEW.ID_PHONE_NUMBER_CONTRACT;
END;


CREATE OR REPLACE FUNCTION e_numero_normalizado(num_telefone VARCHAR2)
RETURN VARCHAR2
IS
    num_normalizado VARCHAR2(255);
    CURSOR c1 IS SELECT n.PREFIX, n.DIGITS_COUNT FROM NETWORK n WHERE IS_ACTIVE = 1;
    clean_prefix_check VARCHAR2(20);
    prefix_exists NUMBER := 0;
    digits_count_check NUMBER := 0;
    portugal_prefix VARCHAR2(5) := '00351';
BEGIN
    -- remover tudo o que não seja números
    num_normalizado := REGEXP_REPLACE(num_telefone, '[^0-9]', '');

    IF SUBSTR(num_normalizado, 1, LENGTH(portugal_prefix)) = portugal_prefix THEN
        num_normalizado := SUBSTR(num_normalizado, LENGTH(portugal_prefix)+1);
    END IF;

    -- vamos ver se existe algum prefixo com o total de dígitos atuais
    FOR reg IN c1 LOOP
        clean_prefix_check := REPLACE(reg.PREFIX, 'x', '');
        -- vamos ver se o prefixo existe no atual
        SELECT INSTR(num_normalizado, clean_prefix_check) INTO prefix_exists FROM DUAL;

        IF prefix_exists > 0 THEN
        	-- aqui nao estou a ver como validar de outra forma
            IF reg.DIGITS_COUNT = '>3' THEN
                digits_count_check := 3;
            ELSE
                digits_count_check := TO_NUMBER(reg.DIGITS_COUNT);
            END IF;

            EXIT; -- encontramos um MATCH por isso vamos sair do loop
        END IF;
    END LOOP;

    RETURN num_normalizado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20599, 'Unexpected error: ' || SQLERRM);
END;




CREATE OR REPLACE PROCEDURE f_envia_SMS (
    num_de_origem IN VARCHAR,
    num_de_destino IN VARCHAR,
    mensagem IN VARCHAR
) IS
	normalized_origin_number NVARCHAR2(255) := '';
	normalized_destiny_number NVARCHAR2(255) := '';
    origem_exists NUMBER;
    phone_number_contract_id NUMBER := 0;
   	contract_id NUMBER := 0;
    client_id NUMBER := 0;
   	status_id NUMBER := 0;

BEGIN
	-- normalizar o numero de origem e de destino
	BEGIN
		normalized_origin_number := e_numero_normalizado(num_de_origem);
		normalized_destiny_number := e_numero_normalizado(num_de_destino);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE;
	END;

    SELECT COUNT(*) INTO origem_exists
    FROM PHONE_NUMBER_CONTRACT
    WHERE PHONE_NUMBER = normalized_origin_number;

    IF origem_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Número de telefone inexistente.');
    END IF;

   	SELECT pnc.ID_CONTRACT, pnc.ID_PHONE_NUMBER_CONTRACT INTO contract_id, phone_number_contract_id
   	FROM PHONE_NUMBER_CONTRACT pnc
   	WHERE pnc.PHONE_NUMBER = normalized_origin_number AND ROW_NUMBER=1;

   	SELECT c.ID_CLIENT INTO client_id FROM CONTRACT c
   	WHERE c.ID_CONTRACT = contract_id;

	SELECT sst.ID INTO status_id FROM SMS_STATUS_TYPE sst
	WHERE UPPER(sst.NAME) = 'SENDING';

   -- TODO: j_get_saldo, se nao tiver saldo lança excepcao -20508 Telefone sem saldo.

   -- TODO: -20511 Número inativo.

    INSERT INTO SMS(ID_CLIENT, ID_STATUS_TYPE, ID_PHONE_NUMBER_CONTRACT, IS_COMPLETED, DESTINY_NUMBER,MESSAGE, COST_VALUE)
    VALUES (
    	client_id,
   		status_id,
   		phone_number_contract_id,
   		0,
   		normalized_destiny_number,
   		mensagem,
   		0
	);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    	RAISE_APPLICATION_ERROR(-20599, 'Unexpected error: No data found');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20599, 'Unexpected error: ' || SQLERRM);
END;
