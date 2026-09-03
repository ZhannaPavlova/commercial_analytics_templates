-- ====================================================================================
-- БИБЛИОТЕКА ШАБЛОНОВ T-SQL ДЛЯ КОММЕРЧЕСКОЙ И ФИНАНСОВОЙ АНАЛИТИКИ
-- Кейсы реализованы на демонстрационной базе данных розничной сети (BikeStores)
-- ====================================================================================


/* БИЗНЕС-КЕЙС 1: Сегментация ассортимента для маркетинговых акций.
Маркетологи планируют запустить промо-кампанию на премиальные товары.
Задача: Вывести список товаров с нумерацией от самого дорогого к самому дешевому 
внутри каждой товарной категории, и изолировать ТОП-5 в каждом сегменте. */

-- Вариант А: Полный список с нумерацией внутри категорий
SELECT 
    c.category_name,
    p.product_name,
    p.list_price,
    ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS row_num
FROM [BikeStore].[production].[products] p
INNER JOIN [BikeStore].[production].[categories] c 
    ON c.category_id = p.category_id
ORDER BY c.category_name ASC;

-- Вариант Б: Изоляция ТОП-5 флагманских SKU для фокусного промо
WITH RankedProducts AS (
    SELECT
        c.category_name AS category,
        p.product_name AS prod,
        p.list_price AS price,
        ROW_NUMBER() OVER (PARTITION BY p.category_id ORDER BY p.list_price DESC) AS row_num
    FROM [BikeStore].[production].[products] p
    INNER JOIN [BikeStore].[production].[categories] c 
        ON c.category_id = p.category_id
)
SELECT
    category,
    prod,
    price
FROM RankedProducts
WHERE row_num <= 5
ORDER BY category ASC;


/* БИЗНЕС-КЕЙС 2: Анализ ценообразования и отклонений от рынка.
Задача: Вывести список всех SKU и в соседнем столбце рассчитать среднюю цену 
вообще всех товаров в базе данных для экспресс-анализа переоцененных позиций. */

SELECT
    product_name,
    list_price,
    AVG(list_price) OVER() AS avg_price
FROM [BikeStore].[production].[products]
ORDER BY list_price DESC;


/* БИЗНЕС-КЕЙС 3: Расчет KPI и оценка эффективности персонала (SFE).
Руководство хочет премировать трех лучших сотрудников каждого магазина по итогам продаж.
Задача: Ранжировать продавцов внутри каждого магазина по количеству оформленных заказов. */

WITH OrderQty AS (
    SELECT
        store_id,
        staff_id,
        COUNT(order_id) AS ordr_num
    FROM [BikeStore].[sales].[orders]
    GROUP BY store_id, staff_id
),
RankedStaff AS (
    SELECT
        store_id,
        staff_id,
        ordr_num,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY ordr_num DESC) AS row_num
    FROM OrderQty
)
SELECT
    store_id,
    staff_id,
    ordr_num
FROM RankedStaff
WHERE row_num <= 3;


/* БИЗНЕС-КЕЙС 4: Анализ динамики продаж Month-over-Month (MoM Growth %) и Накопительный итог.
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
