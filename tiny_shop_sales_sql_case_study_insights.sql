use data_in_motion;

select * from customers;
select * from order_items;
select * from orders;
select * from products;

-- 1. Which product has the highest price? Only return a single row.
select product_id, product_name, price
from products
order by price desc
limit 1;

-- 2. Which customer has made the most orders?
with cust_orders as
(select c.customer_id, c.first_name, c.last_name, count(o.order_id) as no_of_orders
from customers c join orders o
on c.customer_id=o.customer_id
group by c.customer_id, c.first_name, c.last_name
order by count(order_id) desc)
select * from cust_orders
where no_of_orders in (select max(no_of_orders) from cust_orders);

-- 3. What is the total revenue per product?
select p.product_id, p.product_name, sum(p.price*quantity) as total_revenue
from products p join order_items 
on p.product_id=order_items.product_id
group by p.product_id, p.product_name;

-- 4. Find the day with the higest revenue.
with total_revenue_per_order as 
(select oi.order_id, sum(p.price*oi.quantity) as total_revenue
from products p join order_items oi 
on p.product_id=oi.product_id
group by oi.order_id)
select o.order_id, o.order_date, total_revenue
from orders o join total_revenue_per_order tv
on o.order_id=tv.order_id
order by total_revenue desc
limit 1;

-- 5. Find the first order by date for each customer.
with first_order as
(select *, rank() over(partition by customer_id order by order_date asc) as rnk
from orders)
select order_id, customer_id, order_date
from first_order
where rnk=1;

-- 6. Find the top 3 customers who have ordered the most distinct products.
with high_distinct_product as 
(select o.customer_id, count(distinct ot.product_id) as distinct_product
from order_items ot join orders o
on ot.order_id=o.order_id 
group by customer_id)
select dp.customer_id, c.first_name, c.last_name, distinct_product
from high_distinct_product dp join customers c
on dp.customer_id=c.customer_id
where distinct_product = (select max(distinct_product) from high_distinct_product);

-- 7. Which product has been bought the least in terms of quantity?
with total_quantity as 
(select p.product_id, p.product_name, sum(ot.quantity) as quantity_bought
from order_items ot join products p
on ot.product_id=p.product_id
group by p.product_id, p.product_name)
select product_id, product_name, quantity_bought
from total_quantity
where quantity_bought in (select min(quantity_bought) from total_quantity);

-- 8. What is the median order total?
with m_order as 
(select oi.order_id, sum(p.price*oi.quantity) as total_revenue, row_number() over(order by sum(p.price*oi.quantity) desc) as rnk_desc,
row_number() over(order by sum(p.price*oi.quantity) asc) as rnk_asc
from products p join order_items oi 
on p.product_id=oi.product_id
group by oi.order_id)
select round(avg(total_revenue),2) as median_order 
from m_order
where rnk_asc in (rnk_desc-1, rnk_desc, rnk_desc+1);

-- 9. For each order determine if it was 'Expensive'(total over 300), 'Affordable' (total over 100) or 'Cheap)
with cte as 
(select oi.order_id, sum(p.price*oi.quantity) as total_amount
from products p join order_items oi 
on p.product_id=oi.product_id
group by oi.order_id)
select order_id, total_amount,
case when total_amount>=300 then 'Expensive' 
	 when total_amount>=100 and total_amount<300 then 'Affordable'
     else 'Cheap' end order_type
from cte
order by total_amount desc;

select * from customers;
select * from order_items;
select * from orders;
select * from products;

-- 10. Find customers who have ordered the product with the highest price.
with cte1 as
(select oi.order_id, p.product_id, p.price, p.product_name
from order_items oi join products p 
on oi.product_id = p.product_id),
cte2 as 
(select product_id, price, product_name, o.customer_id
from cte1 join orders o
on cte1.order_id=o.order_id)
select c.customer_id, c.first_name, c.last_name, price
from cte2 join customers c
on cte2.customer_id=c.customer_id
where price=(select max(price) from cte2);

