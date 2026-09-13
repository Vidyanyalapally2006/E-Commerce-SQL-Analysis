-- E-Commerce SQL Analysis
-- 07 - Business Questions & Strategic Analysis

USE ecommerce_analysis;


-- Business Question 1:
-- Which customer segments generate the most revenue?

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
            WHEN total_spent >= 2000
                THEN 'High Value'
            WHEN total_spent >= 500
                THEN 'Medium Value'
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
    ) AS revenue_share_percent
FROM customer_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;


-- Business Question 2:
-- What percentage of customers generate 80% of revenue?

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
ranked_customers AS (
    SELECT
        customer_unique_id,
        total_spent,
        ROW_NUMBER() OVER (
            ORDER BY total_spent DESC
        ) AS customer_rank,
        SUM(total_spent) OVER (
            ORDER BY total_spent DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_revenue,
        SUM(total_spent) OVER () AS total_revenue
    FROM customer_revenue
)
SELECT
    customer_rank,
    customer_unique_id,
    ROUND(total_spent, 2) AS total_spent,
    ROUND(
        100 * cumulative_revenue / total_revenue,
        2
    ) AS cumulative_revenue_percent
FROM ranked_customers
WHERE cumulative_revenue / total_revenue >= 0.80
ORDER BY customer_rank
LIMIT 1;


-- Business Question 3:
-- Which categories contribute the most revenue?

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
        ON p.product_category_name =
           ct.product_category_name
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
ORDER BY revenue DESC
LIMIT 15;


-- Business Question 4:
-- How concentrated is category revenue?

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
        ON p.product_category_name =
           ct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY category
),
ranked_categories AS (
    SELECT
        category,
        revenue,
        RANK() OVER (
            ORDER BY revenue DESC
        ) AS category_rank
    FROM category_revenue
)
SELECT
    CASE
        WHEN category_rank <= 5
            THEN 'Top 5 Categories'
        WHEN category_rank <= 10
            THEN 'Ranks 6-10'
        ELSE 'Remaining Categories'
    END AS category_group,
    COUNT(*) AS category_count,
    ROUND(SUM(revenue), 2) AS group_revenue,
    ROUND(
        100 * SUM(revenue)
        / SUM(SUM(revenue)) OVER (),
        2
    ) AS revenue_share_percent
FROM ranked_categories
GROUP BY category_group
ORDER BY group_revenue DESC;


-- Business Question 5:
-- Which categories generate high revenue per order?

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name
    ) AS category,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name =
       ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY revenue_per_order DESC;


-- Business Question 6:
-- Which sellers are most efficient?

SELECT
    s.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id, s.seller_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY revenue_per_order DESC
LIMIT 15;


-- Business Question 7:
-- Which states generate the most customer revenue?

SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS revenue_per_order
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;


-- Business Question 8:
-- Which states have the highest repeat customer rates?

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id,
        c.customer_state
)
SELECT
    customer_state AS state,
    COUNT(*) AS customer_count,
    SUM(order_count > 1) AS repeat_customers,
    ROUND(
        100 * SUM(order_count > 1)
        / COUNT(*),
        2
    ) AS repeat_rate_percent
FROM customer_orders
GROUP BY customer_state
ORDER BY repeat_rate_percent DESC;


-- Business Question 9:
-- How much revenue comes from cross-state sales?

SELECT
    CASE
        WHEN s.seller_state = c.customer_state
            THEN 'Same-State Sale'
        ELSE 'Cross-State Sale'
    END AS sale_type,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue,
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
ORDER BY revenue DESC;


-- Business Question 10:
-- How did revenue change from 2017 to 2018?

SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(oi.price), 2) AS revenue,
    ROUND(
        SUM(oi.price)
        / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND YEAR(o.order_purchase_timestamp)
      IN (2017, 2018)
GROUP BY year
ORDER BY year;


-- Business Question 11:
-- Which categories grew or declined from 2017 to 2018?

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
        ON p.product_category_name =
           ct.product_category_name
    WHERE o.order_status = 'delivered'
      AND YEAR(o.order_purchase_timestamp)
          IN (2017, 2018)
    GROUP BY year, category
),
category_growth AS (
    SELECT
        category,
        SUM(
            CASE
                WHEN year = 2017
                    THEN revenue
                ELSE 0
            END
        ) AS revenue_2017,
        SUM(
            CASE
                WHEN year = 2018
                    THEN revenue
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
WHERE revenue_2017 >= 50000
ORDER BY growth_percent DESC;


-- Business Question 12:
-- Which customers are high-value repeat customers?

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
    customer_unique_id,
    order_count,
    ROUND(total_spent, 2) AS total_spent,
    ROUND(
        total_spent / order_count,
        2
    ) AS average_order_value
FROM customer_value
WHERE order_count > 1
ORDER BY total_spent DESC
LIMIT 20;