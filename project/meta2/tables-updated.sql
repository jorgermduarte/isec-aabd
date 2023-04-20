-- ======================================================================
-- ============ 		 						 		 ================
-- ============ 		 TABLES CREATIONS SCRIPT 		 ================
-- ============ 		 						 		 ================
-- ======================================================================


CREATE TABLE CLIENT(
	ID_CLIENT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	FULL_NAME nvarchar2(255),
	-- NIF MUST BE UNIQUE
	NIF  NUMBER(10) UNIQUE,
	CREATED_AT DATE DEFAULT SYSDATE
)

CREATE TABLE CONTRACT(
	ID_CONTRACT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10),
    PHONE_NUMBER nvarchar2(20),
	START_DATE DATE DEFAULT SYSDATE,
	LOYALTY_DATE DATE, -- FIDELIZATION DATE
	END_DATE DATE,
	DURATION NUMBER(10), -- NUMBER IN DAYS
	CREATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1,
	CONSTRAINT FK_CONTRACT_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT)
)

CREATE TABLE PHONE_NUMBER_CONTRACT(
	ID_PHONE_NUMBER_CONTRACT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	PHONE_NUMBER nvarchar2(20) UNIQUE,
	CANCELLATION_DATE DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PHONE_NUMBER_CONTRACTS_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT)
)

CREATE TABLE PHONE_NUMBER_CONTRACT_CANCELLATION(
	ID_PHONE_NUMBER_CONTRACT_CANCELLATION NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10), -- ID OF THE CLIENT WHO CANCELLED THE PHONE NUMBER
	ID_PHONE_NUMBER_CONTRACT NUMBER(10), -- ID OF THE DELETED PHONE NUMBER
	ID_CONTRACT NUMBER(10), -- ID OF THE CONTRACT
	CANCELLATION_DATE DATE DEFAULT SYSDATE,
	PHONE_NUMBER nvarchar2(20),
	CONSTRAINT FK_PHONE_NUMBER_CONTRACT_CANCELLATION_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT)
)

CREATE TABLE CONTRACT_CANCELLATION(
	ID_CONTRACT_CANCELLATION NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10), -- ID OF THE CLIENT WHO CANCELLED THE CONTRACT
	ID_CONTRACT NUMBER(10), -- ID OF THE DELETED CONTRACT
	CANCELLATION_DATE DATE DEFAULT SYSDATE,
	CONSTRAINT FK_CONTRACT_CANCELLATION_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT)
)

-- PRE PAGO / POS PAGO
CREATE TABLE PLAN_TYPE_BEFORE_PAID(
	ID_PLAN_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE
)

-- SIMPLES & PLAFOND
CREATE TABLE PLAN_TYPE_AFTER_PAID(
	ID_PLAN_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE
)

CREATE TABLE PLAN_AFTER_PAID(
	ID_PLAN_AFTER_PAID NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_PLAN_TYPE_AFTER_PAID NUMBER(10),
	NAME nvarchar2(255),
	DESIGNATION nvarchar2(255),
	LAUNCH_DATE DATE,
	SERVICE_VALUE NUMBER(10),
	TOTAL_SMS NUMBER(10) NULL,
	TOTAL_MINUTES NUMBER(10) NULL,
	CREATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1,
	CONSTRAINT FK_PLAN_AFTER_PAID_ID_PLAN_TYPE_AFTER_PAID
	FOREIGN KEY (ID_PLAN_TYPE_AFTER_PAID) REFERENCES PLAN_TYPE_AFTER_PAID(ID_PLAN_TYPE)
)


CREATE TABLE PLAN_BEFORE_PAID(
	ID_PLAN_BEFORE_PAID NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PLAN_TYPE_BEFORE_PAID NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	NAME nvarchar2(255),
	DESIGNATION nvarchar2(255),
	LAUNCH_DATE DATE,
	SERVICE_VALUE NUMBER(10),
	TOTAL_SMS NUMBER(10) NULL,
	TOTAL_MINUTES NUMBER(10) NULL,
	TOTAL_DAYS NUMBER(10) NULL,
	CREATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1,
	CONSTRAINT FK_PLAN_BEFORE_PAID_ID_PLAN_TYPE_BEFORE_PAID
	FOREIGN KEY (ID_PLAN_TYPE_BEFORE_PAID) REFERENCES PLAN_TYPE_BEFORE_PAID(ID_PLAN_TYPE),
	CONSTRAINT FK_PLAN_BEFORE_PAID_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_PLAN_BEFORE_PAID_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)


CREATE TABLE CONTRACT_AFTER_PAID(
	ID_CONTRACT_AFTER_PAID NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PLAN_AFTER_PAID NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	START_DATE DATE DEFAULT SYSDATE,
	END_DATE DATE,
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_CONTRACT_AFTER_PAID_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_CONTRACT_AFTER_PAID_ID_PLAN_AFTER_PAID
	FOREIGN KEY (ID_PLAN_AFTER_PAID) REFERENCES PLAN_AFTER_PAID(ID_PLAN_AFTER_PAID),
	CONSTRAINT FK_CONTRACT_AFTER_PAID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)

CREATE TABLE CONTRACT_BEFORE_PAID(
	ID_CONTRACT_BEFORE_PAID NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PLAN_BEFORE_PAID NUMBER(10),
	START_DATE DATE DEFAULT SYSDATE,
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	END_DATE DATE,
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_CONTRACT_BEFORE_PAID_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_CONTRACT_BEFORE_PAID_ID_PLAN_BEFORE_PAID
	FOREIGN KEY (ID_PLAN_BEFORE_PAID) REFERENCES PLAN_BEFORE_PAID(ID_PLAN_BEFORE_PAID),
	CONSTRAINT FK_CONTRACT_BEFORE_PAID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)

CREATE TABLE PHONE_NUMBER_DEPOSITS(
	ID_PHONE_NUMBER_BALANCE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	VALUE NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PHONE_NUMBER_DEPOSITS_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_PHONE_NUMBER_DEPOSITS_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)

-- TRIGGER TO UPDATE THE PHONE_NUMBER_BALANCE TABLE AFTER INSERTING A NEW VALUE IN PHONE_NUMBER_DEPOSITS
CREATE TABLE PHONE_NUMBER_BALANCE(
	ID_PHONE_NUMBER_BALANCE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	VALUE NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	UPDATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PHONE_NUMBER_BALANCE_ID_CONTRACT_2
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_PHONE_NUMBER_BALANCE_PHONE_NUMBER_CONTRACT_2
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)

CREATE TABLE PHONE_NUMBER_STATUS_TYPE(
	ID_PHONE_NUMBER_STATUS_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE
)

CREATE TABLE PHONE_NUMBER_STATUS(
	ID_PHONE_NUMBER_STATUS NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	STATUS_TYPE NUMBER(5),
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PHONE_NUMBER_STATUS_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_PHONE_NUMBER_STATUS_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT),
	CONSTRAINT FK_PHONE_NUMBER_STATUS_STATUS_TYPE
	FOREIGN KEY (STATUS_TYPE) REFERENCES PHONE_NUMBER_STATUS_TYPE(ID_PHONE_NUMBER_STATUS_TYPE)
)


CREATE TABLE NETWORK(
	ID_NETWORK NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	PREFIX NVARCHAR2(50),
	DIGITS_COUNT NVARCHAR2(3),
	CREATED_AT DATE DEFAULT SYSDATE,
	UPDATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1
)

-- SMS / VOZ
CREATE TABLE COMMUNICATION_TYPE(
	ID_COMMUNICATION_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE,
	UPDATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1
)

CREATE TABLE TARRIF_UNIT_TYPE(
	ID_TARRIF_UNIT_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE
)

CREATE TABLE TARRIF(
	ID_TARRIF NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_COMMUNICATION_TYPE NUMBER(10),
	ID_NETWORK NUMBER(10),
	NAME nvarchar2(255),
	DESIGNATION nvarchar2(255),
	LAUNCH_DATE DATE,
	MONEY_PER_UNIT NUMBER(10),
	ID_UNIT_TYPE NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	UPDATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1,
	CONSTRAINT FK_TARRIF_ID_COMMUNICATION_TYPE
	FOREIGN KEY (ID_COMMUNICATION_TYPE) REFERENCES COMMUNICATION_TYPE(ID_COMMUNICATION_TYPE),
	CONSTRAINT FK_TARRIF_ID_TARRIF_NETWORK
	FOREIGN KEY (ID_NETWORK) REFERENCES NETWORK(ID_NETWORK),
	CONSTRAINT FK_TARRIF_ID_TARRIF_UNIT_TYPE
	FOREIGN KEY (ID_UNIT_TYPE) REFERENCES TARRIF_UNIT_TYPE(ID_TARRIF_UNIT_TYPE)
)

CREATE TABLE PLAN_AFTER_PAID_TARRIF(
	ID_PLAN_AFTER_PAID_TARRIF NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_PLAN_AFTER_PAID NUMBER(10),
	ID_TARRIF NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PLAN_AFTER_PAID_TARRIF_ID_PLAN_AFTER_PAID
	FOREIGN KEY (ID_PLAN_AFTER_PAID) REFERENCES PLAN_AFTER_PAID(ID_PLAN_AFTER_PAID),
	CONSTRAINT FK_PLAN_AFTER_PAID_TARRIF_ID_TARRIF
	FOREIGN KEY (ID_TARRIF) REFERENCES TARRIF(ID_TARRIF)
)

CREATE TABLE PLAN_BEFORE_PAID_TARRIF(
	ID_PLAN_BEFORE_PAID_TARRIF NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_PLAN_BEFORE_PAID NUMBER(10),
	ID_TARRIF NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PLAN_BEFORE_PAID_TARRIF_ID_PLAN_BEFORE_PAID
	FOREIGN KEY (ID_PLAN_BEFORE_PAID) REFERENCES PLAN_BEFORE_PAID(ID_PLAN_BEFORE_PAID),
	CONSTRAINT FK_PLAN_BEFORE_PAID_TARRIF_ID_TARRIF
	FOREIGN KEY (ID_TARRIF) REFERENCES TARRIF(ID_TARRIF)
)

CREATE TABLE BUNDLE(
	ID_BUNDLE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_NETWORK NUMBER(10),
	ID_COMMUNICATION_TYPE NUMBER(3),
	DESIGNATION NVARCHAR2(255),
	LAUNCH_DATE DATE,
	PRICE_VALUE NUMBER(10),
	QUANTITY NUMBER(10),
	UNIT NVARCHAR2(50),
	PERIOD NUMBER(10), -- THE PERIOD IN DAYS
	CREATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1,
	CONSTRAINT FK_BUNDLE_ID_NETWORK
	FOREIGN KEY (ID_NETWORK) REFERENCES NETWORK(ID_NETWORK),
	CONSTRAINT FK_BUNDLE_ID_COMMUNICATION_TYPE
	FOREIGN KEY (ID_COMMUNICATION_TYPE) REFERENCES COMMUNICATION_TYPE(ID_COMMUNICATION_TYPE)
)

CREATE TABLE BUNDLE_CONTRACT_PURCHASE(
	ID_BUNDLE_CONTRACT NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CONTRACT NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	ID_BUNDLE NUMBER(10),
	STARTED_AT DATE DEFAULT SYSDATE,
	EXPIRATION_DATE DATE,
	CONSTRAINT FK_BUNDLE_CONTRACT_ID_CONTRACT
	FOREIGN KEY (ID_CONTRACT) REFERENCES CONTRACT(ID_CONTRACT),
	CONSTRAINT FK_BUNDLE_CONTRACT_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT),
	CONSTRAINT FK_BUNDLE_CONTRACT_ID_BUNDLE
	FOREIGN KEY (ID_BUNDLE) REFERENCES BUNDLE(ID_BUNDLE)
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
	CREATED_AT DATE DEFAULT SYSDATE,
	IS_ACTIVE NUMBER(1) DEFAULT 1
)

CREATE TABLE PHONE_NUMBER_COMPAIGN(
	ID_CLIENT_CAMPAIGN NUMBER(10) PRIMARY KEY,
	ID_CAMPAIGN NUMBER(10),
	ID_CLIENT_GROUP_OWNER NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	TARGET_PHONE_NUMBER NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_PHONE_NUMBER_COMPAIGN_ID_CAMPAIGN
	FOREIGN KEY (ID_CAMPAIGN) REFERENCES CAMPAIGN(ID_CAMPAIGN),
	CONSTRAINT FK_PHONE_NUMBER_COMPAIGN_ID_CLIENT_GROUP_OWNER
	FOREIGN KEY (ID_CLIENT_GROUP_OWNER) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_PHONE_NUMBER_COMPAIGN_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)


CREATE TABLE CALL_STATUS_TYPE(
	ID_CALL_STATUS_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE,
	DELETED NUMBER(1) DEFAULT 0
)

CREATE TABLE CLIENT_PHONE_NUMBER_CALL(
	ID_CALL NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	ID_NETWORK NUMBER(10),
	ID_STATUS_TYPE NUMBER(10),
	TARGET_NUMBER nvarchar2(20),
	DURATION NUMBER(10),
	COST_VALUE NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	UPDATED_AT DATE DEFAULT SYSDATE,
	CALL_ACCEPTED NUMBER(1) DEFAULT 0,
	CALL_ACCEPTED_DATE DATE NULL,
	CALL_COMPLETED_DATE DATE NULL,
	CALL_ATTEMPTED_SECONDS NUMBER(10),
	CONSTRAINT FK_CLIENT_CALL_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_CLIENT_CALL_ID_NETWORK
	FOREIGN KEY (ID_NETWORK) REFERENCES NETWORK(ID_NETWORK),
	CONSTRAINT FK_CLIENT_CALL_ID_STATUS_TYPE
	FOREIGN KEY (ID_STATUS_TYPE) REFERENCES CALL_STATUS_TYPE(ID_CALL_STATUS_TYPE),
	CONSTRAINT FK_CLIENT_CALL_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)


-- EVERY CHANGE MADE TO THE CLIENT_CALL TABLE (INSERT/UPDATE) WE WILL ADD THE CHANGES ON THE CLIENT_CALL_HISTORY
CREATE TABLE CLIENT_PHONE_NUMBER_CALL_HISTORY(
	ID_CLIENT_PHONE_NUMBER_CALL_HISTORY NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT_PHONE_NUMBER_CALL NUMBER(10),
	ID_STATUS_TYPE NUMBER(10),
	ID_NETWORK NUMBER(10),
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	CALL_ACCEPTED NUMBER(1),
	CALL_ACCEPTED_DATE DATE NULL,
	CALL_COMPLETED_DATE DATE NULL,
	CALL_ATTEMPTED_SECONDS NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	CONSTRAINT FK_CLIENT_PHONE_NUMBER_CALL_HISTORY_ID_CLIENT_PHONE_NUMBER_CALL
	FOREIGN KEY (ID_CLIENT_PHONE_NUMBER_CALL) REFERENCES CLIENT_PHONE_NUMBER_CALL(ID_CALL),
	CONSTRAINT FK_CLIENT_PHONE_NUMBER_CALL_HISTORY_ID_STATUS_TYPE
	FOREIGN KEY (ID_STATUS_TYPE) REFERENCES CALL_STATUS_TYPE(ID_CALL_STATUS_TYPE),
	CONSTRAINT FK_CLIENT_PHONE_NUMBER_CALL_HISTORY_ID_NETWORK
	FOREIGN KEY (ID_NETWORK) REFERENCES NETWORK(ID_NETWORK),
	CONSTRAINT FK_CLIENT_PHONE_NUMBER_CALL_HISTORY_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)


CREATE TABLE NOTIFICATION_STATUS(
	ID_NOTIFICATION_STATUS NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE
)

CREATE TABLE NOTIFICATION(
	ID_NOTIFICATION NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10), -- WE WILL HAVE 2 REGISTRIES TO THE SAME ID_CLIENT PER ENTRY, TARGET AND SOURCE
	-- THE CALL ID TO SEND THE NOTIFICATION NULLABLE
	ID_CLIENT_PHONE_NUMBER_CALL NUMBER(10) DEFAULT NULL,
	ID_STATUS NUMBER(10),
	TARGET_NUMBER nvarchar2(20), -- THE TARGET NUMBER TO SEND THE NOTIFICATION
	NOTIFICATION_DATE DATE DEFAULT SYSDATE,
	CREATED_AT DATE DEFAULT SYSDATE,
	COMPLETED NUMBER(1) DEFAULT 0,  -- IF THE NOTIFICATION HAS BEEN COMPLETED
	CONSTRAINT FK_NOTIFICATION_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_NOTIFICATION_ID_STATUS
	FOREIGN KEY (ID_STATUS) REFERENCES NOTIFICATION_STATUS(ID_NOTIFICATION_STATUS),
	CONSTRAINT FK_NOTIFICATION_ID_CLIENT_PHONE_NUMBER_CALL
	FOREIGN KEY (ID_CLIENT_PHONE_NUMBER_CALL) REFERENCES CLIENT_PHONE_NUMBER_CALL(ID_CALL)
)

CREATE TABLE SMS_STATUS_TYPE(
	ID_SMS_STATUS_TYPE NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	NAME NVARCHAR2(255),
	CREATED_AT DATE DEFAULT SYSDATE,
	DELETED NUMBER(1) DEFAULT 0
)

CREATE TABLE SMS(
	ID_SMS NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_CLIENT NUMBER(10),
	ID_STATUS_TYPE NUMBER(10), -- THE CURRENT STATUS CAN BE: SENT, DELIVERED, NOT DELIVERED, SENDING
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	IS_COMPLETED NUMBER(1) DEFAULT 0,
	DESTINY_NUMBER NVARCHAR2(20),
	CREATED_AT DATE DEFAULT SYSDATE,
	SENT_DATE DATE NULL,
	MESSAGE NVARCHAR2(255),
	COST_VALUE NUMBER(10) NULL,
	CONSTRAINT FK_SMS_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_SMS_ID_STATUS_TYPE
	FOREIGN KEY (ID_STATUS_TYPE) REFERENCES SMS_STATUS_TYPE(ID_SMS_STATUS_TYPE),
	CONSTRAINT FK_SMS_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)

CREATE TABLE SMS_HISTORY(
	ID_SMS_HISTORY NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_SMS NUMBER(10),
	ID_STATUS_TYPE NUMBER(10),
	CREATED_AT DATE DEFAULT SYSDATE,
	COST NUMBER(10) NULL,
	CONSTRAINT FK_SMS_HISTORY_ID_SMS
	FOREIGN KEY (ID_SMS) REFERENCES SMS(ID_SMS),
	CONSTRAINT FK_SMS_HISTORY_ID_STATUS_TYPE
	FOREIGN KEY (ID_STATUS_TYPE) REFERENCES SMS_STATUS_TYPE(ID_SMS_STATUS_TYPE)
)

CREATE TABLE INVOICE_SMS(
	ID_INVOICE_SMS NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	ID_SMS NUMBER(10),
	ID_CLIENT NUMBER(10),
	PHONE_NUMBER_TARGET NVARCHAR2(20),
	INVOICE_DATE DATE DEFAULT SYSDATE,
	VALUE NUMBER(10),
	CONSTRAINT FK_INVOICE_SMS_ID_SMS
	FOREIGN KEY (ID_SMS) REFERENCES SMS(ID_SMS),
	CONSTRAINT FK_INVOICE_SMS_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_INVOICE_SMS_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)

CREATE TABLE INVOICE_CALL(
	ID_INVOICE_CALL NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	ID_PHONE_NUMBER_CONTRACT NUMBER(10),
	ID_CLIENT_PHONE_NUMBER_CALL NUMBER(10),
	ID_CLIENT NUMBER(10),
	PHONE_NUMBER_TARGET NVARCHAR2(20),
	INVOICE_DATE DATE DEFAULT SYSDATE,
	VALUE NUMBER(10),
	CONSTRAINT FK_INVOICE_CALL_ID_CLIENT_PHONE_NUMBER_CALL
	FOREIGN KEY (ID_CLIENT_PHONE_NUMBER_CALL) REFERENCES CLIENT_PHONE_NUMBER_CALL(ID_CALL),
	CONSTRAINT FK_INVOICE_CALL_ID_CLIENT
	FOREIGN KEY (ID_CLIENT) REFERENCES CLIENT(ID_CLIENT),
	CONSTRAINT FK_INVOICE_CALL_ID_PHONE_NUMBER_CONTRACT
	FOREIGN KEY (ID_PHONE_NUMBER_CONTRACT) REFERENCES PHONE_NUMBER_CONTRACT(ID_PHONE_NUMBER_CONTRACT)
)
