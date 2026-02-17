---
name: sql-optimizer
description: Analyzes SQL queries and generates an optimization report notebook with explanations, identified issues, and rewritten queries. Use when the user wants to optimize, explain, improve, or debug a SQL query, or mentions query performance, slow queries, or SQL optimization.
argument-hint: <query-or-file> [--dialect bigquery|postgresql]
---

# SQL Optimizer

## Input

Parse `$ARGUMENTS` for:

- **Query source** — one of:
  - Inline SQL query (if the argument looks like SQL).
  - Path to a `.sql` file.
  - If neither provided, ask the user to paste the query.
- **`--dialect`** flag — optional. Values: `bigquery`, `postgresql`.

### Dialect Auto-Detection

If `--dialect` is not specified, auto-detect from SQL syntax:

- Backtick identifiers (`` `project.dataset.table` ``) → **BigQuery**
- `::` type casts (e.g., `column::integer`) → **PostgreSQL**
- `SAFE_DIVIDE`, `STRUCT`, `UNNEST(ARRAY)` → **BigQuery**
- `LATERAL JOIN`, `DISTINCT ON`, `ILIKE` → **PostgreSQL**
- `PARTITION BY` in DDL context → could be either, default to **PostgreSQL**
- If unclear, ask the user.

## Step 1: Analyze the Query

Parse and understand the query:
- Identify all tables, joins, subqueries.
- Trace the execution flow.
- Identify potential performance issues.
- Note the query's intent (what business question it answers).

## Step 2: Generate the Notebook

Follow [notebook-format.md](../../lib/notebook-format.md) for structure.

### Section 1: Header (markdown)

```
# SQL Query Analysis

*Generated on {YYYY-MM-DD} by sql-optimizer skill*
*Dialect: {detected_dialect}*
```

### Section 2: Original Query (code)

The input query, formatted with proper indentation. Display in a code cell:

```python
query = """
SELECT
    c.segment,
    COUNT(*) AS order_count,
    SUM(o.amount) AS total_spend
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.order_date >= '2025-01-01'
GROUP BY c.segment
ORDER BY total_spend DESC
"""
print(query)
```

### Section 3: Query Explanation (markdown)

Plain-English walkthrough of what the query does:

```
This query:
1. Joins `orders` with `customers` on `customer_id`.
2. Filters for orders from January 2025 onward.
3. Groups by customer segment.
4. Calculates total order count and spend per segment.
5. Returns segments sorted by highest total spend.
```

### Section 4: Execution Flow (markdown)

Step-by-step order of operations as the database engine processes it:

```
1. **FROM** `orders o` — scan orders table (~N rows estimated)
2. **JOIN** `customers c` ON `o.customer_id = c.id` — hash join
3. **WHERE** `o.order_date >= '2025-01-01'` — filter rows
4. **GROUP BY** `c.segment` — aggregate into groups
5. **SELECT** — compute COUNT(*) and SUM(o.amount)
6. **ORDER BY** `total_spend DESC` — sort results
7. **LIMIT** — (none specified, returns all groups)
```

Note at each stage what the data volume looks like, if inferable.

### Section 5: Identified Issues (markdown)

Table with columns: **Severity**, **Issue**, **Location**, **Impact**.

**Critical issues:**
- Correlated subqueries (N+1 execution pattern).
- `SELECT *` (unnecessary data transfer, especially in columnar stores).
- Full table scans on large tables (missing WHERE on partition column).
- Cartesian joins (missing or incorrect JOIN condition).

**Warning issues:**
- Implicit type casts (e.g., comparing string to int).
- Functions on indexed columns in WHERE (prevents index usage).
- Missing `LIMIT` on exploratory queries.
- Redundant subqueries that could be CTEs or JOINs.
- `ORDER BY` without `LIMIT` (sorts entire result set).

**Info issues:**
- Style improvements (consistent aliasing, indentation).
- Readability suggestions (CTEs vs nested subqueries).
- Aliasing recommendations.

### Section 6: Optimized Query (code)

The rewritten query with inline comments explaining each change:

```sql
-- Changed: SELECT * → explicit columns (reduces data scanned)
SELECT
    c.segment,
    COUNT(*) AS order_count,
    SUM(o.amount) AS total_spend
-- Changed: implicit join → explicit JOIN (clearer intent)
FROM orders o
INNER JOIN customers c ON o.customer_id = c.id
-- Added: partition filter for BigQuery cost control
WHERE o.order_date >= '2025-01-01'
GROUP BY c.segment
ORDER BY total_spend DESC
-- Added: LIMIT for safety
LIMIT 1000
```

### Section 7: Dialect-Specific Tips (markdown)

Based on the detected dialect, reference the appropriate tips file and include the 3-5 most relevant tips for the specific query:

- For BigQuery: see [bigquery-tips.md](reference/bigquery-tips.md)
- For PostgreSQL: see [postgresql-tips.md](reference/postgresql-tips.md)

Select tips that are specifically relevant to patterns found in the analyzed query — not generic advice.

## Step 3: Write the Notebook

Write to `./notebooks/sql_optimization_{YYYY-MM-DD}.ipynb`.

Create the `./notebooks/` directory if it doesn't exist.

## Step 4: Report

Tell the user:
- Where the notebook was saved.
- Number of issues found by severity.
- The single most impactful optimization.
