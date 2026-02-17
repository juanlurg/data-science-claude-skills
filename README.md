# data-science-skills

Notebook-first data science skills for Claude Code. Point at a dataset, a paper, or a SQL query and get a polished `.ipynb` you can open, run, and iterate on — no boilerplate, no glue code. Works with your existing stack.

- **auto-eda** — narrative exploratory analysis with distributions, correlations, anomalies, and feature engineering ideas
- **dataset-doctor** — data quality diagnosis with a health score, leakage detection, and drift checks
- **experiment-tracker** — local ML experiment logging with leaderboards and side-by-side comparisons
- **paper-to-code** — research paper to runnable implementation notebook with equations and toy examples
- **sql-optimizer** — query optimization report with rewritten queries and dialect-specific tips

### How it works

These are [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code) invoked via slash commands (e.g. `/data-science:auto-eda`). Each skill detects your environment — package manager (uv / pip / conda / pipenv), dataframe library (pandas / polars), and SQL dialect (BigQuery / PostgreSQL) — and adapts its output accordingly.

## See it in action

| Skill | Example notebook | What it shows |
|-------|-----------------|---------------|
| auto-eda | [`eda_ev_charging_sessions_2025-03-10.ipynb`](examples/auto-eda/notebooks/eda_ev_charging_sessions_2025-03-10.ipynb) | Narrative EDA on 2k EV charging sessions |
| dataset-doctor | [`data_health_food_delivery_churn_2025-03-12.ipynb`](examples/dataset-doctor/notebooks/data_health_food_delivery_churn_2025-03-12.ipynb) | Health score 6/10, leakage & drift detection |
| experiment-tracker | [`leaderboard_used_cars_2025-03-13.ipynb`](examples/experiment-tracker/notebooks/leaderboard_used_cars_2025-03-13.ipynb) | Leaderboard comparing 8 ML runs |
| paper-to-code | [`paper_isolation_forest_2025-03-15.ipynb`](examples/paper-to-code/notebooks/paper_isolation_forest_2025-03-15.ipynb) | Isolation Forest from-scratch implementation |
| sql-optimizer | [`sql_optimization_2025-03-14.ipynb`](examples/sql-optimizer/notebooks/sql_optimization_2025-03-14.ipynb) | Query optimization report with rewrites |

## Installation

```bash
claude plugin add /path/to/data-science-skills
```

Or run Claude Code with the plugin directory:

```bash
claude --plugin-dir /path/to/data-science-skills
```

## Skills

### auto-eda

Generate a narrative exploratory data analysis notebook from a dataset.

```
/data-science:auto-eda data.csv
```

Produces a notebook with executive summary, distributions, correlations, anomaly detection, and feature engineering suggestions — all informed by the actual data, not generic boilerplate.

### experiment-tracker

Log, compare, and visualize ML experiments locally using JSON storage.

```
/data-science:experiment-tracker log
/data-science:experiment-tracker leaderboard
/data-science:experiment-tracker compare 1 3 5
```

### dataset-doctor

Diagnose data quality issues and generate a health report with a score out of 10.

```
/data-science:dataset-doctor train.csv test.csv --target label
```

Checks for missing data, class imbalance, multicollinearity, data leakage, and drift.

### paper-to-code

Convert a research paper into an implementation notebook with equations, code, and a toy example.

```
/data-science:paper-to-code https://arxiv.org/abs/1706.03762
/data-science:paper-to-code paper.pdf
```

### sql-optimizer

Analyze SQL queries and generate an optimization report with rewritten queries and dialect-specific tips.

```
/data-science:sql-optimizer query.sql --dialect postgresql
/data-science:sql-optimizer "SELECT * FROM orders WHERE id IN (SELECT id FROM returns)"
```

Supports BigQuery and PostgreSQL.

## Requirements

- Python 3.8+
- Packages are checked and installed on demand (with confirmation) per skill

## License

MIT
