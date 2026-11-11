WITH orders_d AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp::timestamp AS ts
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
first_o AS (
    SELECT customer_unique_id, MIN(ts) AS first_ts
    FROM orders_d
    GROUP BY customer_unique_id
),
next_o AS (
    SELECT d.customer_unique_id, MIN(d.ts) AS next_ts
    FROM orders_d d
    JOIN first_o f ON f.customer_unique_id = d.customer_unique_id
    WHERE d.ts > f.first_ts
    GROUP BY d.customer_unique_id
),
base AS (
    SELECT
        f.customer_unique_id,
        EXTRACT(EPOCH FROM (n.next_ts - f.first_ts)) / 86400 AS days_to_next
    FROM first_o f
    LEFT JOIN next_o n ON n.customer_unique_id = f.customer_unique_id
    WHERE f.first_ts >= '2017-01-01' AND f.first_ts < '2018-03-01'
),
returners AS (
    SELECT
        CASE
            WHEN days_to_next < 1   THEN '1. Under 1 day'
            WHEN days_to_next <= 7  THEN '2. 1-7 days'
            WHEN days_to_next <= 30 THEN '3. 8-30 days'
            WHEN days_to_next <= 90 THEN '4. 31-90 days'
            ELSE '5. 91-180 days'
        END AS return_bucket
    FROM base
    WHERE days_to_next IS NOT NULL AND days_to_next <= 180
)
SELECT
    return_bucket,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_returners,
    ROUND(100.0 * SUM(COUNT(*)) OVER (ORDER BY return_bucket)
          / SUM(COUNT(*)) OVER (), 1) AS cumulative_pct
FROM returners
GROUP BY return_bucket
ORDER BY return_bucket;
