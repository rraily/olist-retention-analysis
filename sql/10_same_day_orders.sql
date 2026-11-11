WITH orders_d AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp::timestamp AS ts
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
first_o AS (
    SELECT customer_unique_id, MIN(ts) AS first_ts
    FROM orders_d
    GROUP BY customer_unique_id
),
next_o AS (
    SELECT d.customer_unique_id, MIN(d.ts) AS next_ts
    FROM orders_d d
    JOIN first_o f ON f.customer_unique_id = d.customer_unique_id
    WHERE d.ts > f.first_ts
    GROUP BY d.customer_unique_id
)
SELECT
    CASE
        WHEN h < 1  THEN '1. Under 1 hour'
        WHEN h < 6  THEN '2. 1-6 hours'
        ELSE '3. 6-24 hours'
    END AS gap,
    COUNT(*) AS customers
FROM (
    SELECT EXTRACT(EPOCH FROM (n.next_ts - f.first_ts)) / 3600 AS h
    FROM first_o f
    JOIN next_o n ON n.customer_unique_id = f.customer_unique_id
    WHERE f.first_ts >= '2017-01-01' AND f.first_ts < '2018-03-01'
) t
WHERE h < 24
GROUP BY 1
ORDER BY 1;
