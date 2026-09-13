-- E-Commerce SQL Analysis
-- 04 - Product & Category Analysis

USE ecommerce_analysis;


-- 1. Category performance metrics

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(DISTINCT oi.product_id) AS product_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_revenue DESC;


-- 2. Top 10 categories by revenue

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
        DENSE_RANK() OVER (
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


-- 3. Revenue per product by category

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(DISTINCT oi.product_id) AS product_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT oi.product_id),
        2
    ) AS revenue_per_product
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue_per_product DESC;


-- 4. Highest-priced products with meaningful sales volume

SELECT
    oi.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(*) AS units_sold,
    ROUND(AVG(oi.price), 2) AS average_price,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id, category
HAVING COUNT(*) >= 5
ORDER BY average_price DESC
LIMIT 20;


-- 5. Highest-volume products

SELECT
    oi.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(*) AS units_sold,
    ROUND(AVG(oi.price), 2) AS average_price,
    ROUND(SUM(oi.price), 2) AS total_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id, category
ORDER BY units_sold DESC
LIMIT 20;


-- 6. Category revenue contribution

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
    ) AS revenue_contribution_percent
FROM category_revenue
ORDER BY revenue DESC;


-- 7. Category revenue per order

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY revenue_per_order DESC;


-- 8. Category unit volume

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(*) AS units_sold,
    COUNT(DISTINCT oi.product_id) AS product_count,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY units_sold DESC;


-- 9. Category revenue growth: 2017 vs 2018

WITH yearly_category_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year,
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
      AND YEAR(o.order_purchase_timestamp) IN (2017, 2018)
    GROUP BY year, category
),
category_growth AS (
    SELECT
        category,
        SUM(
            CASE
                WHEN year = 2017 THEN revenue
                ELSE 0
            END
        ) AS revenue_2017,
        SUM(
            CASE
                WHEN year = 2018 THEN revenue
                ELSE 0
            END
        ) AS revenue_2018
    FROM yearly_category_revenue
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue_2017, 2) AS revenue_2017,
    ROUND(revenue_2018, 2) AS revenue_2018,
    ROUND(
        100 * (revenue_2018 - revenue_2017)
        / NULLIF(revenue_2017, 0),
        2
    ) AS growth_percent
FROM category_growth
WHERE revenue_2017 > 0
ORDER BY growth_percent DESC;


-- 10. Meaningful category growth
-- Only categories with at least R$50,000 revenue in 2017

WITH yearly_category_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year,
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
      AND YEAR(o.order_purchase_timestamp) IN (2017, 2018)
    GROUP BY year, category
),
category_growth AS (
    SELECT
        category,
        SUM(
            CASE
                WHEN year = 2017 THEN revenue
                ELSE 0
            END
        ) AS revenue_2017,
        SUM(
            CASE
                WHEN year = 2018 THEN revenue
                ELSE 0
            END
        ) AS revenue_2018
    FROM yearly_category_revenue
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue_2017, 2) AS revenue_2017,
    ROUND(revenue_2018, 2) AS revenue_2018,
    ROUND(
        100 * (revenue_2018 - revenue_2017)
        / revenue_2017,
        2
    ) AS growth_percent
FROM category_growth
WHERE revenue_2017 >= 50000
ORDER BY growth_percent DESC;


-- 11. Declining established categories

WITH yearly_category_revenue AS (
    SELECT
        YEAR(o.order_purchase_timestamp) AS year,
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
      AND YEAR(o.order_purchase_timestamp) IN (2017, 2018)
    GROUP BY year, category
),
category_growth AS (
    SELECT
        category,
        SUM(
            CASE
                WHEN year = 2017 THEN revenue
                ELSE 0
            END
        ) AS revenue_2017,
        SUM(
            CASE
                WHEN year = 2018 THEN revenue
                ELSE 0
            END
        ) AS revenue_2018
    FROM yearly_category_revenue
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue_2017, 2) AS revenue_2017,
    ROUND(revenue_2018, 2) AS revenue_2018,
    ROUND(
        100 * (revenue_2018 - revenue_2017)
        / revenue_2017,
        2
    ) AS decline_percent
FROM category_growth
WHERE revenue_2017 >= 50000
  AND revenue_2018 < revenue_2017
ORDER BY decline_percent ASC;