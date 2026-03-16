--1

select 
s.sales_amount,
s.sales_transaction_date,
p.base_msrp
from sales s
INNER JOIN products p ON s.product_id = p.product_id
where sales_transaction_date between '2019-01-01 00:00:00' and '2019-12-31 23:59:59' 
LIMIT 20;

--2

select
s.customer_id,
p.product_type,
c.first_name,
c.last_name
from sales s
inner join products p on s.product_id = p.product_id
inner join customers c on s.customer_id = c.customer_id
where product_type = 'automobile'
limit 20;

--3 

SELECT
    customer_id,
    first_name,
    last_name,
    COALESCE(ip_address, 'Unknow IP') as ip_address_new
FROM customers
ORDER BY ip_address NULLS FIRST;

