/*  Business Questions                          KPIs
Are delayed deliveries affecting ratings?	Review Score vs Delivery Delay
Which states experience the longest delivery times?	Avg Delivery Time by State
Which sellers have the highest delay rates?	Delay Rate by Seller
What percentage of orders arrive after estimated delivery?	Late Delivery 
*/

-- 1. Are delayed deliveries affecting ratings
with orders as (
    select distinct order_id,order_purchase_timestamp,order_delivered_customer_date,review_score
    from facts_order_items
),

delivery_times as (
    select order_id,DATEDIFF(order_delivered_customer_date,order_purchase_timestamp) as delivery_time ,review_score
    from orders
)

select delivery_time,ROUND(AVG(review_score),2)
from delivery_times
where delivery_time is not null
group by delivery_time
order by delivery_time;


-- 2. Which states experience longest delivery time
with orders as (
    select distinct order_id,customer_id,order_purchase_timestamp,order_delivered_customer_date,review_score
    from facts_order_items
)
select cust.customer_state, ROUND(AVG(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp)),2) as delivery_time,
ROUND(AVG(review_score),2) as avg_ratings
from  orders ordr join dim_customers cust
on ordr.customer_id = cust.customer_id
group by cust.customer_state
order by delivery_time desc;


-- 3. Which sellers have highest delay rate
with orders as (
    select distinct order_id,seller_id,order_purchase_timestamp,order_delivered_customer_date
    from facts_order_items
)
select seller_id, ROUND(AVG(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp)),2) as delivery_time
from  orders
group by seller_id
order by delivery_time desc;


-- 4. What percentage of orders arrive after estimated delivery?
WITH orders AS (
    SELECT
        order_id,
        seller_id, MIN(order_estimated_delivery_date) AS estimated_date,  -- earliest estimate
        MAX(order_delivered_customer_date) AS delivered_date   -- actual delivered
    FROM facts_order_items
    GROUP BY order_id, seller_id
)

SELECT 100.0 * SUM(CASE WHEN delivered_date > estimated_date THEN 1 ELSE 0 END
                ) / COUNT(order_id) AS late_deliveries_perc
FROM orders;