# Supply Chain & Operations Executive Summary
### Operations Intelligence Report — FY 2024
**Prepared by:** Divith Raju | Data Analyst  
**Audience:** COO, Head of Procurement, Head of Logistics, CFO

---

## One-Line Summary

Our supply chain is running at 67.3% on-time delivery and 54.2% perfect order rate — both significantly below industry benchmarks of 90% and 85% respectively. Five specific initiatives can recover ₹3.65 crore in annual value against a ₹45 lakh investment.

---

## Operational Health Scorecard

| KPI | Our Performance | Industry Benchmark | Gap |
|---|---|---|---|
| On-Time Delivery Rate | 67.3% | 90%+ | **-22.7pp** 🔴 |
| Perfect Order Rate | 54.2% | 85%+ | **-30.8pp** 🔴 |
| Avg Delay (when late) | 6.4 days | <2 days | **-4.4 days** 🔴 |
| Quality Rejection Rate | 4.2% | <1% | **-3.2pp** 🟠 |
| Freight as % of Value | 6.1% | 4-5% | **-1.1pp** 🟡 |
| Forecast MAPE | 34% | <20% | **-14pp** 🟠 |

---

## The Five Things That Are Costing Us the Most

### Problem 1: 8 Suppliers Causing 78% of All Delays
Our supplier portfolio has 38 active suppliers. The bottom 8 — all flagged as "Critical Risk" in the scorecard — account for 78% of total late deliveries.

The total cost of all delays, modeled at 0.2% of order value per day delayed, is approximately **₹62 lakh per year**. If the 8 critical suppliers improve to company-average performance, we recover ₹38.4 lakh of that.

We continue ordering from these suppliers because procurement perceives no alternative. The data shows 4 of the 8 supply categories that have single-source critical suppliers also have qualified alternate suppliers in the same state — they have simply not been activated.

**Immediate action:** Issue Performance Improvement Notices (PINs) to all 8 this week. Set 60-day improvement targets. For the 3 worst, begin alternate supplier qualification in parallel.

---

### Problem 2: ₹4.7 Crore Locked in Dead Inventory
847 SKUs have had zero stock movement in 90 or more days. The inventory value of these SKUs is ₹4.7 crore — earning 0% return while costing the company **₹1.17 crore per year in carrying cost** (warehousing, insurance, capital opportunity cost at 25% per year).

Classification:
- **Category A dead stock** (high-revenue SKUs now dormant): ₹1.8 crore — negotiate supplier returns in next contract cycle
- **Category C dead stock** (low-revenue, erratic demand SKUs): ₹1.2 crore — liquidate at 30% discount = ₹840K cash recovered
- **Category B dead stock**: ₹1.7 crore — run clearance promotion at 15% discount before liquidating

**90-day target:** Free ₹3.2 crore in working capital. Eliminate ₹1.17 crore in annual carrying cost.

---

### Problem 3: Perfect Order Rate at 54.2% — Nearly Half of Orders Have Problems
Every imperfect order — one that arrives late, damaged, short-shipped, or with quality issues — requires exception handling. The estimated cost of exception handling per imperfect order is ₹1,800 (admin time, rework, customer communication, re-shipping).

At 54.2% POR with 8,500 annual orders:
- Imperfect orders per year: ~3,900
- Exception handling cost: **₹70.2 lakh per year**

The breakdown of failure causes:
- Late delivery: 32.7% of all orders (biggest driver)
- Short shipment: 8.4% of all orders
- Damage in transit: 4.7% of all orders
- Quality rejection: 3.3% of all orders

Each 1 percentage point improvement in POR saves approximately ₹1.53 lakh in exception handling.

**Target:** Reach 75% POR by Q3 (saves ₹32.1 lakh vs current).

---

### Problem 4: Warehouse_Central Has 2.1x Higher Cost-per-Order
Warehouse_Central in Central India shows:
- Cost-per-order: ₹847 vs company average ₹412
- Perfect Order Rate: 49.3% vs company average 54.2%
- Damage rate: 8.1% vs company average 4.7%

This is not a location problem — Warehouse_North, serving a similar geography, runs at ₹389/order with 61.4% POR.

**Root cause hypothesis:** Warehouse_Central has 30% fewer staff per order volume than other warehouses, and its layout was not updated when the SKU range expanded in 2022.

**Action:** Commission a 2-week operations audit of Warehouse_Central. Consider consolidating its volume into Warehouse_East which operates at 72% capacity utilization.

---

### Problem 5: 34% Forecast Error Is Creating Both Overstock and Stockout Simultaneously
The current manual forecasting method — spreadsheet-based with subjective adjustments — has a Mean Absolute Percentage Error (MAPE) of 34%. This means our purchase orders are off by a third on average.

The result: we simultaneously have ₹4.7 crore in dead inventory (over-forecast) and 312 documented stockout events worth ₹2.1 crore in lost sales (under-forecast).

A 3-month rolling average model — which takes 20 minutes to implement in the existing data system — reduces MAPE on historical data to 18%. This single change prevents an estimated **₹1.4 crore** in combined overstock carrying cost and stockout losses annually.

**Action:** Implement 3-month MA forecasting in the next planning cycle. Budget: ₹0. Timeline: 2 weeks.

---

## Investment vs Return Summary

| Initiative | One-Time Cost | Annual Saving/Recovery |
|---|---|---|
| Supplier PIP + alternate sourcing | ₹8L | ₹38.4L |
| Dead stock liquidation | ₹0 | ₹1.17Cr (carrying) + ₹84L (liquidation cash) |
| POR improvement program | ₹12L | ₹32.1L |
| Warehouse_Central audit & fix | ₹25L | ₹48L |
| Demand forecasting upgrade | ₹0 | ₹1.4Cr |
| **Total** | **₹45L** | **₹3.65Cr/year** |

**ROI: 711% in Year 1**

---

## Priority Action Calendar

| Week | Action | Owner |
|---|---|---|
| This week | Issue PIN letters to 8 critical suppliers | Procurement Head |
| This week | Implement 3M MA forecasting | Data/Planning team |
| Week 2 | Dead stock audit — categorise by ABC | Inventory Manager |
| Week 3 | Begin Warehouse_Central audit | COO + Ops Head |
| Month 2 | Liquidate Category C dead stock | Sales + Logistics |
| Month 2 | Begin alternate supplier qualification | Procurement |
| Month 3 | Review supplier PIN outcomes | COO |

---

*Full technical analysis: `notebooks/supply_chain_analysis.ipynb`*  
*SQL operations queries: `sql/supply_chain_queries.sql`*  
*Live dashboard: `streamlit run dashboard/app.py`*
