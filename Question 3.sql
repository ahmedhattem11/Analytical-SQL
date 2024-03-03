/*
You are given the below dataset, Which is the daily purchasing transactions for customers.
You are required to answer two questions:
a- What is the maximum number of consecutive days a customer made purchases?
b- On average, How many days/transactions does it take a customer to reach a spent threshold of 250 L.E?
*/

--Creating the table
CREATE TABLE transactions
(
    Cust_Id NUMBER(20),
    Calendar_Dt VARCHAR2(50),
    Amt_LE NUMBER (10,3)
);
------------------------------------------
--a- What is the maximum number of consecutive days a customer made purchases?
WITH difference AS (
    SELECT Cust_Id, calendar_dt,
       calendar_dt - ROW_NUMBER() OVER (PARTITION BY Cust_Id ORDER BY calendar_dt) AS "Group"
    FROM transactions
), count_days as(
SELECT cust_id,
    COUNT("Group") OVER (PARTITION BY "Group", cust_id) AS count_group
FROM difference
    )
SELECT  cust_id, MAX (count_group) as "Max Consecutive Day"
FROM count_days
GROUP BY cust_id
ORDER BY cust_id;
----------------------------------------------------------------------------------------------------------------------
--b- On average, How many days/transactions does it take a customer to reach a spent threshold of 250 L.E?
WITH customers_sales AS (
    SELECT cust_id , calendar_dt ,
    COUNT(calendar_dt) OVER (PARTITION BY cust_id ORDER BY TO_DATE(calendar_dt, 'YYYY-MM-DD')) AS count_days , Amt_LE ,
    SUM(Amt_LE) OVER (PARTITION BY cust_id ORDER BY TO_DATE(calendar_dt, 'YYYY-MM-DD')) AS total_amount
    FROM transactions 
    ) ,

high_amounts AS (
    SELECT cust_id , count_days ,total_amount 
    FROM customers_sales
    WHERE total_amount >=250 
    ) 

SELECT ROUND(AVG (count_days), 2) AS avg_days 
FROM high_amounts
WHERE (cust_id, total_amount) IN (SELECT cust_id , MIN(total_amount) 
                                                FROM high_amounts
                                                   GROUP BY cust_id
                                                   ) ;
                                                   
-----------------------------------------------------------------------------------------------------------------------                                                  




