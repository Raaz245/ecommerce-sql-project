-- Analysis/E_commerce.sql
-- Refactored and hardened analysis queries for the Olist e-commerce dataset.
-- Improvements made:
--  - Aggregate payments to one row per order before using them (avoids double-counting).
--  - Use date_trunc('month', ...) for monthly grouping.
--  - Defensive NULL/zero handling (NULLIF, COALESCE) to avoid division-by-zero and NULL math.
--  - Fixed churn query and made repeat/one-time buyer logic explicit.
--  - Provided two approaches for category/seller revenue: simple (sum of item price) and allocated (pro-rate order payments across items).
--  - Added comments and small QA checks.

-- NOTE: some product tables use column name "product_category_name" in the Olist dataset.
-- To be safe we use COALESCE(product_category_name, product_category) as product_category.


-- SECTION A: BASIC KPIs (safe versions)

-- A0: Quick QA checks
-- How many orders have multiple payment rows?
WITH payments_per_order AS (
  SELECT order_id, COUNT(*) AS payments_count, SUM(COALESCE(payment_value,0)) AS payments_sum
  FROM payments
  GROUP BY order_id
)
SELECT
  SUM(CASE WHEN payments_count > 1 THEN 1 ELSE 0 END) AS orders_with_multiple_payments,
  SUM(CASE WHEN payments_sum <= 0 THEN 1 ELSE 0 END) AS orders_with_nonpositive_payment_sum
FROM payments_per_order;

-- A1: Total Revenue (aggregate payments per order first)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
)
SELECT ROUND(SUM(order_value)::numeric, 2) AS total_revenue
FROM order_payments;

-- A2: Total Orders (optionally exclude cancelled)
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM orders
-- WHERE order_status NOT IN ('canceled') -- uncomment if you want to exclude cancelled orders
;

-- A3: Average Order Value (per-order average, based on aggregated payments)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
)
SELECT ROUND(AVG(order_value)::numeric, 2) AS avg_order_value
FROM order_payments;

-- A4: Monthly Revenue Trend (date_trunc + aggregated payments)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
)
SELECT
  date_trunc('month', o.order_purchase_timestamp)::date AS month,
  ROUND(SUM(op.order_value)::numeric, 2) AS monthly_revenue
FROM orders o
JOIN order_payments op USING (order_id)
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY month
ORDER BY month;

-- A5: Top 5 Product Categories by Revenue
-- Option A (fast): sum of order_items.price by category (assumes price reflects revenue share)
SELECT
  COALESCE(pr.product_category_name, pr.product_category) AS product_category,
  ROUND(SUM(oi.price)::numeric, 2) AS revenue_by_item_price
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
GROUP BY COALESCE(pr.product_category_name, pr.product_category)
ORDER BY revenue_by_item_price DESC
LIMIT 5;

-- Option B (accurate when payments differ from item price): allocate order-level payment_value across items proportionally by price
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
),
item_shares AS (
  SELECT
    oi.order_id,
    oi.order_item_id,
    oi.price,
    COALESCE(pr.product_category_name, pr.product_category) AS product_category,
    SUM(oi.price) OVER (PARTITION BY oi.order_id) AS order_items_total_price,
    op.order_value
  FROM order_items oi
  JOIN products pr ON oi.product_id = pr.product_id
  JOIN order_payments op ON oi.order_id = op.order_id
)
SELECT
  product_category,
  ROUND(SUM((price::numeric / NULLIF(order_items_total_price,0)) * order_value)::numeric, 2) AS allocated_revenue
FROM item_shares
GROUP BY product_category
ORDER BY allocated_revenue DESC
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

-- B3: Repeat vs One Time Buyers (optionally exclude cancelled orders)
SELECT
  CASE WHEN order_count = 1 THEN 'One Time Buyer' ELSE 'Repeat Buyer' END AS customer_type,
  COUNT(*) AS total_customers
FROM (
  SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  -- WHERE o.order_status NOT IN ('canceled') -- uncomment to ignore cancelled orders
  GROUP BY c.customer_unique_id
) sub
GROUP BY customer_type
ORDER BY total_customers DESC;

-- B4: Churned Customers (last order older than 90 days)
SELECT COUNT(*) AS churned_customers
FROM (
  SELECT c.customer_unique_id, MAX(o.order_purchase_timestamp) AS last_order
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  GROUP BY c.customer_unique_id
  HAVING MAX(o.order_purchase_timestamp) < now() - INTERVAL '90 days'
) t;

-- B5: Top 10 Customers by Spending (use aggregated payments)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
)
SELECT
  c.customer_unique_id,
  ROUND(SUM(op.order_value)::numeric, 2) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;


-- SECTION C: PRODUCT ANALYSIS

-- C1: Top 10 Best Selling Products (by number of items sold)
SELECT
  oi.product_id,
  COALESCE(pr.product_name, '') AS product_name,
  COALESCE(pr.product_category_name, pr.product_category) AS product_category,
  COUNT(*) AS total_sold
FROM order_items oi
LEFT JOIN products pr ON oi.product_id = pr.product_id
GROUP BY oi.product_id, COALESCE(pr.product_name, ''), COALESCE(pr.product_category_name, pr.product_category)
ORDER BY total_sold DESC
LIMIT 10;

-- C2: Average Review Score by Category
SELECT
  COALESCE(pr.product_category_name, pr.product_category) AS product_category,
  ROUND(AVG(r.review_score)::numeric, 2) AS avg_rating
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN reviews r ON oi.order_id = r.order_id
GROUP BY COALESCE(pr.product_category_name, pr.product_category)
ORDER BY avg_rating DESC
LIMIT 10;

-- C3: Lowest Rated Categories
SELECT
  COALESCE(pr.product_category_name, pr.product_category) AS product_category,
  ROUND(AVG(r.review_score)::numeric, 2) AS avg_rating
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN reviews r ON oi.order_id = r.order_id
GROUP BY COALESCE(pr.product_category_name, pr.product_category)
ORDER BY avg_rating ASC
LIMIT 5;


-- SECTION D: SELLER ANALYSIS

-- D1: Top 10 Sellers by Revenue (simple: sum of item prices)
SELECT
  oi.seller_id,
  ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
FROM order_items oi
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- D1b: Top 10 Sellers by Allocated Order Payments (more accurate if payments != sum of item prices)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
),
item_totals AS (
  SELECT order_id, SUM(price) AS tot_price
  FROM order_items
  GROUP BY order_id
)
SELECT
  oi.seller_id,
  ROUND(SUM((oi.price / NULLIF(it.tot_price,0)) * op.order_value)::numeric, 2) AS seller_allocated_revenue
FROM order_items oi
JOIN order_payments op ON oi.order_id = op.order_id
JOIN item_totals it ON oi.order_id = it.order_id
GROUP BY oi.seller_id
ORDER BY seller_allocated_revenue DESC
LIMIT 10;

-- D2: Average Delivery Days by Seller (uses delivered date)
SELECT
  oi.seller_id,
  ROUND(AVG(
    EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0
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


-- SECTION E: WINDOW FUNCTIONS & TRENDS

-- E1: Month over Month Revenue Growth (safe: use aggregated payments and NULLIF)
WITH monthly AS (
  SELECT
    date_trunc('month', o.order_purchase_timestamp) AS month,
    SUM(op.order_value) AS monthly_revenue
  FROM orders o
  JOIN (
    SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
    FROM payments
    GROUP BY order_id
  ) op USING (order_id)
  WHERE o.order_purchase_timestamp IS NOT NULL
  GROUP BY month
)
SELECT
  month::date,
  monthly_revenue,
  LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month,
  ROUND(
    ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
      / NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0) * 100)::numeric
  , 2) AS growth_pct
FROM monthly
ORDER BY month;

-- E2: Running Total Revenue
WITH monthly AS (
  SELECT
    date_trunc('month', o.order_purchase_timestamp) AS month,
    SUM(op.order_value) AS monthly_revenue
  FROM orders o
  JOIN (
    SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
    FROM payments
    GROUP BY order_id
  ) op USING (order_id)
  WHERE o.order_purchase_timestamp IS NOT NULL
  GROUP BY month
)
SELECT
  month::date,
  ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
  ROUND(SUM(monthly_revenue) OVER (ORDER BY month)::numeric, 2) AS running_total
FROM monthly
ORDER BY month;

-- E3: Product Category Rank by Revenue (allocated)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
),
item_shares AS (
  SELECT
    oi.order_id,
    oi.price,
    COALESCE(pr.product_category_name, pr.product_category) AS product_category,
    SUM(oi.price) OVER (PARTITION BY oi.order_id) AS order_items_total_price,
    op.order_value
  FROM order_items oi
  JOIN products pr ON oi.product_id = pr.product_id
  JOIN order_payments op ON oi.order_id = op.order_id
)
SELECT
  product_category,
  ROUND(SUM((price::numeric / NULLIF(order_items_total_price,0)) * order_value)::numeric, 2) AS total_revenue,
  RANK() OVER (ORDER BY SUM((price::numeric / NULLIF(order_items_total_price,0)) * order_value) DESC) AS revenue_rank
FROM item_shares
GROUP BY product_category
ORDER BY revenue_rank;

-- E4: Customer Spending Rank (using aggregated payments)
WITH order_payments AS (
  SELECT order_id, SUM(COALESCE(payment_value,0)) AS order_value
  FROM payments
  GROUP BY order_id
)
SELECT
  c.customer_unique_id,
  ROUND(SUM(op.order_value)::numeric, 2) AS total_spent,
  DENSE_RANK() OVER (ORDER BY SUM(op.order_value) DESC) AS spending_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 20;

-- End of file
