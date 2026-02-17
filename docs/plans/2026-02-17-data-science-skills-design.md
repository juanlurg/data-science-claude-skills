# Data Science Skills for Claude Code - Design Document

**Date**: 2026-02-17
**Status**: Approved

## Overview

A Claude Code plugin providing five independent skills for data science workflows. All skills produce Jupyter notebooks as primary output, are environment-agnostic (adapting to the user's package manager, data libraries, and SQL dialect), and follow a check-and-ask approach for dependencies.

## Plugin Structure

```
data-science-skills/
  README.md
  LICENSE
  skills/
    auto-eda/
      SKILL.md
    experiment-tracker/
      SKILL.md
    dataset-doctor/
      SKILL.md
    paper-to-code/
      SKILL.md
    sql-optimizer/
      SKILL.md
  lib/
    environment-detection.md
```

Each skill is a `SKILL.md` file with frontmatter (name, description, trigger conditions) and detailed instructions for Claude. The `lib/environment-detection.md` file contains shared logic referenced by all skills.

## Skills

### 1. auto-eda

**Trigger**: `/data-science:auto-eda` or natural language intent to explore a dataset.

**Input**: file path to CSV, Parquet, or Excel file. Optionally a DataFrame variable name.

**Dependencies**: pandas, matplotlib, seaborn, scipy.

**Notebook structure**:
- **Executive Summary**: 2-3 paragraph narrative telling the story of the data. Key findings, interesting patterns, potential issues.
- **Data Overview**: shape, dtypes, memory usage, first/last rows, describe().
- **Missing Data Analysis**: heatmap of missingness, MCAR/MAR/MNAR hypothesis, impact assessment.
- **Distributions**: histograms/KDE for numerics, value counts for categoricals. Flag skewness, bimodality, zero-inflation.
- **Relationships**: correlation matrix, top correlated pairs with scatter plots, categorical vs numeric comparisons. Hypotheses about causal vs spurious relationships.
- **Anomaly Detection**: IQR and z-score outliers, isolation forest if sklearn is available.
- **Feature Engineering Suggestions**: log transforms, interaction terms, binning, datetime extraction based on findings.
- **Next Steps**: recommended follow-up analyses.

**Output**: `./notebooks/eda_{dataset_name}_{date}.ipynb`

### 2. experiment-tracker

**Trigger**: `/data-science:experiment-tracker` or natural language intent to log/track/compare experiments.

**Storage**:
```
experiments/
  tracker.json          # all runs as JSON array
  leaderboard.ipynb     # auto-generated comparison notebook
```

**Operations**:
- **Log a run**: extract model name, hyperparameters, metrics, optional notes. Append to `tracker.json` with timestamp, auto-incremented run ID, and script hash.
- **Show leaderboard**: generate/update `leaderboard.ipynb` with styled DataFrame sorted by chosen metric, plus bar chart comparing top runs.
- **Compare runs**: side-by-side diff of params and metrics for 2+ run IDs.

**Run entry schema**:
```json
{
  "run_id": 1,
  "timestamp": "2026-02-17T10:30:00",
  "model": "RandomForest",
  "params": {"n_estimators": 100, "max_depth": 10},
  "metrics": {"accuracy": 0.87, "f1": 0.83},
  "script_hash": "a3f2...",
  "notes": "baseline model"
}
```

No server, no database. JSON and notebooks. Git-trackable.

### 3. dataset-doctor

**Trigger**: `/data-science:dataset-doctor` or natural language intent to diagnose data quality.

**Input**: one or two file paths. Two files = train/test splits.

**Dependencies**: pandas, matplotlib, scipy, sklearn.

**Notebook structure**:
- **Health Score**: top-level summary. "Dataset health: 6/10. 3 critical issues, 2 warnings." Each issue links to its section.
- **Data Quality**: duplicates, mixed dtypes, inconsistent formatting, constant columns, suspicious ranges.
- **Missing Data**: percentage per column, patterns, drop vs impute recommendation.
- **Class Imbalance** (if target identified): distribution, ratio, resampling suggestions.
- **Multicollinearity**: VIF scores, flag pairs above threshold, suggest drops or combinations.
- **Data Leakage** (if train+test): distribution comparison via KS-test, target leakage detection, row overlap check.
- **Data Drift** (if train+test): distribution shift per feature, PSI scores, visual comparison.
- **Recommendations**: prioritized action list.

**Output**: `./notebooks/data_health_{dataset_name}_{date}.ipynb`

### 4. paper-to-code

**Trigger**: `/data-science:paper-to-code` or natural language intent to implement a paper.

**Input**: PDF file path or arXiv URL.

**Process**: fetch PDF if URL, extract content, detect required framework, check dependencies.

**Notebook structure**:
- **Paper Overview**: title, authors, year, plain-language summary of what the paper does.
- **Key Equations**: core formulations in LaTeX with plain-english explanations.
- **Core Implementation**: Python code for the main algorithm/model. Heavily commented, mapping to equations and paper sections.
- **Toy Example**: synthetic data or simple input demonstrating the implementation works.
- **Limitations & Notes**: simplifications, skipped parts, links to official repos.

Includes a disclaimer: this is a starting point, not a verified reproduction.

**Output**: `./notebooks/paper_{short_title}_{date}.ipynb`

### 5. sql-optimizer

**Trigger**: `/data-science:sql-optimizer` or natural language intent to optimize/explain SQL.

**Input**: SQL query (pasted, from `.sql` file, or notebook cell). Optional dialect specification (BigQuery, PostgreSQL). Inferred from syntax if not specified.

**Notebook structure**:
- **Original Query**: formatted and syntax-highlighted.
- **Query Explanation**: plain-english walkthrough of what the query does.
- **Execution Flow**: step-by-step database engine processing order with data volume estimates.
- **Identified Issues**: problems with severity levels (critical/warning/info). Examples: correlated subqueries, SELECT *, missing partitioning, implicit type casts.
- **Optimized Query**: rewritten query with inline comments explaining changes.
- **Dialect-Specific Tips**: BigQuery (partitioning, clustering, APPROX_COUNT_DISTINCT) or PostgreSQL (indexes, EXPLAIN ANALYZE, CTEs vs subqueries).

**Output**: `./notebooks/sql_optimization_{date}.ipynb`

## Shared Conventions

### Environment Detection (`lib/environment-detection.md`)

1. Detect package manager: `uv.lock` > `pyproject.toml` > `Pipfile` > `requirements.txt` > `environment.yml` > fallback to `pip`.
2. Check required packages: `python -c "import X"` for each.
3. If missing: list them, ask user to confirm installation with detected package manager.
4. Detect data library preference: check polars vs pandas. Generate code accordingly.

### Notebook Generation

- Write `.ipynb` files directly as JSON (no `nbformat` dependency needed).
- Every notebook starts with a metadata cell: skill name, date, input file, disclaimer where relevant.
- Default output directory: `./notebooks/`. Create if it doesn't exist.
- File naming: `{skill}_{context}_{YYYY-MM-DD}.ipynb`.

### Invocation

- Each skill: `/data-science:{skill-name}`.
- Natural language triggers: Claude detects relevant intent and suggests the appropriate skill.

### Transparency

No hidden magic. Every notebook is self-contained. No utility imports from the plugin. Generated code is understandable without knowing the skill exists.
