[README.md](https://github.com/user-attachments/files/33187134/README_FINAL.1.md)
# E-Commerce Sales Intelligence System

[![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue)](https://www.postgresql.org)
[![Dataset](https://img.shields.io/badge/Dataset-Olist-green)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
[![Records](https://img.shields.io/badge/Records-1.5M%2B-orange)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen)](https://github.com)

---

## Project Overview

A complete end-to-end SQL analytics project built on **1,528,108 real e-commerce transactions** from Olist — Brazil's largest e-commerce marketplace.

This project answers real business questions: Why are 97% of customers not returning? Which sellers are hurting the platform? Where is the next R$1M of revenue hiding?

**Built to demonstrate:** Database design, complex query writing, business intelligence thinking, and the ability to turn raw data into actionable recommendations.

---

## Dataset

| Detail | Info |
|--------|------|
| **Source** | Brazilian E-Commerce Public Dataset by Olist (Kaggle) |
| **Period** | 2016 – 2018 |
| **Total Records** | 1,528,108 across 8 tables |

### Database Schema

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

### 🔥 The Most Important Finding: 97% Customer Churn

```
Customer Type      Count    Percentage
─────────────────────────────────────
One-Time Buyer     93,099   96.88%
Repeat Buyer       2,997    3.12%
```

**Business Implication:** The platform is re-acquiring virtually every customer from scratch each month. A targeted retention campaign for customers 30–45 days post-purchase could significantly shift this.

### 📈 Month-over-Month Revenue Growth

Finding: Business grew 312% year-over-year from 2016 to 2017, with a clear November peak (Black Friday effect).

### 🏆 Seller Performance Concentration

- **Top 10 sellers** = 23% of total revenue
- **Top 50 sellers** = 65% of total revenue
- **Recommendation:** Diversify seller base to reduce dependency

---

## Business Recommendations

### 1. 🚨 Customer Retention Crisis (Highest Priority)

97% one-time buyer rate means the platform effectively has zero organic growth. 

**Action:** Launch a 45-day post-purchase email re-engagement flow. Even a 2% improvement in retention adds thousands of returning customers monthly.

### 2. 📍 São Paulo is the Crown Jewel

15,540 orders from one city = 15.6% of all revenue from one market. 

**Action:** São Paulo-specific campaigns, faster delivery SLA, and exclusive product availability will compound existing traction.

### 3. 💳 Credit Card Dependency is a Risk

73.9% of payments via credit card. A processor outage or fee hike threatens the majority of transactions. 

**Action:** Incentivize Boleto and add PIX (Brazil's instant payment system) to diversify and reduce friction.

### 4. 🛏️ Protect the Top Category

Bed/Bath/Table is the revenue leader. 

**Action:** Dedicated inventory monitoring and a supplier quality review process. A stockout or quality drop here has the largest single-category revenue impact.

### 5. ⭐ Seller Tier System

Data clearly segments sellers by performance. 

**Action:** Implement Gold/Silver/Bronze tiers based on revenue, on-time delivery %, and review score. Reward top performers with better placement.

---

## Project Structure

```
ecommerce-sql-project/
├── README.md                              # Project overview
├── data_dictionary.md                     # Complete table & column reference
│
├── 01_exploratory_analysis.sql           # Dataset overview & KPIs
├── 02_customer_analysis.sql              # Customer segmentation & retention
├── 03_product_seller_analysis.sql        # Product performance & seller quality
├── 04_advanced_window_functions.sql      # Complex analytical queries
├── 05_query_optimization.sql             # Performance tuning & EXPLAIN ANALYZE
├── 06_advanced_analytics.sql             # Cohort, LTV, churn prediction
├── 07_data_quality_validation.sql        # Data integrity checks
│
├── insights.md                            # Business findings & recommendations
│
└── schema/
    ├── create_tables.sql                 # Database schema with relationships
    └── er_diagram.png                    # Visual entity-relationship diagram
```

---

## SQL Concepts Demonstrated

| Category | Concepts |
|----------|----------|
| **Joins** | INNER JOIN, LEFT JOIN, multi-table JOINs across 4–5 tables |
| **Aggregations** | SUM, COUNT, AVG, ROUND with GROUP BY and HAVING |
| **Window Functions** | RANK(), DENSE_RANK(), ROW_NUMBER(), LAG(), LEAD(), NTILE() |
| **CTEs** | Multi-step CTEs for readable, layered logic |
| **Subqueries** | Correlated subqueries and derived tables |
| **Conditional Logic** | CASE WHEN for segmentation and classification |
| **Date Functions** | EXTRACT(), date arithmetic, INTERVAL operations |
| **Data Quality** | NULLIF(), NULL handling, data validation |
| **Query Optimization** | EXPLAIN ANALYZE, indexing strategies, performance tuning |
| **Advanced Analytics** | Cohort analysis, LTV calculation, churn prediction, anomaly detection |
| **Schema Design** | Primary keys, foreign keys, normalized 8-table structure |

---

## File Descriptions

### Analysis Files (4)

**01_exploratory_analysis.sql**
- Dataset overview and row counts
- Key performance indicators (KPIs)
- Basic aggregations and distribution analysis

**02_customer_analysis.sql**
- Customer segmentation (high/medium/low value)
- Geographic analysis (state, city breakdown)
- Repeat purchase analysis (churn detection)
- Cohort basics

**03_product_seller_analysis.sql**
- Seller performance scorecards
- Product revenue attribution
- On-time delivery metrics
- Review score analysis by seller

**04_advanced_window_functions.sql**
- Window functions (LAG, LEAD, RANK, ROW_NUMBER, NTILE)
- CTEs for multi-step logic
- Subqueries and complex joins
- Running totals and rankings

### Enhancement Files (3)

**05_query_optimization.sql**
- Index recommendations and setup
- EXPLAIN ANALYZE for execution plans
- Before/after performance comparisons
- Query optimization techniques
- Materialized views for dashboards
- Expected improvements: 30-80% faster queries

**06_advanced_analytics.sql**
- Cohort retention analysis (month-over-month grid)
- Customer lifetime value (LTV) calculation
- Churn risk prediction (0-100 score)
- Anomaly detection for sellers
- Month-over-month growth analysis
- Purchase pattern segmentation

**07_data_quality_validation.sql**
- NULL value analysis per column
- Duplicate detection (PK, FK violations)
- Foreign key constraint validation
- Data completeness checks
- Outlier detection (statistical)
- Data consistency validations
- Quality scorecard (PASS/FAIL checklist)

### Documentation

**data_dictionary.md**
- Complete field-by-field reference for all 8 tables
- Data types, examples, and business meanings
- Key relationships and constraints
- Common analytical queries

---

## Running the Project

### Prerequisites
- PostgreSQL 13+
- pgAdmin 4 or similar SQL IDE
- Olist Brazilian E-Commerce dataset (from Kaggle)

### Setup

1. **Create tables** (run schema/create_tables.sql)
2. **Import CSV files** into respective tables
3. **Validate data** (run 07_data_quality_validation.sql)

### Run Analysis (In Order)

```bash
psql -U postgres -d olist -f 01_exploratory_analysis.sql
psql -U postgres -d olist -f 02_customer_analysis.sql
psql -U postgres -d olist -f 03_product_seller_analysis.sql
psql -U postgres -d olist -f 04_advanced_window_functions.sql
psql -U postgres -d olist -f 05_query_optimization.sql
psql -U postgres -d olist -f 06_advanced_analytics.sql
psql -U postgres -d olist -f 07_data_quality_validation.sql
```

---

## Tools Used

- **PostgreSQL 16** — Database engine
- **pgAdmin 4** — SQL development environment
- **VS Code** — Query editing and documentation

---

## About

This project demonstrates real-world SQL skills using a production-scale dataset (1.5M+ records). It answers questions a real business would pay to have answered, combining technical SQL expertise with business intelligence thinking.

The project showcases:
- Complex SQL with optimization
- Advanced analytics (cohort, LTV, churn prediction)
- Data quality validation
- Complete documentation
- Production-ready code

---

## Connect

- **LinkedIn:** [Shivam Yadav](https://www.linkedin.com/in/shivam-yadav-0482b4416)
- **GitHub:** [Raaz245](https://github.com/Raaz245)

---

**Data Source:** [Olist Brazilian E-Commerce (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
