# sql-optimizer Example: E-commerce Analytics (PostgreSQL)

## Input query

**File**: `queries/ecommerce_analytics.sql`
**Dialect**: PostgreSQL
**Queries**: 3

Three analytics queries against an e-commerce schema (`orders`, `order_items`,
`customers`, `products`) with intentional performance anti-patterns.

### Query 1 — Order filtering

Issues: `SELECT *`, correlated subquery in WHERE, `IN (SELECT ...)` anti-pattern

### Query 2 — Product category performance with running totals

Issues: correlated subquery for running total (should be a window function),
`LOWER()` function call preventing index usage

### Query 3 — Customer lifetime value with recency scoring

Issues: 5 correlated subqueries in SELECT (same table scanned 5 times),
repeated `MAX(created_at)` subquery in CASE branches

## Issue summary

| Severity | Count |
|----------|-------|
| Critical | 4 |
| Warning | 4 |
| Info | 3 |

## Generated notebook

`notebooks/sql_optimization_2025-03-14.ipynb`

## Try it yourself

```
/data-science:sql-optimizer examples/sql-optimizer/queries/ecommerce_analytics.sql --dialect postgresql
```
