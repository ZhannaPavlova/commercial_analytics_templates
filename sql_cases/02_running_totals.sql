---Накопительный итог (Running Total) для мониторинга выполнения планов
SELECT 
    order_date,
    SUM(quantity * list_price) AS daily_revenue,
    SUM(SUM(quantity * list_price)) OVER (ORDER BY order_date) AS running_total
FROM sales.orders o
INNER JOIN sales.order_items s 
    ON s.order_id = o.order_id
WHERE order_date BETWEEN '2016-01-01' AND '2016-01-05'
GROUP BY order_date;
