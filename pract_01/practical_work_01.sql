--установка расширения для геопространственных вычислений

create extension if not exists cube;
create extension if not exists earthdistance;

--=========================================================
--Блок А. Анализ времени и дат
--Задача А1. Дни недели продаж

--день недели с наибольшим количеством продаж

select 
    to_char(sales_transaction_date, 'Day') as day_of_week,
    extract(dow from sales_transaction_date) as day_number,
    count(*) as transaction_count,
    round(100.0 * count(*) / sum(count(*)) over(), 2) as percentage
from sales
group by day_of_week, day_number
order by transaction_count desc
limit 1;

--дополнительная статистика по всем дням недели

select 
    to_char(sales_transaction_date, 'Day') as day_of_week,
    extract(dow from sales_transaction_date) as day_number,
    count(*) as transaction_count,
    round(avg(sales_amount)::numeric, 2) as avg_sale_amount,
    round(sum(sales_amount)::numeric, 2) as total_sales_amount,
    round(100.0 * count(*) / sum(count(*)) over(), 2) as percentage
from sales
group by day_of_week, day_number
order by day_number;

--=========================================================
--Блок Б. Геопространственный анализ
--Задача Б6. Ближайший дилер для клиентов из Нью-Йорка

with customer_location as (
    select 
        customer_id,
        first_name,
        last_name,
        city,
        point(longitude, latitude) as customer_point
    from customers
    where city = 'New York City'
),
dealer_distance as (
    select 
        c.customer_id,
        c.first_name,
        c.last_name,
        d.dealership_id,
        d.street_address,
        d.city as dealer_city,
        round(
            (c.customer_point <@> point(d.longitude, d.latitude))::numeric, 
            2
        ) as distance_miles,
        row_number() over (
            partition by c.customer_id 
            order by c.customer_point <@> point(d.longitude, d.latitude)
        ) as rn
    from customer_location c
    cross join dealerships d
)
select 
    customer_id,
    first_name,
    last_name,
    dealership_id,
    street_address as dealer_address,
    dealer_city,
    distance_miles
from dealer_distance
where rn = 1
order by distance_miles;

--среднее расстояние до ближайшего дилера для клиентов из нью-йорка

with nearest_dealers as (
    select distinct on (c.customer_id)
        c.customer_id,
        point(c.longitude, c.latitude) <@> point(d.longitude, d.latitude) as distance
    from customers c
    cross join dealerships d
    where c.city = 'New York City'
    order by c.customer_id, distance
)
select 
    count(*) as customers_count,
    round(avg(distance)::numeric, 2) as avg_distance_to_nearest_dealer,
    round(min(distance)::numeric, 2) as min_distance,
    round(max(distance)::numeric, 2) as max_distance
from nearest_dealers;

--=========================================================
--Блок В. Сложные типы (Массивы и JSON)
--Задача В1. История покупок в JSON

--создание представления с json объектами для всех клиентов

create or replace view customer_purchase_history as
select 
    c.customer_id,
    jsonb_build_object(
        'id', c.customer_id,
        'name', c.first_name || ' ' || c.last_name,
        'email', c.email,
        'phone', c.phone,
        'city', c.city,
        'state', c.state,
        'registration_date', c.date_added,
        'total_purchases', count(*),
        'total_amount', coalesce(sum(s.sales_amount), 0),
        'average_check', coalesce(round(avg(s.sales_amount)::numeric, 2), 0),
        'products', coalesce(
            jsonb_agg(distinct p.product_type) filter (where p.product_type is not null),
            '[]'::jsonb
        ),
        'first_purchase', min(s.sales_transaction_date),
        'last_purchase', max(s.sales_transaction_date),
        'dealerships_visited', coalesce(
            array_agg(distinct d.dealership_id::text) filter (where d.dealership_id is not null),
            array[]::text[]
        )
    ) as customer_json
from customers c
left join sales s on c.customer_id = s.customer_id
left join products p on s.product_id = p.product_id
left join dealerships d on s.dealership_id = d.dealership_id
group by c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.city, c.state, c.date_added
order by c.customer_id;

--=========================================================
--запросы для работы с json представлением
--=========================================================

--запрос 1: получить json для конкретного клиента (id=1)

select customer_json
from customer_purchase_history
where customer_id = 1;

--запрос 2: получить первых 5 клиентов

select customer_json
from customer_purchase_history
limit 5;

--запрос 3: клиенты без покупок

select customer_json
from customer_purchase_history
where (customer_json->>'total_purchases')::int = 0;

--запрос 4: топ-5 клиентов по сумме покупок

select 
    customer_json->>'name' as customer_name,
    (customer_json->>'total_amount')::numeric as total_spent,
    (customer_json->>'total_purchases')::int as purchases_count,
    customer_json->>'products' as products
from customer_purchase_history
order by total_spent desc
limit 5;

--запрос 5: клиенты, купившие более 2 разных типов товаров

select 
    customer_json->>'name' as customer_name,
    jsonb_array_length(customer_json->'products') as product_types_count,
    customer_json->'products' as products,
    (customer_json->>'total_amount')::numeric as total_spent
from customer_purchase_history
where jsonb_array_length(customer_json->'products') > 2
order by product_types_count desc;

--=========================================================
--очистка базы данных
--=========================================================

--удаляем представление

drop view if exists customer_purchase_history;

--удаляем расширения

drop extension if exists earthdistance cascade;
drop extension if exists cube cascade;
