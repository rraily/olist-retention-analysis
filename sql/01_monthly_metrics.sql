-- 01_monthly_metrics.sql
-- Monthly orders, unique customers, revenue and AOV.
-- Only delivered orders (97% of all orders).
-- Revenue = sum of item prices, without freight.
-- customer_unique_id is used as the real customer identifier.

WITH delivered AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
revenue AS (
    SELECT order_id, SUM(price) AS order_revenue
    FROM order_items
    GROUP BY order_id
)
SELECT
    TO_CHAR(d.month, 'YYYY-MM')               AS month,
    COUNT(DISTINCT d.order_id)                AS orders,
    COUNT(DISTINCT d.customer_unique_id)      AS customers,
    ROUND(SUM(r.order_revenue)::numeric, 0)   AS revenue,
    ROUND((SUM(r.order_revenue) / COUNT(DISTINCT d.order_id))::numeric, 2) AS aov
FROM delivered d
JOIN revenue r ON r.order_id = d.order_id
GROUP BY d.month
ORDER BY d.month;
