-- ================================================================================
-- File: 03_data_validation.sql
-- Project: Instacart Behavioral Buying Patterns
-- Author: Dylan Barrett
-- Last Updated: May 12, 2025
--
-- Description:
-- -- This script performs sanity checks after table creation and data import.
-- Each table is tested for:
-- - Row count (to confirm full import)
-- - Data preview using LIMIT 10
-- ================================================================================

-- Set active schema context
SET search_path TO instacart;

-- --------------------------------------------------------------------------------
-- Step 4: Sanity Checks on Imported Tables
-- --------------------------------------------------------------------------------
-- Goal: Confirm that each table was successfully created and populated
-- Logic:
-- - Use SELECT COUNT(*) to check row totals
-- - Use SELECT * LIMIT 10 to preview structure and values

-- Check total number of rows in each table
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_products__prior;
SELECT COUNT(*) FROM order_products__train;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM aisles;
SELECT COUNT(*) FROM departments;

-- Preview the first 10 rows of each table
SELECT * FROM orders LIMIT 10;
SELECT * FROM order_products__prior LIMIT 10;
SELECT * FROM order_products__train LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM aisles LIMIT 10;
SELECT * FROM departments LIMIT 10;
