CREATE INDEX IDX_CLIENT_STATUS_NAME ON CLIENT_STATUS (NAME);


CREATE INDEX IDX_CLIENT_PHONE_NUMBER ON CLIENT (PHONE_NUMBER);
CREATE INDEX IDX_CLIENT_FULL_NAME ON CLIENT (FULL_NAME);
CREATE INDEX IDX_CLIENT_ID_STATUS_TYPE ON CLIENT (ID_STATUS_TYPE);
CREATE INDEX IDX_CLIENT_PHONE_NUMBER_NORMALIZED ON CLIENT (PHONE_NUMBER_NORMALIZED);


CREATE INDEX IDX_PLAN_TYPE_NAME ON PLAN_TYPE (NAME);


CREATE INDEX IDX_PLAN_NAME ON PLAN (NAME);
CREATE INDEX IDX_PLAN_ID_PLAN_TYPE ON PLAN (ID_PLAN_TYPE);


CREATE INDEX IDX_CONTRACT_ID_CLIENT ON CONTRACT (ID_CLIENT);
CREATE INDEX IDX_CONTRACT_ID_PLAN ON CONTRACT (ID_PLAN);


CREATE INDEX IDX_NETWORK_PREFIX ON NETWORK (PREFIX);

CREATE INDEX IDX_COMMUNICATION_TYPE_NAME ON COMMUNICATION_TYPE (NAME);

CREATE INDEX IDX_TARRIF_ID_COMMUNICATION_TYPE ON TARRIF (ID_COMMUNICATION_TYPE);
CREATE INDEX IDX_TARRIF_ID_NETWORK ON TARRIF (ID_NETWORK);

CREATE INDEX IDX_PLAN_TARRIF_ID_PLAN ON PLAN_TARRIF (ID_PLAN);
CREATE INDEX IDX_PLAN_TARRIF_ID_TARRIF ON PLAN_TARRIF (ID_TARRIF);

CREATE INDEX IDX_NOTIFICATION_STATUS_NAME ON NOTIFICATION_STATUS (NAME);

CREATE INDEX IDX_NOTIFICATION_ID_CLIENT ON NOTIFICATION (ID_CLIENT);
CREATE INDEX IDX_NOTIFICATION_TARGET_NUMBER ON NOTIFICATION
