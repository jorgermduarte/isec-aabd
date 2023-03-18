-- ======================================================================
-- ============ 		 						 		 ================
-- ============ 		 TABLES CREATIONS SCRIPT 		 ================
-- ============ 		 						 		 ================
-- ======================================================================
CREATE TABLE CLIENT(
	ID_CLIENT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	PHONE_NUMBER nvarchar2(20),
	PHONE_NUMBER_NORMALIZED NUMBER(9),
	FULL_NAME nvarchar2(255),
	NIF  NUMBER(9),
	BALANCE NUMBER(10) NULL,
	CREATION_DATE DATE DEFAULT SYSDATE,
	MODIFICATION_DATE DATE DEFAULT SYSDATE,
	DELETED NUMBER(1) DEFAULT 0,
	STATUS_TYPE NUMBER(3) -- THE STATUS TYPE REPRESENTS IF THE USER IS OFFLINE/ONLINE/OCUPIED
)


-- Tipos de planos
-- 0 - Pre pago, 1 - Pos pago
CREATE TABLE PLAN(
	ID_PLAN NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME nvarchar2(255),
	DESIGNATION nvarchar2(255),
	LAUNCH_DATE DATE,
	STATUS_TYPE NUMBER(3), -- THE STATUS TYPE REPRESENTS IF THE PLAN IS ACTIVE/INACTIVE
	PLAN_TYPE NUMBER(3), -- THE PLAN TYPE (PRE-POS)
	SERVICE_VALUE NUMBER(10),
	TOTAL_SMS NUMBER(10) NULL,
	TOTAL_MINUTES NUMBER(10) NULL,
	TOTAL_DAYS NUMBER(10) NULL,
	CREATION_DATE DATE DEFAULT SYSDATE,
	MODIFICATION_DATE DATE DEFAULT SYSDATE,
	DELETED NUMBER(1) DEFAULT 0
)


CREATE TABLE CONTRACT(
	ID_CONTRACT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10),
	ID_PLAN NUMBER(10),
	START_DATE DATE DEFAULT SYSDATE,
	LOYALTY_DATE DATE, -- FIDELIZATION DATE
	DURATION NUMBER(10), -- NUMBER IN DAYS
	CREATION_DATE DATE DEFAULT SYSDATE,
	MODIFICATION_DATE DATE DEFAULT SYSDATE,
	ACTIVE NUMBER(1) DEFAULT 1,
	DELETED NUMBER(1) DEFAULT 0,
	CONSTRAINT FK_CONTRACT_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_CONTRACT_ID_PLAN
	FOREIGN KEY (ID_PLAN) REFERENCES PLAN(ID_PLAN)
)

CREATE TABLE TARRIF(
	ID_TARRIF NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME nvarchar2(255),
	DESIGNATION nvarchar2(255),
	LAUNCH_DATE DATE,
	TARRIF_TYPE NUMBER(3), -- THE TARRIF TYPE
	TARRIF_NETWORK NVARCHAR2(50), -- the TARRIF NETWORK
	STATUS NUMBER(2), -- THE STATUS TYPE REPRESENTS IF THE TARRIF IS ACTIVE/INACTIVE
	MONEY_PER_UNIT NUMBER(10),
	UNIT_TYPE nvarchar2(50),
	CREATION_DATE DATE DEFAULT SYSDATE,
	MODIFICATION_DATE DATE DEFAULT SYSDATE,
	DELETED NUMBER(1) DEFAULT 0
)

CREATE TABLE PLAN_TARRIF(
	ID_PLAN_TARRIF NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_PLAN NUMBER(10),
	ID_TARRIF NUMBER(10),
	DELETED NUMBER(1) DEFAULT 0,
	CONSTRAINT FK_PLAN_TARRIF_ID_PLAN
	FOREIGN KEY (ID_PLAN) REFERENCES PLAN(ID_PLAN),
	CONSTRAINT FK_PLAN_TARRIF_ID_TARRIF
	FOREIGN KEY (ID_TARRIF) REFERENCES TARRIF(ID_TARRIF)
)

CREATE TABLE NOTIFICATION(
	ID_NOTIFICATION NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10), -- WE WILL HAVE 2 REGISTRIES TO THE SAME ID_CLIENT PER ENTRY, TARGET AND SOURCE
	TARGET_NUMBER NUMBER(10), -- THE TARGET NUMBER TO SEND THE NOTIFICATION
	STATUS NUMBER(3), -- THE REPRESENTATION OF THE CURRENT STATUS TYPE OF THE NOTIFICATIONS
	NOTIFICATION_DATE DATE DEFAULT SYSDATE,
	COMPLETED NUMBER(1) DEFAULT 0,  -- IF THE NOTIFICATION HAS BEEN COMPLETED
	CONSTRAINT FK_NOTIFICATION_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT)
)

CREATE TABLE INVOICE(
	ID_INVOICE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	MONTHLY_PLAN_VALUE NUMBER(10),
	SMS_VALUE NUMBER(10), -- THE SMS_VALUE MUST CHECK THE TARRIF TABLE AND THE PACKAGE TABLE AND CAMPAINS
	CALLS_VALUE NUMBER(10), -- THE CALLS_VALUE MUST CHECK THE TARRIF TABLE AND THE PACKAGE TABLE AND CAMPAINS
	-- PLANS_VALUE NUMBER(10),   										??????????????????????????????????????
	BILLING_DATE DATE,
	TOTAL_VALUE NUMBER(10),
	CREATION_DATE DATE DEFAULT SYSDATE,
	CONSTRAINT FK_INVOICE_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT)
)

CREATE TABLE BUNDLE(
	ID_PACKAGE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	DESIGNATION NVARCHAR2(255),
	LAUNCH_DATE DATE,
	PACKAGE_TYPE NUMBER(3), -- THE PACKAGE TYPE							??????????????????????????????????????
	PACKAGE_NETWORK NUMBER(3), --  THE PACKAGE NETWORK					??????????????????????????????????????
	STATUS NUMBER(3), -- THE STATUS CAN BE ACTIVE/INACTIVE
	PRICE_VALUE NUMBER(10),
	QUANTITY NUMBER(10),
	UNIT NVARCHAR2(50),
	PERIOD NUMBER(10), -- THE PERIOD IN DAYS							??????????????????????????????????????
	CREATION_DATE DATE DEFAULT SYSDATE
)

CREATE TABLE BUNDLE_CONTRACT(
	ID_BUNDLE_CONTRACT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_BUNDLE NUMBER(10),
	CONSTRAINT FK_BUNDLE_CONTRACT_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_BUNDLE_CONTRACT_ID_BUNDLE
	FOREIGN KEY (ID_BUNDLE) REFERENCES BUNDLE(ID_PACKAGE)
)


CREATE TABLE CALL_NETWORK(
	ID_CALL_NETWORK NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	PREFIX NVARCHAR2(10),
	DIGITS_COUNT NUMBER(5),
	NETWORK NVARCHAR2(50)
)

CREATE TABLE CLIENT_CALL(
	ID_CALL NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10),
	ID_CALL_NETWORK NUMBER(10),
	TARGET_NUMBER NUMBER(10),
	DURATION NUMBER(10),
	COST_VALUE NUMBER(10),
	CREATION_DATE DATE DEFAULT SYSDATE,
	MODIFICATION_DATE DATE DEFAULT SYSDATE,
	CALL_ACCEPTED NUMBER(1) DEFAULT 0,
	CALL_ACCEPTED_DATE DATE NULL,
	CALL_COMPLETED_DATE DATE NULL,
	CALL_ATTEMPTED_SECONDS NUMBER(10),
	STATUS NUMBER(3), -- THE STATUS CAN BE OCCUPIED/ UNAVAILABLE, ACCEPTED, UNKNOWN (DEFAULT)
	CONSTRAINT FK_CALL_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_CALL_ID_CALL_NETWORK
	FOREIGN KEY (ID_CALL_NETWORK) REFERENCES CALL_NETWORK(ID_CALL_NETWORK)
)


-- EVERY CHANGE MADE TO THE CLIENT_CALL TABLE (INSERT/UPDATE) WE WILL ADD THE CHANGES ON THE CLIENT_CALL_HISTORY
CREATE TABLE CLIENT_CALL_HISTORY(
	ID_CALL_HISTORY NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CALL NUMBER(10),
	CALL_ACCEPTED NUMBER(1) DEFAULT 0,
	CALL_ACCEPTED_DATE DATE NULL,
	CALL_COMPLETED_DATE DATE NULL,
	CALL_ATTEMPTED_SECONDS NUMBER(10),
	STATUS NUMBER(3),
	CREATION_DATE DATE DEFAULT SYSDATE,
	CONSTRAINT FK_CLIENT_CALL_HISTORY_ID_CALL
	FOREIGN KEY (ID_CALL) REFERENCES CLIENT_CALL(ID_CALL)
)

CREATE TABLE CAMPAIGN(
	ID_CAMPAIGN NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	DESIGNATION NVARCHAR2(255),
	MAX_FRIENDS NUMBER(10),
	START_DATE DATE,
	END_DATE DATE NULL,
	DISCOUNT_SMS_PERCENTAGE NUMBER(10) NULL,
	DISCOUNT_VOICE_PERCENTAGE NUMBER(10) NULL,
	CREATION_DATE DATE DEFAULT SYSDATE,
	ENABLED NUMBER(1) DEFAULT 0
)

CREATE TABLE CLIENT_CAMPAIGN(
	ID_CLIENT_CAMPAIGN NUMBER(10) PRIMARY KEY,
	ID_CAMPAIGN NUMBER(10),
	ID_CLIENT_GROUP_OWNER NUMBER(10),
	ID_CLIENT_ASSOCIATED NUMBER(10),
	CREATION_DATE DATE DEFAULT SYSDATE,
	CONSTRAINT FK_CLIENT_CAMPAIGN_ID_CLIENT_GROUP_OWNER
	FOREIGN KEY  (ID_CLIENT_GROUP_OWNER) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_CLIENT_CAMPAIGN_ID_CLIENT_ASSOCIATED
	FOREIGN KEY  (ID_CLIENT_ASSOCIATED) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_CLIENT_CAMPAIGN_ID_CAMPAIGN
	FOREIGN KEY (ID_CAMPAIGN) REFERENCES CAMPAIGN(ID_CAMPAIGN)
)

CREATE TABLE SMS(
	ID_SMS NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10),
	DESTINY_NUMBER NVARCHAR2(20),
	DESTINY_NUMBER_NORMALIZED NUMBER(10),
	CREATION_DATE DATE DEFAULT SYSDATE,
	SENT_DATE DATE NULL,
	MESSAGE NVARCHAR2(255),
	CURRENT_STATUS NUMBER(3), -- THE CURRENT STATUS CAN BE: SENT, DELIVERED, NOT DELIVERED, SENDING
	CONSTRAINT FK_SMS_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT)
)

CREATE TABLE SMS_HISTORY(
	ID_SMS_HISTORY NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_SMS NUMBER(10),
	CREATION_DATE DATE DEFAULT SYSDATE,
	CURRENT_STATUS NUMBER(3),
	CONSTRAINT FK_SMS_HISTORY_ID_SMS
	FOREIGN KEY (ID_SMS) REFERENCES SMS(ID_SMS)
)
