-- E-Commerce SQL Analysis
-- 02 - Advanced SQL Analysis

USE ecommerce_analysis;


-- 1. Five-table JOIN:
-- Revenue by customer state and product category

SELECT
    c.customer_state AS state,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    ROUND(SUM(oi.price), 2) AS revenue
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state, category
ORDER BY c.customer_state, revenue DESC;


-- 2. CTE:
-- Revenue by state and category

WITH state_category_revenue AS (
    SELECT
        c.customer_state AS state,
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name
        ) AS category,
        SUM(oi.price) AS revenue
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_state, category
)
SELECT
    state,
    category,
    ROUND(revenue, 2) AS revenue
FROM state_category_revenue
ORDER BY state, revenue DESC;


-- 3. Category revenue contribution

WITH category_revenue AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name
        ) AS category,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue, 2) AS revenue,
    ROUND(
        100 * revenue / SUM(revenue) OVER (),
        2
    ) AS revenue_share_percent
FROM category_revenue
ORDER BY revenue DESC;


-- 4. Rank categories by revenue

WITH category_revenue AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name
        ) AS category,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
),
ranked_categories AS (
    SELECT
        category,
        revenue,
        RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM category_revenue
)
SELECT
    revenue_rank,
    category,
    ROUND(revenue, 2) AS revenue
FROM ranked_categories
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


-- 5. Customer lifetime value

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 20;


-- 6. Customer value segmentation

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
    customer_unique_id,
    ROUND(total_spent, 2) AS total_spent,
    CASE
        WHEN total_spent >= 2000 THEN 'High Value'
        WHEN total_spent >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_value
ORDER BY total_spent DESC;


-- 7. Monthly revenue with previous month

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        LAG(SUM(oi.price)) OVER (
            ORDER BY DATE_FORMAT(
                o.order_purchase_timestamp,
                '%Y-%m'
            )
        ),
        2
    ) AS previous_month_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- 8. Month-over-month revenue growth

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
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100 * (
            revenue - previous_month_revenue
        ) / previous_month_revenue,
        2
    ) AS growth_percent
FROM monthly_growth
ORDER BY month;


-- 9. Running total revenue

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


-- 10. Rank top products by revenue

WITH product_revenue AS (
    SELECT
        oi.product_id,
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name
        ) AS category,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id, category
),
ranked_products AS (
    SELECT
        product_id,
        category,
        revenue,
        DENSE_RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank
    FROM product_revenue
)
SELECT
    revenue_rank,
    product_id,
    category,
    ROUND(revenue, 2) AS revenue
FROM ranked_products
WHERE revenue_rank <= 10
ORDER BY revenue_rank;


-- 11. Next month's revenue using LEAD()

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS month,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        LEAD(SUM(oi.price)) OVER (
            ORDER BY DATE_FORMAT(
                o.order_purchase_timestamp,
                '%Y-%m'
            )
        ),
        2
    ) AS next_month_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- 12. Rank top customers using ROW_NUMBER()

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
    ROW_NUMBER() OVER (
        ORDER BY total_spent DESC
    ) AS customer_rank,
    customer_unique_id,
    ROUND(total_spent, 2) AS total_spent
FROM customer_revenue
ORDER BY customer_rank
LIMIT 20;


-- 13. Customer revenue contribution

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
        100 * total_spent / SUM(total_spent) OVER (),
        2
    ) AS revenue_contribution_percent
FROM customer_revenue
ORDER BY total_spent DESC
LIMIT 20;


-- 14. Customer quartiles using NTILE()

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
),
customer_quartiles AS (
    SELECT
        customer_unique_id,
        total_spent,
        NTILE(4) OVER (
            ORDER BY total_spent
        ) AS customer_quartile
    FROM customer_revenue
)
SELECT
    customer_quartile,
    COUNT(*) AS customer_count,
    ROUND(MIN(total_spent), 2) AS minimum_spent,
    ROUND(MAX(total_spent), 2) AS maximum_spent,
    ROUND(AVG(total_spent), 2) AS average_spent
FROM customer_quartiles
GROUP BY customer_quartile
ORDER BY customer_quartile;