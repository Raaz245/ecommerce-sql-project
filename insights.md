# Key Business Insights — E-Commerce Sales Intelligence System

> All findings derived from SQL analysis of 1,528,108 records across 8 tables (2016–2018)

---

## 💰 Revenue Overview

| Metric | Value |
|--------|-------|
| Total Revenue | $16,008,872 |
| Total Orders | 99,441 |
| Average Order Value | R$154.10 |
| Total Unique Customers | 96,096 |

---

## 📈 Growth Trend

- Business grew **312% year-over-year** from 2016 to 2017
- Peak month identified: **November 2017** — consistent with Black Friday effect
- Revenue trajectory was consistently upward through 2018

---

## 👥 Customer Insights

| Segment | Count | % |
|---------|-------|---|
| One-Time Buyers | 93,099 | 97% |
| Repeat Buyers | 2,997 | 3% |

**Critical Finding:** 97% of customers never returned after their first purchase.
This is the single biggest revenue opportunity — even improving retention to 10%
would add significant recurring revenue.

**Top Markets by Orders:**
1. São Paulo — 15,540 orders
2. Rio de Janeiro — 6,882 orders
3. Belo Horizonte — 2,773 orders

São Paulo alone represents ~15.6% of all orders — a dominant single-city market.

---

## 🛍️ Product Insights

**Top 5 Categories by Revenue:**
1. Bed / Bath / Table
2. Health & Beauty
3. Sports & Leisure
4. Computers & Accessories
5. Furniture & Decor

**Quality Note:** Categories with high revenue but low ratings (< 3.5 stars)
represent churn risk — customers unlikely to return after a bad experience.

---

## 💳 Payment Insights

| Payment Method | Transactions | % Share |
|----------------|-------------|---------|
| Credit Card | 76,795 | 73.9% |
| Boleto | 19,784 | 19.0% |
| Voucher | 5,775 | 5.6% |
| Debit Card | 1,529 | 1.5% |

**Risk:** Over-dependence on credit card payments. If credit card processors face
outages or increase fees, 74% of transactions are at risk.

---

## 🚚 Delivery Performance

- Platform generally **over-delivers** on its promises — actual delivery often
  arrives before the estimated date
- States with logistics challenges: Roraima (RR), Amapá (AP), Amazonas (AM)
  — Amazon region where infrastructure is limited

---

## 💡 Business Recommendations

### 1. Launch a Customer Retention Program (Highest Priority)
97% churn rate means the business is essentially acquiring every customer fresh
each month. A simple email re-engagement campaign targeting customers 45 days
after first purchase could meaningfully shift this number.

### 2. Double Down on São Paulo
15,540 orders from one city. A city-specific marketing campaign, faster delivery
SLA, or exclusive product availability for São Paulo customers would compound
existing traction.

### 3. Diversify Payment Options
Reduce credit card dependency by promoting Boleto and adding PIX (Brazil's
instant payment system). Lower friction = more conversions.

### 4. Protect the Bed/Bath/Table Category
Top-selling category needs dedicated inventory management and a quality review
process. A stockout or quality drop here has outsized revenue impact.

### 5. Seller Performance Tiers
Implement a seller tier system (Gold / Silver / Bronze) based on revenue,
on-time delivery %, and review score. Reward top performers with better
placement. Penalize late-delivery offenders.
