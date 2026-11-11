WITH reviews_agg AS (
    SELECT order_id, AVG(review_score) AS score
    FROM reviews
    GROUP BY order_id
),
orders_d AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp::timestamp AS ts
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
first_o AS (
    SELECT DISTINCT ON (customer_unique_id)
           customer_unique_id, order_id, ts
    FROM orders_d
    ORDER BY customer_unique_id, ts
),
next_o AS (
    SELECT d.customer_unique_id, MIN(d.ts) AS next_ts
    FROM orders_d d
    JOIN first_o f ON f.customer_unique_id = d.customer_unique_id
    WHERE d.ts >= f.ts + INTERVAL '1 day'
    GROUP BY d.customer_unique_id
)
SELECT
    CASE
        WHEN r.score <= 2 THEN '1. Low (1-2)'
        WHEN r.score < 4  THEN '2. Mid (above 2, below 4)'
        ELSE '3. High (4-5)'
    END AS first_order_score,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE n.next_ts <= f.ts + INTERVAL '90 days') AS returned_90d,
    ROUND(100.0 * COUNT(*) FILTER (WHERE n.next_ts <= f.ts + INTERVAL '90 days')
          / COUNT(*), 2) AS retention_90d_pct
FROM first_o f
JOIN reviews_agg r ON r.order_id = f.order_id
LEFT JOIN next_o n ON n.customer_unique_id = f.customer_unique_id
WHERE f.ts >= '2017-01-01' AND f.ts < '2018-06-01'
GROUP BY 1
ORDER BY 1;
