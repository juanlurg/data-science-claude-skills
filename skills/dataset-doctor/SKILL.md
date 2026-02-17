---
name: dataset-doctor
description: Diagnoses data quality problems and generates a health report notebook. Use when the user wants to check data quality, detect data leakage, find data drift, check for imbalance, multicollinearity, or assess dataset health.
argument-hint: <train-file> [test-file] [--target column]
---

# Dataset Doctor

## Input

Parse `$ARGUMENTS` for:

- `$0` — train/main dataset file path (required). If not provided, ask.
- `$1` — optional test dataset file path.
- `--target <column>` — target column name.

If `--target` is not specified, attempt to infer: look for columns named `target`, `label`, `y`, `class`, `outcome`, or `is_*`. If none found, ask the user.

Supported formats: CSV, Parquet, Excel, JSON.

## Step 1: Detect Environment

Follow [environment-detection.md](../../lib/environment-detection.md) to:

1. Detect the package manager.
2. Check for required dependencies: **pandas, matplotlib, scipy, sklearn**.
3. Optional: **statsmodels** (for VIF calculation — if unavailable, use manual formula).
4. If any required packages are missing, ask the user before installing.

## Step 2: Read the Data

Load the train dataset (and test dataset if provided). Examine shapes, columns, dtypes, and basic statistics to inform the health report.

```bash
python -c "
import pandas as pd
df = pd.read_csv('TRAIN_PATH')
print('Train shape:', df.shape)
print('Dtypes:', dict(df.dtypes))
print('Nulls:', dict(df.isnull().sum()))
print('Describe:')
print(df.describe())
"
```

If a test file is provided, repeat for the test set.

## Step 3: Generate the Health Report Notebook

Follow [notebook-format.md](../../lib/notebook-format.md) for structure.

### Section 1: Header (markdown)

```
# Dataset Health Report: {dataset_name}

*Generated on {YYYY-MM-DD} by dataset-doctor skill*
*Train file: `{train_path}`*
*Test file: `{test_path}` (if provided)*
*Target column: `{target}`*
```

### Section 2: Health Score (markdown)

Calculate a health score out of 10:

- Start at 10.
- Deduct **2** per critical issue.
- Deduct **1** per warning.
- Deduct **0.5** per info item.
- Minimum score: 0.

**Critical issues** (deduct 2 each):
- Any column with >30% missing values.
- Data leakage detected (row overlap or suspiciously high correlation with target >0.95).
- Class imbalance >95% (majority class).
- VIF >10 for any feature.

**Warnings** (deduct 1 each):
- Any column with >5% missing values.
- Moderate class imbalance (>80% majority class).
- VIF >5 for any feature.
- Duplicate rows >1%.

**Info items** (deduct 0.5 each):
- Mixed dtypes in a column.
- Constant or near-constant columns (nunique <=1 or >99% same value).
- Minor formatting inconsistencies.

Display: "Dataset health: **X/10**. N critical issues, M warnings."

List each issue with severity and brief description.

### Section 3: Data Quality (code + markdown)

Code cells:
- Duplicate rows: `df.duplicated().sum()`
- Mixed dtypes detection: `df[col].apply(type).nunique()` for each column.
- Inconsistent formatting: for string columns, compare `df[col].str.lower().nunique()` vs `df[col].nunique()`.
- Constant/near-constant columns: `nunique() <= 1` or value counts where top value >99%.
- Suspicious value ranges (negative values where unexpected, future dates, etc.).

Markdown cell summarizing findings.

### Section 4: Missing Data (code + markdown)

Code cells:
- Percentage missing per column.
- Bar chart of missing percentages.
- Missingness correlation matrix (which columns tend to be missing together).

Markdown cell with recommendation per column:
- Drop column if >50% missing.
- Impute if <50% missing (suggest method: mean/median for numeric, mode for categorical).
- Investigate if pattern suggests MAR (missing correlated with another column).

### Section 5: Class Imbalance (code + markdown)

Only include if a target column is identified.

Code cells:
- `df[target].value_counts()`
- Imbalance ratio: majority count / minority count.
- Bar chart of class distribution.

Markdown cell with recommendations:
- If severe (>10:1): suggest SMOTE, class weights, or undersampling.
- If moderate (>3:1): suggest class weights or stratified splitting.
- If balanced: note that no action needed.

### Section 6: Multicollinearity (code + markdown)

Code cells:
- VIF calculation for numeric features:

```python
from sklearn.preprocessing import StandardScaler
import numpy as np

# If statsmodels available:
from statsmodels.stats.outliers_influence import variance_inflation_factor

numeric_df = df.select_dtypes(include='number').dropna()
scaler = StandardScaler()
scaled = scaler.fit_transform(numeric_df)

vif_data = pd.DataFrame({
    'Feature': numeric_df.columns,
    'VIF': [variance_inflation_factor(scaled, i) for i in range(scaled.shape[1])]
}).sort_values('VIF', ascending=False)
```

- Flag pairs with VIF >5.
- Correlation matrix for top offenders.

Markdown cell explaining which features are problematic and suggesting removal/combination.

### Section 7: Data Leakage (code + markdown)

Only include if BOTH train and test files are provided.

Code cells:
- **Row overlap**: check for identical rows between train and test.
- **Distribution comparison**: KS-test per numeric feature between train and test. Flag p-value < 0.05.
- **Target leakage**: for each feature, compute correlation with target. Flag r > 0.95.

Markdown cell explaining any leakage found and its impact.

### Section 8: Data Drift (code + markdown)

Only include if BOTH train and test files are provided.

Code cells:
- **PSI (Population Stability Index)** per feature:

```python
def calculate_psi(expected, actual, bins=10):
    breakpoints = np.linspace(min(expected.min(), actual.min()),
                               max(expected.max(), actual.max()), bins + 1)
    expected_counts = np.histogram(expected, breakpoints)[0] / len(expected)
    actual_counts = np.histogram(actual, breakpoints)[0] / len(actual)
    expected_counts = np.clip(expected_counts, 1e-4, None)
    actual_counts = np.clip(actual_counts, 1e-4, None)
    psi = np.sum((actual_counts - expected_counts) * np.log(actual_counts / expected_counts))
    return psi
```

- Flag PSI > 0.2 (significant drift), > 0.1 (moderate drift).
- Side-by-side distribution plots for top drifting features.

Markdown cell summarizing drift findings.

### Section 9: Recommendations (markdown)

Numbered priority list. Critical issues first, then warnings, then info.

Each recommendation is specific and actionable:
1. "Drop column `id` (constant, provides no signal)."
2. "Investigate leakage in `total_spend` (r=0.99 with target)."
3. "Apply log transform to `income` (skewness=3.2)."

## Step 4: Write the Notebook

Write to `./notebooks/data_health_{dataset_name}_{YYYY-MM-DD}.ipynb`.

Create the `./notebooks/` directory if it doesn't exist.

## Step 5: Report

Tell the user:
- Where the notebook was saved.
- The health score.
- List of critical issues (if any).
- Top 3 recommendations.
