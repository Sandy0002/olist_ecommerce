/*  Business Questions                          KPIs
Which sellers generate the most revenue?	Seller Revenue
Which sellers fulfill the most orders?	Seller Order Count
Which sellers provide better customer experience?	Avg Review Score by Seller
Which sellers deliver fastest?	Avg Delivery Time by Seller
Is revenue concentrated among a few sellers?	Revenue Share of Top Sellers
How distributed are sellers across states ?    Sellers by state
*/

describe dim_sellers;

-- 1. Which sellers generate most revenue
with orders as (
    select distinct order_id,seller_id,payment_value from facts_order_items
)
select seller_id,ROUND(SUM(payment_value),2) as revenue_generated
from orders
group by seller_id
order by revenue_generated desc;


-- 2. Which seller fulfill most orders
with orders as (
    select distinct order_id,seller_id from facts_order_items
)
select seller_id,COUNT(order_id) as orders_fulfilled
from orders
group by seller_id
order by orders_fulfilled desc;


-- 3. Which sellers provide best customer experience
with orders as (
    select distinct order_id,seller_id,review_score from facts_order_items
)
select seller_id,ROUND(AVG(review_score)) as avg_rating
from orders
group by seller_id
order by avg_rating desc, seller_id;


-- 4. Which sellers deliver fastest
WITH orders AS (
    SELECT DISTINCT order_id,  seller_id, order_purchase_timestamp, order_delivered_carrier_date
    FROM facts_order_items
    WHERE order_delivered_carrier_date > order_approved_at
)
SELECT
    seller_id,
    ROUND(AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)),2) AS avg_delivery_time
FROM orders
GROUP BY seller_id
ORDER BY avg_delivery_time;


-- Finding orders which deliverd on same day
WITH orders AS (
    SELECT DISTINCT
        order_id,
        seller_id,
        order_purchase_timestamp,
        order_delivered_carrier_date
    FROM facts_order_items
    WHERE order_delivered_carrier_date > order_approved_at
),
seller_avg AS (
    SELECT
        seller_id,
        AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)) AS avg_delivery_time
    FROM orders
    GROUP BY seller_id
    HAVING AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)) = 0
)
SELECT o.*
FROM orders o
JOIN seller_avg sa
    ON o.seller_id = sa.seller_id
ORDER BY o.seller_id, o.order_id;


-- 5. Is Revenue concentrated among few sellers
-- Step1 : Getting order details
with orders as (SELECT 
   distinct order_id,seller_id,payment_value from facts_order_items
),
seller_revenue AS (   -- Step 2: revenue per seller
    SELECT
        seller_id, ROUND(SUM(payment_value),2) AS revenue
    FROM orders
    GROUP BY seller_id
),
ranked AS (   -- Step 3: Rank seller by revenue
    SELECT
        seller_id,revenue, ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn,
        COUNT(*)  over() AS total_sellers,  -- this is required as a column in every row hence we use OVER()
        SUM(revenue) OVER() as total_revenue
    FROM seller_revenue
) 
SELECT seller_id, revenue, rn, total_sellers,   -- Step 4: computing cummilative distribution
    -- % of sellers (position in ranking)
    (rn * 1.0 / total_sellers) AS seller_pct,
    -- cumulative revenue
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC),2) AS cum_revenue,
    -- % cumulative revenue
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC)
        / total_revenue,2)*100 AS cum_revenue_pct

FROM ranked
ORDER BY rn;

/*
OBSERVATIONS
There are total 3095 sellers out of which:
-> 10% orders are covered by 7 sellers
-> 25% orders are covered by 29 sellers
-> 50% orders are covered by 134 sellers
-> 75% orders are covered by 445 sellers
*/


-- 6. Sellers distribution by state
with sellers as (
    select seller_state, COUNT(seller_id) as num_sellers
    from dim_sellers
    group by seller_state
 
),
rankings as (
    select seller_state,num_sellers, SUM(num_sellers) OVER() as total_sellers,
    ROW_NUMBER() OVER(order by num_sellers desc) as rnk
    from sellers
)

select seller_state,num_sellers,rnk,
        SUM(num_sellers) OVER(order by num_sellers desc,rnk ) as cum_num_sellers,
        ROUND(
            SUM(num_sellers) OVER(order by num_sellers desc,rnk ) *1.0 / total_sellers
        ,4) as cum_num_sellers_perc
        from rankings
order by rnk;