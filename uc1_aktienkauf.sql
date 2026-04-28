-- UC1: Stock Purchase
-- Bind variables:
--   :customer_id   [B] customer ID
--   :depot_iban    [D/E] IBAN of the stock depot
--   :isin          [F/G] stock ISIN
--   :quantity      [G] quantity
--   :confirmation  [J] 'j' = confirm, anything else cancels

DECLARE
    -- test values
    v_customer_id   INTEGER      := 1;
    v_depot_iban    VARCHAR2(34) := 'AT103200000000123458';
    v_isin          VARCHAR2(12) := 'DE0005140008';
    v_quantity      INTEGER      := 5;
    v_confirm       CHAR(1)      := 'j';

    v_checking_iban VARCHAR2(34);
    v_checking_bal  NUMBER(15,2);
    v_price         NUMBER(15,2);
    v_total         NUMBER(15,2);
    v_trans_id      TRANSACTIONS.transaction_id%TYPE;
    v_stmt_id       BANK_STATEMENT.statement_id%TYPE;
BEGIN
    SAVEPOINT before_purchase;

    -- [C] verify customer exists
    BEGIN
        SELECT customer_id INTO v_customer_id FROM CUSTOMER WHERE customer_id = v_customer_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20100, '[C] Customer not found: ' || v_customer_id);
    END;

    -- [E] validate depot ownership and fetch linked checking IBAN
    BEGIN
        SELECT ACCOUNT_iban INTO v_checking_iban
        FROM   ACCOUNT
        WHERE  iban = v_depot_iban
          AND  customer_customer_id = v_customer_id
          AND  account_type = 'AKTIENDEPOT';
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20101, '[E] Depot not found or not owned by customer: ' || v_depot_iban);
    END;

    -- [G] get stock price
    BEGIN
        SELECT price INTO v_price
        FROM   STOCK
        WHERE  isin = v_isin AND available_quantity > 0;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20102, '[F] Stock not found or unavailable: ' || v_isin);
    END;

    v_total := v_quantity * v_price;

    -- Reserve shares before the balance check. chk_reserved_lte_available fires
    -- if quantity > available_quantity. Rolled back automatically on cancel or error.
    UPDATE STOCK
    SET    reserved_quantity = reserved_quantity + v_quantity
    WHERE  isin = v_isin;

    -- [H] lock checking account row — ORA-00054 if another session holds it
    SELECT balance INTO v_checking_bal
    FROM   ACCOUNT
    WHERE  iban = v_checking_iban
    FOR UPDATE NOWAIT;

    IF v_checking_bal < v_total THEN
        ROLLBACK TO before_purchase;
        RAISE_APPLICATION_ERROR(-20103,
            '[I] Insufficient funds.' || CHR(10) ||
            '    Checking balance: ' || v_checking_bal || ' €  |  Required: ' || v_total || ' €');
    END IF;

    -- [J] confirm purchase
    IF v_confirm != 'j' THEN
        ROLLBACK TO before_purchase;
        RETURN; -- [Z] cancelled
    END IF;

    -- [K] execute the purchase
    SELECT statement_id INTO v_stmt_id
    FROM   BANK_STATEMENT
    WHERE  ACCOUNT_iban = v_checking_iban AND status = 'O' AND ROWNUM = 1;

    INSERT INTO TRANSACTIONS (transaction_id, valuta_date, amount, ts,
                              purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
    VALUES (SEQ_TRANSACTION_ID.NEXTVAL, TRUNC(SYSDATE), v_total, SYSTIMESTAMP,
            'Stock purchase ' || v_isin, v_stmt_id, v_checking_iban, 'S')
    RETURNING transaction_id INTO v_trans_id;

    INSERT INTO STOCK_TRANSACTION (transaction_id, stock_price, stock_quantity, STOCK_isin, depot_iban)
    VALUES (v_trans_id, v_price, v_quantity, v_isin, v_depot_iban);

    -- unique constraint: max 1 purchase per stock per day; skip if already exists
    MERGE INTO DEPOT_POSITION dp
    USING DUAL
    ON (dp.depot_iban = v_depot_iban AND dp.STOCK_isin = v_isin AND dp.purchase_date = TRUNC(SYSDATE))
    WHEN NOT MATCHED THEN
        INSERT (depot_iban, STOCK_isin, ACCOUNT_iban, purchase_date, purchase_price)
        VALUES (v_depot_iban, v_isin, v_depot_iban, TRUNC(SYSDATE), v_price);

    UPDATE ACCOUNT SET balance = balance - v_total WHERE iban = v_checking_iban;

    -- release reservation and reduce available quantity
    UPDATE STOCK
    SET    available_quantity = available_quantity - v_quantity,
           reserved_quantity  = reserved_quantity  - v_quantity
    WHERE  isin = v_isin;

    UPDATE BANK_STATEMENT
    SET    withdrawal_sum   = withdrawal_sum + v_total,
           withdrawal_count = withdrawal_count + 1,
           ending_balance   = ending_balance - v_total
    WHERE  statement_id = v_stmt_id;

    COMMIT; -- [L] purchase complete

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_purchase;
        RAISE;
END;
