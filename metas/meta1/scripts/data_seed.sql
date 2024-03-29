-- ======================================================================
-- ============ 		 						 		                     ================
-- ============ 		      DATA SEED SCRIPT               ================
-- ============ 		 						 		                     ================
-- ======================================================================

INSERT INTO PLAN_TYPE (NAME) VALUES('Pré-pago')
INSERT INTO PLAN_TYPE (NAME) VALUES('Pós-pago')

INSERT INTO CLIENT_STATUS (NAME) VALUES('DEFAULT')
INSERT INTO CLIENT_STATUS (NAME) VALUES('ONLINE')
INSERT INTO CLIENT_STATUS (NAME) VALUES('OCCUPIED')
INSERT INTO CLIENT_STATUS (NAME) VALUES('OFFLINE')


INSERT INTO NETWORK (NAME,DIGITS_COUNT,PREFIX) VALUES ('Fixo Nacional','9','2xxxxxxxx')
INSERT INTO NETWORK (NAME,DIGITS_COUNT,PREFIX) VALUES ('Móvel Nacional','9','9xxxxxxxx')
INSERT INTO NETWORK (NAME,DIGITS_COUNT,PREFIX) VALUES ('Móvel Nacional','9','808xxxxxx')
INSERT INTO NETWORK (NAME,DIGITS_COUNT,PREFIX) VALUES ('Gratuito','14','003512xxxxxxxx')
INSERT INTO NETWORK (NAME,DIGITS_COUNT,PREFIX) VALUES ('Internacional','>3','00x...')

INSERT INTO COMMUNICATION_TYPE (NAME) VALUES('VOZ')
INSERT INTO COMMUNICATION_TYPE (NAME) VALUES('SMS')


INSERT INTO CALL_STATUS_TYPE(NAME) VALUES('CALLING')
INSERT INTO CALL_STATUS_TYPE(NAME) VALUES('ACCEPTED')
INSERT INTO CALL_STATUS_TYPE(NAME) VALUES('UNAVAILABLE')
INSERT INTO CALL_STATUS_TYPE(NAME) VALUES('OCCUPIED')
INSERT INTO CALL_STATUS_TYPE(NAME) VALUES('REJECTED')


INSERT INTO SMS_STATUS_TYPE (NAME) VALUES('SENDING')
INSERT INTO SMS_STATUS_TYPE (NAME) VALUES('SENT')
INSERT INTO SMS_STATUS_TYPE (NAME) VALUES('DELIVERED')
INSERT INTO SMS_STATUS_TYPE (NAME) VALUES('NOT DELIVERED')
INSERT INTO SMS_STATUS_TYPE (NAME) VALUES('SENDING')


-- CLIENTS
DECLARE
  v_phone_number CLIENT.PHONE_NUMBER%TYPE;
  v_phone_number_normalized CLIENT.PHONE_NUMBER_NORMALIZED%TYPE;
  v_full_name CLIENT.FULL_NAME%TYPE;
  v_nif CLIENT.NIF%TYPE;
BEGIN
  FOR i IN 1..40 LOOP
    v_phone_number_normalized := DBMS_RANDOM.VALUE(910000000, 930000000);
    v_phone_number := '+351 ' || TO_CHAR(v_phone_number_normalized);
    v_full_name := DBMS_RANDOM.STRING('A', 6) || ' ' || DBMS_RANDOM.STRING('A', 6);
    v_nif := DBMS_RANDOM.VALUE(250000000, 259900000);

    INSERT INTO CLIENT (PHONE_NUMBER, PHONE_NUMBER_NORMALIZED, FULL_NAME, NIF, BALANCE, CREATION_DATE, MODIFICATION_DATE, DELETED, ID_STATUS_TYPE)
    VALUES (v_phone_number, v_phone_number_normalized, v_full_name, v_nif, DBMS_RANDOM.VALUE(100, 1000), SYSDATE, SYSDATE, 0, DBMS_RANDOM.VALUE(1,3));
  END LOOP;
END;


-- Tipos de planos
-- 1 - Pre pago, 2 - Pos pago
-- Status Type
-- 0 - Inativo , 1 - Ativo

-- POS PAGOS SIMPLES
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE ,ID_PLAN_TYPE ,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PPS 1997','Plano Pós-pago simples','1997-12-01',0,2,4.99,NULL,NULL,NULL);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PPS 2001','Plano Pós-pago simples','2001-01-01',1,2,6.99,NULL,NULL,NULL);

-- POS PAGOS COM PLAFOND
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE ,ID_PLAN_TYPE ,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PPS 1997 100/100','Plano Pós-pago 100/100','1997-12-01',0,2,9.99,100,100,NULL);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PPS 2001 100/100','Plano Pós-pago 100/100','2001-01-01',1,2,8.99,100,100,NULL);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PPS 2001 500/500','Plano Pós-pago 500/500','2001-01-01',1,2,11.99,500,500,NULL);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PPS 2021 3000/1000','Plano Pós-pago 3000/1000','2021-01-01',2,1,14.99,3000,1000,NULL);


-- PRE PAGOS
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 7Dias','Pré-pago 7dias','1997-12-01',0,1,2.50,NULL,NULL,7);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 7Dias','Pré-pago 7dias','2001-01-01',1,1,2.99,NULL,NULL,7);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 30Dias','Pré-pago 30dias','2001-01-01',1,1,9.99,NULL,NULL,30);
INSERT INTO PLAN (NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 500min','Pré-pago 500min','2001-01-01',1,1,9.99,500,100,60);

-- ID_COMMUNICATION_TYPE:
--  1 - VOZ, 2 - SMS
-- STATUS:
-- 0 - INACTIVE, 1 - ACTIVE
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE ,ID_NETWORK ,IS_ACTIVE ,MONEY_PER_UNIT,UNIT_TYPE)
VALUES('Voz M01','Voz rede móvel 01','1997-12-01',1,2,0,0.20,'Minuto');
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,UNIT_TYPE)
VALUES('Voz M01','Voz rede móvel 01','2001-01-01',1,2,1,0.30,'Minuto');
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,UNIT_TYPE)
VALUES('Voz M02','Voz rede móvel 01','2001-01-01',1,3,1,0.25,'Minuto');
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,UNIT_TYPE)
VALUES('Voz F01','Voz rede fixa 01','2001-01-01',1,1,1,0.20,'Minuto');
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,UNIT_TYPE)
VALUES('SMS S08','SMS 8 cent','2001-01-01',2,2,1,0.08,'SMS');
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,UNIT_TYPE)
VALUES('Notif N1','Notificação 01','2001-01-01',1,1,1,0.00,'SMS');

-- TYPE:
--  1 - VOZ, 2 - SMS
-- NETWORK:
-- 2- MOVEL, 1 - FIXO
-- STATUS:
-- 0 - INACTIVE, 1 - ACTIVE
INSERT INTO BUNDLE (DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE ,ID_NETWORK ,IS_ACTIVE ,PRICE_VALUE,QUANTITY,UNIT,PERIOD)
VALUES('Pack 100min','1997-12-01',1,2,0,2.00,100,'Minuto',30);
INSERT INTO BUNDLE (DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,PRICE_VALUE,QUANTITY,UNIT,PERIOD)
VALUES('Pack 100min','2001-01-01',1,2,1,2.30,100,'Minuto',30);
INSERT INTO BUNDLE (DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,PRICE_VALUE,QUANTITY,UNIT,PERIOD)
VALUES('Pack 200min','2001-01-01',1,2,1,0.25,200,'Minuto',30);
INSERT INTO BUNDLE (DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,PRICE_VALUE,QUANTITY,UNIT,PERIOD)
VALUES('Pack voz fixo','2001-01-01',1,1,1,0.20,3000,'Minuto',30);
INSERT INTO BUNDLE (DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,PRICE_VALUE,QUANTITY,UNIT,PERIOD)
VALUES('Pack SMS','2001-01-01',2,2,1,0.00,3000,'SMS',30);


INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE,ENABLED)
VALUES ('Grupo05','Grupo 5 amigos',5,'2017-12-01','2017-12-01',30,30,1);
INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE,ENABLED)
VALUES ('Grupo Família','Grupo Família',4,'2021-01-01','2021-04-01',40,40,1);
INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE,ENABLED)
VALUES ('Grupo 10','Grupo 10 amigos',10,'2021-03-01','2021-08-01',50,50,1);
INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE,ENABLED)
VALUES ('SMS','SMS para 10',10,'2021-06-01','2021-12-01',50,NULL,1);