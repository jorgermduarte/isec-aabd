
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


CREATE OR REPLACE PROCEDURE g_estabelece_chamada(
    num_de_origem VARCHAR2,
    num_de_destino VARCHAR2
) AS
    v_id_client NUMBER;
    v_id_phone_contract NUMBER;
    v_phone_status VARCHAR2(20);
    v_phone_number_normalized NVARCHAR2(20);
    v_phone_number_destiny_normalized NVARCHAR2(20);
    v_id_network NUMBER;
BEGIN
    -- vamos buscar o numero normalizado
    v_phone_number_normalized := e_numero_normalizado(num_de_origem);
    v_phone_number_destiny_normalized := e_numero_normalizado(num_de_destino);

    --  vamos buscar o cliente e o id do contrato
    SELECT ID_CLIENT, ID_PHONE_NUMBER_CONTRACT 
    INTO v_id_client, v_id_phone_contract 
    FROM PHONE_NUMBER_CONTRACT 
    WHERE PHONE_NUMBER = v_phone_number_normalized;

    -- assumindo que existe sempre um estado associado ao telemovel de origem
    -- vamos ver o estado do telemovel
    SELECT STATUS_TYPE 
    INTO v_phone_status 
    FROM PHONE_NUMBER_STATUS 
    WHERE ID_PHONE_NUMBER_CONTRACT = v_id_phone_contract
    ORDER BY CREATED_AT DESC FETCH FIRST ROW ONLY;

    IF v_phone_status <> 'AVAILABLE' THEN 
        RAISE_APPLICATION_ERROR(-20507, 'Serviço indisponível.');
    END IF;

    -- Vamos buscar a rede associada ao número de telefone
    -- TODO: ir ao plano de um número de telefone, buscar o seu tarifario que por sua vez tem o id_network e associar aqui
    v_id_network := 0;

    -- registar a chamada
    INSERT INTO CLIENT_PHONE_NUMBER_CALL(
        ID_CLIENT,
        ID_PHONE_NUMBER_CONTRACT,
        TARGET_NUMBER,
        ID_STATUS_TYPE,
        ID_NETWORK
    ) VALUES (
        v_id_client,
        v_id_phone_contract,
        v_phone_number_destiny_normalized, 
        (SELECT ID_CALL_STATUS_TYPE FROM CALL_STATUS_TYPE WHERE UPPER(NAME) = 'CALLING'),
        v_id_network
    ); 

    DBMS_OUTPUT.PUT_LINE('Chamada iniciada: De '|| num_de_origem ||' para '|| num_de_destino);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20502, 'Número de telefone inválido.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20599, SQLERRM);
END;


CREATE OR REPLACE FUNCTION d_tipo_de_chamada_voz(num_telefone VARCHAR2) 
RETURN NUMBER IS
    num_normalizado VARCHAR2(20);
    CURSOR c1 IS SELECT n.PREFIX, n.DIGITS_COUNT, n.ID_NETWORK  FROM NETWORK n WHERE IS_ACTIVE = 1;
    prefix_exists NUMBER := 0;
    id_network_destiny NUMBER := 0;
    clean_prefix_check VARCHAR2(20);
BEGIN
    num_normalizado := e_numero_normalizado(num_telefone);

    -- vamos a todas as networks verificar se corres
    FOR reg IN c1 LOOP
        clean_prefix_check := REPLACE(reg.PREFIX, 'x', '');
        SELECT INSTR(num_normalizado, clean_prefix_check) INTO prefix_exists FROM DUAL;
      
        IF prefix_exists > 0 THEN
            id_network_destiny := reg.ID_NETWORK;
            EXIT;
        END IF;
     
    END LOOP;
  
    -- se não detetamos nenhuma network de destino.
    IF id_network_destiny = 0 THEN
        RAISE_APPLICATION_ERROR(-20515, 'Gama de números indefinido.');
    END IF;
    
    RETURN id_network_destiny;

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20515, 'Erro inesperado: ' || SQLERRM);
END;


CREATE OR REPLACE TRIGGER o_trig_2021110042
AFTER INSERT OR UPDATE ON CLIENT_PHONE_NUMBER_CALL
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN
        INSERT INTO CLIENT_PHONE_NUMBER_CALL_HISTORY (
            ID_CLIENT_PHONE_NUMBER_CALL,
            ID_STATUS_TYPE,
            ID_NETWORK,
            ID_PHONE_NUMBER_CONTRACT,
            CALL_ACCEPTED,
            CALL_ACCEPTED_DATE,
            CALL_COMPLETED_DATE,
            CALL_ATTEMPTED_SECONDS,
            CREATED_AT
        ) VALUES (
            :NEW.ID_CALL,
            :NEW.ID_STATUS_TYPE,
            :NEW.ID_NETWORK,
            :NEW.ID_PHONE_NUMBER_CONTRACT,
            :NEW.CALL_ACCEPTED,
            :NEW.CALL_ACCEPTED_DATE,
            :NEW.CALL_COMPLETED_DATE,
            :NEW.CALL_ATTEMPTED_SECONDS,
            :NEW.CREATED_AT
        );
    ELSIF UPDATING THEN
        INSERT INTO CLIENT_PHONE_NUMBER_CALL_HISTORY (
            ID_CLIENT_PHONE_NUMBER_CALL,
            ID_STATUS_TYPE,
            ID_NETWORK,
            ID_PHONE_NUMBER_CONTRACT,
            CALL_ACCEPTED,
            CALL_ACCEPTED_DATE,
            CALL_COMPLETED_DATE,
            CALL_ATTEMPTED_SECONDS,
            CREATED_AT
        ) VALUES (
            :OLD.ID_CALL,
            :OLD.ID_STATUS_TYPE,
            :OLD.ID_NETWORK,
            :OLD.ID_PHONE_NUMBER_CONTRACT,
            :OLD.CALL_ACCEPTED,
            :OLD.CALL_ACCEPTED_DATE,
            :OLD.CALL_COMPLETED_DATE,
            :OLD.CALL_ATTEMPTED_SECONDS,
            :OLD.CREATED_AT
        );
    END IF;
END;



CREATE OR REPLACE TRIGGER l_carrega_cartao_prepago
AFTER INSERT ON PHONE_NUMBER_DEPOSITS
FOR EACH ROW
DECLARE
	v_old_balance NUMBER;
	v_new_balance NUMBER;
BEGIN

  IF :NEW.PROCESSED = 0 THEN

	SELECT pnb.VALUE INTO v_old_balance FROM PHONE_NUMBER_BALANCE pnb 
  	WHERE pnb.ID_CONTRACT = :NEW.ID_CONTRACT AND pnb.ID_PHONE_NUMBER_CONTRACT = :NEW.ID_PHONE_NUMBER_CONTRACT;

  	v_new_balance := v_old_balance + :NEW.VALUE;

  	UPDATE PHONE_NUMBER_BALANCE pnb
  	SET pnb.VALUE = v_new_balance
	WHERE pnb.ID_CONTRACT = :NEW.ID_CONTRACT AND pnb.ID_PHONE_NUMBER_CONTRACT = :NEW.ID_PHONE_NUMBER_CONTRACT;

  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;


CREATE OR REPLACE FUNCTION b_custo_da_chamada(idChamada NUMBER)
RETURN NUMBER IS
    v_custo NUMBER;
    v_duracao NUMBER;
    v_tipo_plano NUMBER;
    V_id_phone_number_contract NUMBER;
    v_id_tarifa NUMBER;
    v_tipo_tarifario NUMBER :=0;
BEGIN

    SELECT duration INTO v_duracao
    FROM CLIENT_PHONE_NUMBER_CALL
    WHERE ID_CALL = idChamada;

   	-- vamos buscar o phone number contract
    SELECT ID_PHONE_NUMBER_CONTRACT  INTO V_id_phone_number_contract
    FROM CLIENT_PHONE_NUMBER_CALL
    WHERE ID_CALL = idChamada;

   -- vamos buscar o plano pre-pago associado ao numero de telemovel
    SELECT ID_PLAN_AFTER_PAID INTO v_tipo_plano
    FROM CONTRACT_AFTER_PAID
    WHERE ID_PHONE_NUMBER_CONTRACT = V_id_phone_number_contract;

   -- se não existe plano pre-pago associado ao numero de tleemovel, vamos ver se existe pos pago
    IF v_tipo_plano IS NULL THEN
    	-- definimos que o tipo de tarifario é o pos pago
    	v_tipo_tarifario := 1;
        SELECT ID_PLAN_BEFORE_PAID INTO v_tipo_plano
        FROM CONTRACT_BEFORE_PAID
        WHERE ID_PHONE_NUMBER_CONTRACT = V_id_phone_number_contract;
    END IF;

   -- se existir plano
    IF v_tipo_plano IS NOT NULL THEN

    	-- vamos selecionar a tarifa correta do pre-pago
    	IF v_tipo_tarifario = 0 THEN
            SELECT ID_TARRIF INTO v_id_tarifa
            FROM PLAN_BEFORE_PAID_TARRIF
            WHERE ID_PLAN_BEFORE_PAID = v_tipo_plano;
    	END IF;

    	-- vamos selecionar a tarifa correta do pos pago
    	IF v_tipo_tarifario = 1 THEN
	        SELECT ID_TARRIF INTO v_id_tarifa
        	FROM PLAN_AFTER_PAID_TARRIF
        	WHERE ID_PLAN_AFTER_PAID = v_tipo_plano;
    	END IF;

    	-- se existir entao a tarifa vamos buscar o preço unitario das chamadas do determinado tarifario
        IF v_id_tarifa IS NOT NULL THEN
            SELECT MONEY_PER_UNIT INTO v_custo
            FROM TARRIF
            WHERE ID_TARRIF = v_id_tarifa AND
            ID_UNIT_TYPE = (SELECT tut.ID_TARRIF_UNIT_TYPE FROM TARRIF_UNIT_TYPE tut WHERE UPPER(TUT.NAME) = 'MINUTO');

        ELSE
            RAISE_APPLICATION_ERROR(-20503, 'Tarifário inexistente.');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20516, 'Plano inexistente.');
    END IF;

    RETURN v_custo * v_duracao;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20599, 'Falha ao encontrar dados de referencia da chamada');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20599, 'Algo correu mal');
END;