-- ЗАДАНИЕ 1
EXPLAIN ANALYZE SELECT * FROM salespeople WHERE title = 'Sales Associate';

-- ЗАДАНИЕ 2
CREATE INDEX idx_salespeople_title ON salespeople(title);
EXPLAIN ANALYZE SELECT * FROM salespeople WHERE title = 'Sales Associate';
DROP INDEX idx_salespeople_title;

-- ЗАДАНИЕ 3
EXPLAIN ANALYZE
SELECT c.first_name, c.last_name, s.sales_amount, s.sales_transaction_date
FROM sales s JOIN customers c ON s.customer_id = c.customer_id;

CREATE INDEX idx_sales_customer_id ON sales(customer_id);

EXPLAIN ANALYZE
SELECT c.first_name, c.last_name, s.sales_amount, s.sales_transaction_date
FROM sales s JOIN customers c ON s.customer_id = c.customer_id;

DROP INDEX idx_sales_customer_id;
