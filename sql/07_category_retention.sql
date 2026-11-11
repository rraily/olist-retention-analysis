WITH orders_d AS (
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
    WHERE d.ts > f.ts
    GROUP BY d.customer_unique_id
),
agg AS (
    SELECT
        COALESCE(p.product_category_name, 'unknown') AS category,
        COUNT(*) AS customers,
        COUNT(*) FILTER (WHERE n.next_ts <= f.ts + INTERVAL '90 days') AS returned_90d
    FROM first_o f
    JOIN order_items oi ON oi.order_id = f.order_id AND oi.order_item_id = 1
    LEFT JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN next_o n ON n.customer_unique_id = f.customer_unique_id
    WHERE f.ts >= '2017-01-01' AND f.ts < '2018-06-01'
    GROUP BY 1
)
SELECT
    category,
    customers,
    returned_90d,
    ROUND(100.0 * returned_90d / customers, 2) AS retention_90d_pct,
    ROUND(196 * SQRT((returned_90d::numeric / customers)
          * (1 - returned_90d::numeric / customers) / customers), 2) AS ci95_pm_pp
FROM agg
WHERE customers >= 1000
ORDER BY retention_90d_pct DESC;
