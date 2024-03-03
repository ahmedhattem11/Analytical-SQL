/*
Implement a Monetary model for customers behavior for product purchasing and segment each customer based on the below groups 
Champions - Loyal Customers - Potential Loyalists – Recent Customers – Promising - Customers Needing Attention - At Risk - Cant Lose Them – Hibernating – Lost 
The customers will be grouped based on 3 main values: 
• Recency => how recent the last transaction is (Hint: choose a reference date, which is the most recent purchase in the dataset ) 
• Frequency => how many times the customer has bought from our store 
• Monetary => how much each customer has paid for our products 
As there are many groups for each of the R, F, and M features, there are also many potential permutations, this number is too much to manage in terms of marketing strategies. 
For this, we would decrease the permutations by getting the average scores of the frequency and monetary (as both of them are indicative to purchase volume anyway)
*/
WITH retail_transactions AS (
    SELECT customer_id, Quantity, Price, Invoice,
        ROUND(MAX(TO_DATE(InvoiceDate, 'MM/DD/YYYY HH24:MI')) OVER () - MAX(TO_DATE(InvoiceDate, 'MM/DD/YYYY HH24:MI')) OVER (PARTITION BY customer_id)) AS Recency
    FROM tableRetail
),
rfm AS (
    SELECT customer_id, Recency,
        COUNT(DISTINCT invoice) AS Frequency,
        SUM(price * quantity) AS Monetary
    FROM retail_transactions 
    GROUP BY customer_id, recency
),
f_score AS (
    SELECT customer_id, recency, frequency,
        NTILE(5) OVER (ORDER BY frequency ) AS F_score,
        monetary,
        ROUND(PERCENT_RANK() OVER (ORDER BY monetary ), 2) AS monetary_percent_rank
    FROM rfm
),
fm_score AS (
    SELECT customer_id, recency, frequency, monetary, monetary_percent_rank,
        NTILE(5) OVER (ORDER BY recency DESC) AS R_score, 
        NTILE(5) OVER (ORDER BY (F_score + monetary_percent_rank) / 2) AS FM_score
    FROM f_score
)
SELECT customer_id, recency, frequency, monetary, R_score, monetary_percent_rank FM_score, 
    ROUND(monetary / SUM(monetary) OVER (), 2) AS monetary_percentage,
    CASE
        WHEN R_score = 5 AND FM_score IN (5, 4) THEN 'Champions'
        WHEN R_score = 4 AND FM_score = 5 THEN 'Champions'
        WHEN R_score = 5 AND FM_score = 2 THEN 'Potential Loyalist'
        WHEN R_score = 4 AND FM_score IN (2 , 3) THEN 'Potential Loyalist'
        WHEN R_score = 3 AND FM_score = 3 THEN 'Potential Loyalist'
        WHEN R_score = 5 AND FM_score = 3 THEN 'Loyal Customers'
        WHEN R_score = 4 AND FM_score = 4 THEN 'Loyal Customers'
        WHEN R_score = 3 AND FM_score IN (5, 4) THEN 'Loyal Customers'
        WHEN R_score = 5 AND FM_score = 1 THEN 'Recent Customer'
        WHEN R_score = 4 AND FM_score = 1 THEN 'Promising'
        WHEN R_score = 3 AND FM_score = 1 THEN 'Promising'
        WHEN R_score = 2 AND FM_score IN (3, 2) THEN 'Needs Attention'
        WHEN R_score = 3 AND FM_score = 2 THEN 'Needs Attention'
        WHEN R_score = 2 AND FM_score IN (5, 4) THEN 'At Risk'
        WHEN R_score = 1 AND FM_score = 3 THEN 'At Risk'
        WHEN R_score = 1 AND FM_score IN (5, 4) THEN 'Cant Lose Them'
        WHEN R_score = 1 AND FM_score = 2 THEN 'Hibernating'
        WHEN R_score = 1 AND FM_score = 1 THEN 'Lost'
        ELSE 'About to sleep '
    END AS Customer_segmentation
FROM fm_score
ORDER BY customer_id DESC;