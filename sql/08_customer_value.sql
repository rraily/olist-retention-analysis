-- Customer value: revenue share by number of orders, and 90-day retention by first order value quartile
WITH order_rev AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        SUM(oi.price) AS rev
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_unique_id
),
cust AS (
    SELECT customer_unique_id, COUNT(*) AS orders, SUM(rev) AS revenue
    FROM order_rev
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN orders = 1 THEN '1. One order'
        WHEN orders = 2 THEN '2. Two orders'
        ELSE '3. Three+ orders'
    END AS segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_customers,
    ROUND(SUM(revenue)::numeric, 0) AS revenue,
    ROUND((100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER ())::numeric, 2) AS pct_revenue,
    ROUND(AVG(revenue)::numeric, 2) AS revenue_per_customer
FROM cust
GROUP BY 1
ORDER BY 1;

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
first_o AS (
    SELECT DISTINCT ON (customer_unique_id)
           customer_unique_id, ts, rev
    FROM order_rev
    ORDER BY customer_unique_id, ts
),
next_o AS (
    SELECT d.customer_unique_id, MIN(d.ts) AS next_ts
    FROM order_rev d
    JOIN first_o f ON f.customer_unique_id = d.customer_unique_id
    WHERE d.ts > f.ts
    GROUP BY d.customer_unique_id
),
bucketed AS (
    SELECT
        f.customer_unique_id, f.ts, f.rev, n.next_ts,
        NTILE(4) OVER (ORDER BY f.rev) AS quartile
    FROM first_o f
    LEFT JOIN next_o n ON n.customer_unique_id = f.customer_unique_id
    WHERE f.ts >= '2017-01-01' AND f.ts < '2018-06-01'
),
agg AS (
    SELECT
        quartile,
        MIN(rev) AS min_rev,
        MAX(rev) AS max_rev,
        COUNT(*) AS customers,
        COUNT(*) FILTER (WHERE next_ts <= ts + INTERVAL '90 days') AS returned_90d
    FROM bucketed
    GROUP BY quartile
)
SELECT
    quartile,
    ROUND(min_rev::numeric, 0) AS min_rev,
    ROUND(max_rev::numeric, 0) AS max_rev,
    customers,
    returned_90d,
    ROUND(100.0 * returned_90d / customers, 2) AS retention_90d_pct,
    ROUND(196 * SQRT((returned_90d::numeric / customers)
          * (1 - returned_90d::numeric / customers) / customers), 2) AS ci95_pm_pp
FROM agg
ORDER BY quartile;
