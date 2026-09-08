-- ============================================================
-- FILE: 02_customer_analysis.sql
-- PROJECT: E-Commerce Sales Intelligence System
-- DESCRIPTION: Customer segmentation, retention and behavior
-- AUTHOR: Shivam Yadav (Raaz245)
-- ============================================================


-- ─────────────────────────────────────────
-- SECTION B: CUSTOMER ANALYSIS
-- ─────────────────────────────────────────

-- B1: Total Unique Customers
-- Result: 96,096 unique customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_unique_customers
FROM customers;


-- B2: Top 10 Cities by Order Volume
-- Business Use: Identify priority markets for targeted campaigns
-- Result: Sao Paulo leads with 15,540 orders
SELECT 
    customer_city,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_city
ORDER BY total_orders DESC
LIMIT 10;


-- B3: Repeat Buyers vs One-Time Buyers
-- Business Use: Core retention metric — reveals loyalty problem
-- Result: 97% one-time buyers (93,099 out of 96,096)
-- Technique: Subquery + CASE WHEN segmentation
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Buyer'
        ELSE 'Repeat Buyer'
    END AS customer_type,
    COUNT(*)                                            AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) sub
GROUP BY customer_type;


-- B4: Churned Customers (No order in last 90 days)
-- Business Use: Win-back campaign targeting
-- Technique: HAVING clause with date arithmetic
SELECT COUNT(DISTINCT c.customer_unique_id) AS churned_customers
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING MAX(o.order_purchase_timestamp) < NOW() - INTERVAL '90 days';


-- B5: Top 10 Customers by Lifetime Spending
-- Business Use: VIP customer identification for premium programs
SELECT 
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id)                    AS total_orders,
    ROUND(SUM(p.payment_value)::numeric, 2)       AS total_spent
FROM customers c
JOIN orders   o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id    = p.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;


-- B6: Customer Geographic Distribution by State
-- Business Use: Regional logistics and marketing planning
SELECT 
    customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    ROUND(COUNT(DISTINCT c.customer_unique_id) * 100.0 
          / SUM(COUNT(DISTINCT c.customer_unique_id)) OVER (), 2) AS percentage
FROM customers c
GROUP BY customer_state
ORDER BY total_customers DESC;
