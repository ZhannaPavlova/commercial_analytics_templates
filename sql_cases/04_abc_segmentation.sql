/* Сегментация ассортимента для маркетинговых акций.
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
