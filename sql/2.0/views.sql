--View to show the list of all available tarrifs along with their associated communication type and network:
CREATE VIEW tarrif_details AS
SELECT t.name as tarrif_name, t.designation as tarrif_designation, t.money_per_unit, t.unit_type, ct.name as communication_type, n.name as network_name, n.prefix, n.digits_count
FROM tarrif t
JOIN communication_type ct ON t.id_communication_type = ct.id_communication_type
JOIN network n ON t.id_network = n.id_network;


--View to show the list of all available plans along with their associated tarrifs for the clients:
CREATE VIEW client_plan_tarrif AS
SELECT cl.ID_CLIENT, cl.phone_number, p.name as plan_name, p.TOTAL_SMS, p.TOTAL_MINUTES  ,p.TOTAL_DAYS , PT2.NAME AS PLAN_TYPE, t.name as tarrif_name, ct.NAME  AS COMMUNICATION_TYPE
FROM client cl
JOIN contract c ON cl.id_client = c.id_client
JOIN plan p ON c.id_plan = p.id_plan
JOIN PLAN_TYPE pt2 ON p.ID_PLAN_TYPE = pt2.ID_PLAN_TYPE 
LEFT JOIN plan_tarrif pt ON p.id_plan = pt.id_plan
LEFT JOIN tarrif t ON pt.id_tarrif = t.id_tarrif
LEFT JOIN COMMUNICATION_TYPE ct ON t.ID_COMMUNICATION_TYPE = ct.ID_COMMUNICATION_TYPE
WHERE c.IS_ACTIVE =1;

-- View to show the total number of contracts per plan type:
CREATE VIEW contracts_per_plan_type AS
SELECT pt.name as plan_type_name, COUNT(*) as num_contracts
FROM plan p
JOIN plan_type pt ON p.id_plan_type = pt.id_plan_type
JOIN contract c ON p.id_plan = c.id_plan
WHERE c.is_active = 1
GROUP BY pt.name;

-- View to show the total number of clients per plan:
CREATE VIEW clients_per_plan AS
SELECT p.NAME AS PLAN_NAME, COUNT(c.ID_CLIENT) AS TOTAL_CLIENTS
FROM PLAN p
JOIN CONTRACT ct ON ct.ID_PLAN = p.ID_PLAN
JOIN CLIENT c ON c.ID_CLIENT = ct.ID_CLIENT
GROUP BY p.NAME;

--View that lists the bundles associated with the contracts
CREATE VIEW contract_bundles AS
SELECT
  C2.ID_CLIENT,
 c2.PHONE_NUMBER_NORMALIZED,
  c.ID_CONTRACT,
  c.START_DATE,
  b.ID_BUNDLE,
  b.DESIGNATION
FROM
  CONTRACT c
  JOIN BUNDLE_CONTRACT bc  ON bc.ID_CONTRACT=c.ID_CONTRACT
  JOIN BUNDLE b  ON bc.ID_BUNDLE  = b.ID_BUNDLE
 JOIN CLIENT c2 ON c.ID_CLIENT  =c2.ID_CLIENT;

