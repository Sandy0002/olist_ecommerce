/*
    Business Questions                         KPIs 
 Which products generate the most sales?	Units Sold
Which products generate the most revenue?	Product Revenue
Which products are repeatedly purchased?	Repeat Purchase Count
Which categories receive poor ratings?	Average Review Score by Category
Which categories have high order volume?	Orders by Category
Which product is bought high in volume but low in ratings?
*/

describe facts_order_items;

-- 1. Products bringing more sales
select product.product_category_name, COUNT(ordr.product_id) as purchase_count
from facts_order_items ordr join dim_products product
on ordr.product_id = product.product_id
where product.product_category_name is not null
group by product.product_category_name
order by purchase_count desc;


-- 2. Products generating more revenue
select product.product_category_name,ROUND(SUM(ordr.price),2) as product_revenue
from facts_order_items ordr join dim_products product
on ordr.product_id =  product.product_id
group by product.product_category_name
order by product_revenue DESC;

-- 3.  Which products are repeatedly purchased
with orders as (
    SELECT order_id,product_id from facts_order_items 
    group by order_id,product_id
)

select product.product_category_name, COUNT(ordr.product_id) as purchase_count
from orders ordr join dim_products product
on ordr.product_id = product.product_id
group by product.product_category_name
having purchase_count >1
order by purchase_count desc;


-- 4. Which products receive poor ratings
select product.product_category_name, ROUND(AVG(ordr.review_score),2) as avg_product_rating
from facts_order_items ordr join dim_products product
on ordr.product_id = product.product_id
where product.product_category_name is not null
group by product.product_category_name
having avg_product_rating < 4
order by avg_product_rating;


-- 5. Which products have high product volume
-- Number of orders that included products from that category
WITH order_category AS (
    SELECT DISTINCT
        o.order_id, p.product_category_name
    FROM facts_order_items o
    JOIN dim_products p
        ON o.product_id = p.product_id
)

SELECT
    product_category_name,
    COUNT(order_id) AS order_volume
FROM order_category
GROUP BY product_category_name
ORDER BY order_volume DESC;


-- 6. Volume vs ratings
select product.product_category_name, COUNT(ordr.product_id) as purchase_count, ROUND(AVG(ordr.review_score),2) as avg_product_rating
from facts_order_items ordr join dim_products product
on ordr.product_id = product.product_id
where product.product_category_name is not null
group by product.product_category_name
order by purchase_count desc;