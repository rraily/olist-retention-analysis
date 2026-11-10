-- Share of repeat customers and distribution of orders per customer (delivered orders only)
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*)                                          AS customers,
    COUNT(*) FILTER (WHERE orders = 1)                AS one_order,
    COUNT(*) FILTER (WHERE orders >= 2)               AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE orders >= 2) / COUNT(*), 2) AS repeat_rate_pct
FROM customer_orders;

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS orders
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    orders,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY orders
ORDER BY orders;
