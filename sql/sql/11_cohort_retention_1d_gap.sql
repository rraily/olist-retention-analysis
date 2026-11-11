WITH orders_d AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp::timestamp AS ts
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
first_order AS (
    SELECT customer_unique_id, MIN(ts) AS first_ts
    FROM orders_d
    GROUP BY customer_unique_id
),
later_order AS (
    SELECT d.customer_unique_id, MIN(d.ts) AS later_ts
    FROM orders_d d
    JOIN first_order f ON f.customer_unique_id = d.customer_unique_id
    WHERE d.ts >= f.first_ts + INTERVAL '1 day'
    GROUP BY d.customer_unique_id
)
SELECT
    TO_CHAR(DATE_TRUNC('month', f.first_ts), 'YYYY-MM') AS cohort_month,
    COUNT(*) AS cohort_size,
    COUNT(*) FILTER (WHERE l.later_ts <= f.first_ts + INTERVAL '90 days') AS returned_90d,
    ROUND(100.0 * COUNT(*) FILTER (WHERE l.later_ts <= f.first_ts + INTERVAL '90 days')
          / COUNT(*), 2) AS retention_90d_pct
FROM first_order f
LEFT JOIN later_order l ON l.customer_unique_id = f.customer_unique_id
WHERE f.first_ts >= '2017-01-01' AND f.first_ts < '2018-06-01'
GROUP BY DATE_TRUNC('month', f.first_ts)
ORDER BY DATE_TRUNC('month', f.first_ts);
