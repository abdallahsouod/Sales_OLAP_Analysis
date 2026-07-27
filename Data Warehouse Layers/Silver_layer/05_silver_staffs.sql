USE SalesDW;
GO

IF OBJECT_ID('Silver.staffs', 'U') IS NOT NULL 
    DROP TABLE Silver.staffs;
GO

CREATE TABLE Silver.staffs (
    staff_id INT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(50) NULL,
    active INT NOT NULL,
    store_id INT NOT NULL, -- إرجاع الشرط NOT NULL
    manager_id INT NULL,
    dwh_created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (store_id) REFERENCES Silver.stores(store_id)
);
GO

INSERT INTO Silver.staffs (
    staff_id, first_name, last_name, email, phone, active, store_id, manager_id
)
SELECT 
    CAST(TRIM(staff_id) AS INT),
    TRIM(first_name),
   -- تحويل أي NULL أو نص فاضي إلى 'Unknown'
    ISNULL(NULLIF(TRIM(last_name), ''), 'Unknown') AS last_name,
    LOWER(TRIM(email)),
    NULLIF(TRIM(phone), ''),
    CAST(TRIM(active) AS INT),
    CAST(TRIM(store_id) AS INT),
    TRY_CAST(TRIM(manager_id) AS INT)
FROM Bronze.staffs
WHERE staff_id IS NOT NULL 
  AND ISNUMERIC(staff_id) = 1
  -- تسقيط أي صف الـ store_id فيه NULL أو مش رقم
  AND TRY_CAST(TRIM(store_id) AS INT) IS NOT NULL; 
GO

SELECT COUNT(*) AS silver_staffs_rows FROM Silver.staffs;
GO


