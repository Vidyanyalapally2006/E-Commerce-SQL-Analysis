-- E-Commerce SQL Analysis
-- 05 - Seller & Regional Analysis

USE ecommerce_analysis;


-- 1. Seller revenue performance

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
ORDER BY total_revenue DESC
LIMIT 15;


-- 2. Seller revenue efficiency

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 20
ORDER BY revenue_per_order DESC
LIMIT 20;


-- 3. Seller performance by state

SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS seller_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(*) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state
ORDER BY total_revenue DESC;


-- 4. Seller state to customer state routes

SELECT
    s.seller_state AS seller_state,
    c.customer_state AS customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state, c.customer_state
ORDER BY revenue DESC
LIMIT 20;


-- 5. Same-state vs cross-state sales

SELECT
    CASE
        WHEN s.seller_state = c.customer_state
            THEN 'Same-State Sale'
        ELSE 'Cross-State Sale'
    END AS sale_type,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        100 * SUM(oi.price)
        / SUM(SUM(oi.price)) OVER (),
        2
    ) AS revenue_share_percent
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY sale_type
ORDER BY total_revenue DESC;


-- 6. Seller revenue concentration

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id
),
ranked_sellers AS (
    SELECT
        seller_id,
        revenue,
        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS seller_rank
    FROM seller_revenue
)
SELECT
    seller_rank,
    seller_id,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_percent,
    ROUND(
        100 * SUM(revenue) OVER (
            ORDER BY seller_rank
        ) / SUM(revenue) OVER (),
        2
    ) AS cumulative_revenue_percent
FROM ranked_sellers
WHERE seller_rank <= 20
ORDER BY seller_rank;


-- 7. Seller-state revenue contribution

WITH state_revenue AS (
    SELECT
        s.seller_state,
        SUM(oi.price) AS revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_state
)
SELECT
    seller_state,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_percent
FROM state_revenue
ORDER BY revenue DESC;


-- 8. Customer-state revenue

SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- 9. Regional revenue efficiency

SELECT
    s.seller_state AS seller_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY revenue_per_order DESC;