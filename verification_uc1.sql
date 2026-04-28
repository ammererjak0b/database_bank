-- Verification UC1

-- transaction inserted                                                                                             
  SELECT * FROM TRANSACTIONS WHERE purpose LIKE 'Stock purchase%' ORDER BY transaction_id DESC;                       
                                                                         
--TRANSACTION_ID|VALUTA_DATE            |DESCRIPTION_TEXT|AMOUNT|TS                     |PAYMENT_REFERENCE|PURPOSE                    |BANK_STATEMENT_STATEMENT_ID|ACCOUNT_IBAN        |TRANSACTION_TYPE|
--------------+-----------------------+----------------+------+-----------------------+-----------------+---------------------------+---------------------------+--------------------+----------------+
--           105|2026-04-28 00:00:00.000|                |  76.5|2026-04-28 10:10:50.906|                 |Stock purchase DE0005140008|                          1|AT103200000000123456|S               |
--           104|2026-04-28 00:00:00.000|                |  76.5|2026-04-28 10:09:14.170|                 |Stock purchase DE0005140008|                          1|AT103200000000123456|S               |
--           103|2026-04-28 00:00:00.000|                |  76.5|2026-04-28 10:07:35.060|                 |Stock purchase DE0005140008|                          1|AT103200000000123456|S               |
--           102|2026-04-28 00:00:00.000|                |  76.5|2026-04-28 10:06:08.409|                 |Stock purchase DE0005140008|                          1|AT103200000000123456|S               |
--           101|2026-04-28 00:00:00.000|                |  76.5|2026-04-28 10:04:50.196|                 |Stock purchase DE0005140008|                          1|AT103200000000123456|S               |
--           100|2026-04-28 00:00:00.000|                |  76.5|2026-04-28 10:01:25.768|                 |Stock purchase DE0005140008|                          1|AT103200000000123456|S               |

  -- stock transaction linked                                                                                         
  SELECT * FROM STOCK_TRANSACTION ORDER BY transaction_id DESC;                                                       
          
--  TRANSACTION_ID|STOCK_PRICE|STOCK_QUANTITY|STOCK_ISIN  |DEPOT_IBAN          |
--------------+-----------+--------------+------------+--------------------+
--           105|       15.3|             5|DE0005140008|AT103200000000123458|
--           104|       15.3|             5|DE0005140008|AT103200000000123458|
--           103|       15.3|             5|DE0005140008|AT103200000000123458|
--           102|       15.3|             5|DE0005140008|AT103200000000123458|
--           101|       15.3|             5|DE0005140008|AT103200000000123458|
--           100|       15.3|             5|DE0005140008|AT103200000000123458|
--             7|      415.2|             1|US5949181045|AT103200000000123458|
--             6|      178.5|             2|US0378331005|AT103200000000123458|
  
  -- depot position created                                                                                           
  SELECT * FROM DEPOT_POSITION WHERE depot_iban = 'AT103200000000123458';                                                                                  
--DEPOT_IBAN          |STOCK_ISIN  |ACCOUNT_IBAN        |PURCHASE_DATE          |PURCHASE_PRICE|
--------------------+------------+--------------------+-----------------------+--------------+
--AT103200000000123458|DE0005140008|AT103200000000123458|2026-04-28 00:00:00.000|          15.3|
--AT103200000000123458|US0378331005|AT103200000000123458|2025-02-20 00:00:00.000|         178.5|
--AT103200000000123458|US5949181045|AT103200000000123458|2025-02-22 00:00:00.000|         415.2|
  
  -- stock quantity reduced                                                                                           
  SELECT isin, available_quantity, reserved_quantity FROM STOCK WHERE isin = 'DE0005140008';              
--ISIN        |AVAILABLE_QUANTITY|RESERVED_QUANTITY|
------------+------------------+-----------------+
--DE0005140008|               970|                0|
                                                                                                                      
  -- balance deducted (should be 2500 - 76.50 = 2423.50)                                                              
  SELECT iban, balance FROM ACCOUNT WHERE iban = 'AT103200000000123456'; 
--IBAN                |BALANCE|
--------------------+-------+
--AT103200000000123456|   2041|
  
  
  -- Verification UC2
  -- both transactions (debit src, credit tgt)                                                                        
  SELECT transaction_id, amount, purpose, ACCOUNT_iban, transaction_type
  FROM   TRANSACTIONS                                                                                                 
  ORDER BY transaction_id DESC FETCH FIRST 2 ROWS ONLY;
  
--TRANSACTION_ID|AMOUNT|PURPOSE|ACCOUNT_IBAN        |TRANSACTION_TYPE|
--------------+------+-------+--------------------+----------------+
--           107|   100|test   |AT103200000000223456|T               |
--           106|   100|test   |AT103200000000123456|T               |
                                                                                                                      
  -- balances: jakob -100, alex +100
  SELECT iban, balance FROM ACCOUNT                                                                                   
  WHERE iban IN ('AT103200000000123456', 'AT103200000000223456');                                                     
--IBAN                |BALANCE|
--------------------+-------+
--AT103200000000123456|   1941|
--AT103200000000223456|   1900|                                                       
                                         