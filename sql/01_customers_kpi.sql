use ecommerce;

/* Business Questions                           KPIs
Which regions contribute most customers?	Customer Count by State/City
How satisfied are customers?	Average Review Score
How many customers make repeat purchases?	Repeat Customer Count
How frequently do customers purchase?	Purchase Frequency
Which regions have the highest-value customers?	Revenue per Customer
What is the average customer lifetime value?	CLV
*/


-- Removing unecessary column Unnamed from facts_order_items
ALTER TABLE facts_order_items drop column `Unnamed: 0`; 

-- Fixing date columns
ALTER TABLE facts_order_items
    MODIFY COLUMN order_purchase_timestamp DATETIME,
    MODIFY COLUMN order_approved_at DATETIME,
    MODIFY COLUMN order_delivered_carrier_date DATETIME,
    MODIFY COLUMN order_delivered_customer_date DATETIME,
    MODIFY COLUMN shipping_limit_date DATETIME,
    MODIFY COLUMN order_estimated_delivery_date DATETIME;

--  1. Customer count by city and state
select customer_state,COUNT(customer_state) as state_count from dim_customers
group by customer_state ORDER BY state_count DESC;

select customer_city,COUNT(customer_city) as city_count from dim_customers
group by customer_city ORDER BY city_count DESC;


-- Finding customer base
with customer_base AS (   -- Step 1: Customer per state
    SELECT
        customer_state, COUNT(customer_state) AS num_customers
    FROM dim_customers
    GROUP BY customer_state
),
ranked AS (   -- Step 2: Rank states by number of customers
    SELECT
        customer_state,num_customers, ROW_NUMBER() OVER (ORDER BY num_customers DESC) AS rn,
        SUM(num_customers)  over() AS total_customers  -- this is required as a column in every row hence we use OVER()
    FROM customer_base
) 
SELECT customer_state, num_customers, rn, total_customers,   -- Step 3: computing cummilative distribution
    ROUND(SUM(num_customers) OVER (ORDER BY num_customers DESC),2) AS cum_customer_count,
    -- % cumulative customer base
    ROUND(SUM(num_customers) OVER (ORDER BY num_customers DESC)
        / total_customers,4)*100 AS cum_customers_pct

FROM ranked
ORDER BY rn;


-- Finding duplicate records in orders
WITH duplicate_pairs AS (
    SELECT order_id, payment_value
    FROM facts_order_items
    GROUP BY order_id, payment_value
    HAVING COUNT(*) > 1
)
SELECT f.*
FROM facts_order_items f
JOIN duplicate_pairs d
    ON f.order_id = d.order_id
   AND f.payment_value = d.payment_value
ORDER BY f.order_id, f.payment_value;

-- Observation: There are order level duplicates where item value will differ but other columns in same order id will be same for multiple rows


-- 2. Finding customer satisfaction
select AVG(review_score) from facts_order_items;


-- 3.  Repeating customers 
select customer_unique_id,COUNT(customer_id) as purchase_count from dim_customers
group by customer_unique_id
having purchase_count > 1;


-- 4. Frequency of purchase
with customer_purchase_counts as (
    select customer_unique_id,COUNT(customer_id) as purchase_count 
    from dim_customers
    group by customer_unique_id
)

select purchase_count,COUNT(purchase_count)  as purchase_count_frequency
from customer_purchase_counts
group by purchase_count ORDER BY purchase_count_frequency DESC;


-- 5. Revenue by region
-- Here we are using max(payment_value) as it has been observed that there are duplicates on order level where item value will differ but payment value will be same
WITH order_values AS (
    SELECT 
        order_id,
        customer_id,
        MAX(payment_value) AS payment_value
    FROM facts_order_items
    GROUP BY order_id, customer_id
)

SELECT 
    cust.customer_state,
    ROUND(SUM(ordr.payment_value), 2) AS revenue
FROM dim_customers cust
JOIN order_values ordr 
    ON cust.customer_id = ordr.customer_id
GROUP BY cust.customer_state
ORDER BY revenue DESC;


-- 6 High value customers
WITH order_values AS (
    SELECT 
        order_id,
        customer_id,
        MAX(payment_value) AS payment_value
    FROM facts_order_items
    GROUP BY order_id, customer_id
)

select cust.customer_unique_id,ROUND(SUM(ordr.payment_value),2) as revenue 
from dim_customers cust join order_values ordr
on cust.customer_id = ordr.customer_id
group by cust.customer_unique_id
order by revenue desc;


-- High value customers by state
WITH order_values AS (
    SELECT 
        order_id,
        customer_id,
        MAX(payment_value) AS payment_value
    FROM facts_order_items
    GROUP BY order_id, customer_id
)

select cust.customer_state,ROUND(SUM(ordr.payment_value),2) as revenue 
from dim_customers cust join order_values ordr
on cust.customer_id = ordr.customer_id
group by cust.customer_state
order by revenue desc;

-- 7. Customer life time value 
-- CLV=∑Order Value
-- or CLV=Average Order Value×Purchase Frequency×Customer Lifetime

WITH order_values AS (
    SELECT 
        distinct order_id,
        customer_id,
        order_purchase_timestamp,
        payment_value
    FROM facts_order_items
    -- GROUP BY order_id, customer_id,order_purchase_timestamp
)

select cust.customer_unique_id,DATEDIFF(
MAX(ordr.order_purchase_timestamp), MIN(ordr.order_purchase_timestamp)) as retention_period,
COUNT(distinct order_id) as purchase_count ,
ROUND(SUM(ordr.payment_value),2) as revenue
from dim_customers cust join order_values ordr
on cust.customer_id = ordr.customer_id
group by cust.customer_unique_id
order by revenue desc;