CREATE database retail_analysis;
USE retail_analysis;
show tables;
select * from customers_dataset_csv;
select * from customers;
select * from geolocation;
select * from order_items;
select * from orders;
select * from products;
select * from order_review;
SELECT COUNT(*) AS Customers FROM customers;
SELECT COUNT(*) AS Orders FROM orders;
SELECT COUNT(*) AS Order_Items FROM order_items;
SELECT COUNT(*) AS Products FROM products;
SELECT COUNT(*) AS Geolocation FROM geolocation;

DESCRIBE customers;
DESCRIBE orders;
DESCRIBE order_items;
DESCRIBE products;
DESCRIBE geolocation;

SELECT *
FROM customers
WHERE customer_id IS NULL
   OR customer_zip_code IS NULL
   OR gender IS NULL
   OR age_group IS NULL
   OR customer_segment IS NULL;
   
SELECT *
FROM orders
WHERE order_id IS NULL
   OR customer_id IS NULL
   OR order_status IS NULL
   OR payment_type IS NULL
   OR order_purchase_timestamp IS NULL or order_delivered_shipping_date is null or order_delivered_customer_date is null or order_estimated_delivery_date is null;
   
SELECT *
FROM order_items
WHERE order_item_id IS NULL
   OR order_id IS NULL
   OR product_id IS NULL
   OR quantity IS NULL
   OR unit_price IS NULL
   OR `discount(%)` IS NULL
   OR shipping_cost IS NULL;
   
SELECT *
FROM products
WHERE product_id IS NULL
   OR Category_name IS NULL
   OR sub_category_name IS NULL
   OR brand IS NULL
   OR cost_price IS NULL
   OR selling_price IS NULL;
   
SELECT *
FROM geolocation
WHERE geolocation_zip_code IS NULL
   OR geolocation_city IS NULL
   OR geolocation_state IS NULL
   OR geolocation_lat IS NULL
   OR geolocation_lng IS NULL
   OR region IS NULL;
   
SELECT customer_id,
COUNT(*) AS Duplicate_Count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id,
COUNT(*) AS Duplicate_Count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

select order_item_id ,
count(*) as Duplicate_count 
from order_items
group by order_item_id
having count(*) > 1;

select product_id ,
count(*) as Duplicate_count
from products
group by product_id
having count(*) > 1;

-- Top 10 Brands by Revenue
SELECT
    p.brand,
    ROUND(
        SUM(
            (oi.unit_price * oi.quantity) *
            (1 - oi.`discount(%)` / 100)
        ),2
    ) AS Revenue
FROM products p
INNER JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.brand
ORDER BY Revenue DESC
LIMIT 10;

-- Bottom 10 Selling Products
SELECT
    p.product_id,
    p.brand,
    p.Category_name,
    SUM(oi.quantity) AS Units_Sold
FROM products p
INNER JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.brand,
    p.Category_name
ORDER BY Units_Sold ASC
LIMIT 10;

-- top 10 product orders
SELECT
    p.product_id,
    p.Category_name,
    p.brand,
    COUNT(DISTINCT oi.order_id) AS Total_Orders
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.Category_name,
    p.brand
ORDER BY Total_Orders DESC
LIMIT 10;

-- top 10 highest rated products
SELECT
    p.product_id,
    p.Category_name,
    p.brand,
    ROUND(AVG(r.review_score),2) AS Average_Rating
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
JOIN order_review r
ON oi.order_id = r.order_id
GROUP BY
    p.product_id,
    p.Category_name,
    p.brand
HAVING COUNT(r.review_score) >= 1
ORDER BY Average_Rating ASC
LIMIT 10;

-- Top 10 Categories by Average Shipping Cost
SELECT
    p.Category_name,
    ROUND(
        AVG(oi.shipping_cost),2
    ) AS Average_Shipping_Cost
FROM products p
INNER JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.Category_name
ORDER BY Average_Shipping_Cost DESC
LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------

-- Monthly Product Revenue Trend
SELECT
    MONTHNAME(o.order_purchase_timestamp) AS Month,
    MONTH(o.order_purchase_timestamp) AS Month_No,
    ROUND(
        SUM((oi.unit_price * oi.quantity) *
        (1 - oi.`discount(%)`/100)),2
    ) AS Revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_id = p.product_id
GROUP BY
    MONTH(o.order_purchase_timestamp),
    MONTHNAME(o.order_purchase_timestamp)
ORDER BY Month_No;

-- Price vs Quantity Sold
SELECT
    p.product_id,
    p.selling_price,
    SUM(oi.quantity) AS Units_Sold
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY
    p.product_id,
    p.selling_price;

-- Product Price Distribution
SELECT
CASE
    WHEN selling_price < 5000 THEN '0 - 4,999'
    WHEN selling_price < 10000 THEN '5,000 - 9,999'
    WHEN selling_price < 20000 THEN '10,000 - 19,999'
    WHEN selling_price < 50000 THEN '20,000 - 49,999'
    WHEN selling_price < 100000 THEN '50,000 - 99,999'
    ELSE '100,000+'
END AS Price_Range,
COUNT(*) AS Number_of_Products
FROM products
GROUP BY Price_Range
ORDER BY
CASE Price_Range
    WHEN '0 - 4,999' THEN 1
    WHEN '5,000 - 9,999' THEN 2
    WHEN '10,000 - 19,999' THEN 3
    WHEN '20,000 - 49,999' THEN 4
    WHEN '50,000 - 99,999' THEN 5
    ELSE 6
END;

-- stored procedure
DELIMITER //
CREATE PROCEDURE GetTopProducts()
BEGIN
SELECT
p.product_id,
p.brand,
SUM(oi.quantity) Units_Sold
FROM products p
JOIN order_items oi
ON p.product_id=oi.product_id
GROUP BY
p.product_id,
p.brand
ORDER BY Units_Sold DESC
LIMIT 10;
END //
DELIMITER ;

CALL GetTopProducts();

-- Trigger Update stock automatically when an order item is inserted
DELIMITER //
CREATE TRIGGER trg_UpdateStock
AFTER INSERT
ON order_items
FOR EACH ROW
BEGIN
UPDATE products
SET stock_availability='Low Stock'
WHERE product_id=NEW.product_id
AND stock_availability='In Stock';
END //
DELIMITER ;

-- Transaction Apply a seasonal discount
START TRANSACTION;
UPDATE products
SET selling_price=selling_price*0.90
WHERE Category_name='Electronics';
COMMIT;

    


