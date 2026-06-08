/*      KPIs
Which payment methods are most used?	Payment Method Share
Do installment purchases have higher order values?	Avg Order Value by Installments
What is the average number of installments used?	Avg Installments
Which payment methods are associated with high-value purchases?	Revenue by Payment Type
*/

-- 1. What payment methods are most used
select payment_type,COUNT(payment_type) as payment_type_count
from facts_order_items
where payment_type is not null
group by payment_type
order by payment_type_count desc;

select ROUND(COUNT(CASE WHEN payment_type in ('credit_card','boleto') then 1 end) *1.0/
             COUNT(payment_type),3) as payment_perc
from facts_order_items;
 

-- 2. Do installment purchases have higher order values?
WITH orders AS (
    SELECT
        order_id,
        MAX(payment_installments) AS payment_installments,
        MAX(payment_value) AS payment_value
    FROM facts_order_items
    GROUP BY order_id
)

SELECT
    payment_installments,
    ROUND(SUM(payment_value), 2) AS order_value
FROM orders
GROUP BY payment_installments
ORDER BY order_value DESC;


-- 3. What is the average number of installments used
with orders as (
 select order_id,MAX(payment_installments) as payment_installments
 from facts_order_items
 where payment_installments > 0
 group by order_id
)

select AVG(payment_installments) from orders;


--4.  Which payment methods are associated with high value purchases
WITH orders AS (
    SELECT order_id,payment_type,
        MAX(payment_value) AS payment_value
    FROM facts_order_items
    GROUP BY order_id,payment_type
)

SELECT payment_type, ROUND(SUM(payment_value), 2) AS order_value
FROM orders
where payment_type is not null
GROUP BY payment_type
ORDER BY order_value DESC;