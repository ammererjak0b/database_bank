-- UC2: Transfer
-- Bind variables:
--   :customer_id   [B] customer ID
--   :source_iban   [D/E] source account IBAN
--   :target_iban   [F/G/I] target IBAN (own or external — detected automatically)
--   :target_bic    [I] BIC for external transfers (leave empty for internal)
--   :amount        [K] amount in €
--   :transfer_text [K] transfer description / purpose
--   :confirmation  [N] 'j' = confirm, anything else cancels

DECLARE
    -- test values
    v_customer_id  INTEGER      := 1;
    v_src_iban     VARCHAR2(34) := 'AT103200000000123456';
    v_tgt_iban     VARCHAR2(34) := 'AT103200000000223456';
    v_target_bic   VARCHAR2(11) := '';
    v_amount       NUMBER(15,2) := 100;
    v_text         VARCHAR2(32) := 'test';
    v_confirm      CHAR(1)      := 'j';

    v_src_type     CHAR(16);
    v_src_balance  NUMBER(15,2);
    v_src_checking VARCHAR2(34);  -- linked GIROKONTO if source is SPARKONTO
    v_tgt_type     CHAR(16);
    v_tgt_internal VARCHAR2(34);  -- FK iban if target exists internally
    v_tgt_link     VARCHAR2(34);  -- linked GIROKONTO if target is SPARKONTO
    v_trans_type   CHAR(1);       -- 'T' internal, 'P' external
    v_trans_src    INTEGER;
    v_trans_tgt    INTEGER;
    v_stmt_src     INTEGER;
    v_stmt_tgt     INTEGER;
BEGIN
    SAVEPOINT before_transfer;

    -- [C] verify customer exists
    BEGIN
        SELECT customer_id INTO v_customer_id FROM CUSTOMER WHERE customer_id = v_customer_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20200, '[C] Customer not found: ' || v_customer_id);
    END;

    -- [E] validate source account ownership
    BEGIN
        SELECT account_type INTO v_src_type
        FROM   ACCOUNT
        WHERE  iban = v_src_iban AND customer_customer_id = v_customer_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20201, '[E] Source account not found or not owned by customer: ' || v_src_iban);
    END;

    IF v_src_type = 'AKTIENDEPOT' THEN
        RAISE_APPLICATION_ERROR(-20202, '[E] Stock depot cannot be used as source account.');
    END IF;

    -- Row lock — prevents parallel transfers from the same account
    SELECT balance INTO v_src_balance FROM ACCOUNT WHERE iban = v_src_iban FOR UPDATE NOWAIT;

    -- SPARKONTO can only transfer to its linked GIROKONTO
    IF v_src_type = 'SPARKONTO' THEN
        SELECT ACCOUNT_iban INTO v_src_checking FROM ACCOUNT WHERE iban = v_src_iban;
    END IF;

    -- [F/G/I] detect internal vs external target automatically
    BEGIN
        SELECT account_type INTO v_tgt_type FROM ACCOUNT WHERE iban = v_tgt_iban;
        v_tgt_internal := v_tgt_iban;
        v_trans_type   := 'T';
    EXCEPTION WHEN NO_DATA_FOUND THEN
        v_tgt_type     := 'GIROKONTO';
        v_tgt_internal := NULL;
        v_trans_type   := 'P';
    END;

    -- [H] validate account type compatibility
    IF v_tgt_type = 'AKTIENDEPOT' THEN
        ROLLBACK TO before_transfer;
        RAISE_APPLICATION_ERROR(-20205, '[H] Transfer to stock depot not allowed.');
    END IF;

    IF v_src_type = 'SPARKONTO' THEN
        IF v_trans_type = 'P' OR v_tgt_iban != v_src_checking THEN
            ROLLBACK TO before_transfer;
            RAISE_APPLICATION_ERROR(-20206,
                '[H] Savings account can only transfer to its linked checking account (' || v_src_checking || ').');
        END IF;
    END IF;

    IF v_tgt_type = 'SPARKONTO' THEN
        -- only allowed if source is the savings account's linked checking account
        SELECT ACCOUNT_iban INTO v_tgt_link FROM ACCOUNT WHERE iban = v_tgt_iban;
        IF v_tgt_link != v_src_iban THEN
            ROLLBACK TO before_transfer;
            RAISE_APPLICATION_ERROR(-20207, '[H] Transfer to another customer''s savings account not allowed.');
        END IF;
    END IF;

    -- [L] check balance
    IF v_src_balance < v_amount THEN
        ROLLBACK TO before_transfer;
        RAISE_APPLICATION_ERROR(-20208,
            '[L] Insufficient funds.' || CHR(10) ||
            '    Balance: ' || v_src_balance || ' €  |  Amount: ' || v_amount || ' €');
    END IF;

    -- [N] confirm transfer
    IF v_confirm != 'j' THEN
        ROLLBACK TO before_transfer;
        RETURN; -- [Z] cancelled
    END IF;

    -- [O] execute the transfer
    SELECT statement_id INTO v_stmt_src
    FROM   BANK_STATEMENT
    WHERE  ACCOUNT_iban = v_src_iban AND status = 'O' AND ROWNUM = 1;

    INSERT INTO TRANSACTIONS (transaction_id, valuta_date, amount, ts,
                              purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
    VALUES (SEQ_TRANSACTION_ID.NEXTVAL, TRUNC(SYSDATE), v_amount, SYSTIMESTAMP,
            v_text, v_stmt_src, v_src_iban, v_trans_type)
    RETURNING transaction_id INTO v_trans_src;

    -- only external transfers get a PAYMENT_TRANSACTION entry (trigger enforces type='P')
    IF v_trans_type = 'P' THEN
        INSERT INTO PAYMENT_TRANSACTION (transaction_id, target_iban, target_bic, target_account_iban)
        VALUES (v_trans_src, v_tgt_iban, v_target_bic, v_tgt_internal);
    END IF;

    UPDATE ACCOUNT SET balance = balance - v_amount WHERE iban = v_src_iban;

    UPDATE BANK_STATEMENT
    SET    withdrawal_sum   = withdrawal_sum + v_amount,
           withdrawal_count = withdrawal_count + 1,
           ending_balance   = ending_balance - v_amount
    WHERE  statement_id = v_stmt_src;

    -- internal transfer: book counter-entry on target
    IF v_tgt_internal IS NOT NULL THEN

        SELECT statement_id INTO v_stmt_tgt
        FROM   BANK_STATEMENT
        WHERE  ACCOUNT_iban = v_tgt_iban AND status = 'O' AND ROWNUM = 1;

        INSERT INTO TRANSACTIONS (transaction_id, valuta_date, amount, ts,
                                  purpose, BANK_STATEMENT_statement_id, ACCOUNT_iban, transaction_type)
        VALUES (SEQ_TRANSACTION_ID.NEXTVAL, TRUNC(SYSDATE), v_amount, SYSTIMESTAMP,
                v_text, v_stmt_tgt, v_tgt_iban, v_trans_type)
        RETURNING transaction_id INTO v_trans_tgt;

        UPDATE ACCOUNT SET balance = balance + v_amount WHERE iban = v_tgt_iban;

        UPDATE BANK_STATEMENT
        SET    deposit_sum    = deposit_sum + v_amount,
               deposit_count  = deposit_count + 1,
               ending_balance = ending_balance + v_amount
        WHERE  statement_id = v_stmt_tgt;
    END IF;

    COMMIT; -- [P] transfer complete

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO before_transfer;
        RAISE;
END;
