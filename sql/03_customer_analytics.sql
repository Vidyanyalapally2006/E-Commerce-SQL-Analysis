-- E-Commerce SQL Analysis
-- 03 - Customer Analytics

USE ecommerce_analysis;


-- 1. One-time vs repeat customers

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY customer_type
ORDER BY customer_count DESC;


-- 2. Customer order frequency distribution

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    order_count,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;


-- 3. Customer spending by type

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent), 2) AS total_revenue,
    ROUND(AVG(total_spent), 2) AS average_customer_value
FROM customer_value
GROUP BY customer_type;


-- 4. Customer value segmentation

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    CASE
        WHEN total_spent >= 2000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent), 2) AS segment_revenue,
    ROUND(AVG(total_spent), 2) AS average_customer_value
FROM customer_value
GROUP BY customer_segment
ORDER BY segment_revenue DESC;


-- 5. Customer segment revenue contribution

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_segments AS (
    SELECT
        customer_unique_id,
        total_spent,
        CASE
            WHEN total_spent >= 2000 THEN 'High Value'
            WHEN total_spent >= 500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM customer_value
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent), 2) AS segment_revenue,
    ROUND(
        100 * SUM(total_spent)
        / SUM(SUM(total_spent)) OVER (),
        2
    ) AS revenue_contribution_percent
FROM customer_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;


-- 6. Customer quintile analysis

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_quintiles AS (
    SELECT
        customer_unique_id,
        total_spent,
        NTILE(5) OVER (
            ORDER BY total_spent DESC
        ) AS customer_quintile
    FROM customer_value
)
SELECT
    customer_quintile,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_spent), 2) AS quintile_revenue,
    ROUND(
        100 * SUM(total_spent)
        / SUM(SUM(total_spent)) OVER (),
        2
    ) AS revenue_share_percent
FROM customer_quintiles
GROUP BY customer_quintile
ORDER BY customer_quintile;


-- 7. Repeat customer rate

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    SUM(order_count > 1) AS repeat_customers,
    ROUND(
        100 * SUM(order_count > 1) / COUNT(*),
        2
    ) AS repeat_customer_rate_percent
FROM customer_orders;


-- 8. Repeat customers by state

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id, c.customer_state
)
SELECT
    customer_state AS state,
    COUNT(*) AS customer_count,
    SUM(order_count > 1) AS repeat_customers,
    ROUND(
        100 * SUM(order_count > 1) / COUNT(*),
        2
    ) AS repeat_rate_percent
FROM customer_orders
GROUP BY customer_state
ORDER BY repeat_rate_percent DESC;


-- 9. Top repeat customers by total spending

WITH repeat_customers AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
    HAVING COUNT(DISTINCT o.order_id) > 1
)
SELECT
    customer_unique_id,
    order_count,
    ROUND(total_spent, 2) AS total_spent,
    ROUND(
        total_spent / order_count,
        2
    ) AS average_order_value
FROM repeat_customers
ORDER BY total_spent DESC
LIMIT 10;


-- 10. Top customers by revenue contribution

WITH customer_revenue AS (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    ROUND(total_spent, 2) AS total_spent,
    ROUND(
        100 * total_spent
        / SUM(total_spent) OVER (),
        2
    ) AS revenue_contribution_percent
FROM customer_revenue
ORDER BY total_spent DESC
LIMIT 20;