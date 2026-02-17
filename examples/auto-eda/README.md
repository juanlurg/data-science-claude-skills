# auto-eda Example: EV Charging Station Usage

## Dataset

**File**: `data/ev_charging_sessions.csv`
**Records**: 2,003 | **Features**: 15

A synthetic dataset of electric vehicle charging sessions across 6 US cities
(Portland, Austin, Denver, Seattle, Nashville, Raleigh) from January 2024 to
June 2025.

### Columns

| Column | Type | Description |
|--------|------|-------------|
| `session_id` | int | Unique session identifier |
| `station_id` | str | Charging station (ST-001 to ST-025) |
| `city` | str | City where station is located |
| `timestamp` | datetime | Session start time |
| `duration_min` | float | Charging duration in minutes (right-skewed) |
| `energy_kwh` | float | Energy consumed (correlated with duration) |
| `vehicle_type` | str | EV make/model (9 categories) |
| `connector_type` | str | CCS, CHAdeMO, Tesla Supercharger, J1772 |
| `payment_method` | str | App, RFID Card, Credit Card, Free/Promotional |
| `temperature_c` | float | Ambient temperature (~8% missing) |
| `is_weekend` | bool | Whether session occurred on a weekend |
| `session_cost_usd` | float | Cost of the session |
| `battery_start_pct` | float | Battery level at start |
| `battery_end_pct` | float | Battery level at end |
| `user_rating` | float | 1-5 rating (~12% missing) |

### Built-in patterns for EDA discovery

- Right-skewed `duration_min` distribution
- Strong correlation between `energy_kwh` and `duration_min`
- Seasonal pattern in `temperature_c`
- Tesla vehicles predominantly use Tesla Supercharger connectors
- Missing data in `user_rating`, `temperature_c`, and `payment_method`
- A few outlier sessions with extreme duration or energy values

## Generated notebook

`notebooks/eda_ev_charging_sessions_2025-03-10.ipynb`

## Try it yourself

```
/data-science:auto-eda examples/auto-eda/data/ev_charging_sessions.csv
```
