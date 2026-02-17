# Data Science Skills Plugin - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code plugin with 5 data science skills (auto-eda, experiment-tracker, dataset-doctor, paper-to-code, sql-optimizer) that generate Jupyter notebooks as output.

**Architecture:** Each skill is a `SKILL.md` file with YAML frontmatter following the Agent Skills standard. Skills share an environment detection reference (`lib/environment-detection.md`). The plugin uses `.claude-plugin/plugin.json` for metadata and `commands/` for thin wrapper shortcuts. All skills write `.ipynb` files directly as JSON.

**Tech Stack:** Claude Code plugin system (SKILL.md, plugin.json), Jupyter notebook JSON format, Python (pandas/polars, matplotlib, seaborn, scipy, sklearn).

---

### Task 1: Plugin scaffold and manifest

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `LICENSE`

**Step 1: Create the plugin manifest**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "data-science",
  "description": "Data science skills for Claude Code: exploratory analysis, experiment tracking, data quality diagnostics, paper implementation, and SQL optimization",
  "version": "0.1.0",
  "author": {
    "name": "juanlu"
  },
  "license": "MIT",
  "keywords": ["data-science", "eda", "ml", "experiment-tracking", "sql", "notebooks"]
}
```

**Step 2: Create MIT license file**

Create `LICENSE` with the MIT license text, year 2026, author "juanlu".

**Step 3: Verify plugin loads**

Run: `claude --plugin-dir .`
Expected: Claude starts without errors. `/help` should show the plugin name.

**Step 4: Commit**

```bash
git add .claude-plugin/plugin.json LICENSE
git commit -m "feat: initialize data-science plugin scaffold"
```

---

### Task 2: Shared environment detection reference

**Files:**
- Create: `lib/environment-detection.md`

**Step 1: Write the environment detection reference**

Create `lib/environment-detection.md`. This file is NOT a skill — it is a reference document that skills link to with `See [environment-detection.md](../../lib/environment-detection.md)`. It contains instructions Claude follows when a skill references it.

```markdown
# Environment Detection

## Package Manager Detection

Check the project root for these files in priority order:

1. `uv.lock` → use `uv add <package>`
2. `pyproject.toml` (without uv.lock) → check if `[tool.uv]` section exists: if yes use `uv add`, else use `pip install`
3. `Pipfile` → use `pipenv install <package>`
4. `requirements.txt` → use `pip install <package>`
5. `environment.yml` → use `conda install <package>`
6. Nothing found → default to `pip install <package>`

## Dependency Check

For each required package, run:

```bash
python -c "import <package_name>" 2>/dev/null && echo "OK" || echo "MISSING"
```

If any are missing, present the user with:

> The following packages are needed: **X, Y, Z**
> Install with `<detected_command> X Y Z`?

Wait for confirmation before installing. Never install without asking.

## Data Library Detection

Check which data libraries are available:

```bash
python -c "import pandas" 2>/dev/null && echo "pandas"
python -c "import polars" 2>/dev/null && echo "polars"
```

- If only pandas: generate pandas code
- If only polars: generate polars code
- If both: ask user which they prefer, default to pandas

## Python Detection

```bash
python --version 2>/dev/null || python3 --version 2>/dev/null
```

Use whichever is available. Prefer `python` over `python3`.
```

**Step 2: Commit**

```bash
git add lib/environment-detection.md
git commit -m "feat: add shared environment detection reference"
```

---

### Task 3: Notebook generation reference

**Files:**
- Create: `lib/notebook-format.md`

**Step 1: Write the notebook format reference**

Create `lib/notebook-format.md`. This tells Claude how to write `.ipynb` files directly as JSON without needing nbformat.

```markdown
# Notebook Generation

## Writing .ipynb Files

Jupyter notebooks are JSON files. Write them directly using the Write tool. No `nbformat` dependency needed.

## Minimal Notebook Structure

```json
{
  "nbformat": 4,
  "nbformat_minor": 5,
  "metadata": {
    "kernelspec": {
      "display_name": "Python 3",
      "language": "python",
      "name": "python3"
    },
    "language_info": {
      "name": "python",
      "version": "3.11.0"
    }
  },
  "cells": []
}
```

## Cell Types

**Markdown cell:**
```json
{
  "cell_type": "markdown",
  "metadata": {},
  "source": ["# Title\n", "\n", "Description text."]
}
```

**Code cell:**
```json
{
  "cell_type": "code",
  "metadata": {},
  "source": ["import pandas as pd\n", "df = pd.read_csv('data.csv')"],
  "execution_count": null,
  "outputs": []
}
```

## Rules

1. The `source` field is an array of strings. Each string is one line, ending with `\n` except the last line.
2. Always create the `./notebooks/` directory if it doesn't exist before writing.
3. Every notebook starts with a metadata markdown cell containing: skill name, date generated, input file path.
4. File naming: `{skill}_{context}_{YYYY-MM-DD}.ipynb`.
5. All generated code must be self-contained. No imports from the plugin. A user must be able to run the notebook standalone.
6. Escape special characters in JSON strings: backslashes, quotes, newlines.
```

**Step 2: Commit**

```bash
git add lib/notebook-format.md
git commit -m "feat: add notebook generation reference"
```

---

### Task 4: auto-eda skill

**Files:**
- Create: `skills/auto-eda/SKILL.md`
- Create: `commands/auto-eda.md`

**Step 1: Write the auto-eda SKILL.md**

Create `skills/auto-eda/SKILL.md`. Must be under 500 lines. Description must contain ONLY triggering conditions, never summarize the workflow.

```yaml
---
name: auto-eda
description: Generates a narrative exploratory data analysis notebook from a dataset file. Use when the user wants to explore, analyze, profile, or understand a dataset, or mentions EDA, data exploration, or data profiling.
argument-hint: <file-path>
---
```

The body should contain these sections (see full content below). The skill instructs Claude to:

1. **Accept input**: `$ARGUMENTS` is the file path. If not provided, ask. Support CSV, Parquet, Excel, JSON.
2. **Detect environment**: follow [environment-detection.md](../../lib/environment-detection.md) to check package manager and dependencies (pandas, matplotlib, seaborn, scipy).
3. **Generate the notebook** following [notebook-format.md](../../lib/notebook-format.md) with these sections:

**Notebook sections to generate:**

- **Header cell** (markdown): "Exploratory Data Analysis: {dataset_name}" + generated date + skill attribution.
- **Setup cell** (code): imports (pandas, matplotlib, seaborn, scipy.stats, warnings filter). Load the dataset.
- **Executive Summary** (markdown): 2-3 paragraphs. Narrative of dataset: what it contains, size, key findings, interesting patterns, potential issues. Written as an analyst would brief a stakeholder. This cell is generated AFTER Claude has analyzed the data — it references specific columns, correlations, and anomalies found.
- **Data Overview** (code + markdown): `df.shape`, `df.dtypes`, `df.info()`, `df.describe()`, `df.head()`, `df.tail()`, memory usage.
- **Missing Data Analysis** (code + markdown): percentage missing per column, `seaborn.heatmap` of missingness, hypothesis about mechanism (MCAR/MAR/MNAR based on patterns), impact assessment.
- **Distributions** (code + markdown): for each numeric column — histogram with KDE overlay. For each categorical column — value counts bar chart. Flag skewness >1, bimodality, zero-inflation in markdown commentary.
- **Relationships** (code + markdown): correlation matrix heatmap, top 5 correlated pairs with scatter plots, categorical vs numeric box plots for top associations. Markdown hypotheses about relationships.
- **Anomaly Detection** (code + markdown): IQR method for outliers, z-score flagging. If sklearn available, IsolationForest on numeric columns. Summary table of outliers found per column.
- **Feature Engineering Suggestions** (markdown): based on findings — log transforms for skewed features, interaction terms for correlated pairs, binning for high-cardinality, datetime extraction if date columns found, encoding suggestions for categoricals.
- **Next Steps** (markdown): recommended follow-up analyses based on what was found.

4. **Write the notebook** to `./notebooks/eda_{dataset_name}_{YYYY-MM-DD}.ipynb`.
5. Tell the user where the notebook was saved and summarize key findings.

**Important instructions in the skill:**
- Claude must READ the data first (load a sample) to write informed narrative, not generic boilerplate.
- The executive summary must reference specific column names, values, and findings — never be generic.
- Each section should have markdown cells with analysis commentary between code cells.
- Use `plt.tight_layout()` and `plt.show()` after every plot.
- Use `%matplotlib inline` in the setup cell.
- Handle large datasets: if >100k rows, sample for visualizations with a note.

**Step 2: Write the command wrapper**

Create `commands/auto-eda.md`:

```yaml
---
description: Generate a narrative exploratory data analysis notebook from a dataset
argument-hint: <file-path>
disable-model-invocation: true
---

Use and follow the auto-eda skill exactly as written
```

**Step 3: Test manually**

Run: `claude --plugin-dir .`
Then: `/data-science:auto-eda path/to/test.csv`
Expected: Claude reads the skill, detects environment, generates a notebook.

**Step 4: Commit**

```bash
git add skills/auto-eda/SKILL.md commands/auto-eda.md
git commit -m "feat: add auto-eda skill with narrative notebook generation"
```

---

### Task 5: experiment-tracker skill

**Files:**
- Create: `skills/experiment-tracker/SKILL.md`
- Create: `commands/experiment-tracker.md`

**Step 1: Write the experiment-tracker SKILL.md**

Create `skills/experiment-tracker/SKILL.md`.

```yaml
---
name: experiment-tracker
description: Logs ML experiment runs, generates leaderboards, and compares experiments locally using JSON and notebooks. Use when the user wants to track, log, compare, or view ML experiments, model runs, or training results.
argument-hint: <log|leaderboard|compare> [options]
---
```

The body instructs Claude to manage a file-based experiment tracking system:

**Storage:**
```
experiments/
  tracker.json     # Array of run objects
  leaderboard.ipynb
```

**Operations — detected from `$ARGUMENTS` and context:**

**1. Log a run (`log`):**
- Extract from conversation context: model name, params dict, metrics dict, optional notes.
- If not enough info, ask the user.
- Read `experiments/tracker.json` (create if doesn't exist, initialize as `[]`).
- Generate next `run_id` (max existing + 1, or 1 if empty).
- Compute `script_hash`: if a training script is identifiable in context, hash it with `python -c "import hashlib; print(hashlib.sha256(open('file').read().encode()).hexdigest()[:12])"`. Otherwise `null`.
- Append run entry:
```json
{
  "run_id": 1,
  "timestamp": "ISO 8601",
  "model": "name",
  "params": {},
  "metrics": {},
  "script_hash": "abc123" or null,
  "notes": "optional"
}
```
- Write back to `tracker.json`.
- Confirm to user: "Run #N logged. Metrics: {summary}."

**2. Show leaderboard (`leaderboard`):**
- Read `tracker.json`.
- Ask user which metric to sort by (or detect from context).
- Generate `experiments/leaderboard.ipynb` following [notebook-format.md](../../lib/notebook-format.md):
  - Load `tracker.json` with pandas.
  - Styled DataFrame sorted by chosen metric.
  - Bar chart comparing top runs on that metric.
  - Summary markdown: best run, worst run, improvement over time.
- Tell user where notebook was saved.

**3. Compare runs (`compare`):**
- User specifies 2+ run IDs.
- Read `tracker.json`, filter to those runs.
- Generate comparison section: side-by-side table of params and metrics, highlight differences.
- Can be added to leaderboard notebook or written as separate notebook.

**Step 2: Write the command wrapper**

Create `commands/experiment-tracker.md`:

```yaml
---
description: Log, compare, and visualize ML experiments locally
argument-hint: <log|leaderboard|compare> [options]
disable-model-invocation: true
---

Use and follow the experiment-tracker skill exactly as written
```

**Step 3: Test manually**

Run: `claude --plugin-dir .`
Then: `/data-science:experiment-tracker log` and provide model details in conversation.
Expected: Creates `experiments/tracker.json` with first run entry.

**Step 4: Commit**

```bash
git add skills/experiment-tracker/SKILL.md commands/experiment-tracker.md
git commit -m "feat: add experiment-tracker skill for local ML run tracking"
```

---

### Task 6: dataset-doctor skill

**Files:**
- Create: `skills/dataset-doctor/SKILL.md`
- Create: `commands/dataset-doctor.md`

**Step 1: Write the dataset-doctor SKILL.md**

Create `skills/dataset-doctor/SKILL.md`.

```yaml
---
name: dataset-doctor
description: Diagnoses data quality problems and generates a health report notebook. Use when the user wants to check data quality, detect data leakage, find data drift, check for imbalance, multicollinearity, or assess dataset health.
argument-hint: <train-file> [test-file] [--target column]
---
```

The body instructs Claude to:

1. **Accept input**: `$0` = train/main file, `$1` = optional test file, `--target` flag = target column name. If target not specified, attempt to infer (columns named "target", "label", "y", "class") or ask.
2. **Detect environment**: follow [environment-detection.md](../../lib/environment-detection.md). Dependencies: pandas, matplotlib, scipy, sklearn.
3. **Run diagnostics and generate notebook** following [notebook-format.md](../../lib/notebook-format.md):

**Notebook sections:**

- **Header**: "Dataset Health Report: {name}" + date.
- **Health Score** (markdown): "Dataset health: X/10. N critical issues, M warnings." Each issue listed with severity and link to section. Score calculation:
  - Start at 10. Deduct 2 per critical, 1 per warning, 0.5 per info.
  - Critical: >30% missing in any column, data leakage detected, >95% class imbalance, VIF >10.
  - Warning: >5% missing, moderate imbalance, VIF >5, duplicates >1%.
  - Info: mixed dtypes, constant columns, minor formatting inconsistencies.
- **Data Quality** (code + markdown): duplicate rows count, mixed dtypes detection (`df[col].apply(type).nunique()`), inconsistent formatting (e.g., case variations via `df[col].str.lower().nunique()` vs `df[col].nunique()`), constant/near-constant columns (nunique <=1 or >99% same value), suspicious value ranges.
- **Missing Data** (code + markdown): percentage per column, bar chart, missingness correlation matrix, recommendation per column (drop if >50%, impute if <50%, investigate if pattern suggests MAR).
- **Class Imbalance** (code + markdown, only if target identified): value counts, imbalance ratio (majority/minority), bar chart, recommendations (SMOTE, class weights, over/undersampling).
- **Multicollinearity** (code + markdown): VIF calculation for numeric features using `from statsmodels.stats.outliers_influence import variance_inflation_factor` (if available, else manual formula with sklearn). Flag pairs with VIF >5. Correlation matrix for top offenders.
- **Data Leakage** (code + markdown, only if train+test provided):
  - Row overlap: check for identical rows between train and test.
  - Distribution comparison: KS-test per feature between train and test. Flag p-value < 0.05.
  - Target leakage: for each feature, check correlation with target. Flag suspiciously high correlations (>0.95) — these might be derived from the target.
- **Data Drift** (code + markdown, only if train+test provided):
  - PSI (Population Stability Index) per feature. PSI formula in code. Flag PSI >0.2 (significant shift), >0.1 (moderate).
  - Side-by-side distribution plots for top drifting features.
- **Recommendations** (markdown): numbered priority list. Critical first, then warnings, then info. Each with specific action: "1. Drop column `id` (constant, provides no signal). 2. Investigate leakage in `total_spend` (r=0.99 with target)."

4. **Write notebook** to `./notebooks/data_health_{dataset_name}_{YYYY-MM-DD}.ipynb`.

**Step 2: Write the command wrapper**

Create `commands/dataset-doctor.md`:

```yaml
---
description: Diagnose data quality issues and generate a dataset health report
argument-hint: <train-file> [test-file] [--target column]
disable-model-invocation: true
---

Use and follow the dataset-doctor skill exactly as written
```

**Step 3: Test manually**

Run: `claude --plugin-dir .`
Then: `/data-science:dataset-doctor train.csv test.csv --target label`
Expected: Generates health report notebook with all applicable sections.

**Step 4: Commit**

```bash
git add skills/dataset-doctor/SKILL.md commands/dataset-doctor.md
git commit -m "feat: add dataset-doctor skill for data quality diagnostics"
```

---

### Task 7: paper-to-code skill

**Files:**
- Create: `skills/paper-to-code/SKILL.md`
- Create: `commands/paper-to-code.md`

**Step 1: Write the paper-to-code SKILL.md**

Create `skills/paper-to-code/SKILL.md`.

```yaml
---
name: paper-to-code
description: Reads a research paper and generates an implementation notebook with equations, code, and a toy example. Use when the user wants to implement a paper, convert a paper to code, or reproduce a paper's algorithm.
argument-hint: <pdf-path-or-arxiv-url>
---
```

The body instructs Claude to:

1. **Accept input**: `$ARGUMENTS` is a PDF file path or arXiv URL (e.g., `https://arxiv.org/abs/2301.12345`).
2. **Read the paper**:
   - If PDF path: read with the Read tool (Claude can read PDFs).
   - If arXiv URL: use WebFetch to get the abstract page. Extract the PDF link (replace `/abs/` with `/pdf/` and add `.pdf`). Fetch and read.
   - Extract: title, authors, year, abstract, key method sections, equations, algorithm descriptions.
3. **Detect required framework**: based on paper content, identify if it needs PyTorch, TensorFlow, JAX, sklearn, or just numpy. Check environment per [environment-detection.md](../../lib/environment-detection.md).
4. **Generate notebook** following [notebook-format.md](../../lib/notebook-format.md):

**Notebook sections:**

- **Header** (markdown): title, authors, year, link to paper. **Disclaimer**: "This is an AI-generated starting point, not a verified reproduction. Verify against the original paper before use in production."
- **Paper Overview** (markdown): 1-2 paragraphs in plain language explaining what the paper does, why it matters, and what problem it solves. No jargon.
- **Key Equations** (markdown): core mathematical formulations in LaTeX (`$$...$$`). Each equation followed by a plain-english explanation. Example: "$$\alpha_i = \frac{\exp(e_i)}{\sum_j \exp(e_j)}$$ This is the softmax attention weight — it converts raw scores into a probability distribution over all positions."
- **Core Implementation** (code + markdown): Python implementation of the main algorithm. NOT the entire paper — just the novel contribution. Code cells with heavy comments mapping to paper sections: `# Section 3.2, Eq. 5 — compute attention scores`. Break into logical functions/classes.
- **Toy Example** (code + markdown): create a small synthetic dataset or simple input. Run the implementation on it. Print/visualize results. Sanity-check: "Expected behavior: X. Actual: Y. This confirms the implementation handles the basic case."
- **Limitations & Notes** (markdown): what was simplified, what was skipped, differences from the paper's full implementation, links to official repos if they exist (search GitHub for the paper title).

5. **Write notebook** to `./notebooks/paper_{short_title}_{YYYY-MM-DD}.ipynb` where `short_title` is a snake_case abbreviation of the paper title (max 30 chars).

**Important instructions:**
- Focus on the NOVEL contribution of the paper, not standard boilerplate (data loading, training loops).
- If the paper is too complex for a single notebook (e.g., full transformer architecture), pick the core innovation and implement that.
- Prefer functional style for clarity over OOP unless the paper naturally maps to classes.

**Step 2: Write the command wrapper**

Create `commands/paper-to-code.md`:

```yaml
---
description: Convert a research paper into an implementation notebook
argument-hint: <pdf-path-or-arxiv-url>
disable-model-invocation: true
---

Use and follow the paper-to-code skill exactly as written
```

**Step 3: Test manually**

Run: `claude --plugin-dir .`
Then: `/data-science:paper-to-code https://arxiv.org/abs/1706.03762`
Expected: Generates notebook implementing the core self-attention mechanism from "Attention Is All You Need".

**Step 4: Commit**

```bash
git add skills/paper-to-code/SKILL.md commands/paper-to-code.md
git commit -m "feat: add paper-to-code skill for research paper implementation"
```

---

### Task 8: sql-optimizer skill

**Files:**
- Create: `skills/sql-optimizer/SKILL.md`
- Create: `skills/sql-optimizer/reference/bigquery-tips.md`
- Create: `skills/sql-optimizer/reference/postgresql-tips.md`
- Create: `commands/sql-optimizer.md`

**Step 1: Write the sql-optimizer SKILL.md**

Create `skills/sql-optimizer/SKILL.md`.

```yaml
---
name: sql-optimizer
description: Analyzes SQL queries and generates an optimization report notebook with explanations, identified issues, and rewritten queries. Use when the user wants to optimize, explain, improve, or debug a SQL query, or mentions query performance, slow queries, or SQL optimization.
argument-hint: <query-or-file> [--dialect bigquery|postgresql]
---
```

The body instructs Claude to:

1. **Accept input**: `$ARGUMENTS` can be:
   - Inline SQL query (if short)
   - Path to a `.sql` file
   - If neither provided, ask the user to paste the query.
   - Optional `--dialect` flag. If not provided, auto-detect from syntax (e.g., backtick identifiers = BigQuery, `::` casts = PostgreSQL, `PARTITION BY` usage patterns).
2. **Generate notebook** following [notebook-format.md](../../lib/notebook-format.md):

**Notebook sections:**

- **Header** (markdown): "SQL Query Analysis" + date + detected dialect.
- **Original Query** (code cell, SQL): the input query, formatted with proper indentation. Use `%%sql` magic or just put it in a python string for display.
- **Query Explanation** (markdown): plain-english walkthrough. "This query: 1. Joins `orders` with `customers` on `customer_id`. 2. Filters for orders from the last 30 days. 3. Groups by customer segment. 4. Calculates total and average spend per segment."
- **Execution Flow** (markdown): step-by-step order of operations as the database engine processes it: FROM → JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT. Note at each stage what data volume looks like (if inferable).
- **Identified Issues** (markdown): table with columns: Severity, Issue, Location, Impact. Severities:
  - Critical: correlated subqueries, SELECT *, full table scans on large tables, Cartesian joins.
  - Warning: implicit type casts, functions on indexed columns in WHERE, missing LIMIT on exploratory queries, redundant subqueries.
  - Info: style improvements, readability suggestions, aliasing recommendations.
- **Optimized Query** (code cell, SQL): the rewritten query with inline comments explaining each change: `-- Changed: correlated subquery → LEFT JOIN (eliminates N+1 execution)`.
- **Dialect-Specific Tips** (markdown): reference the appropriate file:
  - For BigQuery, see [bigquery-tips.md](reference/bigquery-tips.md)
  - For PostgreSQL, see [postgresql-tips.md](reference/postgresql-tips.md)
  - Include the 3-5 most relevant tips from the reference based on the specific query.

3. **Write notebook** to `./notebooks/sql_optimization_{YYYY-MM-DD}.ipynb`.

**Step 2: Write BigQuery tips reference**

Create `skills/sql-optimizer/reference/bigquery-tips.md`:

```markdown
# BigQuery Optimization Tips

## Partitioning
- Always filter on partition column to avoid full scans
- Use `_PARTITIONTIME` or custom partition columns
- Partition by date is most common; consider integer range for non-date data

## Clustering
- Cluster on columns frequently used in WHERE, JOIN, GROUP BY
- Up to 4 clustering columns, order matters (most filtered first)
- Clustering benefits compound with partitioning

## Approximate Functions
- `APPROX_COUNT_DISTINCT()` instead of `COUNT(DISTINCT)` — much faster, <1% error
- `APPROX_QUANTILES()` for percentiles
- `APPROX_TOP_COUNT()` for top-N values

## Query Patterns
- Avoid `SELECT *` — charges for all columns in columnar storage
- Use `LIMIT` during development — still scans full table but returns faster
- Prefer `EXISTS` over `IN` for subqueries
- Use `SAFE_DIVIDE()` instead of `CASE WHEN denominator = 0`

## Cost Control
- Use `--dry_run` to estimate bytes scanned
- Set `maximum_bytes_billed` as safety net
- Materialize intermediate results for repeated subqueries (CREATE TEMP TABLE)

## Common Anti-Patterns
- Joining on non-clustered columns in large tables
- Using `ORDER BY` without `LIMIT` (sorts entire result)
- Cross joins (even accidental via missing ON clause)
- Regex in WHERE when LIKE suffices
```

**Step 3: Write PostgreSQL tips reference**

Create `skills/sql-optimizer/reference/postgresql-tips.md`:

```markdown
# PostgreSQL Optimization Tips

## EXPLAIN ANALYZE
- Always run `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` to see actual execution
- Look for: Seq Scan (missing index?), Nested Loop (consider Hash Join), Sort (add index?)
- `rows=X` vs `actual rows=Y` mismatch indicates stale statistics — run `ANALYZE table`

## Indexing
- B-tree (default): equality and range queries
- GIN: full-text search, JSONB, arrays
- GiST: geometric, range types
- Partial indexes: `CREATE INDEX idx ON t(col) WHERE condition` — smaller, faster
- Covering indexes: `CREATE INDEX idx ON t(a) INCLUDE (b, c)` — index-only scans

## Query Patterns
- Prefer `EXISTS` over `IN` for correlated checks
- CTEs in PostgreSQL 12+ are NOT optimization fences — use freely
- `DISTINCT ON (col) ORDER BY col, other_col` is PostgreSQL-specific and fast
- Use `LATERAL JOIN` to replace correlated subqueries

## Common Anti-Patterns
- Functions on indexed columns: `WHERE LOWER(name) = 'x'` — use expression index instead
- `SELECT *` in subqueries — specify needed columns
- `NOT IN (subquery)` with NULLs — use `NOT EXISTS` instead
- Missing `VACUUM` / `ANALYZE` — stale statistics cause bad plans

## Performance
- Increase `work_mem` for complex sorts/hash joins (per-query with `SET`)
- `enable_seqscan = off` temporarily to test if index is used
- Connection pooling (pgbouncer) for many short queries
```

**Step 4: Write the command wrapper**

Create `commands/sql-optimizer.md`:

```yaml
---
description: Analyze and optimize SQL queries with dialect-specific tips
argument-hint: <query-or-file> [--dialect bigquery|postgresql]
disable-model-invocation: true
---

Use and follow the sql-optimizer skill exactly as written
```

**Step 5: Test manually**

Run: `claude --plugin-dir .`
Then: `/data-science:sql-optimizer SELECT * FROM orders o, customers c WHERE o.customer_id = c.id --dialect postgresql`
Expected: Generates optimization notebook flagging SELECT * and implicit cross join syntax.

**Step 6: Commit**

```bash
git add skills/sql-optimizer/ commands/sql-optimizer.md
git commit -m "feat: add sql-optimizer skill with BigQuery and PostgreSQL support"
```

---

### Task 9: README and final polish

**Files:**
- Create: `README.md`

**Step 1: Write the README**

Create `README.md` with:

- Plugin name and one-line description.
- Installation instructions (`/plugin marketplace add ...` or `claude --plugin-dir`).
- Skills list with brief description of each and example invocation.
- Requirements (Python 3.8+, packages installed on demand).
- License.

Keep it concise — under 100 lines.

**Step 2: Verify full plugin structure**

Run: `find . -type f | grep -v .git | sort`

Expected structure:
```
.claude-plugin/plugin.json
LICENSE
README.md
commands/auto-eda.md
commands/dataset-doctor.md
commands/experiment-tracker.md
commands/paper-to-code.md
commands/sql-optimizer.md
lib/environment-detection.md
lib/notebook-format.md
skills/auto-eda/SKILL.md
skills/dataset-doctor/SKILL.md
skills/experiment-tracker/SKILL.md
skills/paper-to-code/SKILL.md
skills/sql-optimizer/SKILL.md
skills/sql-optimizer/reference/bigquery-tips.md
skills/sql-optimizer/reference/postgresql-tips.md
```

**Step 3: Test all skills load**

Run: `claude --plugin-dir .`
Verify all 5 skills appear in `/help` under the `data-science` namespace.

**Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add README with installation and usage guide"
```

---

## Task Dependency Summary

```
Task 1 (scaffold) ──→ Task 2 (env detection) ──→ Task 3 (notebook format)
                                                          │
                          ┌───────────────────────────────┤
                          ↓               ↓               ↓               ↓
                       Task 4          Task 5          Task 6          Task 7          Task 8
                     (auto-eda)    (exp-tracker)   (dataset-doctor) (paper-to-code) (sql-optimizer)
                          │               │               │               │               │
                          └───────────────┴───────────────┴───────────────┴───────────────┘
                                                          │
                                                       Task 9
                                                    (README + polish)
```

Tasks 4-8 are independent of each other and can be implemented in parallel after Tasks 1-3 are complete.
