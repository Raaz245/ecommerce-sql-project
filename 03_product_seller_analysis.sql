-- ============================================================
-- FILE: 03_product_seller_analysis.sql
-- PROJECT: E-Commerce Sales Intelligence System
-- DESCRIPTION: Product performance and seller quality metrics
-- AUTHOR: Shivam Yadav (Raaz245)
-- ============================================================


-- ─────────────────────────────────────────
-- SECTION C: PRODUCT ANALYSIS
-- ─────────────────────────────────────────

-- C1: Top 10 Best Selling Product Categories by Volume
-- Business Use: Inventory prioritization
SELECT 
    pr.product_category,
    COUNT(oi.order_id)                                      AS total_units_sold,
    RANK() OVER (ORDER BY COUNT(oi.order_id) DESC)          AS sales_rank
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
GROUP BY pr.product_category
ORDER BY total_units_sold DESC
LIMIT 10;


-- C2: Top 10 Categories by Average Customer Rating
-- Business Use: Identify quality leaders for promotional push
SELECT 
    pr.product_category,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_rating,
    COUNT(r.review_id)                     AS total_reviews
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN reviews  r  ON oi.order_id   = r.order_id
GROUP BY pr.product_category
HAVING COUNT(r.review_id) > 100          -- Only categories with meaningful review volume
ORDER BY avg_rating DESC
LIMIT 10;


-- C3: Lowest Rated Categories (Quality Red Flags)
-- Business Use: Identify categories needing supplier or quality intervention
SELECT 
    pr.product_category,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_rating,
    COUNT(r.review_id)                     AS total_reviews
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN reviews  r  ON oi.order_id   = r.order_id
GROUP BY pr.product_category
HAVING COUNT(r.review_id) > 100
ORDER BY avg_rating ASC
LIMIT 5;


-- C4: Revenue vs Rating by Category (Quality-Revenue Matrix)
-- Business Use: Find high-revenue but low-rated categories — biggest risk areas
SELECT 
    pr.product_category,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue,
    ROUND(AVG(r.review_score)::numeric, 2)  AS avg_rating,
    COUNT(oi.order_id)                      AS total_orders
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN payments p  ON oi.order_id   = p.order_id
JOIN reviews  r  ON oi.order_id   = r.order_id
GROUP BY pr.product_category
ORDER BY total_revenue DESC
LIMIT 15;


-- ─────────────────────────────────────────
-- SECTION D: SELLER ANALYSIS
-- ─────────────────────────────────────────

-- D1: Top 10 Sellers by Revenue
-- Business Use: Identify platform's most valuable seller partners
SELECT 
    oi.seller_id,
    ROUND(SUM(oi.price)::numeric, 2)               AS total_revenue,
    COUNT(DISTINCT oi.order_id)                    AS total_orders,
    DENSE_RANK() OVER (ORDER BY SUM(oi.price) DESC) AS revenue_rank
FROM order_items oi
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;


-- D2: Fastest Sellers by Average Delivery Time
-- Business Use: Best practices from top performers
SELECT 
    oi.seller_id,
    ROUND(AVG(
        EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
    )::numeric, 1) AS avg_delivery_days,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT o.order_id) > 10    -- Sellers with enough volume to be meaningful
ORDER BY avg_delivery_days ASC
LIMIT 10;


-- D3: Late Delivery Offenders (Delivered After Promised Date)
-- Business Use: Seller penalty scoring and customer experience protection
-- Technique: Date comparison — actual vs estimated delivery
SELECT 
    oi.seller_id,
    COUNT(*)                                               AS late_deliveries,
    RANK() OVER (ORDER BY COUNT(*) DESC)                   AS late_rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY oi.seller_id
ORDER BY late_deliveries DESC
LIMIT 10;


-- D4: Seller Performance Scorecard (Revenue + Rating + On-Time %)
-- Business Use: Complete seller quality dashboard
-- Technique: Multi-table JOIN + CASE WHEN + aggregation
SELECT 
    oi.seller_id,
    COUNT(DISTINCT oi.order_id)                            AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2)                       AS total_revenue,
    ROUND(AVG(r.review_score)::numeric, 2)                 AS avg_rating,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
                 THEN 1 ELSE 0 END) * 100.0 
        / COUNT(*), 2
    ) AS on_time_delivery_pct
FROM order_items oi
JOIN orders  o ON oi.order_id  = o.order_id
JOIN reviews r ON oi.order_id  = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT oi.order_id) > 20
ORDER BY total_revenue DESC
LIMIT 15;
