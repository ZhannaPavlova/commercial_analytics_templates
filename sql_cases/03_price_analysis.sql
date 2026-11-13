/* Анализ ценообразования и отклонений от рынка.
Задача: Вывести список всех SKU и в соседнем столбце рассчитать среднюю цену 
вообще всех товаров в базе данных для экспресс-анализа переоцененных позиций. */

SELECT
    product_name,
    list_price,
    AVG(list_price) OVER() AS avg_price
FROM [BikeStore].[production].[products]
ORDER BY list_price DESC;
