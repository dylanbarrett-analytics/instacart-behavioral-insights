-- ================================================================================
-- File: 04_analysis_queries.sql
-- Project: Instacart Behavioral Buying Patterns
-- Author: Dylan Barrett
-- Last Updated: May 25, 2025
--
-- Description:
-- This script contains all major SQL steps used to analyze customer behavior
-- within the Instacart dataset. Topics include repurchase cycles, order size,
-- and co-purchase patterns — with statistical metrics such as behavioral lift, z-score,
-- and standard deviation.
--
-- Key Metrics:
-- - Behavioral Lift: The difference between a product’s average and the global average 
--   (e.g., for repurchase cycle or order size). Quantifies the behavioral deviation from the norm.
-- - Standard Deviation: Measures variability from the average. A lower value means more consistent behavior among data points.
-- - Z-score: Standardized lift value (lift ÷ std dev). Shows how consistently a product’s behavior deviates from the average.
-- Note: "Repurchase Cycle" is labeled as "Reorder Speed" in the final dashboard.
-- Note: A "repurchase event" refers to an individual order in which a product was repurchased (i.e., not a customer's first purchase of that product).

-- Steps Included:
-- - Step 5: Repurchase Cycle Analysis
-- - Step 6: Order Size Analysis
-- - Step 7: Co-Purchase Behavior Analysis
-- ================================================================================

-- Set active schema context
SET search_path TO instacart;

-- --------------------------------------------------------------------------------
-- Step 5a: Global Average Repurchase Cycle
-- Goal: Establish a behavioral benchmark for how quickly customers reorder in general
-- Logic:
-- - Use orders table
-- - Filter out first-time orders (where days_since_prior_order is NULL)
-- - Calculate the global average of days_since_prior_order (i.e. the average for the entire dataset)
-- --------------------------------------------------------------------------------
-- Calculate the average number of days between any two orders across all customers (excluding first-time orders)
SELECT
	ROUND(AVG(days_since_prior_order)::numeric,2) AS global_avg_repurchase_cycle
FROM orders
WHERE days_since_prior_order IS NOT NULL;

-- --------------------------------------------------------------------------------
-- Step 5b: Average Repurchase Cycle by Product
-- Goal: Identify products that are repurchased most quickly, indicating strong habit formation
-- Logic:
-- - Join orders and prior product data
-- - Filter out first-time orders
-- - Filter out products with less than 30 repurchase events for statistical stability (as per Central Limit Theorem)
-- - Group by product to calculate average repurchase cycle (in days) for each product
-- - Count number of repurchase events for each product for further story context
-- --------------------------------------------------------------------------------
-- Link each product to its days_since_prior_order value
WITH product_repurchase_cycles AS (
	SELECT
		product_id,
		days_since_prior_order
	FROM orders o
	JOIN order_products__prior opp ON o.order_id = opp.order_id
	WHERE days_since_prior_order IS NOT NULL
),

-- Calculate average repurchase cycle and count of repurchase events for each product
product_avg_cycles AS (
	SELECT
		product_id,
		ROUND(AVG(days_since_prior_order)::numeric,2) AS product_avg_repurchase_cycle,
		COUNT(*) AS number_of_repurchase_events
	FROM product_repurchase_cycles
	GROUP BY product_id
)

-- Display average repurchase cycles and the number of repurchase events for all qualifying products
SELECT
	pac.product_id,
	product_name,
	product_avg_repurchase_cycle,
	number_of_repurchase_events
FROM product_avg_cycles pac
JOIN products p ON pac.product_id = p.product_id
WHERE number_of_repurchase_events >= 30
ORDER BY product_avg_repurchase_cycle ASC;

-- --------------------------------------------------------------------------------
-- Step 5c: Average Repurchase Cycle by Department (Event-Based)
-- Goal: Summarize customer repurchase behavior at the department level
-- Logic:
-- - Join orders and prior products with product info and department info (3 joins)
-- - Filter out first-time orders
-- - Group by department
-- - Filter out departments with less than 30 repurchase events for statistical stability
-- --------------------------------------------------------------------------------
-- Calculate average repurchase cycle and count of repurchase events for each department
WITH department_repurchase_cycles AS (
	SELECT
		department,
		ROUND(AVG(days_since_prior_order)::numeric,2) AS department_avg_repurchase_cycle,
		COUNT(*) AS number_of_repurchase_events
	FROM orders o
	JOIN order_products__prior opp ON o.order_id = opp.order_id
	JOIN products p ON opp.product_id = p.product_id
	JOIN departments d ON p.department_id = d.department_id
	WHERE days_since_prior_order IS NOT NULL
	GROUP BY department
)

-- Display average repurchase cycles and the number of repurchase events for all qualifying departments
SELECT
	department,
	department_avg_repurchase_cycle,
	number_of_repurchase_events
FROM department_repurchase_cycles
WHERE number_of_repurchase_events >= 30
ORDER BY department_avg_repurchase_cycle ASC;

-- --------------------------------------------------------------------------------
-- Step 5d: Repurchase Cycle Lift by Product
-- Goal: Calculate how each product's average repurchase cycle compares to the global average
-- Logic:
-- - Use product-level averages (from Step 5b)
-- - Join to global average (from Step 5a)
-- - Subtract product's average from global average to compute "lift" (lower value = faster repurchase)
-- - Find standard deviation to see variability among repurchases
-- - Calculate z-score to standardize repurchase cycle lift for easier comparison across all products
-- --------------------------------------------------------------------------------
-- Save product-level repurchase cycle lift and z-score results to table for later use in Tableau
CREATE TABLE repurchase_lift_results AS

-- Calculate global average repurchase cycle across all orders in dataset
WITH global_avg AS (
	SELECT
		ROUND(AVG(days_since_prior_order)::numeric,2) AS global_avg_repurchase_cycle
	FROM orders
	WHERE days_since_prior_order IS NOT NULL
),

-- Map each product to its days_since_prior_order value (one row per event)
product_repurchase_cycles AS (
	SELECT
		product_id,
		days_since_prior_order
	FROM orders o
	JOIN order_products__prior opp ON o.order_id = opp.order_id
	WHERE days_since_prior_order IS NOT NULL
),

-- Calculate average repurchase cycle, standard deviation, and number of repurchase events for each product
product_avg_cycles AS (
	SELECT
		product_id,
		ROUND(AVG(days_since_prior_order)::numeric,2) AS product_avg_repurchase_cycle,
		ROUND(STDDEV_POP(days_since_prior_order)::numeric,2) AS stddev_repurchase_cycle,
		COUNT(*) AS number_of_repurchase_events
	FROM product_repurchase_cycles
	GROUP BY product_id
),

-- Compare product-level averages to global average, and compute lift + z-score for each product
product_lift AS (
	SELECT
		pac.product_id,
		product_name,
		product_avg_repurchase_cycle,
		stddev_repurchase_cycle,
		global_avg_repurchase_cycle,
		ROUND(global_avg_repurchase_cycle - product_avg_repurchase_cycle,2) AS repurchase_cycle_lift,
		ROUND((global_avg_repurchase_cycle - product_avg_repurchase_cycle) / NULLIF(stddev_repurchase_cycle,0),2) AS zscore_repurchase_cycle, 
		number_of_repurchase_events
	FROM product_avg_cycles pac
	JOIN global_avg ga ON TRUE	-- cross join
	JOIN products p ON pac.product_id = p.product_id
	WHERE number_of_repurchase_events >= 30
)

-- Final product-level repurchase cycle results
SELECT *
FROM product_lift
ORDER BY repurchase_cycle_lift DESC;

-- --------------------------------------------------------------------------------
-- Step 5e: Repurchase Cycle Lift by Department
-- Goal: Compare department-level average repurchase cycles to the global average
-- Logic:
-- - Use department-level averages from Step 5c
-- - Join to global average (from Step 5a)
-- - Subtract department's average from global average to compute "lift" (lower value = faster repurchase)
-- --------------------------------------------------------------------------------
-- Calculate global average repurchase cycle across all orders in dataset
WITH global_avg AS (
	SELECT
		ROUND(AVG(days_since_prior_order)::numeric,2) AS global_avg_repurchase_cycle
	FROM orders
	WHERE days_since_prior_order IS NOT NULL
),

-- Calculate average repurchase cycle and number of repurchase events for each department
department_repurchase_cycles AS (
	SELECT
		department,
		ROUND(AVG(days_since_prior_order)::numeric,2) AS department_avg_repurchase_cycle,
		COUNT(*) AS number_of_repurchase_events
	FROM orders o
	JOIN order_products__prior opp ON o.order_id = opp.order_id
	JOIN products p ON opp.product_id = p.product_id
	JOIN departments d ON p.department_id = d.department_id
	WHERE days_since_prior_order IS NOT NULL
	GROUP BY department
),

-- Compare department-level averages to global average, and compute lift for each department
department_lift AS (
	SELECT
		department,
		department_avg_repurchase_cycle,
		global_avg_repurchase_cycle,
		ROUND(global_avg_repurchase_cycle - department_avg_repurchase_cycle,2) AS repurchase_cycle_lift,
		number_of_repurchase_events
	FROM department_repurchase_cycles drc
	JOIN global_avg ON TRUE
	WHERE number_of_repurchase_events >= 30
)

-- Final department-level repurchase cycle results
SELECT *
FROM department_lift
ORDER BY repurchase_cycle_lift DESC;

-- --------------------------------------------------------------------------------
-- Step 6a: Global Average Order Size
-- Goal: Establish a benchmark for how much customers reorder across the entire dataset
-- Logic:
-- - Count items (a.k.a. products) for each order_id using order_products__prior
-- - Average those counts to find global average order size
-- Note: For the sake of brevity, "repurchase events" are referred to as "orders" through the duration of Step 6
-- --------------------------------------------------------------------------------
-- Count number of items for each order (i.e., order size)
WITH order_sizes AS (
	SELECT
		order_id,
		COUNT(*) AS order_size
	FROM order_products__prior
	GROUP BY order_id
)

-- Calculate average order size across all orders
SELECT
	ROUND(AVG(order_size)::numeric,2) AS global_avg_order_size
FROM order_sizes;

-- --------------------------------------------------------------------------------
-- Step 6b: Average Order Size by Product
-- Goal: Measure the average number of products in an order whenever a particular product appears in said order
-- Logic:
-- - Use order_products__prior to get order-product relationships
-- - Find order size for every order
-- - Link these order sizes to each product
-- - Group by product_id to find average order size for each 
-- - Filter out products with less than 30 orders for statistical stability
-- --------------------------------------------------------------------------------
-- Count number of items for each order (i.e., order size)
WITH order_sizes AS (
	SELECT
		order_id,
		COUNT(*) AS order_size
	FROM order_products__prior
	GROUP BY order_id
),

-- Link products to orders (to create unique product-order combinations)
unique_product_orders AS (
	SELECT
		product_id,
		order_id
	FROM order_products__prior
	GROUP BY product_id, order_id
),

-- Link each product to the size of the order it appeared in (to create product-order size pairings)
product_order_behavior AS (
	SELECT
		product_id,
		order_size
	FROM unique_product_orders upo
	JOIN order_sizes os ON upo.order_id = os.order_id
),

-- Calculate average order size and number of orders for each product
average_order_size_by_product AS (
	SELECT
		pbb.product_id,
		p.product_name,
		ROUND(AVG(order_size)::numeric,2) AS avg_order_size,
		COUNT(*) AS number_of_orders
	FROM product_order_behavior pob
	JOIN products p ON pob.product_id = p.product_id
	GROUP BY pob.product_id, p.product_name
)

-- Final product-level order size results
SELECT *
FROM average_order_size_by_product
WHERE number_of_orders >= 30
ORDER BY avg_order_size DESC;

-- --------------------------------------------------------------------------------
-- Step 6c: Average Order Size by Department
-- Goal: Measure the average number of items in an order that includes at least one product from each department
-- Logic:
-- - Find order size for every order
-- - Link these order sizes to each product, and then to each department
-- - Group by department to find average order size for each department
-- - Filter out departments with less than 30 orders for statistical stability
-- --------------------------------------------------------------------------------
-- Count number of items for each order (i.e., order size)
WITH order_sizes AS (
	SELECT
		order_id,
		COUNT(*) AS order_size
	FROM order_products__prior
	GROUP BY order_id
),

-- Link products to orders (to create unique product-order combinations)
unique_product_orders AS (
	SELECT
		product_id,
		order_id
	FROM order_products__prior
	GROUP BY product_id, order_id
),

-- Link each product and its respective department to the size of the order it appeared in
product_order_behavior AS (
	SELECT
		upo.product_id,
		department_id,
		order_size
	FROM unique_product_orders upo
	JOIN products p ON upo.product_id = p.product_id
	JOIN order_sizes os ON upo.order_id = os.order_id
),

-- Calculate average order size and number of orders for each department
average_order_size_by_department AS (
	SELECT
		department,
		ROUND(AVG(basket_size)::numeric,2) AS avg_order_size,
		COUNT(*) AS number_of_orders
	FROM product_order_behavior pob
	JOIN departments d ON pob.department_id = d.department_id
	GROUP BY department
)

-- Final department-level order size results
SELECT *
FROM average_order_size_by_department
WHERE number_of_orders >= 30
ORDER BY avg_order_size DESC;

-- --------------------------------------------------------------------------------
-- Step 6d: Order Size Lift by Product
-- Goal: Calculate how each product's average order size compares to the global average
-- Logic:
-- - Use product-level averages from Step 6b
-- - Join to global average (from Step 6a)
-- - Subtract global average from each product's average to compute "lift" (positive = larger order size)
-- - Find standard deviation to see variability among order sizes 
-- - Calculate z-score to standardize order size lift for easier comparisons across all products
-- --------------------------------------------------------------------------------
-- Save product-level order size lift and z-score results to table for later use in Tableau
CREATE TABLE order_lift_results AS

-- Reference global average order size across all orders in dataset (from Step 6a)
-- There is no need to calculate it again
WITH global_avg AS (
	SELECT
		10.09::numeric AS global_avg_order_size
),

-- Count number of items for each order (i.e., order size)
order_sizes AS (
	SELECT
		order_id,
		COUNT(*) AS order_size
	FROM order_products__prior
	GROUP BY order_id
),

-- Link products to orders (to create unique product-order combinations)
unique_product_orders AS (
	SELECT
		order_id,
		product_id
	FROM order_products__prior
	GROUP BY order_id, product_id
),

-- Link each product to the size of the order it appeared in (to create product-order size pairings)
product_order_behavior AS (
	SELECT
		product_id,
		order_size
	FROM unique_product_orders upo
	JOIN order_sizes os ON upo.order_id = os.order_id
),

-- Calculate average order size, standard deviation, and number of orders for each product
average_order_size_by_product AS (
	SELECT
		pob.product_id,
		product_name,
		ROUND(AVG(order_size)::numeric,2) AS avg_order_size,
		ROUND(STDDEV_POP(order_size)::numeric,2) AS stddev_order_size,
		COUNT(*) AS number_of_orders
	FROM product_order_behavior pob
	JOIN products p ON pob.product_id = p.product_id
	GROUP BY pob.product_id, product_name
	HAVING COUNT(*) >= 30
)

-- Compare product-level averages to global average, and compute lift + z-score for each product
-- Final product-level order size results
SELECT
	product_id,
	product_name,
	avg_order_size,
	stddev_order_size,
	ROUND(avg_order_size - global_avg_order_size,2) AS order_size_lift,
	ROUND((avg_order_size - global_avg_order_size) / NULLIF(stddev_order_size,0),2) AS zscore_order_size,
	number_of_orders
FROM average_order_size_by_product
JOIN global_avg ON TRUE
ORDER BY order_size_lift DESC;

-- --------------------------------------------------------------------------------
-- Step 6e: Order Size Lift by Department
-- Goal: Compare department-level average order sizes to the global average
-- Logic:
-- - Use department-level averages from Step 6c
-- - Join to global average (from Step 6a)
-- - Subtract global average from department's average to compute "lift" (positive = larger order size)
-- --------------------------------------------------------------------------------
-- Reference global average order size across all orders in dataset (from Step 6a)
WITH global_avg AS (
	SELECT
		10.09::numeric AS global_avg_order_size
),

-- Count number of items for each order (i.e., order size)
order_sizes AS (
	SELECT
		order_id,
		COUNT(*) AS order_size
	FROM order_products__prior
	GROUP BY order_id
),

-- Link each department to the size of the order it appeared in (to create department-order size pairings)
department_order_behavior AS (
	SELECT
		department,
		order_size
	FROM order_sizes os
	JOIN order_products__prior opp ON os.order_id = opp.order_id
	JOIN products p ON opp.product_id = p.product_id
	JOIN departments d ON p.department_id = d.department_id
),

-- Calculate average order size and number of orders for each department
avg_order_size_by_department AS (
	SELECT
		department,
		ROUND(AVG(order_size)::numeric,2) AS avg_order_size,
		COUNT(*) AS number_of_orders
	FROM department_order_behavior
	GROUP BY department
	HAVING COUNT(*) >= 30
)

-- Compare department-level averages to global average, and compute lift for each department
-- Final department-level order size results
SELECT
	department,
	avg_order_size,
	ROUND(avg_order_size - global_avg_order_size,2) AS order_size_lift,
	number_of_orders
FROM avg_order_size_by_department
JOIN global_avg ON TRUE
ORDER BY order_size_lift DESC;
	
-- --------------------------------------------------------------------------------
-- Step 7a: Identify Co-Purchased Product Pairs
-- Goal: Detect which product pairs most frequently appear together in the same order.
-- Logic:
-- - Use a self-join on order_products__prior to pair products from the same order
-- - Use LEAST/GREATEST to prevent duplicate flips (e.g., Apple–Banana vs. Banana–Apple)
-- - Exclude self-pair duplicates (e.g., Apple–Apple)
-- - Aggregate by product pair and count how frequently these pairs occur
-- - Filter out pairs with less than 30 co-occurrences for statistical stability
-- Note: A "product pair" consists of an "anchor" (the main product) and its "co-product" (any other product that appears in the same order as the "anchor")
-- --------------------------------------------------------------------------------
-- Find all unique product pairs
WITH co_purchases AS (
	SELECT
		LEAST(a.product_id, b.product_id) AS anchor_id,		
		GREATEST(a.product_id, b.product_id) AS co_product_id,
		COUNT(*) AS number_of_product_pairs
	FROM order_products__prior a
	JOIN order_products__prior b 
		ON a.order_id = b.order_id
		AND a.product_id < b.product_id
	GROUP BY anchor_id, co_product_id
	HAVING COUNT(*) >= 30
)

-- Attach product names and display the top co-purchased product pairs
SELECT
	cp.anchor_id,
	p1.product_name AS anchor_name,
	cp.co_product_id,
	p2.product_name AS co_product_name,
	cp.number_of_product_pairs
FROM co_purchases cp
JOIN products p1 ON cp.anchor_id = p1.product_id
JOIN products p2 ON cp.co_product_id = p2.product_id
ORDER BY cp.number_of_product_pairs DESC;

-- --------------------------------------------------------------------------------
-- Step 7b: Percentage of Anchor Orders Containing Each Co-Purchased Product
-- Goal: For each anchor–co-product pair, calculate how frequently they appear together,
--       expressed as a percentage of the anchor's total orders.
-- Logic:
-- - Count the number of unique orders each anchor appears in
-- - Count the number of unique orders that contain both the anchor and co-product
-- - Divide co-occurrence count by total anchor orders to find co-purchase percentage for each product pair
-- - Filter out pairs with less than 30 co-occurrences for statistical stability
-- --------------------------------------------------------------------------------
-- Count how many unique orders each anchor appears in
WITH anchor_order_counts AS (
	SELECT
		product_id AS anchor_id,
		COUNT(DISTINCT order_id) AS total_anchor_orders
	FROM order_products__prior
	GROUP BY product_id
),

-- Count how many orders each anchor-co-product pair appears in
co_purchase_counts AS (
	SELECT
		a.product_id AS anchor_id,
		b.product_id AS co_product_id,
		COUNT(DISTINCT a.order_id) AS number_of_co_purchases
	FROM order_products__prior a
	JOIN order_products__prior b ON a.order_id = b.order_id
									AND a.product_id < b.product_id
	GROUP BY a.product_id, b.product_id
	HAVING COUNT(DISTINCT a.order_id) >= 30
)

-- Include number of co-purchases (numerator) and total anchor orders (denominator). Divide to find co-purchase % for every product pair
SELECT
	cpc.anchor_id,
	p1.product_name AS anchor_name,
	cpc.co_product_id,
	p2.product_name AS co_product_name,
	number_of_co_purchases,
	total_anchor_orders,
	ROUND((100.0 * number_of_co_purchases / total_anchor_orders),2) AS percentage_of_anchor_orders
FROM co_purchase_counts cpc
JOIN anchor_order_counts aoc ON cpc.anchor_id = aoc.anchor_id
JOIN products p1 ON cpc.anchor_id = p1.product_id
JOIN products p2 ON cpc.co_product_id = p2.product_id
ORDER BY percentage_of_anchor_orders DESC;