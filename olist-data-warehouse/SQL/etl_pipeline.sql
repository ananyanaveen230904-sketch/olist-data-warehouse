-- Olist project: Bronze to Silver/Gold data pipeline setup and validation
ALTER WAREHOUSE COMPUTE_WH RESUME;
CREATE DATABASE OLIST_PROJECT;
USE DATABASE OLIST_PROJECT;
CREATE SCHEMA BRONZE;
CREATE SCHEMA SILVER;
CREATE SCHEMA GOLD;
USE SCHEMA BRONZE;
USE WAREHOUSE COMPUTE_WH;
//USING SILVER SCHEMA
USE SCHEMA SILVER;

//code to remove duplicates.If they differ, remove duplicates.
//ORDER TABLE
SELECT COUNT(*), COUNT(DISTINCT order_id)
FROM BRONZE.ORDERS;

// finding duplicate value for customer table 
SELECT COUNT(*), COUNT(DISTINCT customer_id)
FROM BRONZE.CUSTOMERS;

//finding duplicates value for product table 
SELECT COUNT(*), COUNT(DISTINCT product_id)
FROM BRONZE.PRODUCTS;

//finding duplicate value for SELLER table 
SELECT COUNT(*), COUNT(DISTINCT seller_id)
FROM BRONZE.SELLERS;

//finding duplicate value for ORDER REVIEWS table 
SELECT COUNT(*), COUNT(DISTINCT review_id)
FROM BRONZE.REVIWES; // total rows(99224) , distinct rows (98410) - HAS DUPLICATE VALUES 

//finding duplicate value for category table 
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_item_id) AS unique_order_items
FROM BRONZE.ORDER_ITEMS;// total rows(112650) , distinct rows (21) - HAS DUPLICATE VALUES 


//finding duplicate value for ORDER_ITEMS table 
SELECT COUNT(*), COUNT(DISTINCT order_item_id)
FROM BRONZE.ORDER_ITEMS; //HAS DUPLICATE VALUE ( TOTAL ROWS = 112650 , DISTINCT = 21)

//finding duplicate value for Payments table 
SELECT COUNT(*), COUNT(DISTINCT payment_sequential)
FROM BRONZE.PAYMENTS; // HAS DUPLICATE VALUES ( TOTAL ROWS = 103886, DISTINCT = 29)


//finding null value.check null values in each column

//customers
SELECT
    COUNT_IF(customer_id IS NULL) AS null_customer_id,
    COUNT_IF(customer_unique_id IS NULL) AS null_customer_unique_id,
    COUNT_IF(customer_zip_code_prefix IS NULL) AS null_zip_code,
    COUNT_IF(customer_city IS NULL) AS null_city,
    COUNT_IF(customer_state IS NULL) AS null_state
FROM BRONZE.CUSTOMERS; // no null values

//products
SELECT
    COUNT_IF(product_id IS NULL) AS null_product_id,
    COUNT_IF(product_category_name IS NULL) AS null_category,
    COUNT_IF(product_name_lenght IS NULL) AS null_name_length,
    COUNT_IF(product_description_lenght IS NULL) AS null_description_length,
    COUNT_IF(product_photos_qty IS NULL) AS null_photos,
    COUNT_IF(product_weight_g IS NULL) AS null_weight,
    COUNT_IF(product_length_cm IS NULL) AS null_length,
    COUNT_IF(product_height_cm IS NULL) AS null_height,
    COUNT_IF(product_width_cm IS NULL) AS null_width
FROM BRONZE.PRODUCTS;// has null values

//sellers
SELECT
    COUNT_IF(seller_id IS NULL) AS null_seller_id,
    COUNT_IF(seller_zip_code_prefix IS NULL) AS null_zip,
    COUNT_IF(seller_city IS NULL) AS null_city,
    COUNT_IF(seller_state IS NULL) AS null_state
FROM BRONZE.SELLERS; //no null

//order reviews
SELECT
    COUNT_IF(review_id IS NULL) AS null_review_id,
    COUNT_IF(order_id IS NULL) AS null_order_id,
    COUNT_IF(review_score IS NULL) AS null_review_score,
    COUNT_IF(review_comment_title IS NULL) AS null_comment_title,
    COUNT_IF(review_comment_message IS NULL) AS null_comment_message,
    COUNT_IF(review_creation_date IS NULL) AS null_creation_date,
    COUNT_IF(review_answer_timestamp IS NULL) AS null_answer_timestamp
FROM BRONZE.REVIWES; // HAS MULL VALUES 

//ORDER_ITEMS
SELECT
    COUNT_IF(order_id IS NULL) AS null_order_id,
    COUNT_IF(order_item_id IS NULL) AS null_order_item_id,
    COUNT_IF(product_id IS NULL) AS null_product_id,
    COUNT_IF(seller_id IS NULL) AS null_seller_id,
    COUNT_IF(shipping_limit_date IS NULL) AS null_shipping_limit_date,
    COUNT_IF(price IS NULL) AS null_price,
    COUNT_IF(freight_value IS NULL) AS null_freight_value
FROM BRONZE.ORDER_ITEMS;// NO NULL VALUES

//PAYEMNTS
SELECT
    COUNT_IF(order_id IS NULL) AS null_order_id,
    COUNT_IF(payment_sequential IS NULL) AS null_payment_sequential,
    COUNT_IF(payment_type IS NULL) AS null_payment_type,
    COUNT_IF(payment_installments IS NULL) AS null_installments,
    COUNT_IF(payment_value IS NULL) AS null_payment_value
FROM BRONZE.PAYMENTS;// NO NULL

//GEOLOCATION
SELECT
    COUNT_IF(geolocation_zip_code_prefix IS NULL) AS null_zip,
    COUNT_IF(geolocation_lat IS NULL) AS null_lat,
    COUNT_IF(geolocation_lng IS NULL) AS null_lng,
    COUNT_IF(geolocation_city IS NULL) AS null_city,
    COUNT_IF(geolocation_state IS NULL) AS null_state
FROM BRONZE.GEOLOCATION;// NO NULL VALUES

//ORDERS
SELECT
    COUNT_IF(order_id IS NULL) AS null_order_id,
    COUNT_IF(customer_id IS NULL) AS null_customer_id,
    COUNT_IF(order_status IS NULL) AS null_status,
    COUNT_IF(order_purchase_timestamp IS NULL) AS null_purchase_time,
    COUNT_IF(order_approved_at IS NULL) AS null_approved_at,
    COUNT_IF(order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT_IF(order_delivered_customer_date IS NULL) AS null_customer_date,
    COUNT_IF(order_estimated_delivery_date IS NULL) AS null_estimated_delivery
FROM BRONZE.ORDERS;// HAS NULL

//CATEGORY 
SELECT
    COUNT_IF(C1 IS NULL) AS C1_NULLS,
    COUNT_IF(C2 IS NULL) AS C2_NULLS
FROM BRONZE.CATEGORY_NAME;// NO NULL
--------------------------------------------------------
-- CLEAN REVIEWS TABLE
--------------------------------------------------------
-- STEP 1: TYPE CONVERSION + TEXT STANDARDIZATION
-- ============================================================
-- Rebuild all tables with proper types and trimmed/uppercased text.
-- We use CREATE OR REPLACE so it merges with your prior NULL fixes.

-- ORDERS (already created above — rebuild with proper types)
CREATE OR REPLACE TABLE SILVER_ORDERS AS
SELECT
    order_id,
    customer_id,
    TRIM(LOWER(order_status))                                   AS order_status,
    order_purchase_timestamp::TIMESTAMP                         AS order_purchase_timestamp,
    order_approved_at::TIMESTAMP                                AS order_approved_at,
    order_delivered_carrier_date::TIMESTAMP                     AS order_delivered_carrier_date,
    order_delivered_customer_date::TIMESTAMP                    AS order_delivered_customer_date,
    order_estimated_delivery_date::TIMESTAMP                    AS order_estimated_delivery_date
FROM BRONZE.ORDERS
WHERE order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;


-- CUSTOMERS (already created above — rebuild with trim + uppercase)
CREATE OR REPLACE TABLE SILVER_CUSTOMERS AS
SELECT
    customer_id,
    customer_unique_id,
    TRIM(LOWER(customer_city))              AS customer_city,
    TRIM(UPPER(customer_state))             AS customer_state
FROM BRONZE.CUSTOMERS;


-- SELLERS
CREATE OR REPLACE TABLE SILVER_SELLERS AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    TRIM(LOWER(seller_city))                AS seller_city,
    TRIM(UPPER(seller_state))               AS seller_state
FROM BRONZE.SELLERS;


-- PRODUCTS (already created — rebuild with proper numeric types)
CREATE OR REPLACE TABLE SILVER_PRODUCTS AS
SELECT
    product_id,
    COALESCE(TRIM(LOWER(product_category_name)), 'unknown')     AS product_category_name,
    COALESCE(product_name_lenght, 0)::NUMBER                    AS product_name_length,
    COALESCE(product_description_lenght, 0)::NUMBER             AS product_description_length,
    COALESCE(product_photos_qty, 0)::NUMBER                     AS product_photos_qty,
    COALESCE(product_weight_g, 0)::NUMBER(10,2)                 AS product_weight_g,
    COALESCE(product_length_cm, 0)::NUMBER(10,2)                AS product_length_cm,
    COALESCE(product_height_cm, 0)::NUMBER(10,2)                AS product_height_cm,
    COALESCE(product_width_cm, 0)::NUMBER(10,2)                 AS product_width_cm
FROM BRONZE.PRODUCTS;


-- ORDER_ITEMS (with proper numeric types)
CREATE OR REPLACE TABLE SILVER_ORDER_ITEMS AS
SELECT
    order_id,
    order_item_id::NUMBER                   AS order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::TIMESTAMP          AS shipping_limit_date,
    price::NUMBER(10,2)                     AS price,
    freight_value::NUMBER(10,2)             AS freight_value
FROM BRONZE.ORDER_ITEMS;


-- PAYMENTS (with proper numeric types)
CREATE OR REPLACE TABLE SILVER_PAYMENTS AS
SELECT
    order_id,
    payment_sequential::NUMBER              AS payment_sequential,
    TRIM(LOWER(payment_type))               AS payment_type,
    payment_installments::NUMBER            AS payment_installments,
    payment_value::NUMBER(10,2)             AS payment_value
FROM BRONZE.PAYMENTS;


-- REVIEWS (already created — rebuild with proper timestamps)
CREATE OR REPLACE TABLE SILVER_REVIEWS AS
SELECT
    review_id,
    order_id,
    review_score::NUMBER                                        AS review_score,
    COALESCE(TRIM(review_comment_title),   'No Title')          AS review_comment_title,
    COALESCE(TRIM(review_comment_message), 'No Review')         AS review_comment_message,
    review_creation_date::TIMESTAMP                             AS review_creation_date,
    review_answer_timestamp::TIMESTAMP                          AS review_answer_timestamp
FROM BRONZE.REVIWES;


-- GEOLOCATION (with proper numeric types)
CREATE OR REPLACE TABLE SILVER_GEOLOCATION AS
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat::NUMBER(10,6)           AS geolocation_lat,
    geolocation_lng::NUMBER(10,6)           AS geolocation_lng,
    TRIM(LOWER(geolocation_city))           AS geolocation_city,
    TRIM(UPPER(geolocation_state))          AS geolocation_state
FROM BRONZE.GEOLOCATION;


-- CATEGORY (with standardized names)
CREATE OR REPLACE TABLE SILVER_CATEGORY AS
SELECT
    TRIM(LOWER(C1))                         AS category_name_portuguese,
    TRIM(LOWER(C2))                         AS category_name_english
FROM BRONZE.CATEGORY_NAME;


-- ============================================================
-- STEP 2: DEDUPLICATION (only where true duplicates exist)
-- ============================================================
-- You found duplicates in REVIEWS and PAYMENTS.
-- ORDER_ITEMS has repeated order_item_id (1,2,3...) — those are NOT duplicates.

-- Remove duplicate REVIEWS (keep latest answer timestamp per review_id)
CREATE OR REPLACE TABLE SILVER_REVIEWS AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY review_id
            ORDER BY review_answer_timestamp DESC
        ) AS rn
    FROM SILVER_REVIEWS
)
WHERE rn = 1;


-- Remove duplicate PAYMENTS (keep latest per order_id + payment_sequential)
CREATE OR REPLACE TABLE SILVER_PAYMENTS AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id, payment_sequential
            ORDER BY payment_value DESC
        ) AS rn
    FROM SILVER_PAYMENTS
)
WHERE rn = 1;


-- Verify deduplication worked
SELECT 'REVIEWS'  AS tbl, COUNT(*) AS total, COUNT(DISTINCT review_id)  AS distinct_ids FROM SILVER_REVIEWS
UNION ALL
SELECT 'PAYMENTS' AS tbl, COUNT(*) AS total, COUNT(DISTINCT order_id || '-' || payment_sequential) AS distinct_ids FROM SILVER_PAYMENTS;


-- ============================================================
-- STEP 3: BUSINESS RULES VALIDATION
-- ============================================================

-- RULE 1: Price cannot be negative or zero
CREATE OR REPLACE TABLE SILVER_ORDER_ITEMS AS
SELECT * FROM SILVER_ORDER_ITEMS
WHERE price > 0;

-- RULE 2: Freight value cannot be negative
CREATE OR REPLACE TABLE SILVER_ORDER_ITEMS AS
SELECT * FROM SILVER_ORDER_ITEMS
WHERE freight_value >= 0;

-- RULE 3: Order status must be one of the valid values
CREATE OR REPLACE TABLE SILVER_ORDERS AS
SELECT * FROM SILVER_ORDERS
WHERE order_status IN (
    'delivered', 'shipped', 'canceled',
    'processing', 'unavailable',
    'invoiced', 'approved', 'created'
);

-- RULE 4: Payment value must be greater than 0
CREATE OR REPLACE TABLE SILVER_PAYMENTS AS
SELECT * FROM SILVER_PAYMENTS
WHERE payment_value > 0;

-- RULE 5: Delivery date cannot be before purchase date
CREATE OR REPLACE TABLE SILVER_ORDERS AS
SELECT * FROM SILVER_ORDERS
WHERE order_delivered_customer_date >= order_purchase_timestamp;

-- RULE 6: Approved timestamp cannot be before purchase timestamp
CREATE OR REPLACE TABLE SILVER_ORDERS AS
SELECT * FROM SILVER_ORDERS
WHERE order_approved_at >= order_purchase_timestamp;

-- RULE 7: Review score must be between 1 and 5
CREATE OR REPLACE TABLE SILVER_REVIEWS AS
SELECT * FROM SILVER_REVIEWS
WHERE review_score BETWEEN 1 AND 5;


-- ============================================================
-- STEP 4: FINAL VERIFICATION — row counts for all silver tables
-- ============================================================
SELECT 'SILVER_ORDERS'       AS table_name, COUNT(*) AS row_count FROM SILVER_ORDERS       UNION ALL
SELECT 'SILVER_CUSTOMERS'    AS table_name, COUNT(*) AS row_count FROM SILVER_CUSTOMERS    UNION ALL
SELECT 'SILVER_SELLERS'      AS table_name, COUNT(*) AS row_count FROM SILVER_SELLERS      UNION ALL
SELECT 'SILVER_PRODUCTS'     AS table_name, COUNT(*) AS row_count FROM SILVER_PRODUCTS     UNION ALL
SELECT 'SILVER_ORDER_ITEMS'  AS table_name, COUNT(*) AS row_count FROM SILVER_ORDER_ITEMS  UNION ALL
SELECT 'SILVER_PAYMENTS'     AS table_name, COUNT(*) AS row_count FROM SILVER_PAYMENTS     UNION ALL
SELECT 'SILVER_REVIEWS'      AS table_name, COUNT(*) AS row_count FROM SILVER_REVIEWS      UNION ALL
SELECT 'SILVER_GEOLOCATION'  AS table_name, COUNT(*) AS row_count FROM SILVER_GEOLOCATION  UNION ALL
SELECT 'SILVER_CATEGORY'     AS table_name, COUNT(*) AS row_count FROM SILVER_CATEGORY;
--GOLD LAYER
USE DATABASE OLIST_PROJECT;
USE SCHEMA GOLD;
-- ============================================================
-- DIMENSION 1: DIM_CUSTOMER
-- SCD Type 1 implemented here — if city/state changes, we
-- simply overwrite (no history kept). This satisfies the
-- project requirement.
-- ============================================================

CREATE OR REPLACE TABLE DIM_CUSTOMER (
    customer_sk         NUMBER AUTOINCREMENT PRIMARY KEY,  -- surrogate key
    customer_id         VARCHAR,                           -- natural key from Silver
    customer_unique_id  VARCHAR,
    customer_city       VARCHAR,
    customer_state      VARCHAR,
    dw_created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dw_updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Initial load
INSERT INTO DIM_CUSTOMER (customer_id, customer_unique_id, customer_city, customer_state)
SELECT
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
FROM SILVER.SILVER_CUSTOMERS;

-- SCD Type 1 MERGE — run this whenever you reload Silver data.
-- It updates city/state in place (no history). That IS Type 1.
MERGE INTO DIM_CUSTOMER AS tgt
USING SILVER.SILVER_CUSTOMERS AS src
    ON tgt.customer_id = src.customer_id
WHEN MATCHED AND (
    tgt.customer_city  <> src.customer_city OR
    tgt.customer_state <> src.customer_state
) THEN UPDATE SET
    tgt.customer_city  = src.customer_city,
    tgt.customer_state = src.customer_state,
    tgt.dw_updated_at  = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN INSERT (
    customer_id, customer_unique_id, customer_city, customer_state
) VALUES (
    src.customer_id, src.customer_unique_id, src.customer_city, src.customer_state
);
-- ============================================================
-- DIMENSION 2: DIM_PRODUCT
-- ============================================================
CREATE OR REPLACE TABLE DIM_PRODUCT AS
SELECT
    MD5(product_id)                 AS product_sk,         -- hash surrogate key
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    CURRENT_TIMESTAMP               AS dw_created_at
FROM SILVER.SILVER_PRODUCTS;
-- ============================================================
-- DIMENSION 3: DIM_SELLER
-- ============================================================
CREATE OR REPLACE TABLE DIM_SELLER AS
SELECT
    MD5(seller_id)                  AS seller_sk,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    CURRENT_TIMESTAMP               AS dw_created_at
FROM SILVER.SILVER_SELLERS;
-- ============================================================
-- DIMENSION 4: DIM_DATE
-- Generated from the range of dates in your orders table.
-- A proper date dim is much more useful than just storing
-- raw timestamps in the fact table.
-- ============================================================
CREATE OR REPLACE TABLE DIM_DATE AS
WITH date_spine AS (
    SELECT DATEADD(DAY, SEQ4(), '2016-01-01'::DATE) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))   -- covers ~5.5 years
)
SELECT
    TO_NUMBER(TO_CHAR(date_day, 'YYYYMMDD'))    AS date_sk,       -- e.g. 20180115
    date_day                                    AS full_date,
    YEAR(date_day)                              AS year,
    QUARTER(date_day)                           AS quarter,
    MONTH(date_day)                             AS month,
    TO_CHAR(date_day, 'MMMM')                   AS month_name,
    WEEKOFYEAR(date_day)                        AS week_of_year,
    DAYOFMONTH(date_day)                        AS day_of_month,
    DAYOFWEEK(date_day)                         AS day_of_week,   -- 0=Sun
    TO_CHAR(date_day, 'DY')                     AS day_name,
    CASE WHEN DAYOFWEEK(date_day) IN (0,6)
         THEN TRUE ELSE FALSE END               AS is_weekend
FROM date_spine
WHERE date_day BETWEEN '2016-01-01' AND '2020-12-31';
-- ============================================================
-- DIMENSION 5: DIM_PAYMENT
-- One row per unique payment type + installment combination.
-- ============================================================

CREATE OR REPLACE TABLE DIM_PAYMENT AS
SELECT
    MD5(order_id || '-' || CAST(payment_sequential AS VARCHAR))  AS payment_sk,
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    CURRENT_TIMESTAMP               AS dw_created_at
FROM SILVER.SILVER_PAYMENTS;
-- ============================================================
-- DIMENSION 6: DIM_REVIEW
-- one row per review.
-- ============================================================
CREATE OR REPLACE TABLE DIM_REVIEW AS
SELECT
    MD5(review_id)                    AS review_sk,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    CURRENT_TIMESTAMP                 AS dw_created_at
FROM SILVER.SILVER_REVIEWS;
-- ============================================================
-- FACT TABLE: FACT_ORDER_ITEMS
-- Grain: one row per order line item
-- Measures: price, freight_value, total_amount
-- FKs: point to all dimension surrogate keys
-- ============================================================
CREATE OR REPLACE TABLE FACT_ORDER_ITEMS AS
SELECT
    -- Surrogate keys (FKs to dimensions)
    MD5(oi.order_id || '-' || CAST(oi.order_item_id AS VARCHAR))  AS order_item_sk,
    MD5(p.product_id)                       AS product_sk,
    MD5(s.seller_id)                        AS seller_sk,
    TO_NUMBER(TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')) AS date_sk,
    dc.customer_sk,                         -- from autoincrement DIM_CUSTOMER

    -- Degenerate dimensions (IDs kept in fact for traceability)
    oi.order_id,
    oi.order_item_id,
    o.order_status,

    -- Timestamps (useful for delivery analysis)
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Measures
    oi.price                                AS item_price,
    oi.freight_value,
    oi.price + oi.freight_value             AS total_amount,

    -- Derived measures
    DATEDIFF('day',
        o.order_purchase_timestamp,
        o.order_delivered_customer_date)    AS actual_delivery_days,

    DATEDIFF('day',
        o.order_purchase_timestamp,
        o.order_estimated_delivery_date)    AS estimated_delivery_days,

    DATEDIFF('day',
        o.order_purchase_timestamp,
        o.order_delivered_customer_date)
    - DATEDIFF('day',
        o.order_purchase_timestamp,
        o.order_estimated_delivery_date)    AS delivery_delay_days,  -- negative = early

    CURRENT_TIMESTAMP                       AS dw_created_at

FROM SILVER.SILVER_ORDER_ITEMS      oi
JOIN SILVER.SILVER_ORDERS           o   ON oi.order_id      = o.order_id
JOIN SILVER.SILVER_PRODUCTS         p   ON oi.product_id    = p.product_id
JOIN SILVER.SILVER_SELLERS          s   ON oi.seller_id     = s.seller_id
JOIN DIM_CUSTOMER                   dc  ON o.customer_id    = dc.customer_id;
-- validation
--============================================================
-- VERIFICATION — sanity check row counts + sample queries
-- ============================================================
SELECT 'DIM_CUSTOMER'    AS tbl, COUNT(*) AS rows FROM DIM_CUSTOMER   UNION ALL
SELECT 'DIM_PRODUCT'     AS tbl, COUNT(*) AS rows FROM DIM_PRODUCT    UNION ALL
SELECT 'DIM_SELLER'      AS tbl, COUNT(*) AS rows FROM DIM_SELLER     UNION ALL
SELECT 'DIM_DATE'        AS tbl, COUNT(*) AS rows FROM DIM_DATE       UNION ALL
SELECT 'DIM_PAYMENT'     AS tbl, COUNT(*) AS rows FROM DIM_PAYMENT    UNION ALL
SELECT 'FACT_ORDER_ITEMS'AS tbl, COUNT(*) AS rows FROM FACT_ORDER_ITEMS;
-- Quick test: total revenue by product category per year
SELECT
    d.year,
    p.product_category_name,
    COUNT(*)                        AS total_orders,
    ROUND(SUM(f.item_price), 2)     AS total_revenue,
    ROUND(AVG(f.delivery_delay_days), 1) AS avg_delay_days
FROM FACT_ORDER_ITEMS   f
JOIN DIM_DATE           d ON f.date_sk      = d.date_sk
JOIN DIM_PRODUCT        p ON f.product_sk   = p.product_sk
GROUP BY 1, 2
ORDER BY 1, total_revenue DESC;

SHOW TABLES IN SCHEMA SILVER;

USE DATABASE OLIST_PROJECT;
USE SCHEMA GOLD;
SELECT *
FROM DIM_REVIEW
LIMIT 5;

SELECT CURRENT_DATABASE(), CURRENT_SCHEMA();
SHOW TABLES LIKE 'DIM_REVIEW' IN ACCOUNT;

USE DATABASE OLIST_PROJECT;
USE SCHEMA GOLD;

CREATE OR REPLACE TABLE DIM_REVIEW AS
SELECT *
FROM OLIST_PROJECT.PUBLIC.DIM_REVIEW;
SHOW TABLES IN SCHEMA GOLD;
USE DATABASE OLIST_PROJECT;

CREATE OR REPLACE PROCEDURE RUN_ETL_PIPELINE()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN

------------------------------------------------------------
-- SILVER LAYER
------------------------------------------------------------

CREATE OR REPLACE TABLE SILVER.SILVER_ORDERS AS
SELECT
    order_id,
    customer_id,
    TRIM(LOWER(order_status)) AS order_status,
    order_purchase_timestamp::TIMESTAMP AS order_purchase_timestamp,
    order_approved_at::TIMESTAMP AS order_approved_at,
    order_delivered_carrier_date::TIMESTAMP AS order_delivered_carrier_date,
    order_delivered_customer_date::TIMESTAMP AS order_delivered_customer_date,
    order_estimated_delivery_date::TIMESTAMP AS order_estimated_delivery_date
FROM BRONZE.ORDERS
WHERE order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL;


CREATE OR REPLACE TABLE SILVER.SILVER_CUSTOMERS AS
SELECT
    customer_id,
    customer_unique_id,
    TRIM(LOWER(customer_city)) AS customer_city,
    TRIM(UPPER(customer_state)) AS customer_state
FROM BRONZE.CUSTOMERS;


CREATE OR REPLACE TABLE SILVER.SILVER_SELLERS AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    TRIM(LOWER(seller_city)) AS seller_city,
    TRIM(UPPER(seller_state)) AS seller_state
FROM BRONZE.SELLERS;


CREATE OR REPLACE TABLE SILVER.SILVER_PRODUCTS AS
SELECT
    product_id,
    COALESCE(TRIM(LOWER(product_category_name)), 'unknown') AS product_category_name,
    COALESCE(product_name_lenght,0)::NUMBER AS product_name_length,
    COALESCE(product_description_lenght,0)::NUMBER AS product_description_length,
    COALESCE(product_photos_qty,0)::NUMBER AS product_photos_qty,
    COALESCE(product_weight_g,0)::NUMBER(10,2) AS product_weight_g,
    COALESCE(product_length_cm,0)::NUMBER(10,2) AS product_length_cm,
    COALESCE(product_height_cm,0)::NUMBER(10,2) AS product_height_cm,
    COALESCE(product_width_cm,0)::NUMBER(10,2) AS product_width_cm
FROM BRONZE.PRODUCTS;


CREATE OR REPLACE TABLE SILVER.SILVER_ORDER_ITEMS AS
SELECT
    order_id,
    order_item_id::NUMBER AS order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::TIMESTAMP AS shipping_limit_date,
    price::NUMBER(10,2) AS price,
    freight_value::NUMBER(10,2) AS freight_value
FROM BRONZE.ORDER_ITEMS;


CREATE OR REPLACE TABLE SILVER.SILVER_PAYMENTS AS
SELECT
    order_id,
    payment_sequential::NUMBER AS payment_sequential,
    TRIM(LOWER(payment_type)) AS payment_type,
    payment_installments::NUMBER AS payment_installments,
    payment_value::NUMBER(10,2) AS payment_value
FROM BRONZE.PAYMENTS;


CREATE OR REPLACE TABLE SILVER.SILVER_REVIEWS AS
SELECT
    review_id,
    order_id,
    review_score::NUMBER AS review_score,
    COALESCE(TRIM(review_comment_title),'No Title') AS review_comment_title,
    COALESCE(TRIM(review_comment_message),'No Review') AS review_comment_message,
    review_creation_date::TIMESTAMP AS review_creation_date,
    review_answer_timestamp::TIMESTAMP AS review_answer_timestamp
FROM BRONZE.REVIWES;


CREATE OR REPLACE TABLE SILVER.SILVER_GEOLOCATION AS
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat::NUMBER(10,6) AS geolocation_lat,
    geolocation_lng::NUMBER(10,6) AS geolocation_lng,
    TRIM(LOWER(geolocation_city)) AS geolocation_city,
    TRIM(UPPER(geolocation_state)) AS geolocation_state
FROM BRONZE.GEOLOCATION;


CREATE OR REPLACE TABLE SILVER.SILVER_CATEGORY AS
SELECT
    TRIM(LOWER(C1)) AS category_name_portuguese,
    TRIM(LOWER(C2)) AS category_name_english
FROM BRONZE.CATEGORY_NAME;

------------------------------------------------------------
-- DEDUPLICATION
------------------------------------------------------------

CREATE OR REPLACE TABLE SILVER.SILVER_REVIEWS AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY review_id
               ORDER BY review_answer_timestamp DESC
           ) AS rn
    FROM SILVER.SILVER_REVIEWS
)
WHERE rn = 1;


CREATE OR REPLACE TABLE SILVER.SILVER_PAYMENTS AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, payment_sequential
               ORDER BY payment_value DESC
           ) AS rn
    FROM SILVER.SILVER_PAYMENTS
)
WHERE rn = 1;

------------------------------------------------------------
-- BUSINESS RULES
------------------------------------------------------------

CREATE OR REPLACE TABLE SILVER.SILVER_ORDER_ITEMS AS
SELECT *
FROM SILVER.SILVER_ORDER_ITEMS
WHERE price > 0;


CREATE OR REPLACE TABLE SILVER.SILVER_ORDER_ITEMS AS
SELECT *
FROM SILVER.SILVER_ORDER_ITEMS
WHERE freight_value >= 0;


CREATE OR REPLACE TABLE SILVER.SILVER_ORDERS AS
SELECT *
FROM SILVER.SILVER_ORDERS
WHERE order_status IN (
    'delivered',
    'shipped',
    'canceled',
    'processing',
    'unavailable',
    'invoiced',
    'approved',
    'created'
);


CREATE OR REPLACE TABLE SILVER.SILVER_PAYMENTS AS
SELECT *
FROM SILVER.SILVER_PAYMENTS
WHERE payment_value > 0;


CREATE OR REPLACE TABLE SILVER.SILVER_ORDERS AS
SELECT *
FROM SILVER.SILVER_ORDERS
WHERE order_delivered_customer_date >= order_purchase_timestamp;


CREATE OR REPLACE TABLE SILVER.SILVER_ORDERS AS
SELECT *
FROM SILVER.SILVER_ORDERS
WHERE order_approved_at >= order_purchase_timestamp;


CREATE OR REPLACE TABLE SILVER.SILVER_REVIEWS AS
SELECT *
FROM SILVER.SILVER_REVIEWS
WHERE review_score BETWEEN 1 AND 5;

------------------------------------------------------------
-- GOLD LAYER STARTS HERE
------------------------------------------------------------
------------------------------------------------------------
-- DIM_CUSTOMER
------------------------------------------------------------
MERGE INTO GOLD.DIM_CUSTOMER AS tgt
USING SILVER.SILVER_CUSTOMERS AS src
    ON tgt.customer_id = src.customer_id
WHEN MATCHED AND (
    tgt.customer_city  <> src.customer_city OR
    tgt.customer_state <> src.customer_state
) THEN UPDATE SET
    tgt.customer_city  = src.customer_city,
    tgt.customer_state = src.customer_state,
    tgt.dw_updated_at  = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN INSERT (
    customer_id, customer_unique_id, customer_city, customer_state
) VALUES (
    src.customer_id, src.customer_unique_id, src.customer_city, src.customer_state
);
------------------------------------------------------------
-- DIM_PRODUCT
------------------------------------------------------------

CREATE OR REPLACE TABLE GOLD.DIM_PRODUCT AS
SELECT
    MD5(product_id) AS product_sk,
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    CURRENT_TIMESTAMP AS dw_created_at
FROM SILVER.SILVER_PRODUCTS;


------------------------------------------------------------
-- DIM_SELLER
------------------------------------------------------------

CREATE OR REPLACE TABLE GOLD.DIM_SELLER AS
SELECT
    MD5(seller_id) AS seller_sk,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    CURRENT_TIMESTAMP AS dw_created_at
FROM SILVER.SILVER_SELLERS;


------------------------------------------------------------
-- DIM_DATE
------------------------------------------------------------

CREATE OR REPLACE TABLE GOLD.DIM_DATE AS
WITH date_spine AS
(
    SELECT DATEADD(DAY, SEQ4(), '2016-01-01'::DATE) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
)

SELECT
    TO_NUMBER(TO_CHAR(date_day,'YYYYMMDD')) AS date_sk,
    date_day AS full_date,
    YEAR(date_day) AS year,
    QUARTER(date_day) AS quarter,
    MONTH(date_day) AS month,
    TO_CHAR(date_day,'MMMM') AS month_name,
    WEEKOFYEAR(date_day) AS week_of_year,
    DAYOFMONTH(date_day) AS day_of_month,
    DAYOFWEEK(date_day) AS day_of_week,
    TO_CHAR(date_day,'DY') AS day_name,
    CASE
        WHEN DAYOFWEEK(date_day) IN (0,6)
        THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM date_spine
WHERE date_day BETWEEN '2016-01-01' AND '2020-12-31';


------------------------------------------------------------
-- DIM_PAYMENT
------------------------------------------------------------

CREATE OR REPLACE TABLE GOLD.DIM_PAYMENT AS
SELECT
    MD5(order_id || '-' || CAST(payment_sequential AS VARCHAR)) AS payment_sk,
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value,
    CURRENT_TIMESTAMP AS dw_created_at
FROM SILVER.SILVER_PAYMENTS;


------------------------------------------------------------
-- DIM_REVIEW
------------------------------------------------------------

CREATE OR REPLACE TABLE GOLD.DIM_REVIEW AS
SELECT
    MD5(review_id) AS review_sk,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    CURRENT_TIMESTAMP AS dw_created_at
FROM SILVER.SILVER_REVIEWS;


------------------------------------------------------------
-- FACT_ORDER_ITEMS
------------------------------------------------------------

CREATE OR REPLACE TABLE GOLD.FACT_ORDER_ITEMS AS

SELECT

    MD5(oi.order_id || '-' || CAST(oi.order_item_id AS VARCHAR)) AS order_item_sk,

    MD5(p.product_id) AS product_sk,

    MD5(s.seller_id) AS seller_sk,

    TO_NUMBER(
        TO_CHAR(o.order_purchase_timestamp::DATE,'YYYYMMDD')
    ) AS date_sk,

    dc.customer_sk,

    oi.order_id,
    oi.order_item_id,
    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    oi.price AS item_price,
    oi.freight_value,

    oi.price + oi.freight_value AS total_amount,

    DATEDIFF(
        'day',
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    ) AS actual_delivery_days,

    DATEDIFF(
        'day',
        o.order_purchase_timestamp,
        o.order_estimated_delivery_date
    ) AS estimated_delivery_days,

    DATEDIFF(
        'day',
        o.order_purchase_timestamp,
        o.order_delivered_customer_date
    )
    -
    DATEDIFF(
        'day',
        o.order_purchase_timestamp,
        o.order_estimated_delivery_date
    ) AS delivery_delay_days,

    CURRENT_TIMESTAMP AS dw_created_at

FROM SILVER.SILVER_ORDER_ITEMS oi

JOIN SILVER.SILVER_ORDERS o
ON oi.order_id = o.order_id

JOIN SILVER.SILVER_PRODUCTS p
ON oi.product_id = p.product_id

JOIN SILVER.SILVER_SELLERS s
ON oi.seller_id = s.seller_id

JOIN GOLD.DIM_CUSTOMER dc
ON o.customer_id = dc.customer_id;


------------------------------------------------------------
-- SUCCESS EMAIL AND FAILURE
------------------------------------------------------------
    CALL SYSTEM$SEND_EMAIL(
        'EMAIL_INT',
        'ananyanaveen.230904@gmail.com',
        'ETL Pipeline Status',
        'ETL Pipeline executed successfully.'
    );

    RETURN 'ETL Pipeline Completed Successfully';

EXCEPTION
    WHEN OTHER THEN
        CALL SYSTEM$SEND_EMAIL(
            'EMAIL_INT',
            'ananyanaveen.230904@gmail.com',
            'ETL Pipeline FAILED',
            'The ETL Pipeline failed. Error: ' || SQLERRM
        );
        RETURN 'ETL Pipeline Failed: ' || SQLERRM;

END;
$$;

CALL RUN_ETL_PIPELINE();
CREATE OR REPLACE TASK DAILY_ETL_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = 'USING CRON 0 6 * * * UTC'
AS
CALL RUN_ETL_PIPELINE();
ALTER TASK DAILY_ETL_TASK RESUME;
SHOW TASKS;
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY());

-- testing 
use schema silver;
SELECT COUNT(*)
FROM SILVER.SILVER_ORDERS;

CALL RUN_ETL_PIPELINE();
SELECT COUNT(*) FROM SILVER.SILVER_CUSTOMERS;

SELECT COUNT(*) FROM SILVER.SILVER_ORDERS;

SELECT COUNT(*) FROM SILVER.SILVER_ORDER_ITEMS;

SELECT COUNT(*) FROM SILVER.SILVER_PRODUCTS;
-- gold 
SHOW TABLES IN SCHEMA GOLD;
SELECT COUNT(*) FROM GOLD.DIM_CUSTOMER;

SELECT COUNT(*) FROM GOLD.DIM_PRODUCT;

SELECT COUNT(*) FROM GOLD.DIM_SELLER;

SELECT COUNT(*) FROM GOLD.DIM_DATE;

SELECT COUNT(*) FROM GOLD.DIM_PAYMENT;

SELECT COUNT(*) FROM GOLD.DIM_REVIEW;

SELECT COUNT(*) FROM GOLD.FACT_ORDER_ITEMS;
SHOW TASKS;
EXECUTE TASK DAILY_ETL_TASK;
SHOW TASKS;
SHOW TASKS LIKE 'DAILY_ETL_TASK';
EXECUTE TASK OLIST_PROJECT.PUBLIC.DAILY_ETL_TASK;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE NAME = 'DAILY_ETL_TASK'
ORDER BY SCHEDULED_TIME DESC;
CALL RUN_ETL_PIPELINE();

SELECT COUNT(*)
FROM GOLD.FACT_ORDER_ITEMS;

CREATE NOTIFICATION INTEGRATION email_int
TYPE = EMAIL
ENABLED = TRUE;

CALL SYSTEM$SEND_EMAIL(
    'EMAIL_INT',
    'ananyanaveen.230904@gmail.com',
    'ETL Pipeline Status',
    'ETL Pipeline executed successfully.'
);

CALL SYSTEM$SEND_EMAIL(
'EMAIL_INT',
'ananyanaveen.230904@gmail.com',
'ETL Pipeline Failed',
'The ETL Pipeline failed. Please check Snowflake.'
);
EXECUTE TASK OLIST_PROJECT.PUBLIC.DAILY_ETL_TASK;
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE NAME = 'DAILY_ETL_TASK'
ORDER BY SCHEDULED_TIME DESC
LIMIT 5;