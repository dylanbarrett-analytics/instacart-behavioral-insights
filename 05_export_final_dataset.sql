-- ============================================================================
-- FINAL EXPORT: Instacart Behavioral Buying Patterns
-- Goal: Merge product metrics and co-purchase patterns into a single table
--       for use in Tableau dashboard design.
-- ============================================================================

-- Set active schema context
SET search_path TO instacart;

-- From Step 5d
WITH product_repurchase_metrics AS (
	SELECT
		product_id,
		product_avg_repurchase_cycle,
		stddev_repurchase_cycle,
		ROUND(global_avg_repurchase_cycle - product_avg_repurchase_cycle, 2) AS repurchase_cycle_lift,
		ROUND((global_avg_repurchase_cycle - product_avg_repurchase_cycle) / NULLIF(stddev_repurchase_cycle, 0), 2) AS zscore_repurchase_cycle,
		number_of_repurchase_events
	FROM repurchase_lift_results
),

-- From Step 6d
product_order_metrics AS (
	SELECT
		product_id,
		avg_order_size,
		stddev_order_size,
		ROUND(avg_order_size - 10.09, 2) AS order_size_lift,
		ROUND((avg_order_size - 10.09) / NULLIF(stddev_order_size, 0), 2) AS zscore_order_size,
		number_of_orders
	FROM order_lift_results
),

-- Count how many unique orders each anchor appears in
anchor_order_counts AS (
	SELECT
		product_id AS anchor_id,
		COUNT(DISTINCT order_id) AS total_anchor_orders
	FROM order_products__prior
	GROUP BY product_id
),

-- Count how many orders each anchor-co-product pair appears in
co_purchase_counts AS (
	SELECT
		LEAST(a.product_id, b.product_id) AS anchor_id,
		GREATEST(a.product_id, b.product_id) AS co_product_id,
		COUNT(DISTINCT a.order_id) AS number_of_co_purchases
	FROM order_products__prior a
	JOIN order_products__prior b 
		ON a.order_id = b.order_id
		AND a.product_id < b.product_id
	GROUP BY LEAST(a.product_id, b.product_id), GREATEST(a.product_id, b.product_id)
	HAVING COUNT(DISTINCT a.order_id) >= 30
)

-- Master Table for Tableau use
SELECT
	cpc.anchor_id,
	p_anchor.product_name AS anchor_name,
	prm.repurchase_cycle_lift,
	prm.zscore_repurchase_cycle,
	prm.product_avg_repurchase_cycle,
	prm.stddev_repurchase_cycle,
	prm.number_of_repurchase_events,
	pom.order_size_lift,
	pom.zscore_order_size,
	pom.avg_order_size,
	pom.stddev_order_size,
	pom.number_of_orders,
	d.department,
	a.aisle,
	cpc.co_product_id,
	p_co.product_name AS co_product_name,
	cpc.number_of_co_purchases,
	aoc.total_anchor_orders,
	ROUND(100.0 * cpc.number_of_co_purchases / aoc.total_anchor_orders, 2) AS percent_anchor_orders
FROM co_purchase_counts cpc
JOIN anchor_order_counts aoc ON cpc.anchor_id = aoc.anchor_id
JOIN product_repurchase_metrics prm ON cpc.anchor_id = prm.product_id
JOIN product_order_metrics pom ON cpc.anchor_id = pom.product_id
JOIN products p_anchor ON cpc.anchor_id = p_anchor.product_id
JOIN products p_co ON cpc.co_product_id = p_co.product_id
JOIN departments d ON p_anchor.department_id = d.department_id
JOIN aisles a ON p_anchor.aisle_id = a.aisle_id
ORDER BY percent_anchor_orders DESC;