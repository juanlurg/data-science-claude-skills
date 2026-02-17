-- Monthly revenue report with customer segments and product performance
-- This query has several optimization issues for demonstration purposes

SELECT *
FROM orders o
WHERE o.created_at >= '2024-01-01'
  AND o.created_at < '2025-01-01'
  AND o.status != 'cancelled'
  AND (SELECT COUNT(*)
       FROM order_items oi
       WHERE oi.order_id = o.id) > 0
  AND o.customer_id IN (
    SELECT c.id
    FROM customers c
    WHERE EXTRACT(YEAR FROM c.signup_date) >= 2020
      AND c.is_active = true
  )
ORDER BY o.created_at DESC;

-- Product category performance with running totals
SELECT
  p.category,
  p.subcategory,
  DATE_TRUNC('month', o.created_at) AS month,
  SUM(oi.quantity * oi.unit_price) AS revenue,
  COUNT(DISTINCT o.customer_id) AS unique_customers,
  (SELECT SUM(oi2.quantity * oi2.unit_price)
   FROM order_items oi2
   JOIN orders o2 ON o2.id = oi2.order_id
   JOIN products p2 ON p2.id = oi2.product_id
   WHERE p2.category = p.category
     AND o2.created_at <= DATE_TRUNC('month', o.created_at) + INTERVAL '1 month'
     AND o2.status != 'cancelled'
  ) AS running_total
FROM products p
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE o.status != 'cancelled'
  AND LOWER(p.category) != 'test'
GROUP BY p.category, p.subcategory, DATE_TRUNC('month', o.created_at)
ORDER BY p.category, month;

-- Customer lifetime value with recency scoring
SELECT
  c.id,
  c.email,
  c.name,
  c.signup_date,
  COALESCE(
    (SELECT SUM(o.total_amount)
     FROM orders o
     WHERE o.customer_id = c.id
       AND o.status != 'cancelled'),
    0
  ) AS lifetime_value,
  COALESCE(
    (SELECT COUNT(*)
     FROM orders o
     WHERE o.customer_id = c.id
       AND o.status != 'cancelled'),
    0
  ) AS total_orders,
  COALESCE(
    (SELECT MAX(o.created_at)
     FROM orders o
     WHERE o.customer_id = c.id),
    c.signup_date
  ) AS last_order_date,
  CASE
    WHEN (SELECT MAX(o.created_at) FROM orders o WHERE o.customer_id = c.id)
         >= NOW() - INTERVAL '30 days' THEN 'Active'
    WHEN (SELECT MAX(o.created_at) FROM orders o WHERE o.customer_id = c.id)
         >= NOW() - INTERVAL '90 days' THEN 'At Risk'
    ELSE 'Churned'
  END AS segment
FROM customers c
WHERE c.is_active = true
ORDER BY lifetime_value DESC;
