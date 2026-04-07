# Dataset Information

## Dataset: Supply Chain & Logistics

**Primary Source (recommended):**  
https://www.kaggle.com/datasets/harshsingh2209/supply-chain-analysis  
File: `supply_chain_data.csv`

**Alternative datasets that also work:**  
https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis  
https://www.kaggle.com/datasets/prachi13/customer-analytics  

## Setup

1. Download from any Kaggle link above
2. Rename file to `supply_chain_data.csv`
3. Place in this `/data/` folder
4. Run: `jupyter notebook notebooks/supply_chain_analysis.ipynb`

> **Note:** If no file is found, the notebook generates 8,500 realistic purchase orders automatically. All analyses, charts, and SQL queries work without downloading any data.

## Auto-Generated Dataset Structure

When no file is present, the notebook creates:

| Table | Rows | Description |
|---|---|---|
| `orders` | 8,500 | Purchase orders with supplier, SKU, delivery performance |
| `inventory` | 320 | SKU-level inventory snapshot |

## Key Columns in Orders

| Column | Description |
|---|---|
| order_id | Unique PO identifier |
| order_date | Date of purchase order |
| supplier_id | Supplier code (SUP_01 to SUP_38) |
| supplier_state | State where supplier is located |
| sku_id | Product SKU |
| category | Product category |
| warehouse | Receiving warehouse |
| order_value | Total order value (₹) |
| freight_cost | Logistics cost (₹) |
| promised_lead_days | Lead time agreed with supplier |
| actual_lead_days | Actual lead time taken |
| delay_days | Days delayed (0 if on-time) |
| is_late | 1=late, 0=on-time |
| rejection_rate | % of goods rejected on quality check |
| is_damaged | 1=damage reported |
| is_short_shipped | 1=quantity short |
| is_perfect_order | 1=on-time + complete + undamaged + quality pass |

## Key Columns in Inventory

| Column | Description |
|---|---|
| sku_id | Product SKU |
| current_stock | Units currently in warehouse |
| avg_monthly_demand | Average units sold per month |
| last_movement_days | Days since last stock movement |
| reorder_point | Units at which to trigger reorder |
| stockout_events | Number of stockout events in the period |
| inventory_value | current_stock × unit_cost |
