# Instacart Behavioral Buying Patterns

---

## **Introduction**

This project explores customer behavior on Instacart, a leading online grocery platform, by analyzing over 3 million grocery orders placed by almost 200,000 users. While earlier portfolio projects focused on straightforward KPIs and business segmentation, this project takes a more advanced behavioral approach that uncovers psychological triggers and shopping patterns that drive repeat purchasing and larger orders.

### **What is Instacart?**

Instacart is a North American grocery delivery and pickup service that allows customers to order groceries online from local stores. It offers users a convenient alternative to in-store shopping by combining a large product catalog with personalized recommendations and scheduling flexibility.

---

## **About the Dataset**

This dataset was originally released by Instacart for a Kaggle competition. It includes anonymized data on:

- **3.4 million orders**
- **Over 50,000 unique products**
- **Aisle and department categorizations**
- **Customer-level purchase sequences**

The files used in this project are:

- `orders.csv` — metadata for every order
- `order_products__prior.csv` — line-item detail for each prior order (main historical data)
- `products.csv`, `aisles.csv`, `departments.csv` — lookup tables for product names, aisle names, and department names

**Note:** The `order_products__train.csv` file is included but it will not be used in this analysis, as this project does not have a predictive modeling focus.

---

## **Project Goal**

The goal of this project is to go beyond basic reporting and explore **behavioral drivers** of customer purchasing on Instacart.

Key Questions:

- Which products are **reordered the fastest**, indicating habit strength?  
- Which products are most commonly associated with **larger orders**, contributing to overall order size (a.k.a. cart size)?  
- Which products are frequently **purchased together** (co-purchased), suggesting strong bundling potential or habitual pairings?

---

## Key Terms

- **Repurchase Cycle** (a.k.a. Reorder Speed)
  The number of days between a customer's purchases of the *same* product. A shorter cycle means the product is bought more frequently, suggesting stronger routine or habit.

- **Order Size**  
  The number of items included in a single order. Used to identify which products are associated with larger shopping sessions.

- **Behavioral Lift**  
  The difference between a product’s average metric (e.g. repurchase cycle or order size) and the global average. Helps reveal standout behavioral patterns.

- **Standard Deviation**  
  A measure of variability. In this project, it shows how consistently a product influences reorder speed or order size across customers.

- **Z-Score**  
  A standardized lift value that shows how far a product's behavior deviates from the norm, adjusted for consistency.

- **Anchor** (a.k.a. Anchor Product)  
  A commonly purchased product used to measure behavioral influence, particularly its effect on reorder speed, order size, and co-purchase patterns.

- **Influence Index (II)**  
  A relative 0–10 score combining a product's reorder speed lift (60% weight) and order size lift (40% weight). Reorder speed is weighted more heavily because returning to repurchase items reflects a stronger behavioral tendency than simply adding additional items once shopping has begun. (These weightings are somewhat arbitrary as I simply wanted to use a custom index for experimental purposes.)

---

## Table of Contents

- [Introduction](#introduction)
- [What is Instacart?](#what-is-instacart)
- [About the Dataset](#about-the-dataset)
- [Project Goal](#project-goal)
- [Key Terms](#key-terms)
- [Tools Used](#tools-used)
- [Project Files](#project-files)
- [Step 1: Set Schema Context](#step-1-set-schema-context)
- [Step 2: Data Preparation](#step-2-data-preparation)
- [Step 3: Import Raw Data](#step-3-import-raw-data)
- [Step 4: Data Sanity Check](#step-4-data-sanity-check)
- [Step 5a: Global Average Repurchase Cycle](#step-5a-global-average-repurchase-cycle)
- [Step 5b: Average Repurchase Cycle by Product](#step-5b-average-repurchase-cycle-by-product)
- [Step 5c: Average Repurchase Cycle by Department](#step-5c-average-repurchase-cycle-by-department)
- [Step 5d: Repurchase Cycle Lift by Product](#step-5d-repurchase-cycle-lift-by-product)
- [Step 5e: Repurchase Cycle Lift by Department](#step-5e-repurchase-cycle-lift-by-department)
- [Step 6a: Global Average Order Size](#step-6a-global-average-order-size)
- [Step 6b: Average Order Size by Product](#step-6b-average-order-size-by-product)
- [Step 6c: Average Order Size by Department](#step-6c-average-order-size-by-department)
- [Step 6d: Order Size Lift by Product](#step-6d-order-size-lift-by-product)
- [Step 6e: Order Size Lift by Department](#step-6e-order-size-lift-by-department)
- [Step 7a: Identify Co-Purchased Product Pairs](#step-7a-identify-co-purchased-product-pairs)
- [Step 7b: Percentage of Anchor Orders Containing Co-Products](#step-7b-percentage-of-anchor-orders-containing-co-products)
- [Final Dashboard Design](#final-dashboard-design)
- [Final Thoughts](#final-thoughts)
- [Dashboard](#dashboard)

---

## Tools Used
- PostgreSQL (via pgAdmin 4) — for database setup and management
- SQL — used for data transformation, joins, aggregations, and filtering
- Tableau — used for final visualizations

---

## Project Files
| File | Description |
|------|-------------|
| `01_create_tables.sql` | Creates base and lookup tables |
| `02_import_data.sql` | Imports CSV datasets |
| `03_data_validation.sql` | Performs row count and preview checks |
| `04_analysis_queries.sql` | Contains all analytical SQL steps (Steps 5-7) |
| `05_export_final_dataset.sql` | Assembles final export table for Tableau import |

---

### **Step 1: Set Schema Context**

**Goal:**  
Ensure all tables are created within the correct project schema (`instacart`)

**Actions Taken:**  
- Used `SET search_path TO instacart;` to define the default schema for the project

**Purpose:**  
Avoids repetitive schema prefixes in SQL scripts and ensures clean table organization throughout the duration of the project.

---

### **Step 2: Data Preparation**

**Goal:**  
Create base tables that mirror the structure of the original Instacart CSV datasets

**Actions Taken:**  
- Created tables for 6 core datasets: `orders`, `order_products__prior`, `order_products__train`, `products`, `aisles`, and `departments`  
- Assigned appropriate data types to each column

**Purpose:**  
Establish a relational database structure to enable accurate data merging and analysis in future steps.

---

### **Step 3: Import Raw Data**

**Goal:**  
Load all CSV files into their corresponding SQL tables using the `COPY` command

**Actions Taken:**  
- Imported the following datasets:
  - `orders`
  - `order_products__prior`
  - `order_products__train`
  - `products`
  - `aisles`
  - `departments`  
- Confirmed UTF-8 encoding and delimiter alignment

**Purpose:**  
Populate the schema with the Instacart data for analysis.

---

### **Step 4: Data Sanity Check**

**Goal:**  
Verify that all tables were successfully created and populated.

**Actions Taken:**  
- Ran `SELECT COUNT(*)` to confirm row totals per table  
- Ran `SELECT * LIMIT 10` to preview structure and values in each table

**Purpose:**  
Confirm that the import process worked and that all tables are ready for analysis.

---

### **Step 5a: Global Average Repurchase Cycle**

**Goal:**  
Establish a behavioral benchmark for how quickly customers reorder in general

**Actions Taken:**  
- Queried the `orders` table and filtered out first-time orders (where `days_since_prior_order` is NULL)
- Calculated the global average number of days between customer orders (i.e. the average for the entire dataset)

**Result:**  
The global average repurchase cycle is **11.11 days between orders**

**Purpose:**  
This benchmark serves as a baseline to evaluate how quickly individual products are repurchased. Future steps will compare each product's repurchase cycle against this benchmark to measure habit strength.

---

### **Step 5b: Average Repurchase Cycle by Product**

**Goal:**  
Identify products that are repurchased most quickly, indicating strong habit formation

**Actions Taken:**  
- Joined `orders` and `order_products__prior` tables to track `days_since_prior_order` for each product
- Filtered out first-time orders
- Calculated the average repurchase cycle and number of repurchase events for each product
- Filtered out products with less than 30 repurchase events for statistical stability (as per Central Limit Theorem)

**Purpose:**  
Understand which products are most behaviorally embedded in users’ routines, forming the basis for future "anchor" analysis.

**Note:**  
A more advanced statistical threshold could be calculated using the √N rule of thumb, but given the large sample size (N) of over 3 million orders, a fixed threshold of 30 made way more sense.

---

### **Step 5c: Average Repurchase Cycle by Department (Event-Based)**

**Goal:**  
Summarize customer repurchase behavior at the department level
**Actions Taken:**  
- Joined `orders` and `order_products__prior` with product info and department info (3 joins)
- Filtered out first-time orders
- Grouped by department and calculated the average repurchase cycle and number of repurchase events at the department level  
- Filtered out departments with less than 30 repurchase events for statistical stability

**Purpose:**  
Understand which departments are most behaviorally embedded in users’ routines. These values will also provide more context with regards to overall product performance.

**Note:**  
After trying both methods, I decided to use **event-based aggregation** (repurchase cycles from individual orders) as opposed to simply averaging product-level averages. This provides a more accurate and volume-weighted measure of departmental behavior. (Besides, taking an aggregate of an aggregate is awkward math, generally speaking.)

---

### **Step 5d: Repurchase Cycle Lift by Product**

**Goal:**  
Calculate how each product's average repurchase cycle compares to the global average

**Actions Taken:**  
- Used product-level averages (from Step 5b)
- Queried the global average (from Step 5a)
- Calculated lift by subtracting the product's average from the global average (lower value = faster repurchase)
- Found standard deviation to see variability among repurchases 
- Calculate z-score to standardize repurchase cycle lift for easier comparison across all products  
- Filtered out products with less than 30 repurchase events for statistical stability

**Purpose:**  
Highlight products that are repurchased **more frequently** than average.

---

### **Step 5e: Repurchase Cycle Lift by Department**

**Goal:**  
Compare department-level average repurchase cycles to the global average

**Actions Taken:**  
- Used department-level averages (from Step 5c)  
- Queried the global average (from Step 5a)
- Calculated lift by subtracting the department's average from the global average (lower value = faster repurchase)
- Filtered out departments with less than 30 repurchase events for statistical stability

**Purpose:**  
Highlights departments where customers tend to repurchase from **more frequently** compared to the average.

---

### **Step 6a: Global Average Order Size**

**Goal:**  
Establish a benchmark for how much customers reorder across the entire dataset

**Actions Taken:**  
- Queried the `order_products__prior` table to count the number of items in each order
- Took the average of all order sizes to find the global average order size

**Result:**  
The global average order size is **10.09 items per order**

**Purpose:**  
Future steps will measure each product’s impact on order size relative to this benchmark, helping to identify which products contribute most to larger shopping orders.

**Note:**
"Repurchase events" are referred to as "orders" through the duration of Step 6

---

### **Step 6b: Average Order Size by Product**

**Goal:**  
Measure the average number of products in an order whenever a particular product appears in said order

**Actions Taken:**  
- Counted the number of items for each order (i.e., order size)
- Mapped each product to the unique orders it appeared in
- Mapped each product to the order size of the order it appeared in  
- Calculated the **average order size** and number of orders for each product
- Filtered out products with less than 30 orders for statistical stability

**Purpose:**  
Highlights which products tend to appear in **larger-than-average** orders, suggesting that they may play a role in high-volume purchasing behavior.

---

### **Step 6c: Average Order Size by Department**

**Goal:**  
Measure the average number of items in an order that includes at least one product from each department

**Actions Taken:**  
- Reused `order_products__prior` and `products` tables to match each product with its corresponding department  
- Counted total items in each order (order size)  
- Calculated the average order size for all orders that included at least one product from each department  
- Filtered out departments with less than 30 orders for statistical stability

**Purpose:**  
This step reveals how certain departments correlate with larger overall orders. The presence of specific departments can indicate higher-volume ordering habits.

---

### **Step 6d: Order Size Lift by Product**

**Goal:**  
Calculate how each product's average order size compares to the global average

**Actions Taken:**  
- Used product-level averages (from Step 6b)
- Queried the global average order size (from Step 6a)  
- Calculated *order size lift* by subtracting the global average from each product’s average
- Found standard deviation to see variability among orders
- Calculate z-score to standardize order size lift for easier comparison across all products  
- Filtered out products with less than 30 orders for statistical stability

**Purpose:**  
Highlights a product’s contribution to **order expansion**, helping uncover items that tend to drive larger, more complete orders — a valuable signal for understanding a product's influence.

---

### **Step 6e: Order Size Lift by Department**

**Goal:**  
Compare department-level average order sizes to the global average

**Actions Taken:**  
- Used department-level averages (from Step 6c)  
- Queried the global average (from Step 6a) 
- Calculated lift by subtracting the global average from each department’s average  
- Filtered out departments with less than 30 orders to ensure statistical stability

**Purpose:**  
This step quantifies how much larger or smaller each department's typical order size is compared to the average.

---

### **Step 7a: Identify Co-Purchased Product Pairs**

**Goal:**  
Detect which product pairs most frequently appear together in the same order

**Note:**
A "product pair" consists of an "anchor" (the main product) and its "co-product" (any other product that appears in the same order as the "anchor")

**Actions Taken:**  
- Queried the most frequently purchased products from the `order_products__prior` table  
- Used a self-join to find all co-purchased pairs that occurred in the same order
- Used the LEAST/GREATEST command to prevent duplicate flips (e.g., Apple–Banana vs. Banana–Apple)
- Excluded self-pair duplicates (e.g., Apple–Apple)
- Grouped by product pair, and aggregated to find the number of times each pair appeared together

**Purpose:**  
Lay the foundation for analyzing which products act as strong **co-purchase attractors**.

**Example:**  
If both **Banana** and **Organic Strawberries** appear in the same order, and this happens **10 times** across all orders,  
this particular product pair has a **co-purchase count of 10**.

---

### **Step 7b: Percentage of Anchor Orders Containing Co-Products**

**Goal:**  
For each anchor–co-product pair, calculate how frequently they appear together, expressed as a percentage of the anchor's total orders.

**Actions Taken:**  
- Reused the top anchors from Step 7a  
- Counted how many **unique orders** each anchor–co-product pair appeared in  ->  numerator
- Retrieved the **total number of orders** each anchor product appeared in  ->  denominator
- Calculated the co-purchase percentage using:  
  unique orders / total number of orders
- Filtered out product pairs with less than 30 co-purchases for statistical stability

**Purpose:**  
Helps signal **behavioral closeness** between products. A high co-purchase percentage confirms that the co-product is very frequently purchased alongside the anchor—revealing strong bundling potential, substitution patterns, or habitual combinations in general.

**Example:**  
If **Organic Strawberries** (the anchor) appear in **20 different orders**, and **Banana** (the co-product) is also included in **5** of these same orders,  
then the **percentage of anchor orders** containing Banana is `5 / 20 = 25%`. 

---

## **Final Dashboard Design**

The final Tableau dashboard includes:

- **KPI Cards** — metrics including Influence Index, Reorder Speed, Order Size, and Total Orders (that update dynamically)
- **Behavioral Scatterplot** — plots every product by reorder speed (y-axis) and order size  (x-axis)
- **Top Co-Purchased Product Bar Chart** — shows the top co-products for each anchor, ranked by percentage of anchor orders they appear in
- **Behavior Quadrants**:
  - **Core Routine** (Fast Reordering + Large Orders)
  - **Light Routine** (Fast Reordering + Small Orders)
  - **Occasional Stock-Up** (Slow Reordering + Large Orders)
  - **Occasional Convenience** (Slow Reordering + Small Orders)

- Originally for the scatterplot, I wanted to include a level of detail parameter where the user can switch views between product, aisle, and department. However, Tableau Public's limitations made it not possible to include both this parameter and click-based discovery at the same time, so after hours of failed troubleshooting, the final version simply focuses on **product-level insights** with an exploratory feel. Also, there is no search filter because with every data point search, the chart would automatically zoom in on that data point, making it difficult to see where that point resides in relation to the other data points.

- To improve metric understanding, I adjusted and replaced the raw behavioral lift values on the scatterplot with relative scores (0–10) for both reorder speed and order size.  This makes these particular insights more interpretable, which makes the story easier to follow for everyone (including myself). In my opinion, these project findings cannot be too esoteric because stakeholders need to absorb the information quickly and confidently, so they can focus on making important business decisions without any additional stress.

---

## **Final Thoughts**

For someone who enjoys daydreaming as much as I do, the planning stage of this project was the most enjoyable. After deciding on a direction (behavioral analytics) and a dataset (Instacart orders), I like to write down at least 10 questions about the dataset, its individual tables and column fields. Then I take this list of questions and narrow it down to about 3-4 core questions that I believe can derive the most insightful (and interesting) findings. This thought process becomes the foundation for the final visualizations and KPIs that will appear in the dashboard.

Watching these abstract ideas slowly become reality over a couple of weeks is a very rewarding experience. Sometimes it's not possible to perfect every last detail due to software limitations or time constraints, but as long as these core questions are answered and presented effectively, that's what matters most.

---

## **Dashboard**

[Instacart Behavioral Buying Patterns (Tableau Public)](https://public.tableau.com/app/profile/dylan.barrett1539/viz/InstacartBehavioralBuyingPatterns/Dashboard)
