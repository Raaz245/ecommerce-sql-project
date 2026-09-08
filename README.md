# E-Commerce Sales Intelligence System

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue)
![Dataset](https://img.shields.io/badge/Dataset-Olist-green)
![Records](https://img.shields.io/badge/Records-1.5M%2B-orange)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## Project Overview

A complete end-to-end SQL analytics project built on **1,528,108 real e-commerce transactions**
from Olist — Brazil's largest e-commerce marketplace.

This project goes beyond writing queries. It answers real business questions:
*Why are 97% of customers not returning? Which sellers are hurting the platform?
Where is the next R$1M of revenue hiding?*

**Built to demonstrate:** Database design, complex query writing, business intelligence
thinking, and the ability to turn raw data into actionable recommendations —
without a formal degree.

---

## Dataset

| Detail | Info |
|--------|------|
| Source | [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| Period | 2016 – 2018 |
| Total Records | 1,528,108 across 8 tables |

---

## Database Schema

| Table | Records | Description |
|-------|---------|-------------|
| customers | 99,441 | Customer details and location |
| orders | 99,441 | Order status and timestamps |
| order_items | 112,650 | Products within each order |
| products | 32,951 | Product details and categories |
| sellers | 3,095 | Seller information |
| payments | 103,886 | Payment methods and values |
| reviews | 99,224 | Customer ratings and comments |
| geolocation | 1,000,161 | ZIP code coordinates |

> **Schema Diagram:** See `/schema/er_diagram.png`  
> *(8 tables connected via order_id, customer_id, product_id, seller_id foreign keys)*

---

## Key Business Insights

### 💰 Revenue Snapshot

| Metric | Value |
|--------|-------|
| Total Revenue | $16,008,872 |
| Total Orders | 99,441 |
| Average Order Value | R$154.10 |
| Top Payment Method | Credit Card — 76,795 txns (73.9%) |
| Top City by Orders | São Paulo — 15,540 orders |
| Top Product Category | Bed/Bath/Table — 11,115 orders |

---

### 🔥 The Most Important Finding: 97% Customer Churn

```sql
-- Repeat vs One-Time Buyers — using Subquery + CASE WHEN + Window Function
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Buyer'
        ELSE 'Repeat Buyer'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) sub
GROUP BY customer_type;
```

| customer_type | total_customers | percentage |
|---------------|----------------|------------|
| One-Time Buyer | 93,099 | 96.88% |
| Repeat Buyer | 2,997 | 3.12% |

**Business Implication:** The platform is re-acquiring virtually every customer
from scratch each month. A targeted retention campaign for customers 30–45 days
post-purchase could significantly shift this.

---

### 📈 Month-over-Month Revenue Growth

```sql
-- LAG() Window Function to calculate MoM growth
SELECT 
    year, month, monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year, month))
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY year, month), 0) * 100)::numeric
    , 2) AS mom_growth_pct
FROM (
    SELECT 
        EXTRACT(YEAR FROM o.order_purchase_timestamp)  AS year,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
        ROUND(SUM(p.payment_value)::numeric, 2)        AS monthly_revenue
    FROM orders o JOIN payments p ON o.order_id = p.order_id
    GROUP BY year, month
) monthly_data
ORDER BY year, month;
```

**Finding:** Business grew 312% year-over-year from 2016 to 2017,
with a clear November peak (Black Friday effect).

---

### 🏆 Seller Performance Scorecard

```sql
-- Complete seller quality metric: Revenue + Rating + On-Time Delivery %
SELECT 
    oi.seller_id,
    COUNT(DISTINCT oi.order_id)                      AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2)                 AS total_revenue,
    ROUND(AVG(r.review_score)::numeric, 2)           AS avg_rating,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date 
                 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS on_time_delivery_pct
FROM order_items oi
JOIN orders  o ON oi.order_id = o.order_id
JOIN reviews r ON oi.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT oi.order_id) > 20
ORDER BY total_revenue DESC
LIMIT 15;
```

**Finding:** Top 10% of sellers generate disproportionate revenue —
a seller tier program (Gold/Silver/Bronze) would incentivize quality.

---

## Business Recommendations

### 1. 🚨 Customer Retention Crisis (Highest Priority)
97% one-time buyer rate means the platform effectively has zero organic growth.
**Action:** Launch a 45-day post-purchase email re-engagement flow. Even a 2%
improvement in retention adds thousands of returning customers monthly.

### 2. 📍 São Paulo is the Crown Jewel
15,540 orders from one city = 15.6% of all revenue from one market.
**Action:** São Paulo-specific campaigns, faster delivery SLA, and exclusive
product availability will compound existing traction.

### 3. 💳 Credit Card Dependency is a Risk
73.9% of payments via credit card. A processor outage or fee hike threatens
the majority of transactions.
**Action:** Incentivize Boleto and add PIX (Brazil's instant payment system)
to diversify and reduce friction.

### 4. 🛏️ Protect the Top Category
Bed/Bath/Table is the revenue leader.
**Action:** Dedicated inventory monitoring and a supplier quality review process.
A stockout or quality drop here has the largest single-category revenue impact.

### 5. ⭐ Seller Tier System
Data clearly segments sellers by performance.
**Action:** Implement Gold/Silver/Bronze tiers based on revenue, on-time delivery %,
and review score. Reward top performers with better placement. Issue warnings to
late-delivery offenders before they damage customer trust.

---

## SQL Concepts Demonstrated

| Category | Concepts |
|----------|---------|
| **Joins** | INNER JOIN, LEFT JOIN, multi-table JOINs across 4–5 tables |
| **Aggregations** | SUM, COUNT, AVG, ROUND with GROUP BY and HAVING |
| **Window Functions** | RANK(), DENSE_RANK(), ROW_NUMBER(), LAG(), NTILE(), Running SUM() |
| **CTEs** | Multi-step CTEs for readable, layered logic |
| **Subqueries** | Correlated subqueries and derived tables |
| **Conditional Logic** | CASE WHEN for segmentation and classification |
| **Date Functions** | EXTRACT(), date arithmetic, INTERVAL operations |
| **Data Quality** | NULLIF() to handle division-by-zero, IS NOT NULL filters |
| **Schema Design** | Primary keys, foreign keys, normalized 8-table structure |

---

## Project Structure

```
ecommerce-sql-project/
├── schema/
│   ├── create_tables.sql          # Database schema with all FK relationships
│   └── er_diagram.png             # Visual schema diagram
├── analysis/
│   ├── 01_exploratory_analysis.sql   # KPIs and dataset overview
│   ├── 02_customer_analysis.sql      # Retention, segmentation, geography
│   ├── 03_product_seller_analysis.sql # Product performance and seller quality
│   └── 04_advanced_window_functions.sql # LAG, RANK, CTEs, NTILE
├── insights/
│   └── insights.md                # Full findings and recommendations
└── README.md
```

---

## Tools Used

- **PostgreSQL 16** — Database engine
- **pgAdmin 4** — Query development and schema management
- **VS Code** — SQL file editing

---

## About

This project was built as part of a Data Analytics portfolio to demonstrate
real-world SQL skills without a formal degree.

The goal was not to complete a tutorial — it was to answer questions a real
business would pay to have answered, using real data at real scale (1.5M+ records).

**Connect:** [LinkedIn](www.linkedin.com/in/shivam-yadav-0482b4416) | [GitHub](https://github.com/Raaz245)
