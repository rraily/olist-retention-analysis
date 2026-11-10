WITH reviews_agg AS (
    SELECT order_id, AVG(review_score) AS score
    FROM reviews
    GROUP BY order_id
),
deliv AS (
    SELECT
        o.order_id,
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date::timestamp
            - o.order_estimated_delivery_date::timestamp
        )) / 86400 AS delay_days
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    CASE
        WHEN d.delay_days <= 0 THEN '1. On time or early'
        WHEN d.delay_days <= 3 THEN '2. Late 1-3 days'
        WHEN d.delay_days <= 7 THEN '3. Late 4-7 days'
        ELSE '4. Late 8+ days'
    END AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(AVG(r.score)::numeric, 2) AS avg_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.score <= 2) / COUNT(*), 1) AS pct_low_score
FROM deliv d
JOIN reviews_agg r ON r.order_id = d.order_id
GROUP BY 1
ORDER BY 1;
