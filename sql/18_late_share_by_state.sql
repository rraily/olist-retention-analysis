WITH d AS (
    SELECT
        c.customer_state AS state,
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date::timestamp
            - o.order_estimated_delivery_date::timestamp
        )) / 86400 AS delay_days
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    state,
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE delay_days > 0) AS late_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days > 0) / COUNT(*), 1) AS pct_late,
    COUNT(*) FILTER (WHERE delay_days > 3) AS late_4plus,
    ROUND(100.0 * COUNT(*) FILTER (WHERE delay_days > 3) / COUNT(*), 1) AS pct_late_4plus
FROM d
GROUP BY state
HAVING COUNT(*) >= 1000
ORDER BY pct_late_4plus DESC;
