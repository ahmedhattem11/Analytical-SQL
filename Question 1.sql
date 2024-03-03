/*
Background:
Customers has purchasing transaction that we shall be monitoring to get intuition behind each customer behavior to target the customers in the most efficient and proactive way,
 to increase sales/revenue , improve customer retention and decrease churn.
You will be given a dataset, and you will be required to answer using SQL Analytical functions you have learnt in the course.
Q1- Using OnlineRetail dataset
• write at least 5 analytical SQL queries that tells a story about the data
• write small description about the business meaning behind each query
*/
/*
1- What are the most selling products?
2- What is the monthly sales compared to the average sales?
3- What are the top 3 customers?
4- What are the products that make the most revenue?
5- What is the average time between purchases for each customer?
6- What is the distribution of the total amount spent per customer?
7- How do customers' purchases compare to the average?
*/
----------------------------------------------------------------------------------------------------
--1- What are the most selling products?
with sum_quantity as(
select stockcode, sum(quantity) as total_quantity 
from tableretail
group by stockcode
order by total_quantity desc
)
select stockcode, total_quantity, 
dense_rank() over(order by total_quantity desc) as most_selling
from sum_quantity;
--------------------------------------------------------------------------------------------------------
--2- What is the monthly sales compared to the average sales?

WITH monthly_sales AS (
    SELECT 
        EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS Month,
        EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS Year,
        SUM(price * quantity) AS "Sales/Month",
        AVG(SUM(price * quantity)) OVER() AS Avg_Sales
    FROM tableretail
    GROUP BY EXTRACT(MONTH FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')), EXTRACT(YEAR FROM TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI'))
    ORDER BY Year, Month
)

SELECT 
    Month,
    Year,
    "Sales/Month",
    ROUND(Avg_Sales, 2) AS Avg_Sales,
    ROUND("Sales/Month" - Avg_Sales, 2) AS Difference,
    CASE 
        WHEN "Sales/Month" < Avg_Sales THEN 'Below Average' 
        ELSE 'Above Average' 
    END AS Status
FROM monthly_sales;
----------------------------------------------------------------------------------------------------------
--3- What are the top customers who paid more than 1000?
WITH top_customers AS (
SELECT customer_id, SUM(price * quantity) AS "Amount Paid"
FROM tableretail
GROUP BY customer_id
)
SELECT customer_id, "Amount Paid", DENSE_RANK() OVER(ORDER BY "Amount Paid" DESC) AS "Top Customers"
FROM top_customers
where "Amount Paid" >= 1000;
-----------------------------------------------------------------------------------------------------------
--4- What are the products that make the most revenue?
WITH top_products AS (
SELECT stockcode, SUM(price * quantity) AS "Revenue Made"
FROM tableretail
GROUP BY stockcode
)
SELECT stockcode, "Revenue Made", DENSE_RANK() OVER(ORDER BY "Revenue Made" DESC) AS "Top Products"
FROM top_products;
-------------------------------------------------------------------------------------------------------
--5- What is the average time between purchases for each customer?
WITH cst_visits AS (
    SELECT customer_id, 
        TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI') AS "Invoice Date",
        LAG(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) OVER(PARTITION BY customer_id ORDER BY TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS "Previous Visit",
        TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI') 
            - LAG(TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) OVER(PARTITION BY customer_id ORDER BY TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')) AS "Difference between visits"
    FROM tableretail
    GROUP BY customer_id,  TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')
    ORDER BY customer_id, TO_DATE(invoicedate, 'MM/DD/YYYY HH24:MI')
)
SELECT customer_id, "Invoice Date", "Previous Visit", 
    CASE 
        WHEN "Difference between visits" IS NOT NULL 
        THEN ROUND("Difference between visits", 1) || ' Days'
        ELSE NULL
    END AS "Difference between visits",
    ROUND(AVG("Difference between visits")  OVER(PARTITION BY customer_id), 1) || ' Days' AS "Average Difference"
FROM cst_visits; 
-------------------------------------------------------------------------------------------------------
--6- What is the distribution of the total amount spent per customer?
WITH top_customers AS (
SELECT customer_id, SUM(price * quantity) AS "Amount Paid"
FROM tableretail
GROUP BY customer_id
)
SELECT customer_id, "Amount Paid", 
NTILE(4) OVER(ORDER BY "Amount Paid" DESC) AS Quartile
FROM top_customers;
--------------------------------------------------------------------------------------------------------
--7- How do customers' purchases compare to the average?
WITH top_customers AS (
    SELECT customer_id, 
        SUM(price * quantity) AS "Amount Paid"
    FROM tableretail
    GROUP BY customer_id
)

SELECT customer_id, 
    "Amount Paid",
    ROUND(AVG("Amount Paid") OVER(), 2) AS "Average Purchase",
    "Amount Paid" - ROUND(AVG("Amount Paid") OVER(), 2) AS "Difference",
    CASE
        WHEN "Amount Paid" > ROUND(AVG("Amount Paid") OVER(), 2) THEN 'Above Average'
        ELSE 'Below Average'
    END AS Status
FROM top_customers;
-------------------------------------------------------------------------------------------------------
                  
