-- ======================================================================
-- ============ 		 					             ================
-- ============ 		      DATA SEED SCRIPT  V2       ================
-- ============ 		        	                     ================
-- ======================================================================


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


INSERT INTO PHONE_NUMBER_STATUS_TYPE  (NAME) VALUES('DEFAULT')
INSERT INTO PHONE_NUMBER_STATUS_TYPE (NAME) VALUES('ONLINE')
INSERT INTO PHONE_NUMBER_STATUS_TYPE (NAME) VALUES('OCCUPIED')
INSERT INTO PHONE_NUMBER_STATUS_TYPE (NAME) VALUES('OFFLINE')

-- CLIENTS
DECLARE
  v_full_name CLIENT.FULL_NAME%TYPE;
  v_nif CLIENT.NIF%TYPE;
BEGIN
  FOR i IN 1..100 LOOP
    v_full_name := DBMS_RANDOM.STRING('A', 6) || ' ' || DBMS_RANDOM.STRING('A', 6);
    v_nif := DBMS_RANDOM.VALUE(250000000, 259900000);

    INSERT INTO CLIENT (FULL_NAME, NIF, CREATED_AT)
    VALUES (v_full_name,v_nif,SYSDATE);
  END LOOP;
END;


INSERT INTO PLAN_TYPE_AFTER_PAID(NAME) VALUES('Simples');
INSERT INTO PLAN_TYPE_AFTER_PAID(NAME) VALUES('Com Plafond');



INSERT INTO PLAN_AFTER_PAID(ID_PLAN_TYPE_AFTER_PAID,NAME,DESIGNATION,LAUNCH_DATE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,IS_ACTIVE)
VALUES (1,'PPS 1997','Plano pós-ago simples','1997-12-01',4.99,NULL,NULL,0);

INSERT INTO PLAN_AFTER_PAID(ID_PLAN_TYPE_AFTER_PAID,NAME,DESIGNATION,LAUNCH_DATE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,IS_ACTIVE)
VALUES (1,'PPS 2001','Plano pós-ago simples','2001-01-01',6.99,NULL,NULL,1);


INSERT INTO PLAN_AFTER_PAID(ID_PLAN_TYPE_AFTER_PAID,NAME,DESIGNATION,LAUNCH_DATE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,IS_ACTIVE)
VALUES (2,'PPS 1997 100/100','Plano Pós-pago 100/100','1997-12-01',9.99,100,100,0);
INSERT INTO PLAN_AFTER_PAID(ID_PLAN_TYPE_AFTER_PAID,NAME,DESIGNATION,LAUNCH_DATE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,IS_ACTIVE)
VALUES (2,'PPS 2001 100/100','Plano Pós-pago 100/100','1997-12-01',8.99,100,100,1);
INSERT INTO PLAN_AFTER_PAID(ID_PLAN_TYPE_AFTER_PAID,NAME,DESIGNATION,LAUNCH_DATE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,IS_ACTIVE)
VALUES (2,'PPS 2001 500/500','Plano Pós-pago 500/500','1997-12-01',11.99,500,500,1);
INSERT INTO PLAN_AFTER_PAID(ID_PLAN_TYPE_AFTER_PAID,NAME,DESIGNATION,LAUNCH_DATE,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,IS_ACTIVE)
VALUES (2,'PPS 2021 3000/1000','Plano Pós-pago 3000/1000','2021-01-01',14.99,3000,1000,1);


INSERT INTO PLAN_TYPE_BEFORE_PAID (NAME) VALUES ('Normal')


INSERT INTO PLAN_BEFORE_PAID
(NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE_BEFORE_PAID,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 7Dias','Pré-pago 7dias','1997-12-01',0,1,2.50,NULL,NULL,7);

INSERT INTO PLAN_BEFORE_PAID
(NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE_BEFORE_PAID,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 7Dias','Pré-pago 7dias','2001-01-01',1,1,2.99,NULL,NULL,7);

INSERT INTO PLAN_BEFORE_PAID
(NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE_BEFORE_PAID,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 30Dias','Pré-pago 30dias','2001-01-01',1,1,9.99,NULL,NULL,30);

INSERT INTO PLAN_BEFORE_PAID
(NAME,DESIGNATION,LAUNCH_DATE,IS_ACTIVE,ID_PLAN_TYPE_BEFORE_PAID,SERVICE_VALUE,TOTAL_SMS,TOTAL_MINUTES,TOTAL_DAYS)
VALUES('PP 500min','Pré-pago 500min','2001-01-01',1,1,9.99,500,100,60);


INSERT INTO TARRIF_UNIT_TYPE (NAME)
VALUES ('Minuto')

INSERT INTO TARRIF_UNIT_TYPE (NAME)
VALUES ('SMS')

INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE ,ID_NETWORK ,IS_ACTIVE ,MONEY_PER_UNIT,ID_UNIT_TYPE)
VALUES('Voz M01','Voz rede móvel 01','1997-12-01',1,2,0,0.20,1);
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,ID_UNIT_TYPE)
VALUES('Voz M01','Voz rede móvel 01','2001-01-01',1,2,1,0.30,1);
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,ID_UNIT_TYPE)
VALUES('Voz M02','Voz rede móvel 01','2001-01-01',1,3,1,0.25,1);
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,ID_UNIT_TYPE)
VALUES('Voz F01','Voz rede fixa 01','2001-01-01',1,1,1,0.20,1);
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,ID_UNIT_TYPE)
VALUES('SMS S08','SMS 8 cent','2001-01-01',2,2,1,0.08,2);
INSERT INTO TARRIF (NAME,DESIGNATION,LAUNCH_DATE,ID_COMMUNICATION_TYPE,ID_NETWORK,IS_ACTIVE,MONEY_PER_UNIT,ID_UNIT_TYPE)
VALUES('Notif N1','Notificação 01','2001-01-01',1,1,1,0.00,2);


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



INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE)
VALUES ('Grupo05','Grupo 5 amigos',5,'2017-12-01','2017-12-01',30,30);
INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE)
VALUES ('Grupo Família','Grupo Família',4,'2021-01-01','2021-04-01',40,40);
INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE)
VALUES ('Grupo 10','Grupo 10 amigos',10,'2021-03-01','2021-08-01',50,50);
INSERT INTO CAMPAIGN (NAME,DESIGNATION,MAX_FRIENDS,START_DATE,END_DATE,DISCOUNT_SMS_PERCENTAGE,DISCOUNT_VOICE_PERCENTAGE)
VALUES ('SMS','SMS para 10',10,'2021-06-01','2021-12-01',50,NULL);


DECLARE
  v_id_contract NUMBER;
  v_id_plan_after_paid NUMBER;
  v_id_plan_before_paid NUMBER;
  v_id_phone_number_contract NUMBER;
BEGIN
  -- IDs dos planos
  SELECT MIN(x.ID_PLAN_AFTER_PAID) INTO v_id_plan_after_paid FROM PLAN_AFTER_PAID x WHERE x.IS_ACTIVE =1;
  SELECT MIN(x.ID_PLAN_BEFORE_PAID) INTO v_id_plan_before_paid FROM PLAN_BEFORE_PAID x WHERE x.IS_ACTIVE =1;

  FOR i IN 1..9 LOOP
    -- contrato
    INSERT INTO CONTRACT (ID_CLIENT, PHONE_NUMBER, START_DATE, END_DATE)
    VALUES (i, '92345678'||i, SYSDATE, ADD_MONTHS(SYSDATE, 12))
    RETURNING ID_CONTRACT INTO v_id_contract;

    -- associacao dos numeros ao contrato
    INSERT INTO PHONE_NUMBER_CONTRACT (ID_CONTRACT, PHONE_NUMBER)
    VALUES (v_id_contract, '92345678'||i)
    RETURNING ID_PHONE_NUMBER_CONTRACT INTO v_id_phone_number_contract;

    --ou  CONTRACT_AFTER_PAID ou CONTRACT_BEFORE_PAID, mas não em ambos
    IF MOD(i, 2) = 0 THEN
      INSERT INTO CONTRACT_AFTER_PAID (ID_CONTRACT, ID_PLAN_AFTER_PAID, ID_PHONE_NUMBER_CONTRACT, END_DATE)
      VALUES (v_id_contract, v_id_plan_after_paid, v_id_phone_number_contract, ADD_MONTHS(SYSDATE, 12));
    ELSE
      INSERT INTO CONTRACT_BEFORE_PAID (ID_CONTRACT, ID_PLAN_BEFORE_PAID, ID_PHONE_NUMBER_CONTRACT, END_DATE)
      VALUES (v_id_contract, v_id_plan_before_paid, v_id_phone_number_contract, ADD_MONTHS(SYSDATE, 12));

      -- adicao de depositios para os pre pagos
      INSERT INTO PHONE_NUMBER_DEPOSITS (ID_CONTRACT, ID_PHONE_NUMBER_CONTRACT, VALUE)
      VALUES (v_id_contract, v_id_phone_number_contract, 100);
    END IF;
  END LOOP;
END;


