---
name: auto-eda
description: Generates a narrative exploratory data analysis notebook from a dataset file. Use when the user wants to explore, analyze, profile, or understand a dataset, or mentions EDA, data exploration, or data profiling.
argument-hint: <file-path>
---

# Auto EDA

## Input

`$ARGUMENTS` is the path to a dataset file. If not provided, ask the user for the file path.

Supported formats: CSV, Parquet, Excel (.xlsx/.xls), JSON.

## Step 1: Detect Environment

Follow [environment-detection.md](../../lib/environment-detection.md) to:

1. Detect the package manager.
2. Check for required dependencies: **pandas, matplotlib, seaborn, scipy**.
3. If any are missing, ask the user before installing.
4. Detect whether to use pandas or polars.

## Step 2: Read the Data

Before generating the notebook, you MUST load and examine the data to write informed narrative:

```bash
python -c "
import pandas as pd
df = pd.read_csv('$ARGUMENTS')  # adjust reader for file type
print('Shape:', df.shape)
print('Columns:', list(df.columns))
print('Dtypes:')
print(df.dtypes)
print('Describe:')
print(df.describe())
print('Nulls:')
print(df.isnull().sum())
print('Head:')
print(df.head())
"
```

Adjust the reader based on file extension:
- `.csv` → `pd.read_csv()`
- `.parquet` → `pd.read_parquet()`
- `.xlsx` / `.xls` → `pd.read_excel()`
- `.json` → `pd.read_json()`

Use the output to inform ALL narrative sections below. The executive summary and commentary MUST reference specific column names, values, and findings from this data — never write generic boilerplate.

## Step 3: Generate the Notebook

Follow [notebook-format.md](../../lib/notebook-format.md) for structure. Build the notebook with these sections:

### Section 1: Header (markdown)

```
# Exploratory Data Analysis: {dataset_name}

*Generated on {YYYY-MM-DD} by auto-eda skill*
*Source: `{file_path}`*
```

### Section 2: Setup (code)

```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

%matplotlib inline
sns.set_style('whitegrid')
plt.rcParams['figure.figsize'] = (10, 6)

df = pd.read_csv('{file_path}')  # adjust reader for file type
print(f"Dataset: {df.shape[0]} rows, {df.shape[1]} columns")
```

### Section 3: Executive Summary (markdown)

Write 2-3 paragraphs as an analyst briefing a stakeholder:
- What the dataset contains (rows, columns, what it represents).
- Key findings: notable distributions, correlations, anomalies.
- Potential issues: missing data, outliers, data quality concerns.

This section references SPECIFIC column names, values, correlations, and anomalies you found in Step 2. Never be generic.

### Section 4: Data Overview (code + markdown)

Code cells showing:
- `df.shape`, `df.dtypes`
- `df.info()`
- `df.describe(include='all')`
- `df.head()`, `df.tail()`
- Memory usage: `df.memory_usage(deep=True).sum() / 1024**2` MB

Markdown cell summarizing key observations about the structure.

### Section 5: Missing Data Analysis (code + markdown)

Code cells:
- Percentage missing per column.
- Bar chart of missing percentages.
- `sns.heatmap()` of missingness correlation if multiple columns have nulls.

Markdown cell with:
- Hypothesis about missingness mechanism (MCAR/MAR/MNAR based on patterns).
- Impact assessment for downstream analysis.

### Section 6: Distributions (code + markdown)

For each numeric column:
- Histogram with KDE overlay: `sns.histplot(df[col], kde=True)`

For each categorical column (up to 20 unique values):
- Value counts bar chart.

Markdown commentary flagging:
- Skewness > 1 (right-skewed) or < -1 (left-skewed).
- Bimodal distributions.
- Zero-inflation.

Use `plt.tight_layout()` and `plt.show()` after every plot.

### Section 7: Relationships (code + markdown)

Code cells:
- Correlation matrix heatmap: `sns.heatmap(df.select_dtypes(include='number').corr(), annot=True, cmap='coolwarm')`
- Top 5 correlated pairs with scatter plots.
- Categorical vs numeric box plots for top associations.

Markdown cell with hypotheses about relationships found.

### Section 8: Anomaly Detection (code + markdown)

Code cells:
- IQR method: flag values outside Q1 - 1.5*IQR or Q3 + 1.5*IQR.
- Z-score flagging: |z| > 3.
- If sklearn is available, `IsolationForest` on numeric columns.
- Summary table: outliers found per column.

Markdown cell summarizing anomaly findings.

### Section 9: Feature Engineering Suggestions (markdown)

Based on findings, suggest:
- Log transforms for skewed features.
- Interaction terms for correlated pairs.
- Binning for high-cardinality categoricals.
- Datetime extraction if date columns found.
- Encoding suggestions for categoricals.

### Section 10: Next Steps (markdown)

Recommended follow-up analyses based on what was found.

## Step 4: Write the Notebook

Write to `./notebooks/eda_{dataset_name}_{YYYY-MM-DD}.ipynb` where `dataset_name` is derived from the filename (without extension).

Create the `./notebooks/` directory if it doesn't exist.

## Step 5: Report

Tell the user:
- Where the notebook was saved.
- Summarize 3-5 key findings from the analysis.

## Important Rules

- READ the data first (Step 2) before writing any narrative. Never write generic content.
- The executive summary MUST reference specific column names, values, and findings.
- Each section should have markdown cells with analysis commentary between code cells.
- Use `plt.tight_layout()` and `plt.show()` after every plot.
- Use `%matplotlib inline` in the setup cell.
- For large datasets (>100k rows): sample for visualizations with a note explaining the sampling.
- All code must be self-contained and runnable standalone.
