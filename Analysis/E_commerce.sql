-- SECTION A: BASIC KPIs

-- A1: Total Revenue
SELECT ROUND(SUM(payment_value)::numeric, 2) AS total_revenue
FROM payments;

-- A2: Total Orders
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders;

-- A3: Average Order Value
SELECT ROUND(AVG(payment_value)::numeric, 2) AS avg_order_value
FROM payments;

-- A4: Monthly Revenue Trend
SELECT 
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value)::numeric, 2) AS monthly_revenue
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY year, month
ORDER BY year, month;

-- A5: Top 5 Product Categories by Revenue
SELECT 
    pr.product_category,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN payments p ON oi.order_id = p.order_id
GROUP BY pr.product_category
ORDER BY total_revenue DESC
LIMIT 5;

-- SECTION B: CUSTOMER ANALYSIS

-- B1: Total Unique Customers
SELECT COUNT(DISTINCT customer_unique_id) AS total_unique_customers
FROM customers;

-- B2: Top 10 Cities by Orders
SELECT 
    customer_city,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_city
ORDER BY total_orders DESC
LIMIT 10;

-- B3: Repeat vs One Time Buyers
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One Time Buyer'
        ELSE 'Repeat Buyer'
    END AS customer_type,
    COUNT(*) AS total_customers
FROM (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) subquery
GROUP BY customer_type;

-- B4: Churned Customers (90 days se order nahi kiya)
SELECT COUNT(DISTINCT c.customer_unique_id) AS churned_customers
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING MAX(o.order_purchase_timestamp) < NOW() - INTERVAL '90 days';

-- B5: Top 10 Customers by Spending
SELECT 
    c.customer_unique_id,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- SECTION C: PRODUCT ANALYSIS

-- C1: Top 10 Best Selling Products
SELECT 
    pr.product_category,
    COUNT(oi.order_id) AS total_sold
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
GROUP BY pr.product_category
ORDER BY total_sold DESC
LIMIT 10;

-- C2: Average Review Score by Category
SELECT 
    pr.product_category,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_rating
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN reviews r ON oi.order_id = r.order_id
GROUP BY pr.product_category
ORDER BY avg_rating DESC
LIMIT 10;

-- C3: Lowest Rated Categories
SELECT 
    pr.product_category,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_rating
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN reviews r ON oi.order_id = r.order_id
GROUP BY pr.product_category
ORDER BY avg_rating ASC
LIMIT 5;

-- SECTION D: SELLER ANALYSIS

-- D1: Top 10 Sellers by Revenue
SELECT 
    oi.seller_id,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
FROM order_items oi
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- D2: Average Delivery Days by Seller
SELECT 
    oi.seller_id,
    ROUND(AVG(
        EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
    )::numeric, 1) AS avg_delivery_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
ORDER BY avg_delivery_days ASC
LIMIT 10;

-- D3: Late Delivery Sellers
SELECT 
    oi.seller_id,
    COUNT(*) AS late_deliveries
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY oi.seller_id
ORDER BY late_deliveries DESC
LIMIT 10;

-- SECTION E: WINDOW FUNCTIONS

-- E1: Month over Month Revenue Growth
SELECT 
    year,
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year, month)) 
        / LAG(monthly_revenue) OVER (ORDER BY year, month) * 100)::numeric
    , 2) AS growth_percentage
FROM (
    SELECT 
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
        ROUND(SUM(p.payment_value)::numeric, 2) AS monthly_revenue
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY year, month
) monthly_data
ORDER BY year, month;

-- E2: Running Total Revenue
SELECT 
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    ROUND(SUM(p.payment_value)::numeric, 2) AS monthly_revenue,
    ROUND(SUM(SUM(p.payment_value)) OVER (
        ORDER BY EXTRACT(YEAR FROM o.order_purchase_timestamp), 
        EXTRACT(MONTH FROM o.order_purchase_timestamp)
    )::numeric, 2) AS running_total
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY year, month
ORDER BY year, month;

-- E3: Product Category Rank by Revenue
SELECT 
    pr.product_category,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(p.payment_value) DESC) AS revenue_rank
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN payments p ON oi.order_id = p.order_id
GROUP BY pr.product_category;

-- E4: Customer Spending Rank
SELECT 
    c.customer_unique_id,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_spent,
    DENSE_RANK() OVER (ORDER BY SUM(p.payment_value) DESC) AS spending_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
LIMIT 20;