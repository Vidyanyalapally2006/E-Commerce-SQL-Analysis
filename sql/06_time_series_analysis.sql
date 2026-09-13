-- E-Commerce SQL Analysis
-- 06 - Time-Series & Growth Analysis

USE ecommerce_analysis;


-- 1. Monthly revenue and order volume

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- 2. Month-over-month revenue growth

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
),
monthly_growth AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY month
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month_revenue, 2)
        AS previous_month_revenue,
    ROUND(
        100 * (revenue - previous_month_revenue)
        / previous_month_revenue,
        2
    ) AS growth_percent
FROM monthly_growth
ORDER BY month;


-- 3. Running total revenue

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue,
    ROUND(
        SUM(SUM(oi.price)) OVER (
            ORDER BY DATE_FORMAT(
                o.order_purchase_timestamp,
                '%Y-%m'
            )
        ),
        2
    ) AS running_total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- 4. Monthly order growth

WITH monthly_orders AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    WHERE o.order_status = 'delivered'
    GROUP BY month
),
order_growth AS (
    SELECT
        month,
        order_count,
        LAG(order_count) OVER (
            ORDER BY month
        ) AS previous_month_orders
    FROM monthly_orders
)
SELECT
    month,
    order_count,
    previous_month_orders,
    ROUND(
        100 * (
            order_count - previous_month_orders
        ) / previous_month_orders,
        2
    ) AS growth_percent
FROM order_growth
ORDER BY month;


-- 5. Monthly average order value

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- 6. Yearly performance

SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY year
ORDER BY year;


-- 7. Year-over-year revenue growth

WITH yearly_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY year
),
yearly_growth AS (
    SELECT
        year,
        revenue,
        LAG(revenue) OVER (
            ORDER BY year
        ) AS previous_year_revenue
    FROM yearly_revenue
)
SELECT
    year,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_year_revenue, 2)
        AS previous_year_revenue,
    ROUND(
        100 * (revenue - previous_year_revenue)
        / previous_year_revenue,
        2
    ) AS growth_percent
FROM yearly_growth
ORDER BY year;


-- 8. Monthly revenue ranking

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT
    RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank,
    month,
    ROUND(revenue, 2) AS revenue
FROM monthly_revenue
ORDER BY revenue_rank;


-- 9. Top 5 revenue months

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue
FROM monthly_revenue
ORDER BY revenue DESC
LIMIT 5;


-- 10. Bottom 5 revenue months

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(
            o.order_purchase_timestamp,
            '%Y-%m'
        ) AS month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue
FROM monthly_revenue
ORDER BY revenue ASC
LIMIT 5;