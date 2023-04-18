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
JOIN calls_stats cs ON c.ID_CONTRACT = cs.ID_CONTRACT
JOIN sms_stats ss ON c.ID_CONTRACT = ss.ID_CONTRACT
JOIN average_calls ac ON cs.QuantChamadas >= ac.Avg_Calls;


/*
VIEW_B que, para cada plano, mostre a listagem dos clientes que terminam o período de
fidelização nos próximos 3 meses, em que a quantidade médio de chamadas por mês, dos últimos
3 meses completos, é inferior à quantidade médio de chamadas do total do período de fidelização.
Ordene o resultado descendentemente pela quantidade média de chamadas por mês. 
*/

CREATE VIEW VIEW_B AS
WITH loyalty_period_end AS (
    SELECT
        c.ID_CLIENT,
        c.ID_CONTRACT,
        pap.DESIGNATION AS Plano_PRE_PAGO,
        pbp.DESIGNATION AS Plano_POS_PAGO,
        c.CREATED_AT AS Data_Contrato,
        c.LOYALTY_DATE  AS End_Loyalty_Period
    FROM CONTRACT c
    JOIN CONTRACT_AFTER_PAID cap ON cap.ID_CONTRACT = c.ID_CONTRACT
    JOIN CONTRACT_BEFORE_PAID cbp ON cbp.ID_CONTRACT = c.ID_CONTRACT
    JOIN PLAN_AFTER_PAID pap ON cap.ID_PLAN_AFTER_PAID = pap.ID_PLAN_AFTER_PAID
    JOIN PLAN_BEFORE_PAID pbp ON cbp.ID_PLAN_BEFORE_PAID  = pbp.ID_PLAN_BEFORE_PAID
    WHERE
    	ADD_MONTHS(cap.CREATED_AT, c.DURATION) BETWEEN SYSDATE AND ADD_MONTHS(SYSDATE, 3)
    OR
    	ADD_MONTHS(cbp.CREATED_AT, c.DURATION) BETWEEN SYSDATE AND ADD_MONTHS(SYSDATE, 3)
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
    l.Plano_PRE_PAGO,
    l.Plano_POS_PAGO,
    l.ID_CLIENT AS Num_Cliente,
    l.Data_Contrato,
    c3m.Avg_Calls_Last_3_Months AS N_Medio_Chamadas_3Meses,
    clp.Avg_Calls_Period AS N_Medio_mensal_total_periodo
FROM loyalty_period_end l
JOIN calls_last_3_months c3m ON l.ID_CLIENT = c3m.ID_CLIENT
JOIN calls_loyalty_period clp ON l.ID_CLIENT = clp.ID_CLIENT
WHERE c3m.Avg_Calls_Last_3_Months < clp.Avg_Calls_Period
ORDER BY c3m.Avg_Calls_Last_3_Months DESC;


/*
VIEW_C que, considerando apenas as chamadas no corrente ano realizadas por clientes de planos
pós-pagos, mostre apenas os números de destino que representam mais do que 50% das chamadas
realizadas por esse cliente. Ordene descendentemente pela percentagem de chamadas para esse
número.
*/
CREATE VIEW VIEW_C AS
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
JOIN total_calls_per_client t ON c.Contrato = t.Contrato
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
JOIN hourly_call_average hca ON hcd.Dia_Da_Semana = hca.Dia_Da_Semana
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
        pap.ID_PLAN_AFTER_PAID,
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
        p.ID_PLAN,
        p.NAME AS Plano,
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
JOIN sms_summary ss ON cs.ID_PLAN = ss.ID_PLAN
ORDER BY cs.ID_PLAN;

-- todo: continuar aqui


/*
    VISTA_I que para cada plano pós-pago com plafonds e para mês do ano de 2021, apresente a
    quantidade de minutos do plano, a quantidade média de minutos gastos por mês pelos clientes
    desse plano, e a percentagem média utilizada em cada mês. Mostre apenas os planos que, em cada
    mês, apresentam uma percentagem utilização inferior à média das percentagens dos planos.
    Ordene por mês (numeral), ascendentemente pela percentagem média de utilização. 
*/
CREATE VIEW VISTA_I AS
WITH monthly_usage AS (
    SELECT
        EXTRACT(MONTH FROM c.DATETIME) AS Mes,
        p.NAME AS Plano,
        p.PLAN_MINUTES AS quant_minutos_plano,
        AVG(ca.DURATION) AS Quant_minutos_utilizado
    FROM PLAN p
    JOIN CLIENT cl ON p.ID_PLAN = cl.ID_PLAN
    JOIN CALL ca ON cl.ID_CLIENT = ca.ID_CLIENT
    WHERE p.PLAN_TYPE = 'Postpaid' AND p.HAS_PLAFOND = 'Y'
          AND EXTRACT(YEAR FROM ca.DATETIME) = 2021
    GROUP BY EXTRACT(MONTH FROM c.DATETIME), p.NAME, p.PLAN_MINUTES
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
CREATE VIEW VISTA_J AS
WITH friend_group_usage AS (
    SELECT
        fg.CAMPAIGN_NAME,
        COUNT(ca.ID_CALL) AS total_calls,
        SUM(ca.COST) AS total_cost,
        SUM(ca.COST * (1 - ca.DISCOUNT_RATE)) AS total_discount
    FROM FRIENDS_GROUP fg
    JOIN CLIENT cl ON fg.ID_GROUP = cl.ID_GROUP
    JOIN CALL ca ON cl.ID_CLIENT = ca.ID_CLIENT
    WHERE ca.CALLER IN (SELECT MEMBER FROM FRIENDS_GROUP_MEMBERS WHERE ID_GROUP = fg.ID_GROUP)
          AND ca.CALLEE IN (SELECT MEMBER FROM FRIENDS_GROUP_MEMBERS WHERE ID_GROUP = fg.ID_GROUP)
          AND EXTRACT(MONTH FROM ca.DATETIME) = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -1))
    GROUP BY fg.CAMPAIGN_NAME
),
monthly_growth AS (
    SELECT
        fg.CAMPAIGN_NAME,
        COUNT(CASE WHEN EXTRACT(MONTH FROM cl.DATE_JOINED) = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -1)) THEN 1 END) AS current_month_members,
        COUNT(CASE WHEN EXTRACT(MONTH FROM cl.DATE_JOINED) = EXTRACT(MONTH FROM ADD_MONTHS(SYSDATE, -2)) THEN 1 END) AS previous_month_members
    FROM FRIENDS_GROUP fg
    JOIN CLIENT cl ON fg.ID_GROUP = cl.ID_GROUP
    GROUP BY fg.CAMPAIGN_NAME
)
SELECT
    fgu.CAMPAIGN_NAME,
    fgu.total_calls,
    fgu.total_cost,
    fgu.total_discount
FROM friend_group_usage fgu
JOIN monthly_growth mg ON fgu.CAMPAIGN_NAME = mg.CAMPAIGN_NAME
WHERE mg.current_month_members > 1.1 * mg.previous_month_members
ORDER BY (mg.current_month_members - mg.previous_month_members) / mg.previous_month_members DESC;


/*
    VISTA VIEW_K
    Esta view retorna a quantidade de chamadas realizadas e a duração total das chamadas por dia da semana e plano,
    o que pode ser relevante para a empresa analisar o uso dos planos por dia da semana.
*/

CREATE VIEW VIEW_K_2021110042 AS
SELECT
    TO_CHAR(ca.DATA_CHAMADA, 'DY') AS dia_da_semana,
    pl.PLANO AS plano,
    COUNT(*) AS quant_chamadas,
    SUM(ca.DURACAO_CHAMADAS) AS duracao_total
FROM CHAMADAS ca
JOIN CONTRATO con ON con.N_CONTRATO = ca.N_CONTRATO
JOIN PLANOS pl ON con.PLANO = pl.PLANO
GROUP BY TO_CHAR(ca.DATA_CHAMADA, 'DY'), pl.PLANO
ORDER BY dia_da_semana, plano;


/*
    Cada elemento do grupo deve criar a vista com o formato VIEW_L_<naluno>, que se propôs a
fazer no checkpoint1, que inclua um SELECT encadeado e que considere relevante, justificando
a sua relevância. A relevância e o nível de complexidade das mesmas influenciarão fortemente a
sua avaliação
*/

