# Examples

Each subfolder demonstrates one of the five data-science skills by pairing a
sample dataset (or input) with the notebook that the skill would generate.

| Folder | Skill | Dataset / Input | What it shows |
|--------|-------|-----------------|---------------|
| `auto-eda/` | `/data-science:auto-eda` | EV Charging Station Sessions (2 003 rows) | Full narrative EDA with distributions, correlations, anomalies |
| `dataset-doctor/` | `/data-science:dataset-doctor` | Food Delivery Customer Churn (train + test) | Health score, leakage detection, drift analysis, quality issues |
| `experiment-tracker/` | `/data-science:experiment-tracker` | Used Car Price Prediction (8 runs) | Leaderboard, model comparison, training efficiency |
| `paper-to-code/` | `/data-science:paper-to-code` | "Isolation Forest" (Liu et al., 2008) | Paper overview, from-scratch implementation, toy demo |
| `sql-optimizer/` | `/data-science:sql-optimizer` | E-commerce analytics queries (PostgreSQL) | Issue identification, optimized rewrites, execution flow |

## How to try a skill yourself

```bash
# Install the plugin
claude plugin add /path/to/data-science-skills

# Then run any skill — for example:
/data-science:auto-eda examples/auto-eda/data/ev_charging_sessions.csv
/data-science:dataset-doctor examples/dataset-doctor/data/food_delivery_churn_train.csv examples/dataset-doctor/data/food_delivery_churn_test.csv --target churned
/data-science:experiment-tracker leaderboard
/data-science:paper-to-code "Isolation Forest, Liu et al. 2008"
/data-science:sql-optimizer examples/sql-optimizer/queries/ecommerce_analytics.sql --dialect postgresql
```

## Running the example notebooks

Each notebook is self-contained. Open it in Jupyter and run all cells:

```bash
pip install pandas matplotlib seaborn scipy numpy
jupyter notebook examples/auto-eda/notebooks/eda_ev_charging_sessions_2025-03-10.ipynb
```

> **Note**: The `paper-to-code` notebook only requires `numpy` and `matplotlib`.
