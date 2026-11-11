WITH reviews_agg AS (
    SELECT order_id, AVG(review_score) AS score
    FROM reviews
    GROUP BY order_id
)
SELECT
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE r.score <= 2) AS low_score_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.score <= 2) / COUNT(*), 2) AS pct_low_score
FROM orders o
JOIN reviews_agg r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;
