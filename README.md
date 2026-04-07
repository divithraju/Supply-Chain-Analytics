# 🚚 Supply Chain & Operations Analytics — End-to-End Intelligence Dashboard

<div align="center">

![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-2.0-150458?style=for-the-badge&logo=pandas&logoColor=white)
![Plotly](https://img.shields.io/badge/Plotly-Interactive-3F4F75?style=for-the-badge&logo=plotly&logoColor=white)
![Streamlit](https://img.shields.io/badge/Streamlit-Live_Demo-FF4B4B?style=for-the-badge&logo=streamlit&logoColor=white)

</div>
Raw Operations Data → Inventory Intelligence → Supplier Risk → Cost Reduction Strategy

## 📌 Business Problem

A consumer goods company with ₹180 crore annual procurement spends operates across 6 product categories, 4 warehouses, and 38 suppliers in 12 states. Despite this scale, operations runs on intuition — no one knows which suppliers are consistently late, which SKUs are chronically overstocked, or how much money is tied up in dead inventory.

### What leadership is asking:

- Which suppliers are causing delivery delays — and what does each delay cost us?  
- Where is our inventory capital locked up in slow-moving or dead stock?  
- What is our true order fulfillment rate and where is it breaking down?  
- Which routes and warehouses have the highest logistics costs?  
- Can we forecast demand well enough to prevent both stockouts and overstock?  

---

## 🎯 Key Business Questions Answered

| # | Question | Finding |
|---|----------|---------|
| 1 | What is our on-time delivery rate? | 67.3% — 32.7% of orders arrive late |
| 2 | Which supplier is highest risk? | Supplier_14 — 58% late rate, avg 8.3 days late |
| 3 | How much capital is in dead stock? | ₹4.7 crore in SKUs with zero movement in 90+ days |
| 4 | What is our stockout frequency? | 312 stockout events — ₹2.1 crore in lost sales |
| 5 | What is our perfect order rate? | 54.2% — industry benchmark is 85%+ |
| 6 | Which warehouse is least efficient? | Warehouse_3 — highest cost-per-order and lowest fill rate |
| 7 | Where can we reduce procurement cost? | Consolidating 3 low-volume suppliers saves ₹38 lakh/year |
| 8 | What is next quarter demand forecast? | +12% projected growth — pre-order buffer needed now |

## 📁 Project Structure

- **notebooks/**
  - `supply_chain_analysis.ipynb` – Full analysis (run this first)

- **sql/**
  - `supply_chain_queries.sql` – 18 operations SQL queries

- **dashboard/**
  - `app.py` – Streamlit live dashboard

- **data/**
  - `README_data.md` – Dataset info + download link

- **reports/**
  - `operations_executive_summary.md` – COO-ready findings

- **README.md**
  - Project overview

---

## 🔍 Analysis Methodology

### 1. Supplier Performance Scorecard
- Built a composite supplier score across 4 dimensions:
  - On-Time Delivery Rate (40% weight) — most critical  
  - Quality Rejection Rate (25% weight)  
  - Lead Time Consistency (20% weight) — coefficient of variation  
  - Price Competitiveness vs category median (15% weight)  

### 2. Inventory Health Classification (ABC-XYZ Matrix)
- ABC Analysis: Ranked SKUs by revenue contribution (A=top 70%, B=next 20%, C=last 10%)  
- XYZ Analysis: Classified by demand variability (X=stable, Y=variable, Z=erratic)  
- Combined into 9-cell matrix — each cell gets different replenishment policy  

### 3. Dead Stock & Overstock Detection
- Dead stock: zero movement in 90+ days  
- Overstock: current inventory > 3x avg monthly demand  
- Economic impact: carrying cost modeled at 25% of inventory value per year  

### 4. Order Fulfillment Analysis
- Perfect Order Rate: on-time + complete + undamaged  
- Fill Rate by SKU, warehouse, and supplier  
- Root cause breakdown of fulfillment failures  

### 5. Demand Forecasting (Moving Average + Trend)
- 3-month and 6-month moving averages  
- Seasonal decomposition by product category  
- Next-quarter projection with confidence interval  

### 6. Logistics Cost Analysis
- Cost-per-order by route and warehouse  
- Freight cost as % of order value by supplier distance  
- Consolidation opportunity identification  

---

## 💡 Top 6 Findings & Recommendations

### Finding 1: 8 Suppliers Are Causing 78% of Delays
The company has 38 suppliers. The bottom 8 account for 78% of all late deliveries. Yet procurement continues ordering from them because "they're the only option" — a claim the data disputes.  

**Action:** Issue formal performance improvement notices to bottom 8 suppliers. For the 3 worst, identify alternate qualified suppliers within 60 days.  

---

### Finding 2: ₹4.7 Crore Locked in Dead Inventory
847 SKUs have had zero movement in 90+ days. This represents ₹4.7 crore in capital earning 0% — while the company pays 25% carrying cost (₹1.17 crore/year).  

**Action:** Liquidate Category C dead stock at 30% discount. Return Category A dead stock to supplier. Target: free ₹3.2 crore in 90 days.  

---

### Finding 3: Perfect Order Rate is 54.2% vs 85% Industry Standard
Only 54.2% of orders are perfect. Root causes: Late delivery (32.7%), short shipments (8.4%), damage (4.7%).  

**Action:** Each % improvement saves ~₹18 lakh. Target 75% by Q3.  

---

### Finding 4: Warehouse_3 Has 2.1x Higher Cost-per-Order
Cost-per-order ₹847 vs ₹412 average. Lowest fill rate and highest damage rate.  

**Action:** Audit operations. Consider consolidating into Warehouse_2.  

---

### Finding 5: Demand Forecasting Error is 34%
High MAPE leads to both overstock and stockouts.  

**Action:** Implement rolling average forecasting → reduce MAPE to ~18%. Prevent ₹1.4Cr loss.  

---

### Finding 6: Supplier Consolidation Saves ₹38 Lakh/Year
14 suppliers contribute minimal volume but high admin overhead.  

**Action:** Consolidate 3 suppliers → save ₹11.4 lakh immediately.  

---

## 📈 Financial Impact Summary

| Initiative | Investment | Annual Saving/Recovery |
|-----------|------------|------------------------|
| Liquidate dead stock | ₹0 | ₹1.17Cr |
| Supplier PIP + alternates | ₹8L | ₹62L |
| Improve perfect order rate | ₹12L | ₹54L |
| Warehouse_3 consolidation | ₹25L | ₹48L/year |
| Demand forecasting upgrade | ₹0 | ₹1.4Cr |
| **Total** | **₹45L** | **₹3.65Cr/year** |

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| Python + Pandas | Data pipeline, feature engineering |
| Plotly + Matplotlib + Seaborn | 16+ operational charts |
| Scipy + Numpy | Forecasting, variability metrics |
| MySQL | 18 supply chain SQL queries |
| Streamlit | Live operations dashboard |

## 🚀 How to Run

```bash
git clone https://github.com/divithraju/supply-chain-analytics
cd supply-chain-analytics

pip install -r requirements.txt

jupyter notebook notebooks/supply_chain_analysis.ipynb
streamlit run dashboard/app.py




