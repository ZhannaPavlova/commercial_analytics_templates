/* Расчет KPI и оценка эффективности персонала (SFE).
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
