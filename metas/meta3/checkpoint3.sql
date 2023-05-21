/**
Crie o procedimento a_emite_fatura que recebe como argumento um número de telefone e o ano mês
do período de faturação (ano_mes no formato ‘yyyy-mm’) e se número estiver associado um plano póspago deve emitir e registar os dados da fatura desse período, se esta ainda não existir. Além da data
da emissão, a fatura deve conter o montante a pagar considerando o plano contratado, tarifário
aplicável, ... , e as chamadas e SMS enviados no período. A fatura deve incluir/descriminar a duração
e o custo de cada chamada realizado no período e o custo de cada SMS enviado. Algumas exceções
que poderão ser lançadas: -20501 , -20502 , -20510 , -20511 , -20512 , -20513
*/

CREATE OR REPLACE PROCEDURE a_emite_fatura (
    p_telefone IN VARCHAR2,
    p_ano_mes IN VARCHAR2
) AS
    v_id_contrato NUMBER;
    v_id_cliente NUMBER;
    v_id_plano NUMBER;
    v_total_a_pagar NUMBER;
    v_existe_fatura NUMBER;
    v_ano NUMBER;
    v_mes NUMBER;
BEGIN
    -- Get the contract ID
    SELECT c.id_contract, c.id_client INTO v_id_contrato, v_id_cliente
    FROM contract c
    JOIN phone_number_contract pnc ON pnc.id_contract = c.id_contract
    WHERE pnc.phone_number = p_telefone;
    
    -- Get the plan
    SELECT cap.id_plan_after_paid INTO v_id_plano
    FROM contract_after_paid cap
    WHERE cap.id_contract = v_id_contrato;
    
    -- Check if the invoice already exists
    SELECT COUNT(*) INTO v_existe_fatura
    FROM invoice i
    WHERE i.id_contract = v_id_contrato
    AND i.invoice_date = TO_DATE(p_ano_mes, 'YYYY-MM');
    
    -- If the invoice does not exist, create it
    IF v_existe_fatura = 0 THEN
        v_ano := TO_NUMBER(SUBSTR(p_ano_mes, 1, 4));
        v_mes := TO_NUMBER(SUBSTR(p_ano_mes, 6, 2));
        
        -- Calculate the total amount to pay
        SELECT SUM(c.cost_value) INTO v_total_a_pagar
        FROM client_phone_number_call c
        WHERE c.id_client = v_id_cliente
        AND EXTRACT(YEAR FROM c.created_at) = v_ano
        AND EXTRACT(MONTH FROM c.created_at) = v_mes;
        
        -- Create the invoice
        INSERT INTO invoice (id_invoice, id_client, id_contract, id_plan_after_paid, invoice_date, total_to_pay)
        VALUES (invoice_seq.NEXTVAL, v_id_cliente, v_id_contrato, v_id_plano, TO_DATE(p_ano_mes, 'YYYY-MM'), v_total_a_pagar);
        
    -- If the invoice already exists, raise an exception
    ELSE
        RAISE_APPLICATION_ERROR(-20501, 'A fatura para o período informado já existe.');
    END IF;
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20502, 'Não foi possível encontrar um contrato ou plano para o número de telefone fornecido.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20510, 'Ocorreu um erro inesperado ao emitir a fatura: ' || SQLERRM);
END;


/**
Crie a função b_custo_da_chamada que recebe como argumento o identificador de uma chamada, e calcula
o custo dessa chamada tomando em consideração o plano contratado e do tarifário aplicável ao número de
telefone que efetuou a chamada. Algumas exceções que poderão ser lançadas: -20514
FUNCTION b_custo_da_chamada (idChamada NUMBER) return NUMBER
*/

CREATE OR REPLACE FUNCTION b_custo_da_chamada(idChamada NUMBER)
RETURN NUMBER IS
    v_custo NUMBER;
    v_duracao NUMBER;
    v_tipo_plano NUMBER;
    v_id_contrato NUMBER;
    v_id_tarifa NUMBER;
BEGIN
    SELECT duration INTO v_duracao
    FROM CLIENT_PHONE_NUMBER_CALL
    WHERE ID_CALL = idChamada;

    SELECT ID_CONTRACT INTO v_id_contrato
    FROM CLIENT_PHONE_NUMBER_CALL
    WHERE ID_CALL = idChamada;

    SELECT ID_PLAN_AFTER_PAID INTO v_tipo_plano
    FROM CONTRACT_AFTER_PAID
    WHERE ID_CONTRACT = v_id_contrato;

    IF v_tipo_plano IS NULL THEN
        SELECT ID_PLAN_BEFORE_PAID INTO v_tipo_plano
        FROM CONTRACT_BEFORE_PAID
        WHERE ID_CONTRACT = v_id_contrato;
    END IF;

    IF v_tipo_plano IS NOT NULL THEN
        SELECT ID_TARRIF INTO v_id_tarifa
        FROM PLAN_AFTER_PAID_TARRIF
        WHERE ID_PLAN_AFTER_PAID = v_tipo_plano;

        IF v_id_tarifa IS NULL THEN
            SELECT ID_TARRIF INTO v_id_tarifa
            FROM PLAN_BEFORE_PAID_TARRIF
            WHERE ID_PLAN_BEFORE_PAID = v_tipo_plano;
        END IF;

        IF v_id_tarifa IS NOT NULL THEN
            SELECT MONEY_PER_UNIT INTO v_custo
            FROM TARRIF
            WHERE ID_TARRIF = v_id_tarifa;
        ELSE
            RAISE_APPLICATION_ERROR(-20514, 'Tarifa não encontrada');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20514, 'Plano não encontrado');
    END IF;

    RETURN v_custo * v_duracao;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20514, 'Dados não encontrados');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20514, 'Erro desconhecido');
END;

/**
Crie a função c_preco_por_minuto que recebe como argumento o número de telefone de origem (quem
efetua a chamada) e o número de telefone de destino, e calcula qual o preço por minuto dessa chamada
tomando em consideração o plano contratado e do tarifário aplicável ao número de telefone de origem.
Algumas exceções que poderão ser lançadas: -20501 , -20502 , -20510 , -20511
*/

CREATE OR REPLACE FUNCTION c_preco_por_minuto(p_origem_phone_number IN VARCHAR2, p_destino_phone_number IN VARCHAR2) 
RETURN NUMBER IS 
  v_preco_por_minuto NUMBER(10,3); 
  v_id_origem_contract NUMBER(10); 
  v_id_destino_network NUMBER(10); 

BEGIN 

  SELECT ID_CONTRACT INTO v_id_origem_contract 
  FROM PHONE_NUMBER_CONTRACT
  WHERE PHONE_NUMBER = p_origem_phone_number; 
  
  SELECT ID_NETWORK INTO v_id_destino_network 
  FROM NETWORK
  WHERE PREFIX = SUBSTR(p_destino_phone_number, 1, 2); -- assumindo que os dois primeiros dígitos são o prefixo da rede

  SELECT MONEY_PER_UNIT INTO v_preco_por_minuto 
  FROM TARRIF t 
  INNER JOIN PLAN_AFTER_PAID_TARRIF pat ON t.ID_TARRIF = pat.ID_TARRIF
  INNER JOIN CONTRACT_AFTER_PAID cap ON pat.ID_PLAN_AFTER_PAID = cap.ID_PLAN_AFTER_PAID
  WHERE cap.ID_CONTRACT = v_id_origem_contract
  AND t.ID_NETWORK = v_id_destino_network 
  AND t.ID_COMMUNICATION_TYPE = (SELECT ID_COMMUNICATION_TYPE FROM COMMUNICATION_TYPE WHERE NAME = 'VOZ') 
  AND t.IS_ACTIVE = 1; 

  EXCEPTION
    WHEN NO_DATA_FOUND THEN 
      RAISE_APPLICATION_ERROR(-20501,'Erro: Não foi possível encontrar dados');
    WHEN TOO_MANY_ROWS THEN
      RAISE_APPLICATION_ERROR(-20502,'Erro: Mais de uma linha retornada');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20510,'Erro: Outro erro ocorreu');
  
  RETURN v_preco_por_minuto; 

END c_preco_por_minuto; 


/*
 Crie a função d_tipo_de_chamada_voz que recebe como argumento um número de telefone de destino, e
que valida se é um número de uma gama válida e caso seja, retorna o tipo de destino. Algumas exceções
que poderão ser lançadas: -20501 , -20502 , -20505 , -20511 , -20515
FUNCTION d_tipo_de_chamada_voz (num_telefone VARCHAR) return VARCHAR
*/
CREATE OR REPLACE FUNCTION d_tipo_de_chamada_voz(num_telefone VARCHAR2) 
RETURN VARCHAR2 IS
    num_normalizado VARCHAR2(20);
    tipo_destino VARCHAR2(100);
BEGIN
    num_normalizado := e_numero_normalizado(num_telefone);

    SELECT NAME INTO tipo_destino
    FROM NETWORK
    WHERE SUBSTR(num_normalizado, 1, LENGTH(PREFIX)) = PREFIX;
    
    RETURN tipo_destino;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20501, 'Número de telefone não encontrado em nenhuma gama válida.');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20502, 'Número de telefone encontrado em mais de uma gama.');
    WHEN VALUE_ERROR THEN
        RAISE_APPLICATION_ERROR(-20505, 'Erro na validação do número de telefone.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20515, 'Erro inesperado: ' || SQLERRM);
END;
/


/**
Crie a função e_numero_normalizado que recebe como argumento um número de telefone, retorna o
número de telefone de acordo com as regras de normalização definidas (ver tabela 8). Pode lançar as
exceções: -20502
FUNCTION e_numero_normalizado (num_telefone VARCHAR) return VARCHAR
*/

CREATE OR REPLACE FUNCTION e_numero_normalizado(num_telefone VARCHAR2) 
RETURN VARCHAR2 IS
    num_normalizado VARCHAR2(20);
BEGIN
    -- Remove all non-numeric characters
    num_normalizado := REGEXP_REPLACE(num_telefone, '[^0-9]', '');
    
    -- Normalization rules
    IF num_normalizado LIKE '00351%' THEN
        num_normalizado := SUBSTR(num_normalizado, 6);
    ELSIF num_normalizado LIKE '0044%' THEN
        num_normalizado := SUBSTR(num_normalizado, 5);
    END IF;
    
    -- Error handling
    IF LENGTH(num_normalizado) < 9 THEN
        RAISE_APPLICATION_ERROR(-20502, 'Invalid phone number');
    END IF;

    RETURN num_normalizado;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20502, 'Unexpected error: ' || SQLERRM);
END;


/**
Crie o procedimento f_envia_SMS que recebe como argumento um número de telefone de origem, o número
de telefone de destino e a mensagem e regista o envio dessa mensagem. Algumas exceções que poderão
ser lançadas: -20501 , -20502 , -20508 , -20511
PROCEDURE f_envia_SMS (num_de_origem VARCHAR, num_de_destino VARCHAR, mensagem VARCHAR) 

*/
CREATE OR REPLACE PROCEDURE f_envia_SMS (
    num_de_origem IN VARCHAR,
    num_de_destino IN VARCHAR,
    mensagem IN VARCHAR
) IS
    origem_exists NUMBER;
    destino_exists NUMBER;
BEGIN
    -- Check if the origin number exists
    SELECT COUNT(*) INTO origem_exists 
    FROM PHONE_NUMBER_CONTRACT 
    WHERE PHONE_NUMBER = num_de_origem;

    IF origem_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20501, 'Origin number does not exist');
    END IF;

    -- Check if the destination number exists
    SELECT COUNT(*) INTO destino_exists 
    FROM PHONE_NUMBER_CONTRACT 
    WHERE PHONE_NUMBER = num_de_destino;

    IF destino_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20502, 'Destination number does not exist');
    END IF;

    -- Other validations with other exception codes (-20508, -20511) can be inserted here

    -- Insert into SMS table
    INSERT INTO SMS(NUM_DE_ORIGEM, NUM_DE_DESTINO, MENSAGEM)
    VALUES (num_de_origem, num_de_destino, mensagem);

    -- Save changes
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END f_envia_SMS;


/* Procedimento g_estabelece_chamada */
CREATE OR REPLACE PROCEDURE g_estabelece_chamada(num_de_origem VARCHAR, num_de_destino VARCHAR) AS
v_id_client NUMBER;
v_id_phone_contract NUMBER;
v_phone_status NUMBER;
BEGIN
	-- Get the client and phone contract id
	SELECT ID_CLIENT, ID_PHONE_NUMBER_CONTRACT 
	INTO v_id_client, v_id_phone_contract 
	FROM PHONE_NUMBER_CONTRACT 
	WHERE PHONE_NUMBER = num_de_origem;

	-- Check if the phone number can make a call
	SELECT STATUS_TYPE 
	INTO v_phone_status 
	FROM PHONE_NUMBER_STATUS 
	WHERE ID_PHONE_NUMBER_CONTRACT = v_id_phone_contract 
	ORDER BY CREATED_AT DESC FETCH FIRST ROW ONLY;

	IF v_phone_status != 1 THEN -- assuming 1 as an active status
		RAISE_APPLICATION_ERROR(-20501, 'The phone number cannot make calls at this moment.');
	END IF;

	-- Register the call
	INSERT INTO CLIENT_PHONE_NUMBER_CALL(ID_CLIENT, ID_PHONE_NUMBER_CONTRACT, TARGET_NUMBER, ID_STATUS_TYPE) 
	VALUES (v_id_client, v_id_phone_contract, num_de_destino, 1); -- Assuming 1 as the "Call Initiated" status

	-- Log the event
	DBMS_OUTPUT.PUT_LINE('Call Initiated: From '|| num_de_origem ||' to '|| num_de_destino);

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20502, 'Invalid origin number.');
	WHEN OTHERS THEN
		RAISE_APPLICATION_ERROR(-20508, SQLERRM);
END g_estabelece_chamada;



/*
Crie a função h_pode_realizar_a_chamada, que recebe como argumento um número de origem e um
número de destino e verifica se o número que origina a chamada pode realizar essa chamada. Caso
seja possível, deve retornar o tipo de rede do número de destino (ver tabela 7). Algumas exceções que
poderão ser lançadas: -20501 , -20502 , -20508, -20511
FUNCTION h_pode_realizar_a_chamada (num_de_origem, num_de_destino) return VARCHAR
*/
CREATE OR REPLACE FUNCTION h_pode_realizar_a_chamada(num_de_origem NVARCHAR2, num_de_destino NVARCHAR2) RETURN NVARCHAR2
IS
    v_rede_destino NVARCHAR2(255);
    v_status_origem NUMBER;
    v_status_destino NUMBER;
BEGIN
    -- Verifica se o número de origem está ativo
    SELECT STATUS_TYPE INTO v_status_origem 
    FROM PHONE_NUMBER_STATUS 
    WHERE ID_PHONE_NUMBER_CONTRACT IN (
        SELECT ID_PHONE_NUMBER_CONTRACT FROM PHONE_NUMBER_CONTRACT WHERE PHONE_NUMBER = num_de_origem)
    ORDER BY CREATED_AT DESC FETCH FIRST ROW ONLY;
    
    IF v_status_origem <> 1 THEN
        RAISE_APPLICATION_ERROR(-20501, 'O número de origem não está ativo');
    END IF;
    
    -- Verifica se o número de destino está ativo
    SELECT STATUS_TYPE INTO v_status_destino 
    FROM PHONE_NUMBER_STATUS 
    WHERE ID_PHONE_NUMBER_CONTRACT IN (
        SELECT ID_PHONE_NUMBER_CONTRACT FROM PHONE_NUMBER_CONTRACT WHERE PHONE_NUMBER = num_de_destino)
    ORDER BY CREATED_AT DESC FETCH FIRST ROW ONLY;
    
    IF v_status_destino <> 1 THEN
        RAISE_APPLICATION_ERROR(-20502, 'O número de destino não está ativo');
    END IF;

    -- Retorna o tipo de rede do número de destino
    SELECT NAME INTO v_rede_destino 
    FROM NETWORK
    WHERE ID_NETWORK IN (
        SELECT ID_NETWORK FROM PHONE_NUMBER_CONTRACT WHERE PHONE_NUMBER = num_de_destino);

    RETURN v_rede_destino;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20508, 'Número de origem ou destino não encontrado');
    WHEN TOO_MANY_ROWS THEN
        RAISE_APPLICATION_ERROR(-20511, 'Mais de um número de origem ou destino encontrado');
END;


/**
Crie o trigger i_atualiza_saldo que quanto é registado o término de uma chamada, e de acordo
com o plano contratado, o tarifário aplicável ao número que realizou a chamada, o tipo de chamada, o
tipo de destino e a duração atualize o saldo associado a esse número de telefone (ver 2.1 a 2.4).
TRIGGER atualiza_saldo
*/
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

    -- Registre o depósito feito
    INSERT INTO PHONE_NUMBER_DEPOSITS
    (ID_CONTRACT, ID_PHONE_NUMBER_CONTRACT, VALUE, CREATED_AT, PROCESSED)
    VALUES
    (:NEW.ID_CLIENT, :NEW.ID_PHONE_NUMBER_CONTRACT, -1 * :NEW.COST_VALUE, SYSDATE, 1);
END;


/*
Crie a função j_get_saldo, que recebe como argumento o número de telefone e o tipo de saldo (valor,
voz (número de mínimos) ou SMS (número de SMS)) e devolve o respetivo saldo disponível. O tipo
de saldo por defeito é valor. Algumas exceções que poderão ser lançadas: -20501 , -20502 , -20519
FUNCTION j_get_saldo (numero VARCHAR, tipo VARCHAR) return NUMBER
*/

CREATE OR REPLACE FUNCTION j_get_saldo (numero VARCHAR, tipo VARCHAR DEFAULT 'valor') 
RETURN NUMBER 
IS
  v_saldo NUMBER;
BEGIN
  IF tipo = 'valor' THEN
    SELECT balance INTO v_saldo
    FROM PHONE_NUMBER_CONTRACT
    WHERE phone_number = numero;
  ELSIF tipo = 'voz' THEN
    SELECT voice_balance INTO v_saldo
    FROM PHONE_NUMBER_CONTRACT
    WHERE phone_number = numero;
  ELSIF tipo = 'SMS' THEN
    SELECT sms_balance INTO v_saldo
    FROM PHONE_NUMBER_CONTRACT
    WHERE phone_number = numero;
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


/*
Crie o procedimento k_novo_contrato que recebe como argumento o NIF e o nome do cliente, o nome
do plano contratado e o número de meses do período de fidelização, e regista esse contrato com a data
de hoje, a define a data de término de acordo com o período de fidelização, atribui um novo número
de telefone, que ainda não esteja atribuído, e regista o inicio do período de faturação. Por fim, deve
enviar um SMS de boas vindas para esse número, com a mensagem “Bem vindo “ + primeiro nome
do cliente. Algumas exceções que poderão ser lançadas: -20517 , -20518 , -20516 , ...
PROCEDURE k_novo_contrato (nif VARCHAR, nome VARCHAR, plano VARCHAR, periodo_meses NUMBER)

*/
CREATE OR REPLACE PROCEDURE k_novo_contrato (
    p_nif VARCHAR, 
    p_nome VARCHAR, 
    p_plano VARCHAR, 
    p_periodo_meses NUMBER
) AS
  v_id_client NUMBER;
  v_id_contract NUMBER;
  v_id_phone_number NUMBER;
  v_id_plan NUMBER;
  v_welcome_message VARCHAR2(255);
BEGIN
  -- Verificar se o cliente já existe, se não, criar um novo
  SELECT id_client
  INTO v_id_client
  FROM client
  WHERE nif = p_nif;

  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    INSERT INTO client (nif, name)
    VALUES (p_nif, p_nome)
    RETURNING id_client INTO v_id_client;
  END;

  -- Obter o id do plano
  SELECT id_plan
  INTO v_id_plan
  FROM plan
  WHERE name = p_plano;

  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20517, 'O plano fornecido não existe');
  END;

  -- Criar um novo contrato
  INSERT INTO contract (id_client, id_plan, start_date, end_date)
  VALUES (v_id_client, v_id_plan, SYSDATE, ADD_MONTHS(SYSDATE, p_periodo_meses))
  RETURNING id_contract INTO v_id_contract;

  -- Atribuir um novo número de telefone
  SELECT id_phone_number
  INTO v_id_phone_number
  FROM phone_number
  WHERE is_assigned = 0
    AND ROWNUM = 1;

  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20518, 'Não há números de telefone disponíveis');
  END;

  UPDATE phone_number
  SET is_assigned = 1
  WHERE id_phone_number = v_id_phone_number;

  -- Registar o início do período de faturação
  INSERT INTO billing_period (id_contract, start_date)
  VALUES (v_id_contract, SYSDATE);

  -- Enviar um SMS de boas vindas
  v_welcome_message := 'Bem vindo ' || SUBSTR(p_nome, 1, INSTR(p_nome, ' ') - 1);
  
  INSERT INTO client_sms (id_client, phone_number, message)
  VALUES (v_id_client, v_id_phone_number, v_welcome_message);

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20516, SQLERRM);
END k_novo_contrato;



/*
Crie um trigger l_carrega_cartao_prepago, que quanto é registado o carregamento de um número de
telefone associado a plano pré-pago, deve acumular os saldos de acordo com o definido para o plano
e registar o inicio de um novo período de faturação com a duração prevista no plano.
TRIGGER l_carrega_cartao_prepago
*/

CREATE OR REPLACE TRIGGER l_carrega_cartao_prepago
AFTER INSERT ON prepaid_card
FOR EACH ROW
DECLARE
  v_id_plan NUMBER;
  v_billing_period_duration NUMBER;
BEGIN
  -- Obter o id do plano e a duração do período de faturação
  SELECT pnc.id_plan, p.duration
  INTO v_id_plan, v_billing_period_duration
  FROM phone_number_contract pnc
  JOIN plan p ON pnc.id_plan = p.id_plan
  WHERE pnc.id_phone_number = :NEW.id_phone_number;

  -- Acumular o saldo
  UPDATE phone_number_contract
  SET balance = balance + :NEW.amount
  WHERE id_phone_number = :NEW.id_phone_number;

  -- Registar o início de um novo período de faturação
  INSERT INTO billing_period (id_plan, start_date, end_date)
  VALUES (v_id_plan, SYSDATE, ADD_MONTHS(SYSDATE, v_billing_period_duration));
EXCEPTION
  WHEN OTHERS THEN
    -- Lidar com outros erros inesperados
    RAISE;
END;
