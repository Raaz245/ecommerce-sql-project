-- ============================================================
-- FILE: 01_exploratory_analysis.sql
-- PROJECT: E-Commerce Sales Intelligence System
-- DESCRIPTION: High-level KPIs and dataset overview
-- AUTHOR: Shivam Yadav (Raaz245)
-- ============================================================


-- ─────────────────────────────────────────
-- SECTION A: BASIC KPIs
-- ─────────────────────────────────────────

-- A1: Total Revenue Generated
-- Result: $16,008,872
SELECT ROUND(SUM(payment_value)::numeric, 2) AS total_revenue
FROM payments;


-- A2: Total Unique Orders
-- Result: 99,441
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;


-- A3: Average Order Value
-- Result: R$154.10
SELECT ROUND(AVG(payment_value)::numeric, 2) AS avg_order_value
FROM payments;


-- A4: Monthly Revenue Trend (2016–2018)
-- Business Use: Spot seasonality and growth periods
SELECT 
    EXTRACT(YEAR  FROM order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value)::numeric, 2)      AS monthly_revenue
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY year, month
ORDER BY year, month;


-- A5: Top 5 Product Categories by Revenue
-- Result: bed_bath_table leads with highest sales volume
SELECT 
    pr.product_category,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue
FROM order_items oi
JOIN products  pr ON oi.product_id = pr.product_id
JOIN payments  p  ON oi.order_id   = p.order_id
GROUP BY pr.product_category
ORDER BY total_revenue DESC
LIMIT 5;


-- A6: Payment Method Distribution
-- Result: Credit Card dominates at 73.9% of all transactions
SELECT 
    payment_type,
    COUNT(*)                                        AS total_transactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM payments
GROUP BY payment_type
ORDER BY total_transactions DESC;
