-- 1

select sum(base_msrp)
from products
where product_type = 'automobile';

-- 2

select 
customer_id,
avg(sales_amount) as avg_check
from sales
group by customer_id
order by customer_id;

-- 3


select dealership_id,
    count(distinct product_id) as unique_products
from sales
group by dealership_id
having count(distinct product_id) > 5
order by unique_products desc;