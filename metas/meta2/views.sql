/*
VIEW_A que, para cada contrato realizado no ano passado de um plano pós-pago, mostre a
quantidade e a duração total das chamadas realizadas, e a quantidade de SMS enviados,
considerando apenas os últimos 30 dias. Exclua os contratos cuja quantidade de chamadas seja
inferior à quantidade média de chamadas por contrato
*/

CREATE OR REPLACE VIEW VIEW_A AS
WITH last_year_contracts AS (
	SELECT c.* FROM CONTRACT c 
	INNER JOIN CONTRACT_AFTER_PAID cap ON c.ID_CONTRACT = cap.ID_CONTRACT 
    WHERE EXTRACT(YEAR FROM c.CREATED_AT) = EXTRACT(YEAR FROM SYSDATE) - 1
),
calls_stats AS (
    SELECT
        c.ID_CONTRACT,
        COUNT(cpnc.ID_CALL) AS QuantChamadas,
        SUM(cpnc.DURATION) AS Duracao_Chamadas
    FROM last_year_contracts c
    JOIN PHONE_NUMBER_CONTRACT pnc ON c.ID_CONTRACT = pnc.ID_CONTRACT
    JOIN CLIENT_PHONE_NUMBER_CALL cpnc ON pnc.ID_PHONE_NUMBER_CONTRACT = cpnc.ID_PHONE_NUMBER_CONTRACT
    WHERE cpnc.CREATED_AT >= SYSDATE - 30
    GROUP BY c.ID_CONTRACT
),
sms_stats AS (
    SELECT
        c.ID_CONTRACT,
        COUNT(s.ID_SMS) AS QuantSMS_Enviados
    FROM last_year_contracts c
    JOIN PHONE_NUMBER_CONTRACT pnc ON c.ID_CONTRACT = pnc.ID_CONTRACT
    JOIN SMS s ON pnc.ID_PHONE_NUMBER_CONTRACT = s.ID_PHONE_NUMBER_CONTRACT
    WHERE s.CREATED_AT >= SYSDATE - 30
    GROUP BY c.ID_CONTRACT
),
average_calls AS (
    SELECT AVG(QuantChamadas) AS Avg_Calls
    FROM calls_stats
)
SELECT
    c.ID_CONTRACT AS N_Contrato,
    c.CREATED_AT AS Data_Contrato,
    pnc.PHONE_NUMBER AS N_telefone,
    cs.QuantChamadas,
    cs.Duracao_Chamadas,
    ss.QuantSMS_Enviados
FROM last_year_contracts c
JOIN PHONE_NUMBER_CONTRACT pnc ON c.ID_CONTRACT = pnc.ID_CONTRACT
left JOIN calls_stats cs ON c.ID_CONTRACT = cs.ID_CONTRACT
left JOIN sms_stats ss ON c.ID_CONTRACT = ss.ID_CONTRACT
left JOIN average_calls ac ON cs.QuantChamadas >= ac.Avg_Calls;

/*
VIEW_B que, para cada plano, mostre a listagem dos clientes que terminam o período de
fidelização nos próximos 3 meses, em que a quantidade médio de chamadas por mês, dos últimos
3 meses completos, é inferior à quantidade médio de chamadas do total do período de fidelização.
Ordene o resultado descendentemente pela quantidade média de chamadas por mês. 
*/

CREATE OR REPLACE VIEW VIEW_B AS
WITH loyalty_period_end AS (
    SELECT
        c.ID_CLIENT,
        c.ID_CONTRACT,
        COALESCE(pap.DESIGNATION, pbp.DESIGNATION) AS Plano,
        c.CREATED_AT AS Data_Contrato,
        c.END_DATE  AS End_Loyalty_Period
    FROM CONTRACT c
    LEFT JOIN CONTRACT_AFTER_PAID cap ON cap.ID_CONTRACT = c.ID_CONTRACT
    LEFT JOIN CONTRACT_BEFORE_PAID cbp ON cbp.ID_CONTRACT = c.ID_CONTRACT
    LEFT JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID = pap.ID_PLAN_AFTER_PAID
    LEFT JOIN PLAN_BEFORE_PAID pbp ON cbp.ID_PLAN_BEFORE_PAID = pbp.ID_PLAN_BEFORE_PAID
    WHERE
        c.END_DATE  BETWEEN SYSDATE AND ADD_MONTHS(SYSDATE, 3)
),
calls_last_3_months AS (
    SELECT
        c.ID_CLIENT,
        COUNT(cpnc.ID_CALL) / 3 AS Avg_Calls_Last_3_Months
    FROM loyalty_period_end c
    JOIN PHONE_NUMBER_CONTRACT pnc ON c.ID_CONTRACT = pnc.ID_CONTRACT
    JOIN CLIENT_PHONE_NUMBER_CALL cpnc ON pnc.ID_PHONE_NUMBER_CONTRACT = cpnc.ID_PHONE_NUMBER_CONTRACT
    WHERE cpnc.CREATED_AT BETWEEN ADD_MONTHS(SYSDATE, -3) AND SYSDATE
    GROUP BY c.ID_CLIENT
),
calls_loyalty_period AS (
    SELECT
        c.ID_CLIENT,
        COUNT(cpnc.ID_CALL) / CEIL(MONTHS_BETWEEN(c.End_Loyalty_Period, c.Data_Contrato)) AS Avg_Calls_Period
    FROM loyalty_period_end c
    JOIN PHONE_NUMBER_CONTRACT pnc ON c.ID_CONTRACT = pnc.ID_CONTRACT
    JOIN CLIENT_PHONE_NUMBER_CALL cpnc ON pnc.ID_PHONE_NUMBER_CONTRACT = cpnc.ID_PHONE_NUMBER_CONTRACT
    WHERE cpnc.CREATED_AT BETWEEN c.Data_Contrato AND c.End_Loyalty_Period
    GROUP BY c.ID_CLIENT, c.Data_Contrato, c.End_Loyalty_Period
)
SELECT
    l.Plano,
    l.ID_CLIENT AS Num_Cliente,
    l.Data_Contrato,
    c3m.Avg_Calls_Last_3_Months AS N_Medio_Chamadas_3Meses,
    clp.Avg_Calls_Period AS N_Medio_mensal_total_periodo
FROM loyalty_period_end l
LEFT JOIN calls_last_3_months c3m ON l.ID_CLIENT = c3m.ID_CLIENT
LEFT JOIN calls_loyalty_period clp ON l.ID_CLIENT = clp.ID_CLIENT
WHERE c3m.Avg_Calls_Last_3_Months < clp.Avg_Calls_Period
ORDER BY c3m.Avg_Calls_Last_3_Months DESC;

/*
VIEW_C que, considerando apenas as chamadas no corrente ano realizadas por clientes de planos
pós-pagos, mostre apenas os números de destino que representam mais do que 50% das chamadas
realizadas por esse cliente. Ordene descendentemente pela percentagem de chamadas para esse
número.
*/
CREATE or replace VIEW VIEW_C AS
WITH current_year_calls AS (
    SELECT
        c.ID_CONTRACT AS Contrato,
        pap.DESIGNATION AS Plano,
        cl.FULL_NAME  AS Nome,
        pnc.PHONE_NUMBER AS Telefone,
        cpnc.TARGET_NUMBER  AS Destino,
        COUNT(cpnc.ID_CALL) AS Num_Chamadas
    FROM CLIENT cl
    JOIN CONTRACT c ON cl.ID_CLIENT = c.ID_CLIENT
    --JOIN PLAN p ON c.ID_PLAN_AFTER_PAID = p.ID_PLAN
    JOIN CONTRACT_AFTER_PAID cap ON cap.ID_CONTRACT = C.ID_CONTRACT
	JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID  =pap.ID_PLAN_AFTER_PAID  
    JOIN PHONE_NUMBER_CONTRACT pnc ON c.ID_CONTRACT = pnc.ID_CONTRACT
    JOIN CLIENT_PHONE_NUMBER_CALL cpnc ON pnc.ID_PHONE_NUMBER_CONTRACT = cpnc.ID_PHONE_NUMBER_CONTRACT
    WHERE EXTRACT(YEAR FROM cpnc.CREATED_AT) = EXTRACT(YEAR FROM SYSDATE)
    GROUP BY c.ID_CONTRACT, pap.DESIGNATION, cl.FULL_NAME, pnc.PHONE_NUMBER, cpnc.TARGET_NUMBER 
),
total_calls_per_client AS (
    SELECT
        Contrato,
        SUM(Num_Chamadas) AS Num_Chamadas_Total
    FROM current_year_calls
    GROUP BY Contrato
)
SELECT
    c.Contrato,
    c.Plano,
    c.Nome,
    c.Telefone,
    c.Destino,
    (c.Num_Chamadas * 100.0 / t.Num_Chamadas_Total) AS Percentagem,
    c.Num_Chamadas,
    t.Num_Chamadas_Total
FROM current_year_calls c
left JOIN total_calls_per_client t ON c.Contrato = t.Contrato
WHERE (c.Num_Chamadas * 100.0 / t.Num_Chamadas_Total) > 50
ORDER BY Percentagem DESC;

/*
VIEW_D que para cada plano, mostre a quantidade de contratos realizados e a quantidade de
contratos terminados (cancelados) em cada mês dos últimos 12 meses. Ordene pelo ano e mês
(numeral) e descendentemente pela quantidade de contratos realizados.
*/
CREATE VIEW VIEW_D AS
WITH monthly_new_contracts AS (
    SELECT
        TO_CHAR(c.CREATED_AT, 'YYYY-MM') AS Ano_Mes,
        COALESCE(pap.DESIGNATION, pbb.DESIGNATION) AS Plano,
        COUNT(c.ID_CONTRACT) AS Quantidade_Novos_Contratos
    FROM CONTRACT c
    LEFT JOIN CONTRACT_AFTER_PAID cap ON cap.ID_CONTRACT=c.ID_CONTRACT
    LEFT JOIN CONTRACT_BEFORE_PAID cbp ON cbp.ID_CONTRACT=c.ID_CONTRACT
    LEFT JOIN PLAN_AFTER_PAID pap ON pap.ID_PLAN_AFTER_PAID=cap.ID_CONTRACT_AFTER_PAID
    LEFT JOIN PLAN_BEFORE_PAID pbb ON pbb.ID_PLAN_TYPE_BEFORE_PAID=cbp.ID_CONTRACT_BEFORE_PAID
    WHERE c.CREATED_AT >= ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), -12)
    GROUP BY TO_CHAR(c.CREATED_AT, 'YYYY-MM'), COALESCE(pap.DESIGNATION, pbb.DESIGNATION)
),
monthly_terminated_contracts AS (
    SELECT
        TO_CHAR(cc.CANCELLATION_DATE, 'YYYY-MM') AS Ano_Mes,
        COALESCE(pap.DESIGNATION, pbb.DESIGNATION) AS Plano,
        COUNT(cc.ID_CONTRACT) AS Quantidade_Contratos_Terminados
    FROM CONTRACT_CANCELLATION cc
    JOIN CONTRACT c2 ON cc.ID_CONTRACT = c2.ID_CONTRACT
    LEFT JOIN CONTRACT_AFTER_PAID cap ON cap.ID_CONTRACT=cc.ID_CONTRACT
    LEFT JOIN CONTRACT_BEFORE_PAID cbp ON cbp.ID_CONTRACT=cc.ID_CONTRACT
    LEFT JOIN PLAN_AFTER_PAID pap ON pap.ID_PLAN_AFTER_PAID=cap.ID_CONTRACT_AFTER_PAID
    LEFT JOIN PLAN_BEFORE_PAID pbb ON pbb.ID_PLAN_TYPE_BEFORE_PAID=cbp.ID_CONTRACT_BEFORE_PAID
    WHERE cc.CANCELLATION_DATE >= ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), -12)
    GROUP BY TO_CHAR(cc.CANCELLATION_DATE, 'YYYY-MM'), COALESCE(pap.DESIGNATION, pbb.DESIGNATION)
)
SELECT
    COALESCE(nc.Ano_Mes, tc.Ano_Mes) AS Ano_Mes,
    COALESCE(nc.Plano, tc.Plano) AS Plano,
    COALESCE(nc.Quantidade_Novos_Contratos, 0) AS Quantidade_Novos_Contratos,
    COALESCE(tc.Quantidade_Contratos_Terminados, 0) AS Quantidade_Contratos_Terminados
FROM monthly_new_contracts nc
FULL OUTER JOIN monthly_terminated_contracts tc ON nc.Ano_Mes = tc.Ano_Mes AND nc.Plano = tc.Plano
ORDER BY Ano_Mes, Plano, Quantidade_Novos_Contratos DESC;


/*
VIEW_E que, identifique os dias da semana, e os períodos horários (de hora em hora) em que o
quantidade de chamadas é superior à média da quantidade de chamadas em cada hora desse dia.
Ordene por dia da semana (2ª a domingo) e descendentemente pela quantidade total de chamadas.
*/
CREATE OR REPLACE VIEW VIEW_E AS
WITH hourly_call_data AS (
    SELECT
        TO_CHAR(cpnc.CALL_ACCEPTED_DATE, 'D') AS Dia_Da_Semana,
        TO_CHAR(cpnc.CALL_ACCEPTED_DATE, 'HH24') AS Hora,
        COUNT(cpnc.ID_CALL) AS Quantidade_De_Chamadas
    FROM CLIENT_PHONE_NUMBER_CALL cpnc
    WHERE cpnc.CALL_ACCEPTED = 1
    GROUP BY TO_CHAR(cpnc.CALL_ACCEPTED_DATE , 'D'), TO_CHAR(cpnc.CALL_ACCEPTED_DATE, 'HH24')
),
hourly_call_average AS (
    SELECT
        Dia_Da_Semana,
        AVG(Quantidade_De_Chamadas) AS Quantidade_Media_Chamadas
    FROM hourly_call_data
    GROUP BY Dia_Da_Semana
)
SELECT
    hcd.Dia_Da_Semana,
    hcd.Hora,
    hcd.Quantidade_De_Chamadas,
    hca.Quantidade_Media_Chamadas
FROM hourly_call_data hcd
left JOIN hourly_call_average hca ON hcd.Dia_Da_Semana = hca.Dia_Da_Semana
WHERE hcd.Quantidade_De_Chamadas > hca.Quantidade_Media_Chamadas
ORDER BY hcd.Dia_Da_Semana, hcd.Hora DESC;


/*
    VISTA_F que, considerando a quantidade total de minutos das chamadas realizadas no mês
    anterior para destinos da rede fixa, mostre o top 10 dos clientes com maior quantidade total de
    minutos. Ordene descendentemente pela quantidade de minutos.
*/
CREATE OR REPLACE VIEW VISTA_F AS
WITH previous_month_data AS (
    SELECT
        EXTRACT(YEAR FROM SYSDATE) AS Ano,
        EXTRACT(MONTH FROM SYSDATE) - 1 AS Mes
        FROM DUAL
),
fixed_line_calls AS (
    SELECT
        c.ID_CLIENT,
        c.FULL_NAME AS Nome_Cliente,
        pnc.PHONE_NUMBER AS Telefone,
        TO_CHAR(pmd.Ano) || '-' || LPAD(TO_CHAR(pmd.Mes), 2, '0') AS Ano_Mes,
        SUM(ca.DURATION) AS Quant_Minutos,
        COUNT(ca.ID_CALL) AS Quant_Chamadas,
        COUNT(sms.ID_SMS) AS Quant_SMS
    FROM CLIENT c
    JOIN CLIENT_PHONE_NUMBER_CALL ca ON c.ID_CLIENT = ca.ID_CLIENT
    JOIN PHONE_NUMBER_CONTRACT pnc ON ca.ID_PHONE_NUMBER_CONTRACT=pnc.ID_PHONE_NUMBER_CONTRACT
    JOIN NETWORK n ON CA.ID_NETWORK=N.ID_NETWORK
    JOIN previous_month_data pmd ON EXTRACT(YEAR FROM ca.CALL_ACCEPTED_DATE) = pmd.Ano AND EXTRACT(MONTH FROM ca.CALL_ACCEPTED_DATE) = pmd.Mes
    LEFT JOIN SMS sms ON c.ID_CLIENT = sms.ID_CLIENT AND EXTRACT(YEAR FROM sms.SENT_DATE) = pmd.Ano AND EXTRACT(MONTH FROM sms.SENT_DATE) = pmd.Mes
    WHERE N.NAME = 'Fixo Nacional'
    GROUP BY c.ID_CLIENT, c.FULL_NAME , pnc.PHONE_NUMBER , pmd.Ano, pmd.Mes
)
SELECT
    f.Nome_Cliente,
    f.Telefone,
    f.Ano_Mes,
    f.Quant_Minutos,
    f.Quant_Chamadas,
    f.Quant_SMS
FROM fixed_line_calls f
ORDER BY f.Quant_Minutos DESC
FETCH FIRST 10 ROWS ONLY;


/*
VISTA_G que, considerando apenas os dados do ano atual, mostre para cliente a quantidade de
chamadas e o total a pagar pelas chamadas realizadas para a rede fixa e para a rede móvel. Ordene
descendentemente pela diferença da quantidade de chamadas entre rede fixa e rede móvel.
*/
CREATE OR REPLACE VIEW VISTA_G AS
WITH current_year_data AS (
    SELECT
        EXTRACT(YEAR FROM SYSDATE) AS Ano
        FROM DUAL
),
call_summary AS (
    SELECT
        c.ID_CLIENT,
        c.FULL_NAME  AS Nome_Cliente,
        SUM(CASE WHEN n.NAME  = 'Fixo Nacional' THEN 1 ELSE 0 END) AS Fixa_QuantChamada,
        SUM(CASE WHEN n.NAME  = 'Fixo Nacional' THEN ca.COST_VALUE  ELSE 0 END) AS Fixa_TotalPagar,
        SUM(CASE WHEN n.NAME  = 'Móvel Nacional' THEN 1 ELSE 0 END) AS Movel_QuantChamada,
        SUM(CASE WHEN n.NAME  = 'Móvel Nacional' THEN ca.COST_VALUE ELSE 0 END) AS Movel_TotalPagar
    FROM CLIENT c 
    JOIN CLIENT_PHONE_NUMBER_CALL  ca ON c.ID_CLIENT = ca.ID_CLIENT
    JOIN NETWORK n ON ca.ID_NETWORK=n.ID_NETWORK
    JOIN current_year_data cyd ON EXTRACT(YEAR FROM ca.CALL_ACCEPTED_DATE) = cyd.Ano
    GROUP BY c.ID_CLIENT, c.FULL_NAME 
)
SELECT
    cs.Nome_Cliente,
    cs.Fixa_QuantChamada,
    cs.Fixa_TotalPagar,
    cs.Movel_QuantChamada,
    cs.Movel_TotalPagar
FROM call_summary cs
ORDER BY (cs.Fixa_QuantChamada - cs.Movel_QuantChamada) DESC;


/*
VISTA_H que, para cada plano pós-pagos, mostre a quantidade, a duração total e o custo total das
chamadas, e também a quantidade e o custo total com o envio de SMS,. Ordene pela data em que
na viagem entraram na zona.
*/
CREATE OR REPLACE VIEW VISTA_H AS
WITH call_summary AS (
    SELECT
        pap.ID_PLAN_AFTER_PAID AS ID_PLAN,
        pap.NAME  AS Plano,
        COUNT(*) AS Quant_chamadas,
        SUM(ca.DURATION) AS Quant_minutos,
        SUM(ca.COST_VALUE) AS CustoChamadas
    FROM CONTRACT_AFTER_PAID cap
    JOIN contract c2 ON cap.ID_CONTRACT=c2.ID_CONTRACT
    JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID=pap.ID_PLAN_AFTER_PAID    
    JOIN CLIENT c ON c.ID_CLIENT=c2.ID_CLIENT
    JOIN CLIENT_PHONE_NUMBER_CALL ca ON c.ID_CLIENT = ca.ID_CLIENT
    GROUP BY pap.ID_PLAN_AFTER_PAID, pap.NAME 
),
sms_summary AS (
    SELECT
        pap.ID_PLAN_AFTER_PAID AS ID_PLAN,
        pap.NAME AS Plano,
        COUNT(*) AS Quant_SMS,
        SUM(s.COST_VALUE) AS Custo_SMS
    FROM CONTRACT_AFTER_PAID cap
    JOIN contract c2 ON cap.ID_CONTRACT=c2.ID_CONTRACT
    JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID=pap.ID_PLAN_AFTER_PAID    
    JOIN CLIENT c ON c.ID_CLIENT=c2.ID_CLIENT
    JOIN SMS s ON c.ID_CLIENT = s.ID_CLIENT
    GROUP BY  pap.ID_PLAN_AFTER_PAID, pap.NAME 
)
SELECT
    cs.Plano,
    cs.Quant_chamadas,
    cs.Quant_minutos,
    cs.CustoChamadas,
    ss.Quant_SMS,
    ss.Custo_SMS
FROM call_summary cs
LEFT JOIN sms_summary ss ON cs.ID_PLAN = ss.ID_PLAN
ORDER BY cs.ID_PLAN;

/*
    VISTA_I que para cada plano pós-pago com plafonds e para mês do ano de 2021, apresente a
    quantidade de minutos do plano, a quantidade média de minutos gastos por mês pelos clientes
    desse plano, e a percentagem média utilizada em cada mês. Mostre apenas os planos que, em cada
    mês, apresentam uma percentagem utilização inferior à média das percentagens dos planos.
    Ordene por mês (numeral), ascendentemente pela percentagem média de utilização. 
*/
CREATE OR REPLACE VIEW VISTA_I AS
WITH monthly_usage AS (
    SELECT
        EXTRACT(MONTH FROM cpnc.CREATED_AT) AS Mes,
        pap.NAME  AS Plano,
        pap.TOTAL_MINUTES  AS quant_minutos_plano,
        AVG(cpnc.DURATION) AS Quant_minutos_utilizado
    FROM PLAN_AFTER_PAID pap
    JOIN PLAN_TYPE_AFTER_PAID ptap ON pap.ID_PLAN_TYPE_AFTER_PAID=ptap.ID_PLAN_TYPE
    JOIN CONTRACT_AFTER_PAID cap ON pap.ID_PLAN_AFTER_PAID=cap.ID_PLAN_AFTER_PAID
    JOIN CONTRACT c ON cap.ID_CONTRACT=c.ID_CONTRACT
    JOIN CLIENT cl ON cl.ID_CLIENT=c.ID_CLIENT 
    JOIN PHONE_NUMBER_CONTRACT pnc ON pnc.ID_CONTRACT=c.ID_CONTRACT
    JOIN CLIENT_PHONE_NUMBER_CALL cpnc ON CPNC.ID_PHONE_NUMBER_CONTRACT=pnc.ID_PHONE_NUMBER_CONTRACT
    WHERE 
    		ptap.NAME = 'Com Plafond'
          AND EXTRACT(YEAR FROM cpnc.CREATED_AT) = 2021
    GROUP BY EXTRACT(MONTH FROM cpnc.CREATED_AT), pap.NAME, pap.TOTAL_MINUTES
),
avg_pct_usage AS (
    SELECT
        Mes,
        AVG(100 * Quant_minutos_utilizado / quant_minutos_plano) AS avg_percent_utilizacao
    FROM monthly_usage
    GROUP BY Mes
)
SELECT
    mu.Mes,
    mu.Plano,
    mu.quant_minutos_plano,
    mu.Quant_minutos_utilizado,
    100 * mu.Quant_minutos_utilizado / mu.quant_minutos_plano AS percent_utilizacao
FROM monthly_usage mu
JOIN avg_pct_usage apu ON mu.Mes = apu.Mes
WHERE 100 * mu.Quant_minutos_utilizado / mu.quant_minutos_plano < apu.avg_percent_utilizacao
ORDER BY mu.Mes ASC, (100 * mu.Quant_minutos_utilizado / mu.quant_minutos_plano) ASC;

/*
    VISTA_J que para cada campanha de grupos de amigos, calcule a quantidade total de chamadas
    realizadas entre números do grupo, o valor total dessas chamadas e o valor total de desconto
    atribuído a essas chamadas. Considere apenas as campanhas no último mês que terminou se tenha
    verificado um aumento da quantidade de aderentes superior a 10% em relação à quantidade de
    aderentes do mês anterior. Ordene descendentemente pela percentagem de crescimento. 
*/
CREATE OR REPLACE VIEW VISTA_J AS
WITH friend_group_usage AS (
	SELECT 
		c.NAME,
		count(cpnc.ID_CALL) AS total_calls,
		sum(cpnc.COST_VALUE) AS total_cost,
		SUM( cpnc.COST_VALUE * (c.DISCOUNT_VOICE_PERCENTAGE / 100) ) AS total_discount
	FROM PHONE_NUMBER_COMPAIGN pnc 
	JOIN CAMPAIGN c ON PNC.ID_CAMPAIGN=c.ID_CAMPAIGN 
	JOIN CLIENT_PHONE_NUMBER_CALL cpnc ON cpnc.ID_PHONE_NUMBER_CONTRACT=pnc.ID_PHONE_NUMBER_CONTRACT 
	WHERE cpnc.TARGET_NUMBER IN 
		(	
			SELECT pnc2.TARGET_PHONE_NUMBER  FROM PHONE_NUMBER_COMPAIGN pnc2 WHERE pnc2.ID_PHONE_NUMBER_CONTRACT =pnc.ID_PHONE_NUMBER_CONTRACT  AND pnc2.ID_CLIENT_CAMPAIGN=pnc.ID_CLIENT_CAMPAIGN 
		)
	GROUP BY c.NAME 
),
monthly_growth AS (
    SELECT
        c.NAME,
        COUNT(CASE WHEN EXTRACT(MONTH FROM pnc.CREATED_AT) <= EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -1)) THEN 1 END) AS current_month_members,
        COUNT(CASE WHEN EXTRACT(MONTH FROM pnc.CREATED_AT) < EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -2)) THEN 1 END) AS previous_month_members
    FROM PHONE_NUMBER_COMPAIGN pnc
    JOIN CAMPAIGN c ON pnc.ID_CAMPAIGN = c.ID_CAMPAIGN
    GROUP BY c.NAME
)
SELECT
    fgu.NAME,
    fgu.total_calls,
    fgu.total_cost,
    fgu.total_discount
FROM friend_group_usage fgu
JOIN monthly_growth mg ON fgu.NAME = mg.NAME
WHERE mg.current_month_members > 1.1 * mg.previous_month_members
ORDER BY 
(mg.current_month_members - mg.previous_month_members) / NULLIF(mg.previous_month_members, 0) DESC;

/*
 * VIEW_K_2021110042
 * resumo das informações relacionadas aos planos e números de telefone associados de cada cliente
 */
CREATE OR REPLACE VIEW VIEW_K_2021110042 AS
SELECT
  c.ID_CLIENT,
  c.FULL_NAME,
  COUNT(DISTINCT pa.ID_PLAN_AFTER_PAID) + COUNT(DISTINCT pb.ID_PLAN_BEFORE_PAID) AS TOTAL_PLANS,
  COUNT(DISTINCT pnc.ID_PHONE_NUMBER_CONTRACT) AS TOTAL_PHONE_NUMBERS
FROM
  CLIENT c
LEFT JOIN CONTRACT con ON con.ID_CLIENT = c.ID_CLIENT
LEFT JOIN PHONE_NUMBER_CONTRACT pnc ON pnc.ID_CONTRACT = con.ID_CONTRACT
LEFT JOIN CONTRACT_AFTER_PAID cap ON cap.ID_CONTRACT = con.ID_CONTRACT
LEFT JOIN CONTRACT_BEFORE_PAID cbp ON cbp.ID_CONTRACT = con.ID_CONTRACT
LEFT JOIN PLAN_AFTER_PAID pa ON pa.ID_PLAN_AFTER_PAID = cap.ID_PLAN_AFTER_PAID
LEFT JOIN PLAN_BEFORE_PAID pb ON pb.ID_PLAN_BEFORE_PAID = cbp.ID_PLAN_BEFORE_PAID
GROUP BY
  c.ID_CLIENT,
  c.FULL_NAME;

/*
 * VISTA VIEW_L_2021110042
 * Para cada cliente, mostra os contratos do número de telefone e os planos associados a esses números
*/

CREATE OR REPLACE VIEW VIEW_L_2021110042 AS
SELECT
  c.ID_CLIENT,
  c.FULL_NAME,
  pnc.ID_PHONE_NUMBER_CONTRACT,
  pnc.PHONE_NUMBER,
  COALESCE(pbp.NAME,pap.NAME ) AS PLAN,
COALESCE(pbp.DESIGNATION,pap.DESIGNATION ) AS DESIGNATION
FROM
  CLIENT c
JOIN CONTRACT con ON c.ID_CLIENT = con.ID_CLIENT
JOIN PHONE_NUMBER_CONTRACT pnc ON con.ID_CONTRACT = pnc.ID_CONTRACT
LEFT JOIN CONTRACT_BEFORE_PAID cbp ON con.ID_CONTRACT = cbp.ID_CONTRACT AND pnc.ID_PHONE_NUMBER_CONTRACT = cbp.ID_PHONE_NUMBER_CONTRACT
LEFT JOIN PLAN_BEFORE_PAID pbp ON cbp.ID_PLAN_BEFORE_PAID = pbp.ID_PLAN_BEFORE_PAID
LEFT JOIN CONTRACT_AFTER_PAID cap ON con.ID_CONTRACT = cap.ID_CONTRACT AND pnc.ID_PHONE_NUMBER_CONTRACT = cap.ID_PHONE_NUMBER_CONTRACT
LEFT JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID = pap.ID_PLAN_AFTER_PAID
ORDER BY
  c.ID_CLIENT,
  pnc.ID_PHONE_NUMBER_CONTRACT;


/*
    VISTA VIEW_M_2021110042
 * View  para verificar se todos os números de telefone de um contrato foram cancelados com sucesso
 * estamos a comparar os números de telefone cancelados associados ao contrato com os números de telefone do contrato
*/
CREATE OR REPLACE VIEW VIEW_M_2021110042 AS
SELECT
  cc.ID_CONTRACT_CANCELLATION,
  c.ID_CLIENT,
  c.FULL_NAME,
  cc.ID_CONTRACT,
  cc.CANCELLATION_DATE,
  COUNT(DISTINCT pncc.ID_PHONE_NUMBER_CONTRACT_CANCELLATION) AS NUM_PHONE_NUMBERS_CANCELLED,
  COUNT(DISTINCT pnc.ID_PHONE_NUMBER_CONTRACT) AS NUM_PHONE_NUMBERS,
  CASE
    WHEN COUNT(DISTINCT pncc.ID_PHONE_NUMBER_CONTRACT_CANCELLATION) = COUNT(DISTINCT pnc.ID_PHONE_NUMBER_CONTRACT) THEN 'Y'
    ELSE 'N'
  END AS ALL_PHONES_CANCELLED
FROM
  CONTRACT_CANCELLATION cc
  JOIN CLIENT c ON cc.ID_CLIENT = c.ID_CLIENT
  JOIN PHONE_NUMBER_CONTRACT_CANCELLATION pncc ON cc.ID_CONTRACT = pncc.ID_CONTRACT
  JOIN PHONE_NUMBER_CONTRACT pnc ON cc.ID_CONTRACT = pnc.ID_CONTRACT
GROUP BY
  cc.ID_CONTRACT_CANCELLATION,
  c.ID_CLIENT,
  c.FULL_NAME,
  cc.ID_CONTRACT,
  cc.CANCELLATION_DATE;


/*
    *
    * VISTA VIEW_N_2021110042
    * View para verificar os depositos nao processados para o balance
*/
CREATE OR REPLACE VIEW VIEW_N_2021110042 AS
SELECT 
PND.ID_CONTRACT, pnc.PHONE_NUMBER  AS PHONE_NUMBER, pnc.ID_PHONE_NUMBER_CONTRACT, SUM(PND.VALUE) AS VALUE
FROM PHONE_NUMBER_DEPOSITS pnd
JOIN PHONE_NUMBER_CONTRACT pnc ON Pnd.ID_PHONE_NUMBER_CONTRACT=pnc.ID_PHONE_NUMBER_CONTRACT 
WHERE pnd.PROCESSED = 0
GROUP BY PND.ID_CONTRACT,PNC.PHONE_NUMBER ,pnc.ID_PHONE_NUMBER_CONTRACT;


/*
    *
    * VISTA VIEW_O_2021110042
    * View de tarifarios de numeros de telemovel pre-pagos
*/

CREATE OR REPLACE VIEW VIEW_O_2021110042
AS
SELECT 
	C2.ID_CLIENT,
	c.ID_CONTRACT,
	cap.ID_PHONE_NUMBER_CONTRACT,
	cap.ID_CONTRACT_AFTER_PAID,
	papt.ID_PLAN_AFTER_PAID_TARRIF,
	pnc.PHONE_NUMBER,
	t.NAME AS TARIFF,
	t.MONEY_PER_UNIT,
	tut.NAME  AS UNIT_TYPE
	FROM CONTRACT_AFTER_PAID cap
	JOIN PHONE_NUMBER_CONTRACT pnc ON cap.ID_PHONE_NUMBER_CONTRACT=pnc.ID_PHONE_NUMBER_CONTRACT
    JOIN CONTRACT C ON cap.ID_CONTRACT =c.ID_CONTRACT	
    JOIN CLIENT c2 ON c.ID_CLIENT=c2.ID_CLIENT
    JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID=pap.ID_PLAN_AFTER_PAID
    JOIN PLAN_AFTER_PAID_TARRIF papt ON PAPT.ID_PLAN_AFTER_PAID=pap.ID_PLAN_AFTER_PAID
	JOIN TARRIF t ON t.ID_TARRIF = PAPT.ID_TARRIF 
	JOIN TARRIF_UNIT_TYPE tut ON t.ID_UNIT_TYPE=tut.ID_TARRIF_UNIT_TYPE 
WHERE 
	t.IS_ACTIVE=1 AND c.IS_ACTIVE=1;

/*
    *
    * VISTA VIEW_P_2021110042
    * View de tarifarios de numeros de telemovel pos-pagos
*/

CREATE OR REPLACE VIEW VIEW_P_2021110042
AS
SELECT 
    C2.ID_CLIENT,
    c.ID_CONTRACT,
    cbp.ID_PHONE_NUMBER_CONTRACT,
    cbp.ID_CONTRACT_BEFORE_PAID,
    pbpt.ID_PLAN_BEFORE_PAID_TARRIF,
    pnc.PHONE_NUMBER,
    t.NAME AS TARIFF,
    t.MONEY_PER_UNIT,
    tut.NAME  AS UNIT_TYPE
    FROM CONTRACT_BEFORE_PAID cbp
    JOIN PHONE_NUMBER_CONTRACT pnc ON cbp.ID_PHONE_NUMBER_CONTRACT=pnc.ID_PHONE_NUMBER_CONTRACT
    JOIN CONTRACT C ON cbp.ID_CONTRACT =c.ID_CONTRACT	
    JOIN CLIENT c2 ON c.ID_CLIENT=c2.ID_CLIENT
    JOIN PLAN_BEFORE_PAID pbp ON cbp.ID_PLAN_BEFORE_PAID=pbp.ID_PLAN_BEFORE_PAID
    JOIN PLAN_BEFORE_PAID_TARRIF pbpt ON PBPT.ID_PLAN_BEFORE_PAID=pbp.ID_PLAN_BEFORE_PAID
    JOIN TARRIF t ON t.ID_TARRIF = PBPT.ID_TARRIF 
    JOIN TARRIF_UNIT_TYPE tut ON t.ID_UNIT_TYPE=tut.ID_TARRIF_UNIT_TYPE 
WHERE 
	t.IS_ACTIVE=1 AND c.IS_ACTIVE=1;
