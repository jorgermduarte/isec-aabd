
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


CREATE OR REPLACE FUNCTION M_FUNC_2021110042_get_phone_number_contract_id (num_de_origem NVARCHAR2) RETURN NUMBER
IS 
   	v_num_origem_normalizado NVARCHAR2;
    id_phone_number_contract NUMBER;
BEGIN 
	-- numero normalizado
	v_num_origem_normalizado := e_numero_normalizado(num_de_origem);

	-- vamos buscar o phone_number_contract_id atraves do numero de telemovel
	SELECT pnc.ID_PHONE_NUMBER_CONTRACT INTO id_phone_number_contract
		FROM PHONE_NUMBER_CONTRACT pnc 
	WHERE pnc.PHONE_NUMBER = v_num_origem_normalizado;


    RETURN id_phone_number_contract;

	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			 RAISE_APPLICATION_ERROR(-20509, 'Contrato inexistente.');
		WHEN OTHERS THEN
			 RAISE_APPLICATION_ERROR(-20599, 'Algo correu mal');
END;


CREATE OR REPLACE FUNCTION h_pode_realizar_a_chamada(num_de_origem NVARCHAR2, num_de_destino NVARCHAR2) RETURN NVARCHAR2
IS
    v_rede_destino NUMBER;
   	v_status_origem NUMBER;
    v_phone_number_contract_id NUMBER;
   	v_num_origem_normalizado NVARCHAR2;
    v_num_destino_normalizado NVARCHAR2;
BEGIN

	-- normalizar dados
	v_num_origem_normalizado := e_numero_normalizado(num_de_origem);
	v_num_destino_normalizado := e_numero_normalizado(num_de_destino);

	-- vamos buscar o phone_number_contract_id atraves do numero de telemovel
	v_phone_number_contract_id := M_FUNC_2021110042_get_phone_number_contract_id(v_num_origem_normalizado);

	BEGIN
	    -- Verifica se o número de origem está disponivel
	    SELECT pns.STATUS_TYPE INTO v_status_origem 
	    FROM PHONE_NUMBER_STATUS pns
	    JOIN PHONE_NUMBER_STATUS_TYPE pnst ON pns.STATUS_TYPE=pnst.ID_PHONE_NUMBER_STATUS 
	    WHERE pns.ID_PHONE_NUMBER_CONTRACT = v_phone_number_contract_id
	    EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	    	 RAISE_APPLICATION_ERROR(-20508, 'Número de origem não encontrado ou não disponivel');
   	END;
   	-- TODO: ver se o numero de origem tem saldo

    -- Retorna o tipo de rede do número de destino
    v_rede_destino = d_tipo_de_chamada_voz(v_num_destino_normalizado);

   -- vamos retornar o nome do tipo de rede destino como é dado no requisito
     RETURN v_rede_destino;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20508, 'Número de origem ou destino não encontrado');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20511, 'Mais de um número de origem ou destino encontrado');
END;



CREATE OR REPLACE FUNCTION j_get_saldo (numero VARCHAR, tipo VARCHAR DEFAULT 'valor') 
RETURN NUMBER 
IS
  v_saldo NUMBER;
  v_normalized_phone_number VARCHAR;
  v_phone_number_contract NUMBER;
  
BEGIN
	
	BEGIN 
		-- vai buscar o numero normalizado
		v_normalized_phone_number := e_numero_normalizado(numero);
	
	    -- vamos buscar o id do contrato
	   	v_phone_number_contract := M_FUNC_2021110042_get_phone_number_contract_id(v_normalized_phone_number);
	   
	   EXCEPTION
	   	WHEN OTHERS THEN 
	   		RAISE_APPLICATION_ERROR(-20509,'Contrato inexistente.');
	END;
	
  IF tipo = 'valor' THEN
  	SELECT pnb.VALUE INTO v_saldo FROM PHONE_NUMBER_BALANCE pnb 
    WHERE pnb.ID_PHONE_NUMBER_CONTRACT  = v_phone_number_contract;
  ELSIF tipo = 'voz' THEN
	v_saldo := -1;
    -- todo - implement this
  ELSIF tipo = 'SMS' THEN
  	v_saldo := -1;  
    -- todo - implement this
  ELSE
    RAISE_APPLICATION_ERROR(-20519, 'Tipo de saldo inválido');
  END IF;
 
  RETURN v_saldo;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20501, 'Número de telefone inexistente');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20502, 'Inválido Número de telefone');
END;


CREATE OR REPLACE FUNCTION c_preco_por_minuto(p_origem_phone_number VARCHAR2, p_destino_phone_number VARCHAR2) 
RETURN NUMBER IS 
	v_preco_por_minuto NUMBER(10,3); 
	v_id_origem_contract NUMBER(10); 
	v_id_destino_network NUMBER(10); 
 
  	v_normalized_origin_phone NVARCHAR2;
  	v_normalized_destiny_phone NVARCHAR2;
 	v_phone_number_contract NUMBER;
 
    v_network_destiny_number NUMBER;

BEGIN 
	-- get normalized phone numbers
	v_normalized_origin_phone := e_numero_normalizado(p_origem_phone_number);
	v_normalized_destiny_phone := e_numero_normalizado(p_destino_phone_number);

	
	-- vamos buscar o id do contrato
	v_phone_number_contract := M_FUNC_2021110042_get_phone_number_contract_id(v_normalized_origin_phone);

	-- vamos buscar a rede do numero destino
	v_network_destiny_number:= d_tipo_de_chamada_voz(v_normalized_destiny_phone);
  
	

	SELECT MONEY_PER_UNIT INTO v_preco_por_minuto FROM TARRIF t 
	INNER JOIN PLAN_AFTER_PAID_TARRIF papt ON t.ID_TARRIF =PAPT.ID_TARRIF
	INNER JOIN CONTRACT_AFTER_PAID cap ON PAPT.ID_PLAN_AFTER_PAID = cap.ID_PLAN_AFTER_PAID 
	WHERE cap.ID_PHONE_NUMBER_CONTRACT =v_phone_number_contract
	AND T.ID_COMMUNICATION_TYPE = (SELECT ct.ID_COMMUNICATION_TYPE  FROM COMMUNICATION_TYPE ct WHERE UPPER(ct.NAME) = 'VOZ' )
	AND t.ID_NETWORK = v_network_destiny_number;


  	RETURN v_preco_por_minuto; 

  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      RAISE_APPLICATION_ERROR(-20501,'Erro: Não foi possível encontrar dados');
    WHEN TOO_MANY_ROWS THEN
      RAISE_APPLICATION_ERROR(-20502,'Erro: Mais de uma linha retornada');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20510,'Erro: Outro erro ocorreu');
END; 



CREATE OR REPLACE FUNCTION f_aux_get_plan_id_by_phone_number
(
	phone_number_contract NUMBER
)
RETURN NUMBER
IS
	v_id_plano NUMBER;
	v_tipo_plano NUMBER := 0; -- pre-pago BY DEFAULT
BEGIN
    BEGIN
        -- vamos buscar o plano pre-pago associado ao numero de telemovel
        SELECT ID_PLAN_AFTER_PAID INTO v_id_plano
        FROM CONTRACT_AFTER_PAID
        WHERE ID_PHONE_NUMBER_CONTRACT = phone_number_contract;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        -- se não existe plano pre-pago associado ao numero de tleemovel, vamos ver se existe pos pago
        v_tipo_plano := 1;
        SELECT ID_PLAN_BEFORE_PAID INTO v_id_plano
        FROM CONTRACT_BEFORE_PAID
        WHERE ID_PHONE_NUMBER_CONTRACT = phone_number_contract;
    END;

   -- se existir plano
    IF v_id_plano IS NOT NULL THEN
		RETURN v_id_plano;
    ELSE
        RAISE_APPLICATION_ERROR(-20516, 'Plano inexistente.');
    END IF;
END;


CREATE OR REPLACE FUNCTION f_aux_get_plan_type_by_phone_number
(
	phone_number_contract NUMBER
)
RETURN NVARCHAR2
IS
	v_id_plano NUMBER;
	v_tipo_plano NVARCHAR2 := 'pre-pago'; -- pre-pago BY DEFAULT
BEGIN
    BEGIN
        -- vamos buscar o plano pre-pago associado ao numero de telemovel
        SELECT ID_PLAN_AFTER_PAID INTO v_id_plano
        FROM CONTRACT_AFTER_PAID
        WHERE ID_PHONE_NUMBER_CONTRACT = phone_number_contract;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        -- se não existe plano pre-pago associado ao numero de tleemovel, vamos ver se existe pos pago
        v_tipo_plano := 'pos-pago';
        SELECT ID_PLAN_BEFORE_PAID INTO v_id_plano
        FROM CONTRACT_BEFORE_PAID
        WHERE ID_PHONE_NUMBER_CONTRACT = phone_number_contract;
    END;

   -- se existir plano
    IF v_id_plano IS NOT NULL THEN
		RETURN v_tipo_plano;
    ELSE
        RAISE_APPLICATION_ERROR(-20516, 'Plano inexistente.');
    END IF;
END;



CREATE OR REPLACE PROCEDURE a_emite_fatura (
    p_telefone varchar2,
    p_ano_mes varchar2
) AS
	v_telefone_normalized varchar2;
    v_id_phone_number_contract NUMBER;
   	v_type_plan NVARCHAR2;
    v_id_plano NUMBER;
    v_id_invoice NUMBER := 0;
    v_existe_fatura NUMBER;
    v_total_a_pagar NUMBER;
	v_total_calls NUMBER := 0; -- Declare a variável aqui
BEGIN
	-- normalized the phone number
	v_telefone_normalized := e_numero_normalizado(p_telefone);

	-- get the id plan from the id_phone_number_contract
	v_id_phone_number_contract := M_FUNC_2021110042_get_phone_number_contract_id(v_telefone_normalized);

	-- get the plan type
	v_type_plan := f_aux_get_plan_type_by_phone_number(v_id_phone_number_contract);
	
	-- get the plan id
	v_id_plano := f_aux_get_plan_id_by_phone_number(v_id_phone_number_contract);

	-- verify if there's already a invoice date associated to the phone number
	SELECT count(*) INTO v_existe_fatura
	FROM INVOICE i
	WHERE i.ID_PHONE_NUMBER_CONTRACT = v_id_phone_number_contract
	AND TO_CHAR(i.invoice_date, 'YYYY-MM') = p_ano_mes;
	
	IF v_existe_fatura = 0 THEN
		-- Insert a new invoice
		INSERT INTO INVOICE (ID_PHONE_NUMBER_CONTRACT, ID_CLIENT, VALUE)
		VALUES (v_id_phone_number_contract, (SELECT ID_CLIENT FROM PHONE_NUMBER_CONTRACT WHERE ID_PHONE_NUMBER_CONTRACT = v_id_phone_number_contract), v_total_a_pagar)
		RETURNING ID_INVOICE INTO v_id_invoice;
		
		-- Insert into INVOICE_RELLATION
		INSERT INTO INVOICE_RELLATION (ID_INVOICE, ID_INVOICE_SMS)
		VALUES ( v_id_invoice,
		(SELECT ins.ID_INVOICE_SMS FROM INVOICE_SMS ins
		WHERE TO_CHAR(ins.INVOICE_DATE,'YYYY-MM') = p_ano_mes
		AND ins.ID_PHONE_NUMBER_CONTRACT = v_id_phone_number_contract));

		INSERT INTO INVOICE_RELLATION (ID_INVOICE, ID_INVOICE_CALL)
		VALUES(v_id_invoice,
			(SELECT inc.ID_INVOICE_CALL FROM INVOICE_CALL inc
			WHERE TO_CHAR(inc.INVOICE_DATE,'YYYY-MM') = p_ano_mes
		AND inc.ID_PHONE_NUMBER_CONTRACT = v_id_phone_number_contract));

		-- Update the total
		SELECT SUM(ins.VALUE) 
		INTO v_total_a_pagar 
		FROM INVOICE_SMS ins
		WHERE ins.ID_INVOICE_SMS IN(
			SELECT ir.ID_INVOICE_SMS  FROM INVOICE_RELLATION ir
			WHERE ir.ID_INVOICE = v_id_invoice AND ir.ID_INVOICE_SMS IS NOT NULL
		);
		
		-- Add the cost of INVOICE_CALL
		SELECT SUM(inc.VALUE)
		INTO v_total_calls
		FROM INVOICE_CALL inc
		WHERE inc.ID_INVOICE_CALL IN (
			SELECT ir.ID_INVOICE_CALL  FROM INVOICE_RELLATION ir
			WHERE ir.ID_INVOICE = v_id_invoice AND ir.ID_INVOICE_CALL IS NOT NULL
		);
		
		-- Add the total calls to the total
		v_total_a_pagar := v_total_a_pagar + v_total_calls;

		-- Update the invoice value
		UPDATE INVOICE
		SET VALUE = v_total_a_pagar
		WHERE ID_INVOICE = v_id_invoice;
	
    ELSE
    	RAISE_APPLICATION_ERROR(-20501, 'A fatura para o período informado já existe.');
    END IF;
    
END;
