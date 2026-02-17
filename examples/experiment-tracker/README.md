# experiment-tracker Example: Used Car Price Prediction

## Experiment data

**File**: `experiments/tracker.json`
**Runs**: 8 | **Task**: Regression (predict used car price)

A set of 8 simulated ML experiment runs showing a realistic progression from
a simple baseline to a tuned gradient boosting model.

### Run progression

| Run | Model | R² | MAE | Training time |
|-----|-------|----|-----|---------------|
| 1 | LinearRegression | 0.621 | $3,842 | 0.8s |
| 2 | Ridge | 0.631 | $3,798 | 1.1s |
| 3 | RandomForest (default) | 0.866 | $2,157 | 12.4s |
| 4 | RandomForest (tuned) | 0.885 | $1,987 | 58.3s |
| 5 | GradientBoosting | 0.899 | $1,846 | 34.7s |
| 6 | XGBoost | 0.923 | $1,612 | 22.1s |
| 7 | LightGBM | 0.926 | $1,578 | 8.9s |
| 8 | LightGBM (tuned) | 0.930 | $1,535 | 15.2s |

### Key storyline

- Runs 1-2: Linear baselines establish floor
- Run 3: Tree model gives a big jump (+0.23 R²)
- Runs 4-5: Tuning and gradient boosting squeeze out more
- Run 6: XGBoost with log-target transform breaks 0.92
- Runs 7-8: LightGBM matches XGBoost quality at 2.5x less training time

## Generated notebook

`notebooks/leaderboard_used_cars_2025-03-13.ipynb`

## Try it yourself

```
/data-science:experiment-tracker leaderboard
/data-science:experiment-tracker compare 6 7 8
```
