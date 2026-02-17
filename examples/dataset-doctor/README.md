# dataset-doctor Example: Food Delivery Customer Churn

## Dataset

**Files**: `data/food_delivery_churn_train.csv` (1,500 rows) + `data/food_delivery_churn_test.csv` (500 rows)
**Target**: `churned` (binary)

A synthetic dataset for predicting customer churn on a food delivery platform,
with **intentional data quality issues** designed to showcase the dataset-doctor
skill.

### Intentional quality issues

| Issue | Type | Where |
|-------|------|-------|
| Data leakage | Critical | `cancellation_rate` correlates r > 0.95 with `churned` |
| Class imbalance | Critical | ~88/12 train, ~85/15 test |
| Distribution drift | Critical | `avg_delivery_time_min` mean ~35 (train) vs ~42 (test) |
| Missing values | Warning | `satisfaction_score` ~15%, `avg_order_value` ~8% |
| Duplicate rows | Warning | 15-20 duplicates in training set |
| Mixed dtypes | Warning | `has_saved_payment` mixes True/False with "Yes"/"No" |
| Dirty strings | Warning | Trailing spaces in some `city` values |
| Near-constant column | Info | `platform` is "iOS" 98% of the time |

### Columns

| Column | Type | Description |
|--------|------|-------------|
| `customer_id` | int | Unique customer identifier |
| `signup_months_ago` | int | Months since signup |
| `city` | str | Customer city (5 values, some with trailing spaces) |
| `subscription_tier` | str | Free, Basic, or Premium |
| `avg_order_value` | float | Average order value in USD (~8% missing) |
| `orders_last_30d` | int | Orders in last 30 days |
| `orders_last_90d` | int | Orders in last 90 days |
| `avg_delivery_time_min` | float | Average delivery time (drifts between splits) |
| `support_tickets_last_90d` | int | Support tickets filed |
| `app_sessions_last_30d` | int | App sessions in last 30 days |
| `discount_usage_pct` | float | Percentage of orders using discounts |
| `preferred_cuisine` | str | Most ordered cuisine type |
| `has_saved_payment` | mixed | Boolean with mixed string values |
| `last_order_days_ago` | int | Days since last order |
| `lifetime_value_usd` | float | Total spend |
| `satisfaction_score` | float | 1-5 rating (~15% missing) |
| `referral_count` | int | Referrals made |
| `cancellation_rate` | float | LEAKAGE — highly correlated with target |
| `platform` | str | Near-constant ("iOS" 98%) |
| `churned` | int | Target variable (0 or 1) |

## Generated notebook

`notebooks/data_health_food_delivery_churn_2025-03-12.ipynb`

## Try it yourself

```
/data-science:dataset-doctor examples/dataset-doctor/data/food_delivery_churn_train.csv examples/dataset-doctor/data/food_delivery_churn_test.csv --target churned
```
