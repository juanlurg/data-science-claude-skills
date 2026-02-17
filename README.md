# data-science

Data science skills for Claude Code: exploratory analysis, experiment tracking, data quality diagnostics, paper implementation, and SQL optimization.

All skills generate Jupyter notebooks (`.ipynb`) as output — ready to open, run, and iterate on.

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
