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
