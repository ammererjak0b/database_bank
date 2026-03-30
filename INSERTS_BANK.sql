--DELETES

DELETE FROM DEPOT_POSITION;
DELETE FROM STOCK_TRANSACTION;
DELETE FROM PAYMENT_TRANSACTION;
DELETE FROM TRANSACTIONS;
DELETE FROM BANK_STATEMENT;
DELETE FROM STOCK;
DELETE FROM ACCOUNT;
DELETE FROM CUSTOMER;
DELETE FROM BANK;
DELETE FROM CUSTOMER_GROUP;
DELETE FROM ADRESS;
DELETE FROM LOCATION;

COMMIT;


INSERT ALL
    INTO LOCATION (zip_code, city, country) VALUES ('5400', 'Hallein', 'Austria')
    INTO LOCATION (zip_code, city, country) VALUES ('5020', 'Salzburg', 'Austria')
    INTO LOCATION (zip_code, city, country) VALUES ('1010', 'Wien', 'Austria')
    INTO LOCATION (zip_code, city, country) VALUES ('80331', 'Muenchen', 'Germany')
SELECT * FROM DUAL;

INSERT ALL
    INTO ADRESS (adress_id, street, house_nr, LOCATION_zip_code, LOCATION_city, LOCATION_country)
        VALUES (1, 'Mozartplatz', '1', '5020', 'Salzburg', 'Austria')
    INTO ADRESS (adress_id, street, house_nr, LOCATION_zip_code, LOCATION_city, LOCATION_country)
        VALUES (2, 'Hauptstrasse', '12', '5400', 'Hallein', 'Austria')
    INTO ADRESS (adress_id, street, house_nr, LOCATION_zip_code, LOCATION_city, LOCATION_country)
        VALUES (3, 'Bergstrasse', '5', '5020', 'Salzburg', 'Austria')
    INTO ADRESS (adress_id, street, house_nr, LOCATION_zip_code, LOCATION_city, LOCATION_country)
        VALUES (4, 'Seestrasse', '8', '1010', 'Wien', 'Austria')
    INTO ADRESS (adress_id, street, house_nr, LOCATION_zip_code, LOCATION_city, LOCATION_country)
        VALUES (5, 'Gewerbepark', '1', '5020', 'Salzburg', 'Austria')
    INTO ADRESS (adress_id, street, house_nr, LOCATION_zip_code, LOCATION_city, LOCATION_country)
        VALUES (6, 'Schillerplatz', '3', '1010', 'Wien', 'Austria')
SELECT * FROM DUAL;

INSERT ALL
    INTO CUSTOMER_GROUP (group_id, group_name) VALUES (1, 'Privatkunden')
    INTO CUSTOMER_GROUP (group_id, group_name) VALUES (2, 'Firmenkunden')
    INTO CUSTOMER_GROUP (group_id, group_name) VALUES (3, 'Premium')
SELECT * FROM DUAL;

INSERT ALL
    INTO BANK (bic, name, ADRESS_adress_id) VALUES ('RZBAATWW123', 'Raiffeisen Bank', 1)
    INTO BANK (bic, name, ADRESS_adress_id) VALUES ('BKAUATWWXXX', 'UniCredit Bank Austria', 6)
SELECT * FROM DUAL;

INSERT ALL
    INTO CUSTOMER (customer_id, customer_number, name, BANK_bic, CUSTOMER_GROUP_group_id, ADRESS_adress_id)
        VALUES (1, 1001, 'Jakob Ammerer', 'RZBAATWW123', 1, 2)
    INTO CUSTOMER (customer_id, customer_number, name, BANK_bic, CUSTOMER_GROUP_group_id, ADRESS_adress_id)
        VALUES (2, 1002, 'Alex Schrattenecker', 'RZBAATWW123', 1, 3)
    INTO CUSTOMER (customer_id, customer_number, name, BANK_bic, CUSTOMER_GROUP_group_id, ADRESS_adress_id)
        VALUES (3, 1003, 'Maria Gruber', 'BKAUATWWXXX', 3, 4)
    INTO CUSTOMER (customer_id, customer_number, name, BANK_bic, CUSTOMER_GROUP_group_id, ADRESS_adress_id)
        VALUES (4, 2001, 'TechCorp GmbH', 'RZBAATWW123', 2, 5)
SELECT * FROM DUAL;

-- ACCOUNT: einzeln eingefuegt damit der Trigger TRG_ACCOUNT_INIT_STATEMENT
-- fuer jeden Account einen ersten leeren Kontoauszug erstellt.
-- INSERT ALL wuerde den Row-Level Trigger nicht feuern.
INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT103200000000123456', DATE '2023-01-15', 'Hauptkonto Jakob', 2500.00, 'GIROKONTO', 1, NULL);

INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT103200000000123457', DATE '2023-01-15', 'Sparkonto Jakob', 10000.00, 'SPARKONTO', 1, NULL);

INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT103200000000123458', DATE '2023-06-01', 'Aktiendepot Jakob', 0.00, 'AKTIENDEPOT', 1, NULL);

INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT103200000000223456', DATE '2023-03-10', 'Hauptkonto Alex', 1800.00, 'GIROKONTO', 2, NULL);

INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT103200000000223457', DATE '2023-03-10', 'Aktiendepot Alex', 0.00, 'AKTIENDEPOT', 2, NULL);

INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT201200000000333456', DATE '2022-11-20', 'Hauptkonto Maria', 5200.00, 'GIROKONTO', 3, NULL);

INSERT INTO ACCOUNT (iban, creation_date, designation, balance, account_type, CUSTOMER_customer_id, ACCOUNT_iban)
VALUES ('AT201200000000443456', DATE '2024-01-05', 'Firmenkonto TechCorp', 48000.00, 'GIROKONTO', 4, NULL);

-- Referenzkonto fuer Sparkonto und Aktiendepot setzen
UPDATE ACCOUNT SET ACCOUNT_iban = 'AT103200000000123456' WHERE iban = 'AT103200000000123457';
UPDATE ACCOUNT SET ACCOUNT_iban = 'AT103200000000123456' WHERE iban = 'AT103200000000123458';
UPDATE ACCOUNT SET ACCOUNT_iban = 'AT103200000000223456' WHERE iban = 'AT103200000000223457';

INSERT ALL
    INTO STOCK (isin, stock_name, available_quantity, price)
        VALUES ('US0378331005', 'Apple Inc.',       500,  178.50)
    INTO STOCK (isin, stock_name, available_quantity, price)
        VALUES ('US5949181045', 'Microsoft Corp.',  300,  415.20)
    INTO STOCK (isin, stock_name, available_quantity, price)
        VALUES ('US02079K3059', 'Alphabet Inc.',    200,  175.80)
    INTO STOCK (isin, stock_name, available_quantity, price)
        VALUES ('DE0005140008', 'Deutsche Bank AG', 1000, 15.30)
    INTO STOCK (isin, stock_name, available_quantity, price)
        VALUES ('AT0000652011', 'OMV AG',            750,  38.90)
SELECT * FROM DUAL;

-- Zweiter Auszug fuer Jakobs Girokonto (Vorgaenger statement_id = 1)
-- Zweiter Auszug fuer Alex Girokonto (Vorgaenger statement_id = 4)
-- Die IDs 1-7 wurden vom Trigger bei Kontoanlage vergeben
INSERT INTO BANK_STATEMENT (
    statement_id, start_date, end_date,
    beginning_balance, ending_balance,
    ACCOUNT_iban, BANK_STATEMENT_statement_id,
    status, deposit_sum, deposit_count,
    withdrawel_sum, withdrawel_count)
VALUES (
    8, DATE '2025-02-01', DATE '2025-02-28',
    3000.00, 2500.00,
    'AT103200000000123456', 1,
    'C', 0.00, 0, 500.00, 2);

INSERT INTO BANK_STATEMENT (
    statement_id, start_date, end_date,
    beginning_balance, ending_balance,
    ACCOUNT_iban, BANK_STATEMENT_statement_id,
    status, deposit_sum, deposit_count,
    withdrawel_sum, withdrawel_count)
VALUES (
    9, DATE '2025-02-01', NULL,
    1800.00, 1800.00,
    'AT103200000000223456', 4,
    'O', 0.00, 0, 0.00, 0);

INSERT ALL
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (1, DATE '2025-01-05', 'Gehaltseingang Januar',  3000.00,  TIMESTAMP '2025-01-05 08:00:00', 'REF-001', NULL, 1, 'AT103200000000123456', 'P')
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (2, DATE '2025-02-10', 'Miete Februar',          -800.00,  TIMESTAMP '2025-02-10 09:15:00', 'REF-002', NULL, 8, 'AT103200000000123456', 'P')
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (3, DATE '2025-02-15', 'Ueberweisung an Alex',   -300.00,  TIMESTAMP '2025-02-15 11:30:00', NULL, 'Schulden', 8, 'AT103200000000123456', 'T')
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (4, DATE '2025-02-15', 'Eingang von Jakob',       300.00,  TIMESTAMP '2025-02-15 11:30:00', NULL, 'Schulden', 9, 'AT103200000000223456', 'T')
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (5, DATE '2025-01-10', 'Gehaltseingang',          1800.00, TIMESTAMP '2025-01-10 08:00:00', 'REF-004', NULL, 4, 'AT103200000000223456', 'P')
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (6, DATE '2025-02-20', 'Apple Aktienkauf',        -357.00, TIMESTAMP '2025-02-20 10:00:00', NULL, 'Aktienkauf Apple', 8, 'AT103200000000123456', 'S')
    INTO TRANSACTIONS (transaction_id, valuta_date, description_text, amount, ts, payment_reference, purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (7, DATE '2025-02-22', 'Microsoft Aktienkauf',    -415.20, TIMESTAMP '2025-02-22 14:00:00', NULL, 'Aktienkauf Microsoft', 8, 'AT103200000000123456', 'S')
SELECT * FROM DUAL;

INSERT ALL
    INTO PAYMENT_TRANSACTION (transaction_id, external_iban, external_bic)
        VALUES (1, 'DE89370400440532013000', 'COBADEFFXXX')
    INTO PAYMENT_TRANSACTION (transaction_id, external_iban, external_bic)
        VALUES (2, 'AT103200000000999999', 'RZBAATWW123')
    INTO PAYMENT_TRANSACTION (transaction_id, external_iban, external_bic)
        VALUES (5, 'DE89370400440532013001', 'COBADEFFXXX')
SELECT * FROM DUAL;

INSERT ALL
    INTO STOCK_TRANSACTION (transaction_id, stock_price, stock_quantity, STOCK_isin)
        VALUES (6, 178.50, 2, 'US0378331005')
    INTO STOCK_TRANSACTION (transaction_id, stock_price, stock_quantity, STOCK_isin)
        VALUES (7, 415.20, 1, 'US5949181045')
SELECT * FROM DUAL;

INSERT ALL
    INTO DEPOT_POSITION (depot_iban, STOCK_isin, ACCOUNT_iban, purchase_date, purchase_price)
        VALUES ('AT103200000000123458', 'US0378331005', 'AT103200000000123458', DATE '2025-02-20', 178.50)
    INTO DEPOT_POSITION (depot_iban, STOCK_isin, ACCOUNT_iban, purchase_date, purchase_price)
        VALUES ('AT103200000000123458', 'US5949181045', 'AT103200000000123458', DATE '2025-02-22', 415.20)
    INTO DEPOT_POSITION (depot_iban, STOCK_isin, ACCOUNT_iban, purchase_date, purchase_price)
        VALUES ('AT103200000000223457', 'AT0000652011', 'AT103200000000223457', DATE '2025-01-15', 38.90)
SELECT * FROM DUAL;

COMMIT;