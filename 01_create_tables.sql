-- ================================================================================
-- File: 01_create_tables.sql
-- Project: Instacart Behavioral Buying Patterns
-- Author: Dylan Barrett
-- Last Updated: May 12, 2025
--
-- Description:
-- This script creates all database tables for the Instacart project.
-- Tables reflect key CSV datasets used in the analysis:
-- - Orders
-- - Order products (prior)
-- - Order products (train)
-- - Products
-- - Aisles
-- - Departments
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Step 1: Set Active Schema Context
-- --------------------------------------------------------------------------------
SET search_path TO instacart;

-- --------------------------------------------------------------------------------
-- Step 2: Create Base Tables
-- --------------------------------------------------------------------------------
-- Goal: Create core tables for 6 key datasets (orders, order_products__prior, order_products__train, products, aisles, departments)
-- Logic:
-- - Mirror original CSV structure
-- - Define appropriate data types for relational joins

-- Table: orders  
-- Contains metadata for every order, including user ID, timing, and evaluation set
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    user_id INTEGER,
	eval_set TEXT,
    order_number INTEGER,
    order_dow INTEGER,
    order_hour_of_day INTEGER,
    days_since_prior_order FLOAT
);

-- Table: order_products__prior  
-- Lists all products purchased in prior orders (main historical dataset)
CREATE TABLE order_products__prior (
    order_id INTEGER,
    product_id INTEGER,
    add_to_cart_order INTEGER,
    reordered INTEGER
);

-- Table: order_products__train  
-- Lists products in users’ final training orders (for modeling use, not analysis here)
CREATE TABLE order_products__train (
    order_id INTEGER,
    product_id INTEGER,
    add_to_cart_order INTEGER,
    reordered INTEGER
);

-- Table: products  
-- Contains product names and links to aisle and department identifiers
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT,
    aisle_id INTEGER,
    department_id INTEGER
);

-- Table: aisles  
-- Lookup table for aisle names (e.g., beverages, frozen foods)
CREATE TABLE aisles (
    aisle_id INTEGER PRIMARY KEY,
    aisle TEXT
);

-- Table: departments  
-- Lookup table for department names (e.g., dairy, snacks)
CREATE TABLE departments (
    department_id INTEGER PRIMARY KEY,
    department TEXT
);
