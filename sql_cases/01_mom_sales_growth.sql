/* Анализ динамики продаж Month-over-Month (MoM Growth %) и Накопительный итог.
Задача: Рассчитать скользящую выручку день к дню, а также ежемесячные темпы прироста 
продаж в процентах к прошлому периоду с защитой от ошибок деления на ноль. */

-- Вариант А: Накопительный итог (Running Total) для мониторинга выполнения планов
SELECT 
    order_date,
    SUM(quantity * list_price) AS daily_revenue,
    SUM(SUM(quantity * list_price)) OVER (ORDER BY order_date) AS running_total
FROM sales.orders o
INNER JOIN sales.order_items s 
    ON s.order_id = o.order_id
WHERE order_date BETWEEN '2016-01-01' AND '2016-01-05'
GROUP BY order_date;

-- Вариант Б: Расчет темпов роста продаж (MoM Growth) через функцию LAG
WITH MonthlyRevenue AS (
    SELECT 
        DATETRUNC(month, o.order_date) AS order_month,
        SUM(i.quantity * i.list_price * (1 - i.discount)) AS current_month_revenue
    FROM [BikeStore].[sales].[orders] o
    JOIN [BikeStore].[sales].[order_items] i 
        ON o.order_id = i.order_id
    GROUP BY DATETRUNC(month, o.order_date)
),
LaggedRevenue AS (
    SELECT 
        order_month,
        current_month_revenue,
        LAG(current_month_revenue, 1) OVER (ORDER BY order_month ASC) AS previous_month_revenue
    FROM MonthlyRevenue
)
SELECT
    order_month,
    ROUND(current_month_revenue, 2) AS current_revenue,
    ROUND(previous_month_revenue, 2) AS previous_revenue,
    ROUND(
        (current_month_revenue - previous_month_revenue) * 100.0 / NULLIF(previous_month_revenue, 0), 
        2
    ) AS MoM_growth_percent
FROM LaggedRevenue;
