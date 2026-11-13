/* Анализ динамики продаж Month-over-Month (MoM Growth %).
Задача: Рассчитать скользящую выручку день к дню, а также ежемесячные темпы прироста 
продаж в процентах к прошлому периоду с защитой от ошибок деления на ноль. */

-- Расчет темпов роста продаж (MoM Growth) через функцию LAG
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
