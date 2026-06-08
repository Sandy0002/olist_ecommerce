/*
Business Questions                      KPI
How are orders trending over time?	Orders per Month
How is revenue trending?	Revenue per Month
How much does an average order generate?	Average Order Value (AOV)
How quickly are orders approved?	Average Approval Delay
How long do deliveries take?	Average Delivery Time
How efficient is shipping?	Average Shipping Time
How many products are purchased per order?	Average Items per Order
What percentage of orders are delayed?	Delayed Order Rate
*/

DESCRIBE facts_order_items;

-- 1. Orders trend over time
select DATE_FORMAT(order_purchase_timestamp,'%Y-%m') as order_month, 
COUNT(distinct order_id) as orders_count from facts_order_items
group by order_month
order by order_month;


-- 2  Revenue trend over time
with order_counts as (
   SELECT DISTINCT order_id, order_purchase_timestamp, payment_value AS order_revenue
    FROM facts_order_items
)

SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    ROUND(SUM(order_revenue), 2) AS revenue
FROM order_counts
GROUP BY order_month
ORDER BY order_month;


-- 3. Average order value = Total revenue / Number of orders
select DATE_FORMAT(order_purchase_timestamp,'%Y-%m') as order_month,
       ROUND(
        SUM(payment_value) / count(distinct order_id),2
       ) as average_order_value
    from facts_order_items
group by order_month
order by order_month;


-- 4. How quickly approval happens
WITH orders AS (
    SELECT order_id, DATEDIFF(order_approved_at, order_purchase_timestamp) AS approval_days
    FROM facts_order_items
    GROUP BY order_id, order_approved_at, order_purchase_timestamp
)
SELECT ROUND(AVG(approval_days), 2) AS avg_approval_time_days
FROM orders;


-- 5. How long delivery takes
WITH orders AS (
    SELECT order_id, DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days
    FROM facts_order_items
    GROUP BY order_id, order_delivered_customer_date, order_purchase_timestamp
)
SELECT ROUND(AVG(delivery_days), 2) AS avg_delivery_time_days
FROM orders;


-- 6. How efficient is shipping 
WITH orders AS (
    SELECT order_id, DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp) AS shipping_days
    FROM facts_order_items
    GROUP BY order_id, order_delivered_carrier_date, order_purchase_timestamp
)

SELECT ROUND(AVG(shipping_days), 2) AS avg_shipping_time_days
FROM orders;


-- How many products are purchased in an order
WITH orders AS (
    SELECT order_id, count(order_item_id) as num_items 
    FROM facts_order_items
    GROUP BY order_id
)
SELECT ROUND(AVG(num_items), 2) AS avg_num_items
FROM orders;


-- 7. What percentage of orders are delayed
WITH order_delivery_days AS (
    SELECT
        order_id,
        DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) AS delivery_days
    FROM facts_order_items
    GROUP BY order_id, order_delivered_customer_date, order_purchase_timestamp
),
avg_delivery AS (
    SELECT AVG(delivery_days) AS avg_days
    FROM order_delivery_days
)
SELECT
    ROUND(
        SUM(CASE WHEN d.delivery_days > a.avg_days THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS pct_above_average_delivery
FROM order_delivery_days d
CROSS JOIN avg_delivery a;