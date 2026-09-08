#  E-Commerce Sales Intelligence System

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-blue)
![Dataset](https://img.shields.io/badge/Dataset-Olist-green)
![Records](https://img.shields.io/badge/Records-100K+-orange)

## Project Overview
A complete end-to-end SQL analytics project built on 100,000+ real 
e-commerce transactions. This project demonstrates real-world database 
design, complex query writing, and business intelligence skills by 
analyzing data from Olist — Brazil's largest e-commerce marketplace.

---

##  Dataset
- **Source:** Brazilian E-Commerce Public Dataset by Olist (Kaggle)
- **Period:** 2016 – 2018
- **Total Records:** 1,528,108 across 8 tables

---

##  Database Schema

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


* Total Revenue  -- $ 16,008,872 
* Total Orders   --- 99,441 
* Average Order Value -- R$ 154.10 
* Top Payment Method | Credit Card (76,795 transactions) 
* Top City by Orders | Sao Paulo (15,540 orders) |
* Top Product Category | Bed/Bath/Table (11,115 orders) |
* One-Time Buyers | 93,099 (97%) |
* Repeat Buyers | 2,997 (3%) |



##  Business Recommendations

1. **Customer Retention Crisis** — 97% one-time buyer rate indicates 
   a serious retention problem. A loyalty rewards program is needed.

2. **Sao Paulo Dominance** — With 15,540 orders, Sao Paulo is the 
   key market. Targeted campaigns can maximize revenue here.

3. **Credit Card Dependency** — 76,795 out of 103,886 payments via 
   credit card. Diversifying payment options can attract more buyers.

4. **Bed/Bath/Table Opportunity** — Top selling category needs 
   strong inventory management to avoid stockouts.

---

##  SQL Concepts Demonstrated

- Database Design and Schema Creation
-  Primary Keys and Foreign Key Relationships
-  Complex JOIN Operations (INNER, LEFT, Multiple Tables)
-  Subqueries and Nested Queries
-  CTEs (Common Table Expressions)
-  Window Functions (RANK, DENSE_RANK, LAG, Running Total)
-  Aggregate Functions (SUM, COUNT, AVG, ROUND)
-  Business Intelligence Queries
-  Data Import and Management (1.5M+ records)

---

## Project Structure
```text

ecommerce-sql-project/
├── schema/
│   └── create_tables.sql         # Database schema
├── analysis/
│   └── ecommerce_analysis.sql    # All business queries
└── insights/
    └── insights.md               # Key findings

## Tools Used
- PostgreSQL 18
- pgAdmin 4
- VS Code

##About
This project was built as part of a Data Analytics portfolio 
to demonstrate real-world SQL skills without a formal degree.
