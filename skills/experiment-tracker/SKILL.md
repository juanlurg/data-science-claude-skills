---
name: experiment-tracker
description: Logs ML experiment runs, generates leaderboards, and compares experiments locally using JSON and notebooks. Use when the user wants to track, log, compare, or view ML experiments, model runs, or training results.
argument-hint: <log|leaderboard|compare> [options]
---

# Experiment Tracker

## Input

`$ARGUMENTS` specifies the operation. Detect which operation from the arguments and conversation context:

- `log` — Log a new experiment run.
- `leaderboard` — Generate a leaderboard notebook.
- `compare` — Compare specific runs side-by-side.

If the operation is unclear, ask the user.

## Storage

All experiment data is stored in:

```
experiments/
  tracker.json     # Array of run objects
  leaderboard.ipynb
```

Create the `experiments/` directory if it doesn't exist.

---

## Operation 1: Log a Run

### Step 1: Extract Run Details

From the conversation context, extract:
- **model**: Model name/type (e.g., "RandomForest", "XGBoost").
- **params**: Dictionary of hyperparameters (e.g., `{"n_estimators": 100, "max_depth": 5}`).
- **metrics**: Dictionary of evaluation metrics (e.g., `{"accuracy": 0.92, "f1": 0.89}`).
- **notes**: Optional free-text notes.

If not enough information is available, ask the user for the missing details.

### Step 2: Read Existing Tracker

Read `experiments/tracker.json`. If it doesn't exist, initialize as `[]`.

### Step 3: Generate Run Entry

- `run_id`: max existing run_id + 1, or 1 if empty.
- `timestamp`: current ISO 8601 datetime.
- `script_hash`: if a training script is identifiable in the conversation context, compute:

```bash
python -c "import hashlib; print(hashlib.sha256(open('SCRIPT_PATH').read().encode()).hexdigest()[:12])"
```

Otherwise set to `null`.

### Step 4: Append and Write

Append the run entry to the array:

```json
{
  "run_id": 1,
  "timestamp": "2026-02-17T10:30:00Z",
  "model": "RandomForest",
  "params": {"n_estimators": 100, "max_depth": 5},
  "metrics": {"accuracy": 0.92, "f1": 0.89},
  "script_hash": "abc123def456",
  "notes": "Baseline model"
}
```

Write back to `experiments/tracker.json` (pretty-printed with 2-space indent).

### Step 5: Confirm

Tell the user: "Run #N logged. Metrics: {summary of metrics}."

---

## Operation 2: Show Leaderboard

### Step 1: Read Tracker

Read `experiments/tracker.json`. If empty or missing, tell user no runs are logged yet.

### Step 2: Determine Sort Metric

Ask the user which metric to sort by, or detect from context. If only one metric exists across all runs, use that.

### Step 3: Generate Notebook

Follow [notebook-format.md](../../lib/notebook-format.md). Detect environment per [environment-detection.md](../../lib/environment-detection.md) for pandas dependency.

**Notebook sections:**

**Header (markdown):**
```
# Experiment Leaderboard
*Generated on {YYYY-MM-DD} by experiment-tracker skill*
*Sorted by: {metric_name}*
```

**Load Data (code):**
```python
import pandas as pd
import matplotlib.pyplot as plt
import json

with open('experiments/tracker.json') as f:
    runs = json.load(f)

df = pd.json_normalize(runs)
print(f"Total runs: {len(df)}")
```

**Leaderboard Table (code):**
- Styled DataFrame sorted by the chosen metric (descending).
- Highlight the best run.

**Comparison Chart (code):**
- Bar chart comparing top runs on the chosen metric.
- `plt.tight_layout()` and `plt.show()`.

**Summary (markdown):**
- Best run: model, params, metrics.
- Worst run: model, params, metrics.
- Improvement over time (first run vs best run).

### Step 4: Write Notebook

Write to `experiments/leaderboard.ipynb`.

Tell the user where the notebook was saved.

---

## Operation 3: Compare Runs

### Step 1: Identify Runs

User specifies 2+ run IDs (e.g., `compare 1 3 5`). Extract from `$ARGUMENTS`.

### Step 2: Read and Filter

Read `experiments/tracker.json`. Filter to the specified run IDs. If any ID is not found, tell the user.

### Step 3: Generate Comparison

Generate a notebook or add to the leaderboard notebook. Follow [notebook-format.md](../../lib/notebook-format.md).

**Notebook sections:**

**Header (markdown):**
```
# Experiment Comparison: Runs {ids}
*Generated on {YYYY-MM-DD}*
```

**Side-by-Side Table (code):**
- DataFrame with runs as columns, params and metrics as rows.
- Highlight differences between runs.

**Metrics Comparison Chart (code):**
- Grouped bar chart showing all metrics for each run.
- `plt.tight_layout()` and `plt.show()`.

**Diff Summary (markdown):**
- Which parameters changed between runs.
- Which run performed best on each metric.
- Recommendation based on trade-offs.

### Step 4: Write Notebook

Write to `experiments/comparison_{run_ids}_{YYYY-MM-DD}.ipynb`.

Tell the user where the notebook was saved.
