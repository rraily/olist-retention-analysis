WITH order_rev AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp::timestamp AS ts,
        SUM(oi.price) AS rev
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_unique_id, o.order_purchase_timestamp
),
first_ts AS (
    SELECT customer_unique_id, MIN(ts) AS first_ts
    FROM order_rev
    GROUP BY customer_unique_id
),
cust AS (
    SELECT
        r.customer_unique_id,
        SUM(r.rev) AS revenue,
        BOOL_OR(r.ts >= f.first_ts + INTERVAL '1 day') AS is_repeat
    FROM order_rev r
    JOIN first_ts f ON f.customer_unique_id = r.customer_unique_id
    GROUP BY r.customer_unique_id
)
SELECT
    CASE WHEN is_repeat THEN '2. Repeat (order 1+ day after first)'
         ELSE '1. One purchase day' END AS segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_customers,
    ROUND(SUM(revenue)::numeric, 0) AS revenue,
    ROUND((100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER ())::numeric, 2) AS pct_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS revenue_per_customer
FROM cust
GROUP BY 1
ORDER BY 1;
