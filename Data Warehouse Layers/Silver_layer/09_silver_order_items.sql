USE SalesDW;
GO

IF OBJECT_ID('Silver.order_items', 'U') IS NOT NULL 
    DROP TABLE Silver.order_items;
GO

CREATE TABLE Silver.order_items (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    list_price DECIMAL(10, 2) NOT NULL,
    discount DECIMAL(4, 2) NOT NULL,
    dwh_created_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (order_id, item_id),
    FOREIGN KEY (order_id) REFERENCES Silver.orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Silver.products(product_id)
);
GO

-- [تعديل 1]: استخدام CTE (جدول مؤقت) عشان نقدر نرقم الصفوف ونعزل المكرر
WITH CleanedAndRankedOrderItems AS (
    SELECT 
        TRY_CAST(TRIM(order_id) AS INT) AS clean_order_id,                  -- [تعديل 2]: استبدال CAST بـ TRY_CAST في كل العواميد لتجنب توقف الكود بسبب الحروف
        TRY_CAST(TRIM(item_id) AS INT) AS clean_item_id,                    -- [تعديل 2]
        TRY_CAST(TRIM(product_id) AS INT) AS clean_product_id,              -- [تعديل 2]
        TRY_CAST(TRIM(quantity) AS INT) AS clean_quantity,                  -- [تعديل 2]
        TRY_CAST(TRIM(list_price) AS DECIMAL(10, 2)) AS clean_list_price,   -- [تعديل 2]
        TRY_CAST(TRIM(discount) AS DECIMAL(4, 2)) AS clean_discount,        -- [تعديل 2]
        
        -- [تعديل 3]: ترقيم الصفوف بناءً على المفتاح المركب (order_id + item_id) لاكتشاف التكرار
        ROW_NUMBER() OVER (
            PARTITION BY 
                TRY_CAST(TRIM(order_id) AS INT), 
                TRY_CAST(TRIM(item_id) AS INT)
            ORDER BY (SELECT NULL)
        ) AS row_num
    FROM Bronze.order_items
    -- [تعديل 4]: استبعاد الصفوف اللي الـ IDs بتاعتها باظت وتحولت لـ NULL بعد الـ TRY_CAST
    WHERE TRY_CAST(TRIM(order_id) AS INT) IS NOT NULL 
      AND TRY_CAST(TRIM(item_id) AS INT) IS NOT NULL
)
INSERT INTO Silver.order_items (
    order_id, item_id, product_id, quantity, list_price, discount
)
SELECT 
    clean_order_id,
    clean_item_id,
    ISNULL(clean_product_id, -1),    -- [تعديل 5]: وضع قيم افتراضية بدل الـ NULL للحفاظ على شرط الـ NOT NULL في الجدول
    ISNULL(clean_quantity, 1),       -- [تعديل 5]
    ISNULL(clean_list_price, 0.00),  -- [تعديل 5]
    ISNULL(clean_discount, 0.00)     -- [تعديل 5]
FROM CleanedAndRankedOrderItems
WHERE row_num = 1;                   -- [تعديل 6]: اختيار الصف الأول فقط من كل تكرار لتجنب خطأ Primary Key
GO

SELECT COUNT(*) AS silver_order_items_rows FROM Silver.order_items;
GO 

