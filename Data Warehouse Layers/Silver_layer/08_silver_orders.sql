USE SalesDW;
GO

IF OBJECT_ID('Silver.orders', 'U') IS NOT NULL 
    DROP TABLE Silver.orders;
GO

CREATE TABLE Silver.orders (
    order_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_status INT NOT NULL,
    order_date DATE NOT NULL,
    required_date DATE NULL,
    shipped_date DATE NULL,
    store_id INT NOT NULL,
    staff_id INT NOT NULL,
    dwh_created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (customer_id) REFERENCES Silver.customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES Silver.stores(store_id),
    FOREIGN KEY (staff_id) REFERENCES Silver.staffs(staff_id)
);
GO

INSERT INTO Silver.orders (
    order_id, customer_id, order_status, order_date, required_date, shipped_date, store_id, staff_id
)
SELECT 
    CAST(TRIM(order_id) AS INT),
    CAST(TRIM(customer_id) AS INT),
    CAST(TRIM(order_status) AS INT),
    TRY_CAST(TRIM(order_date) AS DATE),
    TRY_CAST(TRIM(required_date) AS DATE),
    TRY_CAST(TRIM(shipped_date) AS DATE),
    CAST(TRIM(store_id) AS INT),
    CAST(TRIM(staff_id) AS INT)
FROM Bronze.orders
WHERE order_id IS NOT NULL AND ISNUMERIC(order_id) = 1;
GO

SELECT COUNT(*) AS silver_orders_rows FROM Silver.orders;
GO



