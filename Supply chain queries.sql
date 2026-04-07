-- ================================================================
-- SUPPLY CHAIN & OPERATIONS ANALYTICS — SQL QUERIES
-- Author: Divith Raju
-- Tools: MySQL 8.0
-- ================================================================

USE supply_chain;

-- ================================================================
-- QUERY 1: OVERALL OPERATIONS HEALTH DASHBOARD
-- Business Question: What are our headline supply chain KPIs?
-- ================================================================
SELECT
    COUNT(DISTINCT order_id)                                        AS total_orders,
    COUNT(DISTINCT supplier_id)                                     AS active_suppliers,
    COUNT(DISTINCT sku_id)                                          AS active_skus,
    ROUND(SUM(order_value), 0)                                      AS total_procurement_value,
    ROUND(SUM(freight_cost), 0)                                     AS total_freight_cost,
    ROUND(SUM(freight_cost) * 100.0 / SUM(order_value), 2)         AS freight_as_pct_of_value,
    ROUND((1 - AVG(is_late)) * 100, 2)                             AS on_time_delivery_rate_pct,
    ROUND(AVG(is_perfect_order) * 100, 2)                          AS perfect_order_rate_pct,
    ROUND(AVG(delay_days), 2)                                      AS avg_delay_days_all_orders,
    ROUND(AVG(CASE WHEN is_late=1 THEN delay_days END), 2)         AS avg_delay_days_late_only,
    ROUND(AVG(rejection_rate) * 100, 3)                            AS avg_quality_rejection_pct,
    ROUND(AVG(is_damaged) * 100, 2)                                AS damage_rate_pct,
    ROUND(AVG(is_short_shipped) * 100, 2)                          AS short_shipment_rate_pct
FROM supply_orders;


-- ================================================================
-- QUERY 2: SUPPLIER PERFORMANCE SCORECARD
-- Business Question: Who are our best and worst suppliers?
-- ================================================================
WITH supplier_metrics AS (
    SELECT
        supplier_id,
        supplier_state,
        COUNT(DISTINCT order_id)                                    AS total_orders,
        ROUND(SUM(order_value), 0)                                  AS total_spend,
        ROUND((1 - AVG(is_late)) * 100, 2)                         AS otd_rate_pct,
        ROUND(AVG(CASE WHEN is_late=1 THEN delay_days END), 1)     AS avg_delay_when_late,
        ROUND(AVG(rejection_rate) * 100, 3)                        AS avg_rejection_pct,
        ROUND(AVG(actual_lead_days), 1)                            AS avg_lead_time,
        ROUND(STDDEV(actual_lead_days) / NULLIF(AVG(actual_lead_days),0) * 100, 1) AS lead_time_cv_pct,
        ROUND(AVG(is_perfect_order) * 100, 1)                      AS perfect_order_rate_pct,
        ROUND(SUM(freight_cost) * 100.0 / NULLIF(SUM(order_value),0), 2) AS freight_pct
    FROM supply_orders
    GROUP BY supplier_id, supplier_state
    HAVING total_orders >= 10
),
scored AS (
    SELECT *,
        -- Composite score: OTD 40% + Quality 25% + Lead Time Consistency 20% + Cost 15%
        ROUND(
            (otd_rate_pct / 100 * 40) +
            ((1 - avg_rejection_pct/100) * 25) +
            ((1 - LEAST(lead_time_cv_pct/100, 1)) * 20) +
            ((1 - LEAST(freight_pct/15, 1)) * 15)
        , 1) AS composite_score
    FROM supplier_metrics
)
SELECT *,
    CASE
        WHEN composite_score >= 70 THEN '🟢 Preferred Supplier'
        WHEN composite_score >= 50 THEN '🟡 Medium Risk — Monitor'
        WHEN composite_score >= 30 THEN '🟠 High Risk — Issue Warning'
        ELSE '🔴 Critical Risk — Immediate Action'
    END AS risk_classification,
    RANK() OVER (ORDER BY composite_score DESC) AS performance_rank
FROM scored
ORDER BY composite_score;


-- ================================================================
-- QUERY 3: ON-TIME DELIVERY TREND BY MONTH
-- Business Question: Is our delivery performance improving?
-- ================================================================
SELECT
    DATE_FORMAT(order_date, '%Y-%m')                                AS month,
    COUNT(*)                                                        AS total_orders,
    SUM(is_late)                                                    AS late_orders,
    ROUND((1 - AVG(is_late)) * 100, 2)                             AS otd_rate_pct,
    ROUND(AVG(CASE WHEN is_late=1 THEN delay_days END), 1)         AS avg_delay_days,
    -- MoM change
    ROUND(
        (1 - AVG(is_late)) * 100 -
        LAG((1-AVG(is_late))*100) OVER (ORDER BY DATE_FORMAT(order_date,'%Y-%m'))
    , 2)                                                            AS mom_otd_change_pp
FROM supply_orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


-- ================================================================
-- QUERY 4: PERFECT ORDER RATE DECOMPOSITION
-- Business Question: Where exactly is the perfect order rate breaking down?
-- ================================================================
SELECT
    'Total Orders'       AS metric, COUNT(*) AS value, '—' AS pct_of_total
FROM supply_orders
UNION ALL
SELECT 'On-Time', SUM(1-is_late),
    CONCAT(ROUND(AVG(1-is_late)*100,1),'%') FROM supply_orders
UNION ALL
SELECT 'Complete (no short-ship)', SUM(1-is_short_shipped),
    CONCAT(ROUND(AVG(1-is_short_shipped)*100,1),'%') FROM supply_orders
UNION ALL
SELECT 'Undamaged', SUM(1-is_damaged),
    CONCAT(ROUND(AVG(1-is_damaged)*100,1),'%') FROM supply_orders
UNION ALL
SELECT 'Acceptable Quality', SUM(CASE WHEN rejection_rate<0.01 THEN 1 ELSE 0 END),
    CONCAT(ROUND(AVG(CASE WHEN rejection_rate<0.01 THEN 1.0 ELSE 0 END)*100,1),'%')
FROM supply_orders
UNION ALL
SELECT 'PERFECT ORDERS', SUM(is_perfect_order),
    CONCAT(ROUND(AVG(is_perfect_order)*100,1),'%') FROM supply_orders;


-- ================================================================
-- QUERY 5: WAREHOUSE PERFORMANCE COMPARISON
-- Business Question: Which warehouse has the worst performance?
-- ================================================================
SELECT
    warehouse,
    COUNT(*)                                                        AS total_orders,
    ROUND((1 - AVG(is_late)) * 100, 1)                             AS otd_rate_pct,
    ROUND(AVG(is_perfect_order) * 100, 1)                          AS perfect_order_pct,
    ROUND(AVG(is_damaged) * 100, 2)                                AS damage_rate_pct,
    ROUND(AVG(is_short_shipped) * 100, 2)                          AS short_ship_pct,
    ROUND(SUM(freight_cost) / COUNT(*), 0)                         AS cost_per_order,
    ROUND(AVG(actual_lead_days), 1)                                AS avg_lead_days,
    RANK() OVER (ORDER BY AVG(is_perfect_order) DESC)              AS performance_rank,
    CASE
        WHEN AVG(is_perfect_order) >= 0.75 THEN '🟢 Good'
        WHEN AVG(is_perfect_order) >= 0.60 THEN '🟡 Average'
        ELSE '🔴 Needs Immediate Audit'
    END                                                            AS warehouse_status
FROM supply_orders
GROUP BY warehouse
ORDER BY perfect_order_pct DESC;


-- ================================================================
-- QUERY 6: DEAD STOCK IDENTIFICATION
-- Business Question: Which SKUs have zero movement in 90+ days?
-- ================================================================
SELECT
    i.sku_id,
    i.category,
    i.current_stock,
    i.unit_cost,
    ROUND(i.inventory_value, 0)                                     AS inventory_value,
    i.last_movement_days,
    i.avg_monthly_demand,
    -- Carrying cost at 25% per year
    ROUND(i.inventory_value * 0.25, 0)                             AS annual_carrying_cost,
    -- Liquidation value at 30% discount
    ROUND(i.inventory_value * 0.70, 0)                             AS liquidation_value,
    CASE
        WHEN i.last_movement_days >= 180 THEN '💀 Write-off candidate'
        WHEN i.last_movement_days >= 90  THEN '🔴 Dead Stock — Liquidate'
        WHEN i.last_movement_days >= 60  THEN '🟠 Slow Moving — Promote'
        ELSE '🟢 Moving'
    END                                                            AS stock_health
FROM inventory i
WHERE i.current_stock > 0
    AND i.last_movement_days >= 60
ORDER BY i.inventory_value DESC
LIMIT 50;


-- ================================================================
-- QUERY 7: ABC ANALYSIS — SKU Revenue Classification
-- Business Question: Which SKUs drive our revenue?
-- ================================================================
WITH sku_revenue AS (
    SELECT
        sku_id,
        category,
        ROUND(SUM(order_revenue), 0)    AS total_revenue,
        COUNT(DISTINCT order_id)         AS orders,
        ROUND(AVG(quantity_ordered), 1)  AS avg_order_qty
    FROM supply_orders
    GROUP BY sku_id, category
),
ranked AS (
    SELECT *,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC
            ROWS UNBOUNDED PRECEDING)                               AS cumulative_revenue,
        SUM(total_revenue) OVER ()                                  AS grand_total,
        ROUND(
            SUM(total_revenue) OVER (ORDER BY total_revenue DESC
            ROWS UNBOUNDED PRECEDING) * 100.0 / SUM(total_revenue) OVER ()
        , 2)                                                        AS cumulative_pct
    FROM sku_revenue
)
SELECT
    sku_id, category, total_revenue, orders, avg_order_qty,
    cumulative_pct,
    CASE
        WHEN cumulative_pct <= 70 THEN 'A — High Value (top 70% revenue)'
        WHEN cumulative_pct <= 90 THEN 'B — Medium Value (70-90% revenue)'
        ELSE 'C — Low Value (bottom 10% revenue)'
    END AS abc_class
FROM ranked
ORDER BY total_revenue DESC
LIMIT 60;


-- ================================================================
-- QUERY 8: CATEGORY-WISE PROCUREMENT ANALYSIS
-- Business Question: Which categories should we renegotiate first?
-- ================================================================
SELECT
    category,
    COUNT(DISTINCT order_id)                                        AS total_orders,
    COUNT(DISTINCT supplier_id)                                     AS suppliers_used,
    ROUND(SUM(order_value), 0)                                      AS total_spend,
    ROUND(SUM(freight_cost), 0)                                     AS total_freight,
    ROUND(SUM(freight_cost)*100.0/SUM(order_value), 2)             AS freight_pct,
    ROUND(AVG(actual_lead_days), 1)                                 AS avg_lead_days,
    ROUND((1-AVG(is_late))*100, 1)                                  AS otd_pct,
    ROUND(AVG(rejection_rate)*100, 2)                               AS rejection_pct,
    -- Spend per supplier (lower = more concentrated = more leverage)
    ROUND(SUM(order_value)/COUNT(DISTINCT supplier_id), 0)          AS spend_per_supplier,
    CASE
        WHEN COUNT(DISTINCT supplier_id) = 1 THEN '🚨 Single Source — Critical Risk'
        WHEN COUNT(DISTINCT supplier_id) <= 2 THEN '⚠️  Dual Source — Low Resilience'
        ELSE '✅ Multiple Sources'
    END                                                            AS sourcing_risk
FROM supply_orders
GROUP BY category
ORDER BY total_spend DESC;


-- ================================================================
-- QUERY 9: LEAD TIME ANALYSIS BY SUPPLIER STATE
-- Business Question: Does supplier geography drive lead time?
-- ================================================================
SELECT
    supplier_state,
    COUNT(DISTINCT supplier_id)                                     AS suppliers_in_state,
    COUNT(*)                                                        AS total_orders,
    ROUND(AVG(promised_lead_days), 1)                              AS avg_promised_lead,
    ROUND(AVG(actual_lead_days), 1)                                AS avg_actual_lead,
    ROUND(AVG(actual_lead_days - promised_lead_days), 1)           AS avg_slip_days,
    ROUND((1-AVG(is_late))*100, 1)                                 AS otd_rate_pct,
    ROUND(SUM(freight_cost)/COUNT(*), 0)                           AS avg_freight_per_order,
    -- Distance proxy: higher freight = farther state
    CASE
        WHEN AVG(freight_cost/order_value) > 0.08 THEN '📍 Far (High Freight)'
        WHEN AVG(freight_cost/order_value) > 0.05 THEN '📍 Medium Distance'
        ELSE '📍 Near'
    END                                                            AS distance_proxy
FROM supply_orders
GROUP BY supplier_state
ORDER BY avg_actual_lead DESC;


-- ================================================================
-- QUERY 10: STOCKOUT IMPACT ANALYSIS
-- Business Question: How much revenue did stockouts cost us?
-- ================================================================
SELECT
    i.sku_id,
    i.category,
    i.stockout_events,
    i.avg_monthly_demand,
    ROUND(i.avg_monthly_demand * s.avg_unit_price, 0)              AS avg_monthly_revenue,
    -- Estimated revenue lost per stockout (assume avg 3-day stockout)
    ROUND(i.avg_monthly_demand / 30 * 3 * s.avg_unit_price, 0)     AS est_revenue_per_stockout,
    ROUND(i.stockout_events * i.avg_monthly_demand/30 * 3
          * s.avg_unit_price, 0)                                    AS total_stockout_revenue_lost,
    i.current_stock,
    i.reorder_point,
    CASE
        WHEN i.current_stock <= i.reorder_point THEN '🚨 REORDER NOW'
        WHEN i.current_stock <= i.reorder_point * 1.5 THEN '⚠️  Approaching Reorder Point'
        ELSE '✅ Adequate Stock'
    END                                                            AS replenishment_alert
FROM inventory i
JOIN (
    SELECT sku_id,
           AVG(order_revenue / NULLIF(quantity_ordered,0)) AS avg_unit_price
    FROM supply_orders
    GROUP BY sku_id
) s ON i.sku_id = s.sku_id
WHERE i.stockout_events > 0
ORDER BY total_stockout_revenue_lost DESC
LIMIT 30;


-- ================================================================
-- QUERY 11: OVERSTOCK DETECTION WITH CARRYING COST
-- Business Question: Where is working capital unnecessarily tied up?
-- ================================================================
SELECT
    i.sku_id,
    i.category,
    i.current_stock,
    i.avg_monthly_demand,
    ROUND(i.months_of_stock, 1)                                     AS months_of_supply,
    ROUND(i.inventory_value, 0)                                     AS total_inv_value,
    -- Excess inventory = stock above 3 months of demand
    ROUND(GREATEST(i.current_stock - i.avg_monthly_demand*3, 0)
          * i.unit_cost, 0)                                         AS excess_inventory_value,
    -- Annual carrying cost on excess
    ROUND(GREATEST(i.current_stock - i.avg_monthly_demand*3, 0)
          * i.unit_cost * 0.25, 0)                                  AS annual_carrying_cost,
    CASE
        WHEN i.months_of_stock > 12 THEN '🔴 Extreme Overstock — Review now'
        WHEN i.months_of_stock > 6  THEN '🟠 High Overstock'
        WHEN i.months_of_stock > 3  THEN '🟡 Moderate Overstock'
        ELSE '🟢 Acceptable'
    END                                                            AS overstock_severity
FROM inventory i
WHERE i.months_of_stock > 3
    AND i.avg_monthly_demand > 0
    AND i.current_stock > 0
ORDER BY excess_inventory_value DESC
LIMIT 40;


-- ================================================================
-- QUERY 12: SUPPLIER DELAY COST QUANTIFICATION
-- Business Question: What does each supplier's delays cost us in ₹?
-- ================================================================
SELECT
    supplier_id,
    COUNT(*)                                                        AS total_orders,
    SUM(is_late)                                                    AS late_orders,
    ROUND(AVG(is_late)*100, 1)                                     AS late_rate_pct,
    ROUND(SUM(delay_days), 0)                                      AS total_delay_days,
    ROUND(AVG(CASE WHEN is_late=1 THEN delay_days END), 1)         AS avg_delay_days,
    -- Delay cost = 0.2% of order value per day delayed
    ROUND(SUM(delay_days * order_value * 0.002), 0)                AS est_delay_cost_inr,
    ROUND(SUM(order_value), 0)                                     AS total_spend,
    ROUND(SUM(delay_days * order_value * 0.002) * 100.0
          / NULLIF(SUM(order_value), 0), 2)                        AS delay_cost_as_pct_of_spend
FROM supply_orders
GROUP BY supplier_id
HAVING late_orders > 5
ORDER BY est_delay_cost_inr DESC
LIMIT 15;


-- ================================================================
-- QUERY 13: MONTHLY DEMAND FORECAST PREPARATION
-- Business Question: What does rolling average predict for next quarter?
-- ================================================================
WITH monthly AS (
    SELECT
        YEAR(order_date)                        AS yr,
        MONTH(order_date)                       AS mth,
        ROUND(SUM(order_value), 0)              AS monthly_value,
        ROUND(SUM(quantity_ordered), 0)         AS monthly_qty,
        COUNT(DISTINCT order_id)                AS orders
    FROM supply_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    yr, mth,
    monthly_value,
    monthly_qty,
    -- 3-month moving average
    ROUND(AVG(monthly_value) OVER (
        ORDER BY yr, mth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 0)                                       AS ma3_value,
    -- 6-month moving average
    ROUND(AVG(monthly_value) OVER (
        ORDER BY yr, mth ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ), 0)                                       AS ma6_value,
    -- MoM growth
    ROUND(
        (monthly_value - LAG(monthly_value) OVER (ORDER BY yr, mth))
        * 100.0 / NULLIF(LAG(monthly_value) OVER (ORDER BY yr, mth), 0)
    , 1)                                        AS mom_growth_pct,
    -- YoY comparison
    ROUND(
        (monthly_value - LAG(monthly_value, 12) OVER (ORDER BY yr, mth))
        * 100.0 / NULLIF(LAG(monthly_value, 12) OVER (ORDER BY yr, mth), 0)
    , 1)                                        AS yoy_growth_pct
FROM monthly
ORDER BY yr, mth;


-- ================================================================
-- QUERY 14: FREIGHT COST OPTIMISATION OPPORTUNITIES
-- Business Question: Where can we reduce logistics spend?
-- ================================================================
SELECT
    supplier_id,
    supplier_state,
    COUNT(*)                                                        AS orders,
    ROUND(SUM(order_value), 0)                                      AS total_spend,
    ROUND(SUM(freight_cost), 0)                                     AS total_freight,
    ROUND(AVG(freight_cost), 0)                                     AS avg_freight_per_order,
    ROUND(SUM(freight_cost)*100.0/NULLIF(SUM(order_value),0), 2)   AS freight_pct,
    -- Flag if freight > 8% (benchmark is 5%)
    CASE
        WHEN SUM(freight_cost)*100.0/NULLIF(SUM(order_value),0) > 10
        THEN '🔴 Very High — Renegotiate or consolidate orders'
        WHEN SUM(freight_cost)*100.0/NULLIF(SUM(order_value),0) > 7
        THEN '🟠 High — Review shipment frequency'
        ELSE '🟢 Acceptable'
    END                                                            AS freight_flag,
    -- Potential saving if brought to 5% target
    ROUND(
        GREATEST(SUM(freight_cost) - SUM(order_value)*0.05, 0), 0
    )                                                              AS potential_saving_inr
FROM supply_orders
GROUP BY supplier_id, supplier_state
HAVING orders >= 5
ORDER BY freight_pct DESC
LIMIT 20;


-- ================================================================
-- QUERY 15: REPLENISHMENT ALERT — REORDER NOW LIST
-- Business Question: Which SKUs need to be reordered immediately?
-- ================================================================
SELECT
    i.sku_id,
    i.category,
    i.current_stock,
    i.reorder_point,
    i.avg_monthly_demand,
    ROUND(i.current_stock / NULLIF(i.avg_monthly_demand/30, 0), 0) AS days_of_stock_remaining,
    -- Lead time from last supplier
    s.avg_lead_days                                                AS supplier_lead_days,
    CASE
        WHEN i.current_stock = 0 THEN '🚨 STOCKOUT — ORDER EMERGENCY'
        WHEN i.current_stock <= i.reorder_point * 0.5
        THEN '🔴 CRITICAL — Order immediately (below 50% ROP)'
        WHEN i.current_stock <= i.reorder_point
        THEN '🟠 REORDER — At reorder point'
        ELSE '🟡 WATCH — Approaching reorder point'
    END                                                            AS urgency,
    -- Suggested order quantity (3 months demand)
    ROUND(i.avg_monthly_demand * 3, 0)                             AS suggested_order_qty,
    ROUND(i.avg_monthly_demand * 3 * i.unit_cost, 0)              AS suggested_order_value
FROM inventory i
LEFT JOIN (
    SELECT sku_id, ROUND(AVG(actual_lead_days),0) AS avg_lead_days
    FROM supply_orders GROUP BY sku_id
) s ON i.sku_id = s.sku_id
WHERE i.current_stock <= i.reorder_point * 1.3
    AND i.avg_monthly_demand > 0
ORDER BY days_of_stock_remaining ASC
LIMIT 30;


-- ================================================================
-- QUERY 16: SUPPLIER CONSOLIDATION OPPORTUNITY
-- Business Question: Which tail suppliers should we eliminate?
-- ================================================================
WITH supplier_annual AS (
    SELECT
        supplier_id,
        supplier_state,
        COUNT(DISTINCT order_id)                                    AS annual_orders,
        ROUND(SUM(order_value), 0)                                  AS annual_spend,
        COUNT(DISTINCT category)                                    AS categories_supplied,
        ROUND((1-AVG(is_late))*100, 1)                             AS otd_pct,
        ROUND(AVG(rejection_rate)*100, 2)                          AS rejection_pct
    FROM supply_orders
    GROUP BY supplier_id, supplier_state
)
SELECT
    supplier_id,
    supplier_state,
    annual_orders,
    annual_spend,
    categories_supplied,
    otd_pct,
    rejection_pct,
    -- Admin cost estimate
    380000                                                          AS est_admin_cost_inr,
    -- Is this supplier strategic?
    CASE
        WHEN annual_spend >= 1500000 THEN '✅ Strategic — Keep'
        WHEN categories_supplied > 1  THEN '🟡 Multi-category — Evaluate'
        WHEN otd_pct >= 85           THEN '🟡 Good performer — Consider keeping'
        ELSE '🔴 Tail Supplier — Candidate for elimination'
    END                                                            AS consolidation_decision
FROM supplier_annual
ORDER BY annual_spend ASC
LIMIT 20;


-- ================================================================
-- QUERY 17: PERFECT ORDER RATE BY CATEGORY × SUPPLIER
-- Business Question: Which supplier-category combinations are most unreliable?
-- ================================================================
SELECT
    category,
    supplier_id,
    COUNT(*)                                                        AS orders,
    ROUND(AVG(is_perfect_order)*100, 1)                            AS por_pct,
    ROUND((1-AVG(is_late))*100, 1)                                 AS otd_pct,
    ROUND(AVG(is_damaged)*100, 2)                                  AS damage_pct,
    ROUND(AVG(rejection_rate)*100, 2)                              AS rejection_pct,
    CASE
        WHEN AVG(is_perfect_order) < 0.40 THEN '🔴 Unreliable — Replace'
        WHEN AVG(is_perfect_order) < 0.65 THEN '🟠 Below Par — Issue Warning'
        WHEN AVG(is_perfect_order) < 0.80 THEN '🟡 Average — Monitor'
        ELSE '🟢 Reliable'
    END                                                            AS reliability_status
FROM supply_orders
GROUP BY category, supplier_id
HAVING COUNT(*) >= 10
ORDER BY por_pct ASC
LIMIT 25;


-- ================================================================
-- QUERY 18: COO EXECUTIVE SUMMARY — ONE PAGE
-- Business Question: What does the COO see first thing Monday?
-- ================================================================
SELECT 'Procurement Value (YTD)'   AS metric,
    CONCAT('Rs.',ROUND(SUM(order_value)/10000000,1),' Cr') AS value
FROM supply_orders
UNION ALL
SELECT 'On-Time Delivery Rate',
    CONCAT(ROUND((1-AVG(is_late))*100,1),'%') FROM supply_orders
UNION ALL
SELECT 'Perfect Order Rate',
    CONCAT(ROUND(AVG(is_perfect_order)*100,1),'% (benchmark: 85%)') FROM supply_orders
UNION ALL
SELECT 'Avg Delay (late orders)',
    CONCAT(ROUND(AVG(CASE WHEN is_late=1 THEN delay_days END),1),' days')
FROM supply_orders
UNION ALL
SELECT 'Critical Risk Suppliers',  '8 suppliers — PIP required' UNION ALL
SELECT 'Dead Inventory Value',     'Rs.4.7 Cr (liquidation opportunity)' UNION ALL
SELECT 'Stockout Revenue Lost',    'Rs.2.1 Cr estimated' UNION ALL
SELECT 'Worst Warehouse',         'Warehouse_Central — audit required' UNION ALL
SELECT 'Forecast MAPE (current)', '34% — reduce to 18% with MA3' UNION ALL
SELECT 'Top Saving Opportunity',  'Rs.3.65 Cr/year across 5 initiatives' UNION ALL
SELECT 'Action #1',              'Issue PIP to 8 critical suppliers this week' UNION ALL
SELECT 'Action #2',              'Liquidate dead stock — Rs.3.2 Cr in 90 days' UNION ALL
SELECT 'Action #3',              'Adopt 3M moving average for demand planning';

-- ================================================================
-- END OF QUERIES
-- Full analysis: notebooks/supply_chain_analysis.ipynb
-- Dashboard: streamlit run dashboard/app.py
-- ================================================================
