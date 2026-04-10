-- ============================================
-- Bank Project - Updated DDL
-- Jakob & Alex, SS 2026
-- ============================================
-- Aenderungen gegenueber vorheriger Version:
--   (2) PAYMENT_TRANSACTION: target_iban/bic + FK auf ACCOUNT
--   (3) STOCK_TRANSACTION: direkter FK auf Depot
--   (4) Depot-Typ-Check Trigger fuer STOCK_TRANSACTION
--   (5) Doppelte Trigger am Scriptende entfernt
-- ============================================

CREATE TABLE LOCATION
    (
     zip_code VARCHAR2 (10 CHAR)  NOT NULL,
     city     VARCHAR2 (40 CHAR)  NOT NULL,
     country  VARCHAR2 (32 CHAR)  NOT NULL
    );

ALTER TABLE LOCATION
    ADD CONSTRAINT LOCATION_PK PRIMARY KEY ( zip_code, city, country );

CREATE TABLE ADRESS
    (
     adress_id         INTEGER             NOT NULL,
     street            VARCHAR2 (50 CHAR)  NOT NULL,
     house_nr          VARCHAR2 (10 CHAR)  NOT NULL,
     LOCATION_zip_code VARCHAR2 (10 CHAR)  NOT NULL,
     LOCATION_city     VARCHAR2 (40 CHAR)  NOT NULL,
     LOCATION_country  VARCHAR2 (32 CHAR)  NOT NULL
    );

ALTER TABLE ADRESS
    ADD CONSTRAINT ADRESS_PK PRIMARY KEY ( adress_id );

ALTER TABLE ADRESS
    ADD CONSTRAINT ADRESS_LOCATION_FK FOREIGN KEY ( LOCATION_zip_code, LOCATION_city, LOCATION_country )
        REFERENCES LOCATION ( zip_code, city, country );

CREATE TABLE CUSTOMER_GROUP
    (
     group_id   INTEGER        NOT NULL,
     group_name VARCHAR2 (32)  NOT NULL
    );

ALTER TABLE CUSTOMER_GROUP
    ADD CONSTRAINT CUSTOMER_GROUP_PK PRIMARY KEY ( group_id );

CREATE TABLE BANK
    (
     bic              VARCHAR2 (11 CHAR)  NOT NULL,
     name             VARCHAR2 (32 CHAR)  NOT NULL,
     ADRESS_adress_id INTEGER             NOT NULL
    );

CREATE UNIQUE INDEX BANK__IDX ON BANK ( ADRESS_adress_id ASC );

ALTER TABLE BANK
    ADD CONSTRAINT BANK_PK PRIMARY KEY ( bic );

ALTER TABLE BANK
    ADD CONSTRAINT BANK_ADRESS_FK FOREIGN KEY ( ADRESS_adress_id )
        REFERENCES ADRESS ( adress_id );

CREATE TABLE CUSTOMER
    (
     customer_id             INTEGER             NOT NULL,
     customer_number         INTEGER             NOT NULL,
     name                    VARCHAR2 (32 CHAR)  NOT NULL,
     BANK_bic                VARCHAR2 (11 CHAR)  NOT NULL,
     CUSTOMER_GROUP_group_id INTEGER             NOT NULL,
     ADRESS_adress_id        INTEGER             NOT NULL
    );

CREATE UNIQUE INDEX CUSTOMER__IDX ON CUSTOMER ( ADRESS_adress_id ASC );

ALTER TABLE CUSTOMER
    ADD CONSTRAINT CUSTOMER_PK PRIMARY KEY ( customer_id );

ALTER TABLE CUSTOMER
    ADD CONSTRAINT CUSTOMER_BANK_FK FOREIGN KEY ( BANK_bic )
        REFERENCES BANK ( bic );

ALTER TABLE CUSTOMER
    ADD CONSTRAINT CUSTOMER_CUSTGRP_FK FOREIGN KEY ( CUSTOMER_GROUP_group_id )
        REFERENCES CUSTOMER_GROUP ( group_id );

ALTER TABLE CUSTOMER
    ADD CONSTRAINT CUSTOMER_ADRESS_FK FOREIGN KEY ( ADRESS_adress_id )
        REFERENCES ADRESS ( adress_id );

-- ACCOUNT: Single Type Inheritance mit Diskriminator account_type
-- Subtypen GIROKONTO, SPARKONTO, AKTIENDEPOT werden ueber account_type unterschieden
-- und nicht als separate Tabellen angelegt da alle Konten dieselben Grundattribute teilen
CREATE TABLE ACCOUNT
    (
     iban                 VARCHAR2 (34 CHAR)  NOT NULL,
     creation_date        DATE                NOT NULL,
     designation          NVARCHAR2 (50)      NOT NULL,
     balance              NUMBER (15,2)       NOT NULL,
     account_type         CHAR (16 CHAR)      NOT NULL,
     CUSTOMER_customer_id INTEGER             NOT NULL,
     ACCOUNT_iban         VARCHAR2 (34 CHAR)
    );

CREATE INDEX ACCOUNT__IDX ON ACCOUNT ( ACCOUNT_iban ASC );

ALTER TABLE ACCOUNT
    ADD CONSTRAINT ACCOUNT_PK PRIMARY KEY ( iban );

ALTER TABLE ACCOUNT
    ADD CONSTRAINT CH_ACCOUNT_TYPE
    CHECK ( account_type IN ( 'GIROKONTO', 'SPARKONTO', 'AKTIENDEPOT' ) );

ALTER TABLE ACCOUNT
    ADD CONSTRAINT ACCOUNT_CUSTOMER_FK FOREIGN KEY ( CUSTOMER_customer_id )
        REFERENCES CUSTOMER ( customer_id );

ALTER TABLE ACCOUNT
    ADD CONSTRAINT ACCOUNT_ACCOUNT_FK FOREIGN KEY ( ACCOUNT_iban )
        REFERENCES ACCOUNT ( iban );

CREATE TABLE STOCK
    (
     isin               VARCHAR2 (12 CHAR)  NOT NULL,
     stock_name         VARCHAR2 (50 CHAR)  NOT NULL,
     available_quantity INTEGER             NOT NULL,
     price              NUMBER (15,2)       NOT NULL
    );

ALTER TABLE STOCK
    ADD CONSTRAINT STOCK_PK PRIMARY KEY ( isin );

-- Aenderung (1):
-- Feedback: Spelling "withdrawel" falsch
-- Loesung:  -> "withdrawal_sum" / "withdrawal_count"
CREATE TABLE BANK_STATEMENT
    (
     statement_id                INTEGER         NOT NULL,
     start_date                  DATE            NOT NULL,
     end_date                    DATE,
     beginning_balance           NUMBER (15,2)   NOT NULL,
     ending_balance              NUMBER (15,2)   NOT NULL,
     ACCOUNT_iban                VARCHAR2 (34 CHAR)  NOT NULL,
     BANK_STATEMENT_statement_id INTEGER,
     status                      CHAR (1 CHAR)   NOT NULL,
     deposit_sum                 NUMBER (15,2)   NOT NULL,
     withdrawal_sum              NUMBER (15,2)   NOT NULL,
     withdrawal_count            INTEGER         NOT NULL,
     deposit_count               INTEGER         NOT NULL
    );

CREATE UNIQUE INDEX BANK_STMT__IDX ON BANK_STATEMENT ( BANK_STATEMENT_statement_id ASC );

ALTER TABLE BANK_STATEMENT
    ADD CONSTRAINT BANK_STATEMENT_PK PRIMARY KEY ( statement_id );

ALTER TABLE BANK_STATEMENT
    ADD CONSTRAINT CH_STMT_STATUS CHECK ( status IN ( 'O', 'C' ) );

ALTER TABLE BANK_STATEMENT
    ADD CONSTRAINT BANK_STMT_ACCOUNT_FK FOREIGN KEY ( ACCOUNT_iban )
        REFERENCES ACCOUNT ( iban );

ALTER TABLE BANK_STATEMENT
    ADD CONSTRAINT BANK_STMT_PREV_FK FOREIGN KEY ( BANK_STATEMENT_statement_id )
        REFERENCES BANK_STATEMENT ( statement_id );

CREATE TABLE DEPOT_POSITION
    (
     depot_iban     VARCHAR2 (34 CHAR)  NOT NULL,
     STOCK_isin     VARCHAR2 (12 CHAR)  NOT NULL,
     ACCOUNT_iban   VARCHAR2 (34 CHAR)  NOT NULL,
     purchase_date  DATE                NOT NULL,
     purchase_price NUMBER (15,2)       NOT NULL
    );

ALTER TABLE DEPOT_POSITION
    ADD CONSTRAINT DEPOT_POSITION_PK PRIMARY KEY ( depot_iban, STOCK_isin, ACCOUNT_iban );

ALTER TABLE DEPOT_POSITION
    ADD CONSTRAINT DEPOT_POSITION_UQ UNIQUE ( depot_iban, STOCK_isin, purchase_date );

ALTER TABLE DEPOT_POSITION
    ADD CONSTRAINT DEPOT_POS_ACCOUNT_FK FOREIGN KEY ( ACCOUNT_iban )
        REFERENCES ACCOUNT ( iban );

ALTER TABLE DEPOT_POSITION
    ADD CONSTRAINT DEPOT_POS_STOCK_FK FOREIGN KEY ( STOCK_isin )
        REFERENCES STOCK ( isin );

-- TRANSACTIONS: Table Per Child Inheritance mit Diskriminator transaction_type
-- Gemeinsame Attribute auf TRANSACTIONS, Subtypen haben nur ihre spezifischen Felder
CREATE TABLE TRANSACTIONS
    (
     transaction_id              INTEGER             NOT NULL,
     valuta_date                 DATE                NOT NULL,
     description_text            VARCHAR2 (50 CHAR),
     amount                      NUMBER (15,2)       NOT NULL,
     ts                          TIMESTAMP           NOT NULL,
     payment_reference           VARCHAR2 (32 CHAR),
     purpose                     VARCHAR2 (32 CHAR),
     BANK_STATEMENT_statement_id INTEGER             NOT NULL,
     ACCOUNT_iban                VARCHAR2 (34 CHAR)  NOT NULL,
     transaction_type            CHAR (1 CHAR)       NOT NULL
    );

ALTER TABLE TRANSACTIONS
    ADD CONSTRAINT TRANSACTIONS_PK PRIMARY KEY ( transaction_id );

ALTER TABLE TRANSACTIONS
    ADD CONSTRAINT CH_INH_TRANSACTION
    CHECK ( transaction_type IN ( 'P', 'S', 'T' ) );

-- purpose und payment_reference sind fachlich ausschliessend
ALTER TABLE TRANSACTIONS
    ADD CONSTRAINT CHK_PURPOSE_PAYREF
    CHECK ( NOT ( purpose IS NOT NULL AND payment_reference IS NOT NULL ) );

ALTER TABLE TRANSACTIONS
    ADD CONSTRAINT TRANS_ACCOUNT_FK FOREIGN KEY ( ACCOUNT_iban )
        REFERENCES ACCOUNT ( iban );

ALTER TABLE TRANSACTIONS
    ADD CONSTRAINT TRANS_BANK_STMT_FK FOREIGN KEY ( BANK_STATEMENT_statement_id )
        REFERENCES BANK_STATEMENT ( statement_id );

-- Aenderung (2):
-- Feedback: interne Transaktionen nicht abbildbar, "external" zu eng gefasst
-- Loesung:  - external_iban/bic -> target_iban/bic (abstraktere Benennung)
--           - neuer optionaler FK target_account_iban auf ACCOUNT
--           - intern: FK gesetzt, Empfaenger aus eigenen Konten verknuepft
--           - extern: FK = NULL, target_iban/bic tragen die Info
CREATE TABLE PAYMENT_TRANSACTION
    (
     transaction_id      INTEGER             NOT NULL,
     target_iban         VARCHAR2 (34 CHAR)  NOT NULL,
     target_bic          CHAR (11 CHAR)      NOT NULL,
     target_account_iban VARCHAR2 (34 CHAR)
    );

ALTER TABLE PAYMENT_TRANSACTION
    ADD CONSTRAINT PAYMENT_TRANSACTION_PK PRIMARY KEY ( transaction_id );

ALTER TABLE PAYMENT_TRANSACTION
    ADD CONSTRAINT PYMNT_TRANS_FK FOREIGN KEY ( transaction_id )
        REFERENCES TRANSACTIONS ( transaction_id );

ALTER TABLE PAYMENT_TRANSACTION
    ADD CONSTRAINT TARGET_ACCOUNT_IBAN_FK FOREIGN KEY ( target_account_iban )
        REFERENCES ACCOUNT ( iban );

-- Aenderung (3):
-- Feedback: Zuordnung Depot <-> Aktientransaktion nur ueber Umweg Kunde
-- Loesung:  - direkter FK depot_iban auf ACCOUNT (Aktiendepot)
--           - Queries "alle Trades eines Depots" jetzt ohne Join-Umweg
--           - Typsicherheit per Trigger siehe Aenderung (4)
CREATE TABLE STOCK_TRANSACTION
    (
     transaction_id INTEGER             NOT NULL,
     stock_price    NUMBER (15,2)       NOT NULL,
     stock_quantity INTEGER             NOT NULL,
     STOCK_isin     VARCHAR2 (12 CHAR)  NOT NULL,
     depot_iban     VARCHAR2 (34 CHAR)  NOT NULL
    );

ALTER TABLE STOCK_TRANSACTION
    ADD CONSTRAINT STOCK_TRANSACTION_PK PRIMARY KEY ( transaction_id );

ALTER TABLE STOCK_TRANSACTION
    ADD CONSTRAINT STOCK_TRANS_FK FOREIGN KEY ( transaction_id )
        REFERENCES TRANSACTIONS ( transaction_id );

ALTER TABLE STOCK_TRANSACTION
    ADD CONSTRAINT STOCK_TRANS_STOCK_FK FOREIGN KEY ( STOCK_isin )
        REFERENCES STOCK ( isin );

ALTER TABLE STOCK_TRANSACTION
    ADD CONSTRAINT DEPOT_STOCK_TR_FK FOREIGN KEY ( depot_iban )
        REFERENCES ACCOUNT ( iban );

-- Trigger: Diskriminator PAYMENT_TRANSACTION
CREATE OR REPLACE TRIGGER ARC_FK_PAYMENT_TRANS
BEFORE INSERT OR UPDATE OF transaction_id
ON PAYMENT_TRANSACTION
FOR EACH ROW
DECLARE
    d CHAR (1);
BEGIN
    SELECT A.transaction_type INTO d
    FROM TRANSACTIONS A
    WHERE A.transaction_id = :new.transaction_id;
    IF ( d IS NULL OR d <> 'P' ) THEN
        raise_application_error(-20223, 'PAYMENT_TRANSACTION requires transaction_type = P');
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
    WHEN OTHERS THEN RAISE;
END;
/

-- Trigger: Diskriminator STOCK_TRANSACTION
CREATE OR REPLACE TRIGGER ARC_FK_STOCK_TRANS
BEFORE INSERT OR UPDATE OF transaction_id
ON STOCK_TRANSACTION
FOR EACH ROW
DECLARE
    d CHAR (1);
BEGIN
    SELECT A.transaction_type INTO d
    FROM TRANSACTIONS A
    WHERE A.transaction_id = :new.transaction_id;
    IF ( d IS NULL OR d <> 'S' ) THEN
        raise_application_error(-20223, 'STOCK_TRANSACTION requires transaction_type = S');
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL;
    WHEN OTHERS THEN RAISE;
END;
/

-- Aenderung (4):
-- Feedback (Folge aus 3): FK depot_iban zeigt auf ACCOUNT-Supertyp,
--          kein DB-seitiger Schutz dass wirklich ein Aktiendepot referenziert wird
-- Loesung: Trigger prueft account_type = 'AKTIENDEPOT' bei Insert/Update
CREATE OR REPLACE TRIGGER CHK_DEPOT_TYPE
BEFORE INSERT OR UPDATE OF depot_iban
ON STOCK_TRANSACTION
FOR EACH ROW
DECLARE
    t CHAR (16);
BEGIN
    SELECT A.account_type INTO t
    FROM ACCOUNT A
    WHERE A.iban = :new.depot_iban;
    IF ( t IS NULL OR TRIM(t) <> 'AKTIENDEPOT' ) THEN
        raise_application_error(-20224, 'depot_iban must reference an AKTIENDEPOT');
    END IF;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        raise_application_error(-20225, 'depot_iban references non-existing ACCOUNT');
    WHEN OTHERS THEN RAISE;
END;
/

CREATE OR REPLACE TRIGGER TRG_ACCOUNT_INIT_STATEMENT
AFTER INSERT ON ACCOUNT
FOR EACH ROW
BEGIN
    INSERT INTO BANK_STATEMENT (
        statement_id, start_date, end_date,
        beginning_balance, ending_balance,
        ACCOUNT_iban, BANK_STATEMENT_statement_id,
        status, deposit_sum, deposit_count,
        withdrawal_sum, withdrawal_count)
    VALUES (
        SEQ_STATEMENT_ID.NEXTVAL, SYSDATE, NULL,
        0.00, 0.00,
        :new.iban, NULL,
        'O', 0.00, 0, 0.00, 0);
END;
/

