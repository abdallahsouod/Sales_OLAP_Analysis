USE SalesDW;
GO

IF OBJECT_ID('Silver.products', 'U') IS NOT NULL 
    DROP TABLE Silver.products;
GO

CREATE TABLE Silver.products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    brand_id INT NOT NULL,
    category_id INT NOT NULL,
    model_year INT NULL,
    list_price DECIMAL(10, 2) NOT NULL,
    dwh_created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (brand_id) REFERENCES Silver.brands(brand_id),
    FOREIGN KEY (category_id) REFERENCES Silver.categories(category_id)
);
GO

-- [تعديل 1]: استخدام CTE وحساب ROW_NUMBER لحل مشكلة التكرار (Deduplication)
WITH CleanedAndRankedProducts AS (
    SELECT 
        TRY_CAST(TRIM(product_id) AS INT) AS clean_product_id, -- [تعديل 2]: استخدام TRY_CAST بدلاً من CAST للتحويل الآمن للقيم العدديّة
        TRIM(product_name) AS clean_product_name,
        TRY_CAST(TRIM(brand_id) AS INT) AS clean_brand_id,
        TRY_CAST(TRIM(category_id) AS INT) AS clean_category_id,
        TRY_CAST(TRIM(model_year) AS INT) AS clean_model_year,
        TRY_CAST(TRIM(list_price) AS DECIMAL(10, 2)) AS clean_list_price,
        -- ترتيب الصفوف المتكررة لتمييز النسخة الأولى برقم 1
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(product_id) 
            ORDER BY (SELECT NULL)
        ) AS row_num -- [تعديل 3]: ترقيم الصفوف المكررة لنفس الـ product_id
    FROM Bronze.products
    WHERE product_id IS NOT NULL AND ISNUMERIC(product_id) = 1
)
INSERT INTO Silver.products (
    product_id, product_name, brand_id, category_id, model_year, list_price
)
SELECT 
    clean_product_id,
    ISNULL(clean_product_name, 'Unknown'), -- [تعديل 4]: معالجة الـ NULLs لعدم كسر شرط NOT NULL
    ISNULL(clean_brand_id, -1),
    ISNULL(clean_category_id, -1),
    clean_model_year,
    ISNULL(clean_list_price, 0.00)
FROM CleanedAndRankedProducts
WHERE row_num = 1; -- [تعديل 5]: تصفية النتائج لأخذ الصف الأول فقط واستبعاد التكرار تماماً
GO

SELECT COUNT(*) AS silver_products_rows FROM Silver.products;
GO

