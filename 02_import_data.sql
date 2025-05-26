-- ================================================================================
-- File: 02_import_data.sql
-- Project: Instacart Market Basket Behavior Analysis
-- Author: Dylan Barrett
-- Last Updated: May 12, 2025
--
-- Description:
-- This script imports all required CSV datasets into their corresponding tables.
-- File paths should be updated as needed to match local machine structure.
-- ================================================================================

-- Set active schema context
SET search_path TO instacart;

-- --------------------------------------------------------------------------------
-- Step 3: Import CSVs into Database Tables
-- --------------------------------------------------------------------------------
-- Import orders.csv
COPY orders
FROM 'C:\temp\4\orders.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8'
QUOTE '"';

-- Import order_products__prior.csv
COPY order_products__prior
FROM 'C:\temp\4\order_products__prior.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8'
QUOTE '"';

-- Import order_products__train.csv
COPY order_products__train
FROM 'C:\temp\4\order_products__train.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8'
QUOTE '"';

-- Import products.csv
COPY products
FROM 'C:\temp\4\products.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8'
QUOTE '"';

-- Import aisles.csv
COPY aisles
FROM 'C:\temp\4\aisles.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8'
QUOTE '"';

-- Import departments.csv
COPY departments
FROM 'C:\temp\4\departments.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8'
QUOTE '"';