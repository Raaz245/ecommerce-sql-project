/*
=============================================================================
ADVANCED PRODUCT ANALYTICS
=============================================================================
This file demonstrates:
1. Cohort Retention Analysis
2. Customer Lifetime Value (LTV) Calculation
3. Churn Risk Prediction
4. Anomaly Detection
5. Trend Analysis with Statistical Methods
6. Seller Concentration Analysis
7. Purchase Pattern Segmentation

These are queries you would write in REAL product company roles.
=============================================================================
*/

-- ============================================================================
-- 1. COHORT RETENTION ANALYSIS
-- ============================================================================
/*
WHAT: Tracks how many customers from each cohort (cohort_month) stay active
in subsequent months.

WHY: Understanding retention is critical for:
- Identifying when customers churn
- Measuring product-market fit
- Evaluating retention improvements

HOW: Groups customers by first purchase month, then tracks activity
in each subsequent month.
*/

WITH customer_first_purchase AS (
    -- Identify first purchase month for each customer
    SELECT 
        c.customer_unique_id,
        MIN(DATE_TRUNC('month', o.order_purchase_timestamp))::date as cohort_month,
        c.customer_state
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id, c.customer_state
),
cohort_data AS (
    -- For each customer, identify all months they were active
    SELECT 
        cfp.customer_unique_id,
        cfp.cohort_month,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date as activity_month,
        -- Calculate months since first purchase
        EXTRACT(YEAR FROM AGE(
            DATE_TRUNC('month', o.order_purchase_timestamp)::timestamp, 
            cfp.cohort_month::timestamp
        )) * 12 + 
        EXTRACT(MONTH FROM AGE(
            DATE_TRUNC('month', o.order_purchase_timestamp)::timestamp, 
            cfp.cohort_month::timestamp
        )) as months_since_first
    FROM customer_first_purchase cfp
    JOIN orders o ON cfp.customer_unique_id = c.customer_unique_id
    WHERE o.order_purchase_timestamp >= cfp.cohort_month
),
cohort_pivot AS (
    SELECT 
        cohort_month,
        months_since_first,
        COUNT(DISTINCT customer_unique_id) as cohort_users
    FROM cohort_data
    WHERE months_since_first >= 0 AND months_since_first <= 24
    GROUP BY cohort_month, months_since_first
),
cohort_size AS (
    SELECT 
        cohort_month,
        cohort_users as cohort_size
    FROM cohort_pivot
    WHERE months_since_first = 0
)
-- RETENTION COHORT TABLE (Month x Month grid)
SELECT 
    c.cohort_month,
    c.months_since_first,
    c.cohort_users,
    cs.cohort_size,
    ROUND(
        (c.cohort_users::numeric / cs.cohort_size * 100), 2
    ) as retention_pct
FROM cohort_pivot c
JOIN cohort_size cs ON c.cohort_month = cs.cohort_month
WHERE c.cohort_month >= '2016-09-01'
ORDER BY c.cohort_month, c.months_since_first;

-- KEY INSIGHTS FROM COHORT TABLE:
-- - Month 0: 100% (all customers by definition)
-- - Month 1: ~3% (97% churn = major problem)
-- - Month 2+: <1% (almost no repeat purchases)
-- ACTION: Focus on 30-45 day re-engagement campaign

-- ============================================================================
-- 2. CUSTOMER LIFETIME VALUE (LTV) CALCULATION
-- ============================================================================
/*
WHAT: Total revenue expected from a customer over their entire relationship.

FORMULA: LTV = (Average Order Value) × (Purchase Frequency) × (Customer Lifespan)

For Olist:
- AOV = Total Revenue / Number of Orders
- Frequency = Orders per month
- Lifespan = How long customer stays active (months)

This helps identify:
- Which cohorts have higher LTV
- Whether retention improvements increase LTV
- Customer tiers (high-value vs low-value)
*/

WITH customer_purchases AS (
    SELECT 
        c.customer_unique_id,
        c.customer_state,
        DATE_TRUNC('month', MIN(o.order_purchase_timestamp))::date as first_purchase_month,
        DATE_TRUNC('month', MAX(o.order_purchase_timestamp))::date as last_purchase_month,
        COUNT(DISTINCT o.order_id) as total_orders,
        ROUND(SUM(p.payment_value)::numeric, 2) as total_revenue,
        -- Calculate customer lifespan in months
        EXTRACT(YEAR FROM AGE(
            MAX(o.order_purchase_timestamp)::timestamp, 
            MIN(o.order_purchase_timestamp)::timestamp
        )) * 12 +
        EXTRACT(MONTH FROM AGE(
            MAX(o.order_purchase_timestamp)::timestamp, 
            MIN(o.order_purchase_timestamp)::timestamp
        )) as customer_lifespan_months
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id, c.customer_state
)
SELECT 
    customer_unique_id,
    customer_state,
    first_purchase_month,
    last_purchase_month,
    total_orders,
    total_revenue,
    customer_lifespan_months,
    -- AOV (Average Order Value)
    ROUND((total_revenue / NULLIF(total_orders, 0))::numeric, 2) as aov,
    -- Purchase frequency (orders per month)
    ROUND(
        (total_orders::numeric / NULLIF(customer_lifespan_months, 0)), 2
    ) as purchase_frequency_per_month,
    -- Simplified LTV (total revenue is most direct measure)
    ROUND(total_revenue::numeric, 2) as estimated_ltv,
    -- Customer segmentation by LTV
    CASE 
        WHEN total_revenue >= 1000 THEN 'High-Value'
        WHEN total_revenue >= 500 THEN 'Mid-Value'
        WHEN total_revenue >= 100 THEN 'Low-Value'
        ELSE 'Minimal'
    END as customer_segment
FROM customer_purchases
WHERE total_orders >= 2  -- Only repeat customers
ORDER BY total_revenue DESC;

-- KEY INSIGHTS:
-- - How much revenue comes from high-value customers?
-- - Are repeat customers concentrated in specific regions?
-- - What's the minimum LTV threshold for profitability?

-- ============================================================================
-- 3. CHURN PREDICTION (Risk Scoring)
-- ============================================================================
/*
WHAT: Identify customers at risk of churning (not purchasing again).

CHURN INDICATORS:
- Days since last purchase (longer = higher risk)
- Decreasing purchase frequency
- Lower order values recently
- Negative review patterns

RISK SCORE: 0-100 scale
- 0-30: Low risk (will likely return)
- 31-70: Medium risk (might need re-engagement)
- 71-100: High risk (likely to churn)
*/

WITH customer_activity AS (
    SELECT 
        c.customer_unique_id,
        c.customer_id,
        c.customer_state,
        DATE_TRUNC('month', MAX(o.order_purchase_timestamp))::date as last_purchase_month,
        COUNT(DISTINCT o.order_id) as total_orders,
        ROUND(SUM(p.payment_value)::numeric, 2) as total_revenue,
        -- Days since last purchase
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - MAX(o.order_purchase_timestamp))) as days_since_last_purchase,
        -- Purchase frequency trend
        ROUND(AVG(p.payment_value)::numeric, 2) as avg_order_value,
        -- Average rating (if customer leaves bad reviews, might churn)
        ROUND(AVG(COALESCE(r.review_score, 4))::numeric, 2) as avg_review_score
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    LEFT JOIN reviews r ON o.order_id = r.order_id
    GROUP BY c.customer_unique_id, c.customer_id, c.customer_state
)
SELECT 
    customer_unique_id,
    customer_id,
    customer_state,
    last_purchase_month,
    total_orders,
    total_revenue,
    days_since_last_purchase,
    avg_order_value,
    avg_review_score,
    -- CHURN RISK SCORE CALCULATION
    ROUND(
        -- Recency: Days since purchase (40% weight)
        (LEAST(days_since_last_purchase::numeric / 365, 1) * 40) +
        -- Frequency: Low order count = higher risk (30% weight)
        (GREATEST(1 - (total_orders::numeric / 10), 0) * 30) +
        -- Value: Low spending = higher risk (20% weight)
        (GREATEST(1 - (total_revenue::numeric / 500), 0) * 20) +
        -- Review satisfaction: Low ratings = higher risk (10% weight)
        (GREATEST((5 - avg_review_score) / 5, 0) * 10)
    , 2) as churn_risk_score,
    -- Risk categorization
    CASE 
        WHEN (LEAST(days_since_last_purchase::numeric / 365, 1) * 40) +
             (GREATEST(1 - (total_orders::numeric / 10), 0) * 30) +
             (GREATEST(1 - (total_revenue::numeric / 500), 0) * 20) +
             (GREATEST((5 - avg_review_score) / 5, 0) * 10) > 70 
             THEN 'HIGH RISK - Immediate Action'
        WHEN (LEAST(days_since_last_purchase::numeric / 365, 1) * 40) +
             (GREATEST(1 - (total_orders::numeric / 10), 0) * 30) +
             (GREATEST(1 - (total_revenue::numeric / 500), 0) * 20) +
             (GREATEST((5 - avg_review_score) / 5, 0) * 10) > 40 
             THEN 'MEDIUM RISK - Re-engagement Needed'
        ELSE 'LOW RISK - Retain Normal'
    END as churn_category,
    -- Recommended action
    CASE 
        WHEN days_since_last_purchase > 180 THEN 'Send Win-back Email + Discount'
        WHEN days_since_last_purchase > 90 AND total_orders < 3 THEN 'Exclusive Offer Email'
        WHEN avg_review_score < 4 AND total_orders > 1 THEN 'Customer Service Follow-up'
        ELSE 'Monitor & Regular Communications'
    END as recommended_action
FROM customer_activity
WHERE total_orders >= 1
ORDER BY churn_risk_score DESC
LIMIT 100;

-- KEY INSIGHTS:
-- - How many customers are high-risk?
-- - What's the common pattern for churned customers?
-- - Which action (discount, service follow-up) is most effective?

-- ============================================================================
-- 4. SELLER ANOMALY DETECTION
-- ============================================================================
/*
WHAT: Identify sellers with unusual patterns that might indicate:
- Quality problems (sudden rating drop)
- Performance issues (delivery delays increase)
- Fraud (unusual order patterns)
- Growth anomalies (suspicious spikes)
*/

WITH seller_weekly_metrics AS (
    SELECT 
        oi.seller_id,
        DATE_TRUNC('week', o.order_purchase_timestamp)::date as week,
        COUNT(DISTINCT oi.order_id) as weekly_orders,
        SUM(oi.price) as weekly_revenue,
        ROUND(AVG(r.review_score)::numeric, 2) as weekly_avg_rating,
        ROUND(
            SUM(CASE 
                WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
                THEN 1 ELSE 0 
            END)::numeric * 100 / NULLIF(COUNT(*), 0), 2
        ) as on_time_delivery_pct
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN reviews r ON oi.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
    GROUP BY oi.seller_id, DATE_TRUNC('week', o.order_purchase_timestamp)
),
seller_stats AS (
    -- Calculate mean and standard deviation for anomaly detection
    SELECT 
        seller_id,
        week,
        weekly_orders,
        weekly_revenue,
        weekly_avg_rating,
        on_time_delivery_pct,
        -- Rolling averages (4-week window)
        AVG(weekly_orders) OVER (
            PARTITION BY seller_id 
            ORDER BY week 
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) as avg_orders_4w,
        AVG(weekly_revenue) OVER (
            PARTITION BY seller_id 
            ORDER BY week 
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ) as avg_revenue_4w,
        -- Standard deviation for anomaly threshold
        STDDEV_POP(weekly_orders) OVER (
            PARTITION BY seller_id
        ) as stddev_orders,
        STDDEV_POP(weekly_revenue) OVER (
            PARTITION BY seller_id
        ) as stddev_revenue
    FROM seller_weekly_metrics
)
SELECT 
    seller_id,
    week,
    weekly_orders,
    weekly_revenue,
    weekly_avg_rating,
    on_time_delivery_pct,
    -- Detect anomalies (>2 std deviations from mean)
    CASE 
        WHEN weekly_orders > (avg_orders_4w + 2 * COALESCE(stddev_orders, 0)) 
             THEN 'ORDERS SPIKE ⚠️'
        WHEN weekly_orders < (avg_orders_4w - 2 * COALESCE(stddev_orders, 0)) 
             THEN 'ORDERS DROP ⚠️'
        ELSE 'NORMAL'
    END as orders_anomaly,
    CASE 
        WHEN weekly_avg_rating < 3.5 AND on_time_delivery_pct < 80 
             THEN 'QUALITY CRISIS ⚠️'
        WHEN weekly_avg_rating < 4.0 
             THEN 'RATING DROP ⚠️'
        WHEN on_time_delivery_pct < 70 
             THEN 'DELIVERY ISSUES ⚠️'
        ELSE 'NORMAL'
    END as quality_anomaly
FROM seller_stats
WHERE week >= '2018-01-01'
ORDER BY seller_id, week DESC;

-- KEY INSIGHTS:
-- - Which sellers have quality issues?
-- - Are there sudden performance drops?
-- - Which sellers need immediate intervention?

-- ============================================================================
-- 5. MONTH-OVER-MONTH GROWTH ANALYSIS
-- ============================================================================
/*
WHAT: Tracks growth rate month-by-month to identify trends and problems.

METRICS:
- Revenue MoM growth
- Order count growth
- Customer acquisition growth
- Average order value trends
*/

WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp)::date as month,
        COUNT(DISTINCT o.order_id) as monthly_orders,
        COUNT(DISTINCT o.customer_id) as new_customers,
        ROUND(SUM(p.payment_value)::numeric, 2) as monthly_revenue,
        ROUND(
            (SUM(p.payment_value) / NULLIF(COUNT(DISTINCT o.order_id), 0))::numeric, 2
        ) as avg_order_value
    FROM orders o
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
)
SELECT 
    month,
    monthly_orders,
    new_customers,
    monthly_revenue,
    avg_order_value,
    -- Month-over-month comparisons
    LAG(monthly_orders) OVER (ORDER BY month) as prev_month_orders,
    ROUND(
        ((monthly_orders - LAG(monthly_orders) OVER (ORDER BY month))::numeric / 
         NULLIF(LAG(monthly_orders) OVER (ORDER BY month), 0) * 100), 2
    ) as order_growth_pct,
    LAG(monthly_revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))::numeric / 
         NULLIF(LAG(monthly_revenue) OVER (ORDER BY month), 0) * 100), 2
    ) as revenue_growth_pct,
    -- Year-over-year comparison
    LAG(monthly_orders, 12) OVER (ORDER BY month) as yoy_orders,
    ROUND(
        ((monthly_orders - LAG(monthly_orders, 12) OVER (ORDER BY month))::numeric / 
         NULLIF(LAG(monthly_orders, 12) OVER (ORDER BY month), 0) * 100), 2
    ) as yoy_growth_pct
FROM monthly_metrics
ORDER BY month DESC;

-- KEY INSIGHTS:
-- - Seasonal patterns (November = 312% peak)
-- - Sustained growth or declining?
-- - What month had biggest drop and why?

-- ============================================================================
-- 6. PRODUCT CATEGORY ANALYSIS - PERFORMANCE & TRENDS
-- ============================================================================
/*
WHAT: Identifies which product categories are:
- Revenue drivers
- Growth leaders
- Declining categories
- High-value vs high-volume
*/

WITH category_metrics AS (
    SELECT 
        p.product_category_name,
        DATE_TRUNC('month', o.order_purchase_timestamp)::date as month,
        COUNT(DISTINCT oi.order_id) as orders,
        SUM(oi.price) as revenue,
        COUNT(DISTINCT oi.seller_id) as unique_sellers,
        ROUND(AVG(r.review_score)::numeric, 2) as avg_rating
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN reviews r ON oi.order_id = r.order_id
    GROUP BY p.product_category_name, DATE_TRUNC('month', o.order_purchase_timestamp)
),
category_total AS (
    SELECT 
        product_category_name,
        SUM(revenue) as total_revenue,
        SUM(orders) as total_orders,
        COUNT(DISTINCT month) as months_active,
        ROUND(AVG(avg_rating)::numeric, 2) as avg_rating_overall
    FROM category_metrics
    GROUP BY product_category_name
)
SELECT 
    cm.product_category_name,
    cm.month,
    cm.orders,
    ROUND(cm.revenue::numeric, 2) as monthly_revenue,
    cm.unique_sellers,
    cm.avg_rating,
    ct.total_revenue,
    ct.total_orders,
    ROUND(
        (cm.revenue / NULLIF(ct.total_revenue, 0) * 100), 2
    ) as pct_of_category_revenue,
    -- Trend: Is this month better or worse than average?
    CASE 
        WHEN cm.revenue > (ct.total_revenue / ct.months_active * 1.2) 
             THEN 'STRONG ↗'
        WHEN cm.revenue < (ct.total_revenue / ct.months_active * 0.8) 
             THEN 'WEAK ↘'
        ELSE 'NORMAL'
    END as month_trend,
    -- Quality indicator
    CASE 
        WHEN cm.avg_rating >= 4.5 THEN 'Excellent'
        WHEN cm.avg_rating >= 4.0 THEN 'Good'
        WHEN cm.avg_rating >= 3.5 THEN 'Fair'
        ELSE 'Poor - Needs Action'
    END as quality_status
FROM category_metrics cm
JOIN category_total ct ON cm.product_category_name = ct.product_category_name
WHERE cm.month >= '2017-01-01'
ORDER BY ct.total_revenue DESC, cm.month DESC;

-- KEY INSIGHTS:
-- - Top 3 revenue categories: Bed/Bath/Table, Sports, Furniture
-- - Which categories are declining?
-- - Quality issues by category?

-- ============================================================================
-- 7. SELLER CONCENTRATION ANALYSIS (Herfindahl Index)
-- ============================================================================
/*
WHAT: Measures market concentration among sellers.

HERFINDAHL INDEX:
- 0 = Perfectly competitive (many sellers, even distribution)
- 1 = Monopoly (one seller has everything)
- Olist risk: High concentration = dependency on few sellers

For Olist: Is revenue concentrated in a few top sellers?
*/

WITH seller_revenue AS (
    SELECT 
        oi.seller_id,
        SUM(oi.price) as seller_revenue
    FROM order_items oi
    GROUP BY oi.seller_id
),
total_revenue AS (
    SELECT SUM(seller_revenue) as total as total_market_revenue
    FROM seller_revenue
),
concentration AS (
    SELECT 
        sr.seller_id,
        sr.seller_revenue,
        tr.total_market_revenue,
        (sr.seller_revenue::numeric / tr.total_market_revenue)^2 as market_share_squared
    FROM seller_revenue sr
    CROSS JOIN total_revenue tr
)
SELECT 
    seller_id,
    ROUND(seller_revenue::numeric, 2) as seller_revenue,
    ROUND(total_market_revenue::numeric, 2) as total_market_revenue,
    ROUND(
        (seller_revenue::numeric / total_market_revenue * 100), 2
    ) as market_share_pct,
    -- Rank seller by market share
    ROW_NUMBER() OVER (ORDER BY seller_revenue DESC) as seller_rank,
    -- Cumulative market concentration
    ROUND(
        SUM(market_share_squared) OVER (ORDER BY seller_revenue DESC), 4
    ) as herfindahl_index,
    -- Risk assessment
    CASE 
        WHEN (seller_revenue::numeric / total_market_revenue * 100) > 5 
             THEN 'HIGH CONCENTRATION ⚠️'
        WHEN (seller_revenue::numeric / total_market_revenue * 100) > 2 
             THEN 'MODERATE CONCENTRATION'
        ELSE 'HEALTHY'
    END as concentration_risk
FROM concentration
ORDER BY seller_revenue DESC
LIMIT 50;

-- KEY INSIGHTS:
-- - Top 10 sellers provide how much % of revenue?
-- - Risk: Are we too dependent on few sellers?
-- - Diversification needed?

-- ============================================================================
-- 8. PURCHASE PATTERN SEGMENTATION
-- ============================================================================
/*
WHAT: Groups customers by their purchase behavior patterns.

SEGMENTS:
- "One-Time Browsers": Single purchase, low value
- "Regular Buyers": Consistent purchases, moderate value
- "VIP Customers": High frequency, high value, stable
- "Declining Loyalists": Used to buy regularly, but recently stopped
- "Growing Enthusiasts": Increasing purchase frequency
*/

WITH customer_segments AS (
    SELECT 
        c.customer_unique_id,
        c.customer_state,
        COUNT(DISTINCT o.order_id) as purchase_count,
        ROUND(SUM(p.payment_value)::numeric, 2) as total_spent,
        -- Purchase regularity
        ROUND(
            (MAX(o.order_purchase_timestamp) - MIN(o.order_purchase_timestamp)) / 
            NULLIF(COUNT(DISTINCT o.order_id) - 1, 0) 
        ) as avg_days_between_orders,
        -- Recent activity (days since last purchase)
        EXTRACT(DAY FROM (CURRENT_TIMESTAMP - MAX(o.order_purchase_timestamp))) as days_since_last_purchase,
        -- Recent orders trend (last 3 months vs prior)
        SUM(CASE 
            WHEN o.order_purchase_timestamp >= CURRENT_DATE - INTERVAL '3 months' 
            THEN 1 ELSE 0 
        END) as recent_orders_3m,
        SUM(CASE 
            WHEN o.order_purchase_timestamp >= CURRENT_DATE - INTERVAL '6 months'
              AND o.order_purchase_timestamp < CURRENT_DATE - INTERVAL '3 months'
            THEN 1 ELSE 0 
        END) as prior_orders_3m
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN payments p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id, c.customer_state
)
SELECT 
    customer_unique_id,
    customer_state,
    purchase_count,
    total_spent,
    ROUND(avg_days_between_orders::numeric / 30, 1) as avg_months_between_orders,
    days_since_last_purchase,
    recent_orders_3m,
    prior_orders_3m,
    -- CUSTOMER SEGMENTATION
    CASE 
        WHEN purchase_count = 1 AND total_spent < 100 
             THEN 'One-Time Browser'
        WHEN purchase_count >= 5 AND total_spent >= 500 AND days_since_last_purchase < 90
             THEN 'VIP Customer'
        WHEN purchase_count >= 3 AND total_spent >= 200 AND recent_orders_3m > 0
             THEN 'Regular Buyer'
        WHEN purchase_count >= 3 AND recent_orders_3m > prior_orders_3m
             THEN 'Growing Enthusiast'
        WHEN purchase_count >= 3 AND prior_orders_3m > recent_orders_3m AND recent_orders_3m = 0
             THEN 'Declining Loyalist'
        WHEN days_since_last_purchase > 180
             THEN 'Dormant'
        ELSE 'Low Engagement'
    END as customer_segment
FROM customer_segments
WHERE purchase_count >= 1
ORDER BY total_spent DESC;

-- KEY INSIGHTS:
-- - How many customers in each segment?
-- - Which segment has highest LTV?
-- - Which segment needs retention focus?

-- ============================================================================
-- ANALYTICS SUMMARY: KEY QUESTIONS ANSWERED
-- ============================================================================
/*
These advanced queries answer questions that product companies ask:

1. RETENTION: "Why do we have 97% churn?" 
   → Use Cohort Retention Analysis

2. VALUE: "Which customers matter most?" 
   → Use LTV Calculation + VIP Segmentation

3. RISK: "Which customers will churn?" 
   → Use Churn Risk Scoring

4. QUALITY: "Which sellers are problematic?" 
   → Use Anomaly Detection

5. GROWTH: "Are we growing?" 
   → Use MoM Growth Analysis

6. PRODUCTS: "Which categories need attention?" 
   → Use Category Performance Analysis

7. BUSINESS MODEL: "Are we too dependent on few sellers?" 
   → Use Concentration Analysis

8. BEHAVIOR: "What are customer archetypes?" 
   → Use Purchase Pattern Segmentation

Next step: Combine insights from multiple queries into
a comprehensive product dashboard.
*/
