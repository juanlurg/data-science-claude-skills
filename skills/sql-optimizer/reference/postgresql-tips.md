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
