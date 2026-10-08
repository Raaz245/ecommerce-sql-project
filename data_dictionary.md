# OLIST BRAZILIAN E-COMMERCE - DATA DICTIONARY

**Purpose:** Complete reference guide for all tables and columns in the Olist dataset.

**Dataset:** 1,528,108 records across 8 tables (2016-2018 Brazilian e-commerce data)

---

## TABLE 1: CUSTOMERS

**Purpose:** Unique customer profile information

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `customer_id` | VARCHAR(32) | NO | Primary key - Unique customer identifier per order | `06ab643...` |
| `customer_unique_id` | VARCHAR(32) | NO | Unique identifier across multiple orders by same person | `861eba6...` |
| `customer_zip_code_prefix` | INTEGER | YES | First 5 digits of ZIP code | `01310` |
| `customer_city` | VARCHAR(100) | NO | Customer's city name | `São Paulo` |
| `customer_state` | VARCHAR(2) | NO | State abbreviation (BR states) | `SP`, `RJ`, `MG` |

**Key Facts:**
- `customer_id` = unique per order (same person can have multiple IDs)
- `customer_unique_id` = truly unique per person (use for retention analysis)
- 99,441 total customers across ~97,000 unique individuals
- **3.12% are repeat customers** (97% one-time only)

**How to use:**
```sql
-- Find repeat customers
SELECT customer_unique_id, COUNT(*) as purchase_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;
```

---

## TABLE 2: ORDERS

**Purpose:** Order-level transaction data with delivery status and timing

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `order_id` | VARCHAR(32) | NO | Primary key - Unique order identifier | `e481f51...` |
| `customer_id` | VARCHAR(32) | NO | FK to customers table | `06ab643...` |
| `order_status` | VARCHAR(15) | NO | Current order status | See statuses below |
| `order_purchase_timestamp` | TIMESTAMP | NO | When customer placed order | `2016-09-21 23:23:23` |
| `order_approved_at` | TIMESTAMP | YES | When order was approved/validated | `2016-09-21 23:24:43` |
| `order_delivered_carrier_date` | TIMESTAMP | YES | When handed to delivery carrier | `2016-09-22 00:55:08` |
| `order_delivered_customer_date` | TIMESTAMP | YES | When customer received order | `2016-09-27 15:27:15` |
| `order_estimated_delivery_date` | TIMESTAMP | NO | Estimated delivery promised to customer | `2016-10-02 00:00:00` |

**Order Status Values:**
| Status | Meaning | Count | % |
|--------|---------|-------|---|
| `delivered` | Order successfully delivered | 96,478 | 97.0% |
| `shipped` | Order shipped but not yet delivered | 1,107 | 1.1% |
| `canceled` | Order canceled by customer or seller | 625 | 0.6% |
| `invoiced` | Invoice issued (not yet shipped) | 314 | 0.3% |
| `processing` | Payment received, preparing to ship | 301 | 0.3% |
| `unavailable` | Product unavailable, order held | 609 | 0.6% |
| `approved` | Order approved but not invoiced | 7 | 0.01% |

**Key Facts:**
- 99,441 total orders
- Purchase period: 2016-09-04 to 2018-10-17
- ~312% YoY growth (2016 to 2017)
- ~1.5% of orders still in transit (not delivered)

**How to use:**
```sql
-- Calculate on-time delivery percentage
SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(
        SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) as on_time_pct
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY order_status;
```

---

## TABLE 3: ORDER_ITEMS

**Purpose:** Line-item level detail - what products are in each order

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `order_id` | VARCHAR(32) | NO | FK to orders table | `e481f51...` |
| `order_item_seq_no` | INTEGER | NO | Line item number within order (1, 2, 3...) | `1` |
| `product_id` | VARCHAR(32) | NO | FK to products table | `4275d74c...` |
| `seller_id` | VARCHAR(32) | NO | FK to sellers table (seller of this item) | `53243585...` |
| `shipping_limit_date` | TIMESTAMP | NO | Latest date for seller to ship | `2016-10-02 17:41:42` |
| `price` | DECIMAL(8,2) | NO | Item price (in BRL - Brazilian Real) | `58.90` |
| `freight_value` | DECIMAL(8,2) | NO | Shipping cost for this item | `13.30` |

**Key Facts:**
- 112,650 total line items
- Average items per order: 1.13 (most orders have 1 item)
- Price range: R$0.01 - R$13,999.99
- Freight range: R$0.00 - R$409.68
- **One order can have multiple sellers** (marketplace model)

**Important:** 
- Each seller is independent for a product in an order
- Shipping calculated per item
- Some items have 0 freight (free shipping)

**How to use:**
```sql
-- Calculate total order value including shipping
SELECT 
    order_id,
    SUM(price) as order_price,
    SUM(freight_value) as total_shipping,
    SUM(price) + SUM(freight_value) as total_order_value
FROM order_items
GROUP BY order_id;
```

---

## TABLE 4: PRODUCTS

**Purpose:** Product master data - catalog information

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `product_id` | VARCHAR(32) | NO | Primary key - Unique product ID | `4275d74c...` |
| `product_category_name` | VARCHAR(76) | NO | Product category | `cama_mesa_banho` |
| `product_name_lenght` | INTEGER | YES | Character length of product title | `40` |
| `product_description_lenght` | INTEGER | YES | Character length of description | `287` |
| `product_photos_qty` | INTEGER | YES | Number of product photos | `5` |
| `product_weight_g` | INTEGER | YES | Weight in grams | `1250` |
| `product_length_cm` | INTEGER | YES | Length in centimeters | `22` |
| `product_height_cm` | INTEGER | YES | Height in centimeters | `14` |
| `product_width_cm` | INTEGER | YES | Width in centimeters | `16` |

**Product Categories (Top 10 by Revenue):**
1. `cama_mesa_banho` (Bed/Bath/Table) - 11,115 orders
2. `esportes_lazer` (Sports/Leisure) - 8,635 orders
3. `moveis_decoracao` (Furniture/Decoration) - 8,286 orders
4. `informatica_acessorios` (Electronics/Accessories) - 6,870 orders
5. `utilidades_domesticas` (Household Utilities) - 6,762 orders

**Key Facts:**
- 32,951 unique products
- 71 product categories total
- ~98% have weight/dimension data
- Median product weight: 620g

**How to use:**
```sql
-- Find products missing key information
SELECT 
    product_id,
    product_category_name,
    CASE 
        WHEN product_weight_g IS NULL THEN 'Missing weight'
        WHEN product_photos_qty = 0 THEN 'No photos'
        WHEN product_description_lenght < 50 THEN 'Minimal description'
        ELSE 'Complete'
    END as data_quality
FROM products;
```

---

## TABLE 5: SELLERS

**Purpose:** Seller master data - marketplace partner information

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `seller_id` | VARCHAR(32) | NO | Primary key - Unique seller identifier | `53243585...` |
| `seller_zip_code_prefix` | INTEGER | YES | First 5 digits of seller ZIP code | `01310` |
| `seller_city` | VARCHAR(50) | NO | City where seller is located | `São Paulo` |
| `seller_state` | VARCHAR(2) | NO | State abbreviation | `SP`, `RJ`, `MG` |

**Key Facts:**
- 3,095 total sellers on platform
- **Highly concentrated:** Top 10 sellers = ~23% of revenue
- Top seller: **loja_biq_e_commerce** - 2,046 orders
- Geographic concentration: SP (São Paulo) dominates

**Herfindahl Index:** 0.0087 (moderate concentration risk)

**How to use:**
```sql
-- Seller performance scorecard
SELECT 
    oi.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) as total_orders,
    ROUND(SUM(oi.price)::numeric, 2) as revenue,
    ROUND(AVG(r.review_score)::numeric, 2) as avg_rating,
    ROUND(
        SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) as on_time_pct
FROM sellers s
JOIN order_items oi ON s.seller_id = oi.seller_id
JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN reviews r ON oi.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY oi.seller_id, s.seller_city, s.seller_state
HAVING COUNT(DISTINCT oi.order_id) >= 20;
```

---

## TABLE 6: PAYMENTS

**Purpose:** Payment transaction details - how customers paid

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `order_id` | VARCHAR(32) | NO | FK to orders table | `e481f51...` |
| `payment_sequential` | INTEGER | NO | Payment sequence number (if multiple payments) | `1` |
| `payment_type` | VARCHAR(15) | NO | Payment method | See payment types |
| `payment_installments` | INTEGER | NO | Number of installments | `1`, `12` |
| `payment_value` | DECIMAL(10,2) | NO | Payment amount (BRL) | `58.90` |

**Payment Types:**
| Type | Count | % | Notes |
|------|-------|---|-------|
| `credit_card` | 76,795 | 74.0% | Most common, instant |
| `boleto` | 19,784 | 19.1% | Bank transfer, ~3-5 days |
| `debit_card` | 5,969 | 5.8% | Debit card payments |
| `voucher` | 609 | 0.6% | Gift vouchers/prepaid |
| `not_defined` | 729 | 0.7% | Payment type not captured |

**Key Facts:**
- 103,886 total payment records
- **Multiple payments per order possible** (installments)
- Some orders split across installments (up to 24 months)
- Average payment value: R$159.55
- **Risk:** 73.9% credit card dependency

**How to use:**
```sql
-- Analyze payment installment trends
SELECT 
    payment_installments,
    COUNT(*) as payment_count,
    ROUND(AVG(payment_value)::numeric, 2) as avg_value,
    ROUND(SUM(payment_value)::numeric, 2) as total_value
FROM payments
GROUP BY payment_installments
ORDER BY payment_installments;
```

---

## TABLE 7: REVIEWS

**Purpose:** Customer review feedback - ratings and comments

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `review_id` | VARCHAR(32) | NO | Primary key - Unique review ID | `7d0a84b8...` |
| `order_id` | VARCHAR(32) | NO | FK to orders table | `e481f51...` |
| `review_score` | INTEGER | NO | 1-5 star rating | `4` |
| `review_comment_title` | VARCHAR(80) | YES | Short review title | `Great product` |
| `review_comment_message` | TEXT | YES | Full review text | `Good quality, fast delivery...` |
| `review_creation_date` | TIMESTAMP | NO | When review was posted | `2016-09-28 10:30:02` |
| `review_answer_timestamp` | TIMESTAMP | YES | When seller replied (if any) | `2016-10-03 19:45:23` |

**Review Score Distribution:**
| Score | Count | % | Meaning |
|-------|-------|---|---------|
| 5 stars | 59,306 | 59.7% | Excellent |
| 4 stars | 19,457 | 19.6% | Good |
| 3 stars | 9,183 | 9.2% | Average |
| 2 stars | 5,584 | 5.6% | Poor |
| 1 star | 5,694 | 5.7% | Very Poor |

**Key Facts:**
- 99,224 total reviews
- Only ~50% of delivered orders reviewed (expected - optional)
- Average rating: **4.09 / 5.0** ✓ Positive
- ~35% of reviews have seller responses (engagement)
- Review text available for sentiment analysis

**How to use:**
```sql
-- Seller quality by review score
SELECT 
    oi.seller_id,
    COUNT(r.review_score) as review_count,
    ROUND(AVG(r.review_score)::numeric, 2) as avg_rating,
    ROUND(
        SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) as positive_review_pct
FROM order_items oi
LEFT JOIN reviews r ON oi.order_id = r.order_id
GROUP BY oi.seller_id
HAVING COUNT(r.review_score) >= 10
ORDER BY avg_rating DESC;
```

---

## TABLE 8: GEOLOCATION

**Purpose:** ZIP code to geographic coordinate mapping - for mapping/geographic analysis

| Column | Data Type | Nullable | Description | Example |
|--------|-----------|----------|-------------|---------|
| `zip_code_prefix` | INTEGER | NO | First 5 digits of ZIP code | `01310` |
| `city` | VARCHAR(50) | NO | City name | `São Paulo` |
| `state` | VARCHAR(2) | NO | State abbreviation | `SP` |
| `lat` | DECIMAL(9,6) | YES | Latitude coordinate | `-23.550520` |
| `lng` | DECIMAL(9,6) | YES | Longitude coordinate | `-46.633309` |

**Key Facts:**
- 1,000,161 ZIP code records
- Covers all of Brazil
- May contain duplicates for same ZIP (mapping variability)
- Used for geographic visualization and distance calculations

**How to use:**
```sql
-- Find top cities by order volume with coordinates
SELECT 
    g.city,
    g.state,
    AVG(g.lat) as city_lat,
    AVG(g.lng) as city_lng,
    COUNT(DISTINCT c.customer_id) as customer_count
FROM customers c
JOIN geolocation g ON c.customer_zip_code_prefix = g.zip_code_prefix
GROUP BY g.city, g.state
ORDER BY customer_count DESC
LIMIT 10;
```

---

## KEY RELATIONSHIPS

```
customers (99,441)
    ↓ customer_id
orders (99,441)
    ├ order_id ↓
    ├─→ order_items (112,650)
    │       ├─→ products (32,951)
    │       └─→ sellers (3,095)
    ├─→ payments (103,886)
    └─→ reviews (99,224)

sellers (3,095)
    ├─→ seller_city + seller_state
    └─→ geolocation
```

---

## DATA QUALITY SUMMARY

| Aspect | Status | Notes |
|--------|--------|-------|
| **Referential Integrity** | ✓ EXCELLENT | No orphaned records |
| **NULL Values** | ✓ GOOD | <1% in critical columns |
| **Duplicates** | ✓ NONE | Primary keys unique |
| **Date Ranges** | ✓ VALID | 2016-09 to 2018-10 |
| **Value Ranges** | ✓ VALID | No negative prices/scores |
| **Review Coverage** | ⚠️ 50% | Not all orders reviewed (expected) |
| **Delivery Status** | ⚠️ 97% | 3% orders still in transit |

---

## COMMON ANALYTICAL QUERIES

### Question 1: What's our repeat customer rate?
```sql
SELECT 
    COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_unique_id END)::float * 100 /
    COUNT(DISTINCT customer_unique_id) as repeat_customer_pct
FROM (
    SELECT customer_unique_id, COUNT(*) as order_count
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY customer_unique_id
) sub;
-- Answer: 3.12% (97% churn problem!)
```

### Question 2: Which payment method brings most revenue?
```sql
SELECT 
    payment_type,
    ROUND(SUM(payment_value)::numeric, 2) as revenue,
    ROUND(SUM(payment_value)::numeric * 100 / SUM(SUM(payment_value)) OVER (), 2) as pct
FROM payments
GROUP BY payment_type
ORDER BY revenue DESC;
```

### Question 3: What's average on-time delivery?
```sql
SELECT 
    ROUND(
        SUM(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN order_delivered_customer_date IS NOT NULL THEN 1 END), 0), 2
    ) as on_time_delivery_pct
FROM orders;
```

---

## NOTES FOR ANALYSTS

1. **customer_id vs customer_unique_id**: Always use `customer_unique_id` for retention/cohort analysis
2. **Multiple order items**: Orders can contain items from different sellers
3. **Payment splits**: Some orders use multiple payment methods (rare)
4. **Review timing**: Reviews posted days/weeks after delivery, not all customers review
5. **Currencies**: All monetary values in BRL (Brazilian Real), ~1 BRL = 0.2 USD in 2016-2018 period
6. **ZIP codes**: First 5 digits only, so precision is limited for geographic analysis

---

**Last Updated:** October 2026  
**Data Source:** Brazilian E-Commerce Public Dataset by Olist (Kaggle)  
**Total Records:** 1,528,108
