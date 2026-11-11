WITH orders_d AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp::timestamp AS ts,
        EXTRACT(EPOCH FROM (
            o.order_delivered_customer_date::timestamp
            - o.order_estimated_delivery_date::timestamp
        )) / 86400 AS delay_days
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
first_o AS (
    SELECT DISTINCT ON (customer_unique_id)
           customer_unique_id, ts, delay_days
    FROM orders_d
    ORDER BY customer_unique_id, ts
),
next_o AS (
    SELECT d.customer_unique_id, MIN(d.ts) AS next_ts
    FROM orders_d d
    JOIN first_o f ON f.customer_unique_id = d.customer_unique_id
    WHERE d.ts >= f.ts + INTERVAL '1 day'
    GROUP BY d.customer_unique_id
)
SELECT
    CASE
        WHEN f.delay_days <= 0 THEN '1. On time or early'
        WHEN f.delay_days <= 3 THEN '2. Late 1-3 days'
        ELSE '3. Late 4+ days'
    END AS first_order_bucket,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE n.next_ts <= f.ts + INTERVAL '90 days') AS returned_90d,
    ROUND(100.0 * COUNT(*) FILTER (WHERE n.next_ts <= f.ts + INTERVAL '90 days')
          / COUNT(*), 2) AS retention_90d_pct
FROM first_o f
LEFT JOIN next_o n ON n.customer_unique_id = f.customer_unique_id
WHERE f.ts >= '2017-01-01' AND f.ts < '2018-06-01'
  AND f.delay_days IS NOT NULL
GROUP BY 1
ORDER BY 1;
