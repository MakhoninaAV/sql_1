-- лабораторная работа 4
-- 1
-- Пронумеровать все дилерские центры по географической долготе (longitude) с запада на восток.

select dealership_id, city, state, row_number() over(order by longitude)
from dealerships
order by longitude;

-- 2
--Для каждой продажи вывести сумму продажи и сумму следующей продажи в этом же дилерском центре.

select customer_id, dealership_id, sales_amount, sales_transaction_date,
lead(sales_amount) over (partition by dealership_id order by sales_transaction_date) as next_sale
from sales;

-- 3
--Нарастающий итог выплаченных бонусов (предположим 10% от sales_amount) для каждого продавца.

select customer_id, product_id, sales_amount, sales_amount * 0.10 as bonus_amount,
sum(sales_amount * 0.10) over (partition by customer_id order by sales_transaction_date) as bonus
from sales
order by customer_id;