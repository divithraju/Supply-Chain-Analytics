"""
Supply Chain & Operations Analytics Dashboard
Author: Divith Raju
Run: streamlit run app.py
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
from scipy.stats import variation

st.set_page_config(page_title="Supply Chain Dashboard", page_icon="🚚", layout="wide")

st.markdown("""
<style>
    .critical { background:#fadbd8; border-left:4px solid #e74c3c;
                padding:.75rem 1rem; border-radius:4px; margin:.4rem 0; }
    .warning  { background:#fef9e7; border-left:4px solid #f39c12;
                padding:.75rem 1rem; border-radius:4px; margin:.4rem 0; }
    .good     { background:#d5f5e3; border-left:4px solid #2ecc71;
                padding:.75rem 1rem; border-radius:4px; margin:.4rem 0; }
    .info     { background:#eaf4fb; border-left:4px solid #3498db;
                padding:.75rem 1rem; border-radius:4px; font-size:.9rem; margin:.4rem 0; }
</style>
""", unsafe_allow_html=True)


# ── Data ───────────────────────────────────────────────────────────────
@st.cache_data
def generate_data():
    np.random.seed(42)
    N = 8500
    WAREHOUSES = ['Warehouse_North','Warehouse_South','Warehouse_East','Warehouse_Central']
    CATEGORIES = ['Electronics','Apparel','FMCG','Home & Garden','Industrial','Pharma']
    STATES     = ['Maharashtra','Karnataka','Tamil Nadu','Delhi','Rajasthan',
                  'Gujarat','West Bengal','UP','Telangana','Punjab']
    sup_ids    = [f'SUP_{str(i).zfill(2)}' for i in range(1,39)]
    bad_sups   = ['SUP_07','SUP_14','SUP_19','SUP_22','SUP_28','SUP_31','SUP_33','SUP_36']

    sup_late   = {s: (0.55 if s in bad_sups else np.random.uniform(0.05,0.28)) for s in sup_ids}
    sup_lead   = {s: (np.random.randint(18,35) if s in bad_sups else np.random.randint(5,18)) for s in sup_ids}
    sup_state  = {s: np.random.choice(STATES) for s in sup_ids}
    sup_spend  = {s: np.random.randint(500000,15000000) for s in sup_ids}

    dates   = pd.date_range('2022-01-01','2024-12-31',periods=N)
    prob    = np.array([sup_spend[s] for s in sup_ids])
    prob    = prob / prob.sum()
    sups    = np.random.choice(sup_ids, N, p=prob)
    cats    = np.random.choice(CATEGORIES, N, p=[0.18,0.22,0.25,0.14,0.12,0.09])
    whs     = np.random.choice(WAREHOUSES, N, p=[0.35,0.25,0.25,0.15])

    prom_lead = np.array([sup_lead[s] for s in sups])
    act_lead  = np.array([max(1, int(np.random.normal(
        sup_lead[s]*(1.4 if s in bad_sups else 1.0),
        sup_lead[s]*0.3))) for s in sups])
    delay     = np.maximum(0, act_lead - prom_lead)
    is_late   = (delay > 0).astype(int)

    qty       = np.random.randint(10, 500, N)
    unit_cost = np.random.choice([150,350,750,1500,3500,8500], N)
    ov        = (qty * unit_cost).astype(int)
    fc        = (ov * np.random.uniform(0.02,0.12,N)).astype(int)

    rej       = np.where(np.isin(sups, bad_sups),
                         np.random.uniform(0.05,0.18,N),
                         np.random.uniform(0.00,0.04,N))
    dmg       = np.random.binomial(1, 0.047, N)
    short     = np.random.binomial(1, 0.084, N)
    perfect   = ((is_late==0)&(dmg==0)&(short==0)&(rej<0.01)).astype(int)

    df = pd.DataFrame({
        'order_date':       pd.to_datetime(dates),
        'supplier_id':      sups,
        'supplier_state':   [sup_state[s] for s in sups],
        'category':         cats,
        'warehouse':        whs,
        'order_value':      ov,
        'freight_cost':     fc,
        'actual_lead_days': act_lead,
        'promised_lead_days': prom_lead,
        'delay_days':       delay,
        'is_late':          is_late,
        'rejection_rate':   rej.round(4),
        'is_damaged':       dmg,
        'is_short_shipped': short,
        'is_perfect_order': perfect
    })
    df['year']    = df['order_date'].dt.year
    df['month']   = df['order_date'].dt.month
    df['quarter'] = df['order_date'].dt.quarter
    df['month_str'] = df['order_date'].dt.to_period('M').astype(str)
    return df

df = generate_data()


# ── Sidebar ────────────────────────────────────────────────────────────
st.sidebar.title("🚚 Operations Filters")
yr_sel  = st.sidebar.multiselect("Year", sorted(df['year'].unique(), reverse=True),
                                  default=list(df['year'].unique()))
cat_sel = st.sidebar.multiselect("Category", df['category'].unique(),
                                  default=list(df['category'].unique()))
wh_sel  = st.sidebar.multiselect("Warehouse", df['warehouse'].unique(),
                                  default=list(df['warehouse'].unique()))

mask = df['year'].isin(yr_sel) & df['category'].isin(cat_sel) & df['warehouse'].isin(wh_sel)
df_f = df[mask]

st.sidebar.markdown(f"**Orders in view:** {len(df_f):,}")


# ── Header ─────────────────────────────────────────────────────────────
st.title("🚚 Supply Chain & Operations Analytics")
st.markdown("*End-to-end visibility: Supplier performance | Inventory health | Fulfillment quality | Demand forecast*")
st.markdown("---")

# ── KPI Row ────────────────────────────────────────────────────────────
k1,k2,k3,k4,k5,k6 = st.columns(6)
otd   = (1 - df_f['is_late'].mean()) * 100
por   = df_f['is_perfect_order'].mean() * 100
tot_v = df_f['order_value'].sum()
avg_d = df_f[df_f['is_late']==1]['delay_days'].mean()
dmg   = df_f['is_damaged'].mean() * 100
frt_p = df_f['freight_cost'].sum() / df_f['order_value'].sum() * 100

k1.metric("On-Time Delivery", f"{otd:.1f}%",  delta=f"{otd-90:.1f}pp vs 90% target", delta_color="normal")
k2.metric("Perfect Order Rate", f"{por:.1f}%", delta=f"{por-85:.1f}pp vs 85% bench",  delta_color="normal")
k3.metric("Procurement Value", f"₹{tot_v/10000000:.1f}Cr")
k4.metric("Avg Delay (late)", f"{avg_d:.1f} days")
k5.metric("Damage Rate",       f"{dmg:.2f}%")
k6.metric("Freight % of Value",f"{frt_p:.1f}%")

if por < 70:
    st.markdown(f'<div class="critical">🚨 Perfect Order Rate at {por:.1f}% — far below 85% industry benchmark. Estimated ₹{len(df_f)*(1-por/100)*1800/100000:.0f}L wasted annually in exception handling.</div>', unsafe_allow_html=True)

st.markdown("---")

# ── Row 1: OTD Trend + Supplier Scatter ───────────────────────────────
c1, c2 = st.columns(2)

with c1:
    st.subheader("📅 Monthly On-Time Delivery Trend")
    m_otd = df_f.groupby('month_str').agg(
        otd=('is_late', lambda x: (1-x.mean())*100),
        orders=('order_value','count')
    ).reset_index().sort_values('month_str')

    fig1 = go.Figure()
    fig1.add_trace(go.Scatter(x=m_otd['month_str'], y=m_otd['otd'],
        mode='lines+markers', fill='tozeroy',
        fillcolor='rgba(52,152,219,0.1)',
        line=dict(color='#3498db', width=3), name='OTD %'))
    fig1.add_hline(y=90, line_dash='dash', line_color='green',
                   annotation_text='90% target')
    fig1.add_hline(y=otd, line_dash='dot', line_color='red',
                   annotation_text=f'Avg {otd:.1f}%')
    fig1.update_layout(yaxis_title='OTD Rate (%)',
                       yaxis=dict(range=[40,105]), height=330)
    st.plotly_chart(fig1, use_container_width=True)

with c2:
    st.subheader("🔴 Supplier Risk Map")
    sup_s = df_f.groupby('supplier_id').agg(
        otd=('is_late', lambda x: (1-x.mean())*100),
        rejection=('rejection_rate','mean'),
        spend=('order_value','sum'),
        orders=('order_value','count')
    ).reset_index()
    sup_s['rejection'] *= 100

    fig2 = px.scatter(sup_s, x='otd', y='rejection', size='spend',
                      color='otd', color_continuous_scale='RdYlGn',
                      hover_name='supplier_id', size_max=35,
                      labels={'otd':'OTD Rate (%)','rejection':'Rejection Rate (%)'},
                      title='Supplier: OTD vs Quality (size=spend)')
    fig2.add_vline(x=sup_s['otd'].mean(), line_dash='dash', line_color='gray')
    fig2.add_hline(y=sup_s['rejection'].mean(), line_dash='dash', line_color='gray')
    fig2.update_layout(height=330, showlegend=False)
    st.plotly_chart(fig2, use_container_width=True)

# ── Row 2: Perfect Order Funnel + Warehouse ────────────────────────────
st.markdown("---")
c3, c4 = st.columns(2)

with c3:
    st.subheader("🎯 Perfect Order Funnel")
    otd_r  = (1-df_f['is_late'].mean())*100
    comp_r = (1-df_f['is_short_shipped'].mean())*100
    undmg  = (1-df_f['is_damaged'].mean())*100
    qual_r = (1-(df_f['rejection_rate']>=0.01).mean())*100

    fig3 = go.Figure(go.Funnel(
        y=['Total Orders','On-Time','Complete','Undamaged','Quality OK','Perfect Orders'],
        x=[100, otd_r, comp_r, undmg, qual_r, por],
        textinfo='value+percent initial',
        marker=dict(color=['#3498db','#2ecc71','#f39c12','#e67e22','#e74c3c','#9b59b6'])
    ))
    fig3.update_layout(height=370)
    st.plotly_chart(fig3, use_container_width=True)
    st.markdown(f'<div class="critical">🔴 Only {por:.1f}% perfect orders vs 85% benchmark — biggest gap is <b>On-Time Delivery ({otd_r:.1f}%)</b></div>', unsafe_allow_html=True)

with c4:
    st.subheader("🏭 Warehouse Performance")
    wh_p = df_f.groupby('warehouse').agg(
        por=('is_perfect_order','mean'),
        otd=('is_late', lambda x: (1-x.mean())),
        cost_per_order=('freight_cost','mean'),
        orders=('order_value','count')
    ).reset_index()
    wh_p['por'] *= 100
    wh_p['otd'] *= 100
    wh_p = wh_p.sort_values('por', ascending=True)

    colors_wh = ['#e74c3c' if v<55 else '#f39c12' if v<70 else '#2ecc71' for v in wh_p['por']]
    fig4 = go.Figure(go.Bar(
        y=wh_p['warehouse'], x=wh_p['por'],
        orientation='h', marker_color=colors_wh,
        text=wh_p['por'].apply(lambda x: f'{x:.1f}%'), textposition='outside'
    ))
    fig4.add_vline(x=85, line_dash='dash', line_color='green', annotation_text='Target 85%')
    fig4.update_layout(xaxis_title='Perfect Order Rate (%)', height=370)
    st.plotly_chart(fig4, use_container_width=True)
    worst_wh = wh_p.iloc[0]['warehouse']
    st.markdown(f'<div class="warning">⚠️ <b>{worst_wh}</b> has lowest POR — operations audit needed. Check staffing and process adherence.</div>', unsafe_allow_html=True)

# ── Row 3: Category Analysis + Demand Trend ───────────────────────────
st.markdown("---")
c5, c6 = st.columns(2)

with c5:
    st.subheader("📦 OTD & Rejection by Category")
    cat_p = df_f.groupby('category').agg(
        otd=('is_late', lambda x: (1-x.mean())*100),
        rejection=('rejection_rate', lambda x: x.mean()*100),
        spend=('order_value','sum')
    ).reset_index().sort_values('otd')

    fig5 = go.Figure()
    fig5.add_trace(go.Bar(x=cat_p['category'], y=cat_p['otd'],
        name='OTD %', marker_color='#3498db'))
    fig5.add_trace(go.Bar(x=cat_p['category'], y=cat_p['rejection'],
        name='Rejection %', marker_color='#e74c3c'))
    fig5.update_layout(barmode='group', yaxis_title='Rate (%)', height=360)
    st.plotly_chart(fig5, use_container_width=True)

with c6:
    st.subheader("📈 Monthly Demand & 3M Forecast")
    m_dem = df_f.groupby('month_str')['order_value'].sum().reset_index()
    m_dem.columns = ['Month','Value']
    m_dem = m_dem.sort_values('Month')
    m_dem['MA3'] = m_dem['Value'].rolling(3, min_periods=1).mean()

    fig6 = go.Figure()
    fig6.add_trace(go.Bar(x=m_dem['Month'], y=m_dem['Value'],
        name='Actual', marker_color='#3498db', opacity=0.7))
    fig6.add_trace(go.Scatter(x=m_dem['Month'], y=m_dem['MA3'],
        mode='lines', name='3M Moving Avg',
        line=dict(color='#e74c3c', width=2.5)))

    # Simple forecast
    last3  = m_dem['MA3'].tail(3).mean()
    growth = (m_dem['Value'].tail(6).mean() / m_dem['Value'].head(6).mean()) ** (1/6)
    fcst   = [last3 * growth**i for i in range(1,4)]
    fig6.add_trace(go.Scatter(
        x=['Forecast+1','Forecast+2','Forecast+3'], y=fcst,
        mode='markers+lines', name='Forecast',
        line=dict(color='#2ecc71', dash='dot', width=3),
        marker=dict(size=10, symbol='diamond')))
    fig6.update_layout(height=360, hovermode='x unified')
    st.plotly_chart(fig6, use_container_width=True)
    st.markdown(f'<div class="info">📊 3M forecast projects ₹{sum(fcst)/10000000:.2f}Cr next quarter — pre-order buffer recommended</div>', unsafe_allow_html=True)

# ── Bottom: At-Risk Supplier Table ─────────────────────────────────────
st.markdown("---")
st.subheader("🚨 Supplier Risk Watchlist — Action Required")

sup_risk = df_f.groupby('supplier_id').agg(
    orders=('order_value','count'),
    spend=('order_value','sum'),
    otd=('is_late', lambda x: round((1-x.mean())*100,1)),
    avg_delay=('delay_days', lambda x: round(x[df_f.loc[x.index,'is_late']==1].mean(),1)),
    rejection=('rejection_rate', lambda x: round(x.mean()*100,2)),
    por=('is_perfect_order', lambda x: round(x.mean()*100,1))
).reset_index()

sup_risk['score'] = (
    sup_risk['otd']/100 * 40 +
    (1 - sup_risk['rejection']/100) * 25 +
    sup_risk['por']/100 * 35
).round(1)

sup_risk['Risk'] = sup_risk['score'].apply(
    lambda s: '🔴 Critical' if s<40 else ('🟠 High' if s<55 else ('🟡 Medium' if s<70 else '🟢 OK'))
)
sup_risk = sup_risk[sup_risk['score'] < 70].sort_values('score')

tier_filter = st.selectbox("Filter by Risk", ['All','🔴 Critical','🟠 High','🟡 Medium'])
disp = sup_risk if tier_filter=='All' else sup_risk[sup_risk['Risk']==tier_filter]

st.dataframe(disp.rename(columns={
    'supplier_id':'Supplier','orders':'Orders',
    'spend':'Spend (₹)','otd':'OTD %','avg_delay':'Avg Delay(d)',
    'rejection':'Rejection %','por':'POR %','score':'Score','Risk':'Risk Tier'
}), hide_index=True, use_container_width=True)

st.markdown(f"Showing **{len(disp)}** at-risk suppliers | Critical: {(sup_risk['Risk']=='🔴 Critical').sum()} | High: {(sup_risk['Risk']=='🟠 High').sum()}")

# ── Footer ─────────────────────────────────────────────────────────────
st.markdown("---")
st.markdown("**🚚 Divith Raju** | [GitHub](https://github.com/divithraju) · [LinkedIn](https://linkedin.com/in/divithraju) | Tools: Python · Pandas · Plotly · Streamlit · MySQL")
