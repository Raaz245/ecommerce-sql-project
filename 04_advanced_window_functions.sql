-- ============================================================
-- FILE: 04_advanced_window_functions.sql
-- PROJECT: E-Commerce Sales Intelligence System
-- DESCRIPTION: Advanced SQL — Window Functions, CTEs, time-series
-- AUTHOR: Shivam Yadav (Raaz245)
-- NOTE: This file demonstrates FAANG-level SQL patterns
-- ============================================================


-- ─────────────────────────────────────────
-- SECTION E: WINDOW FUNCTIONS & ADVANCED SQL
-- ─────────────────────────────────────────

-- E1: Month-over-Month Revenue Growth %
-- Business Use: Track business momentum — are we growing or declining?
-- Technique: LAG() window function over time-ordered partition
SELECT 
    year,
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year, month)     AS prev_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year, month))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY year, month), 0) * 100)::numeric
    , 2)                                                  AS mom_growth_pct
FROM (
    SELECT 
        EXTRACT(YEAR  FROM o.order_purchase_timestamp) AS year,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
        ROUND(SUM(p.payment_value)::numeric, 2)        AS monthly_revenue
    FROM orders   o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY year, month
) monthly_data
ORDER BY year, month;


-- E2: Cumulative Revenue (Running Total)
-- Business Use: Track when business crossed key revenue milestones
-- Technique: SUM() as window function with ORDER BY
SELECT 
    EXTRACT(YEAR  FROM o.order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value)::numeric, 2)         AS monthly_revenue,
    ROUND(SUM(SUM(p.payment_value)) OVER (
        ORDER BY 
            EXTRACT(YEAR  FROM o.order_purchase_timestamp),
            EXTRACT(MONTH FROM o.order_purchase_timestamp)
    )::numeric, 2)                                  AS cumulative_revenue
FROM orders   o
JOIN payments p ON o.order_id = p.order_id
GROUP BY year, month
ORDER BY year, month;


-- E3: Product Category Revenue Ranking
-- Business Use: Official leaderboard for category performance
-- Technique: RANK() — tied values get same rank with gap after
SELECT 
    pr.product_category,
    ROUND(SUM(p.payment_value)::numeric, 2)              AS total_revenue,
    COUNT(DISTINCT oi.order_id)                          AS total_orders,
    RANK() OVER (ORDER BY SUM(p.payment_value) DESC)     AS revenue_rank
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN payments p  ON oi.order_id   = p.order_id
GROUP BY pr.product_category
ORDER BY revenue_rank;


-- E4: Customer Spending Percentile
-- Business Use: Top 1%, top 10% customer segmentation for VIP programs
-- Technique: DENSE_RANK() + NTILE() for percentile buckets
WITH customer_spending AS (
    SELECT 
        c.customer_unique_id,
        ROUND(SUM(p.payment_value)::numeric, 2) AS total_spent
    FROM customers c
    JOIN orders   o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id    = p.order_id
    GROUP BY c.customer_unique_id
)
SELECT 
    customer_unique_id,
    total_spent,
    DENSE_RANK() OVER (ORDER BY total_spent DESC)    AS spending_rank,
    NTILE(100)   OVER (ORDER BY total_spent DESC)    AS spending_percentile
FROM customer_spending
ORDER BY total_spent DESC
LIMIT 20;


-- E5: Delivery Performance — Actual vs Promised
-- Business Use: SLA compliance tracking
-- Technique: Date subtraction + CASE WHEN classification
SELECT 
    CASE 
        WHEN actual_days <= estimated_days - 5 THEN 'Delivered Very Early'
        WHEN actual_days <= estimated_days     THEN 'On Time'
        WHEN actual_days <= estimated_days + 3 THEN 'Slightly Late'
        ELSE 'Significantly Late'
    END                        AS delivery_status,
    COUNT(*)                   AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM (
    SELECT 
        EXTRACT(DAY FROM (order_delivered_customer_date - order_purchase_timestamp)) AS actual_days,
        EXTRACT(DAY FROM (order_estimated_delivery_date  - order_purchase_timestamp)) AS estimated_days
    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
) delivery_data
GROUP BY delivery_status
ORDER BY total_orders DESC;


-- E6: Review Score Distribution with % Share
-- Business Use: Overall platform quality health check
-- Technique: Window function for percentage without subquery
SELECT 
    review_score,
    COUNT(*)                                            AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM reviews
GROUP BY review_score
ORDER BY review_score DESC;


-- E7: Top Seller per Product Category
-- Business Use: Find the dominant seller in each category
-- Technique: CTE + RANK() — classic interview pattern
WITH category_seller_revenue AS (
    SELECT 
        pr.product_category,
        oi.seller_id,
        ROUND(SUM(oi.price)::numeric, 2) AS seller_revenue
    FROM order_items oi
    JOIN products pr ON oi.product_id = pr.product_id
    GROUP BY pr.product_category, oi.seller_id
),
ranked AS (
    SELECT 
        product_category,
        seller_id,
        seller_revenue,
        RANK() OVER (PARTITION BY product_category ORDER BY seller_revenue DESC) AS rnk
    FROM category_seller_revenue
)
SELECT product_category, seller_id, seller_revenue
FROM ranked
WHERE rnk = 1
ORDER BY seller_revenue DESC
LIMIT 15;
