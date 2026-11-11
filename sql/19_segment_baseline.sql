WITH reviews_agg AS (
    SELECT order_id, AVG(review_score) AS score
    FROM reviews
    GROUP BY order_id
),
d AS (
    SELECT
        r.score,
        CASE
            WHEN x.delay <= 0 THEN '1. On time or early'
            WHEN x.delay <= 3 THEN '2. Late 1-3 days'
            WHEN x.delay <= 7 THEN '3. Late 4-7 days'
            ELSE '4. Late 8+ days'
        END AS bucket
    FROM (
        SELECT
            o.order_id,
            c.customer_state,
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date::timestamp
                - o.order_estimated_delivery_date::timestamp
            )) / 86400 AS delay
        FROM orders o
        JOIN customers c ON c.customer_id = o.customer_id
        WHERE o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
    ) x
    JOIN reviews_agg r ON r.order_id = x.order_id
    WHERE x.customer_state IN ('CE', 'RJ', 'BA', 'ES', 'PE')
)
SELECT
    COALESCE(bucket, '0. All five states') AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(AVG(score)::numeric, 2) AS avg_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE score <= 2) / COUNT(*), 1) AS pct_low_score
FROM d
GROUP BY ROLLUP (bucket)
ORDER BY 1;
