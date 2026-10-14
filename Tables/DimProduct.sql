;WITH Numbers AS
(
    SELECT TOP (1000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
ProductAttributes AS
(
    SELECT
        n,
        CASE
            WHEN n % 10 IN (0, 1, 2, 3, 4, 5, 6)
                THEN 'Clothing'
            WHEN n % 10 IN (7, 8)
                THEN 'Footwear'
            ELSE 'Accessories'
        END AS Category
    FROM Numbers
),
Subcategories AS
(
    SELECT
        n,
        Category,
        CASE
            WHEN Category = 'Clothing' THEN
                CASE n % 7
                    WHEN 0 THEN 'T-Shirts'
                    WHEN 1 THEN 'Shirts'
                    WHEN 2 THEN 'Jeans'
                    WHEN 3 THEN 'Trousers'
                    WHEN 4 THEN 'Dresses'
                    WHEN 5 THEN 'Jackets'
                    ELSE 'Skirts'
                END
            WHEN Category = 'Footwear' THEN
                CASE n % 4
                    WHEN 0 THEN 'Sneakers'
                    WHEN 1 THEN 'Boots'
                    WHEN 2 THEN 'Sandals'
                    ELSE 'Formal Shoes'
                END
            ELSE
                CASE n % 5
                    WHEN 0 THEN 'Bags'
                    WHEN 1 THEN 'Belts'
                    WHEN 2 THEN 'Hats'
                    WHEN 3 THEN 'Scarves'
                    ELSE 'Watches'
                END
        END AS Subcategory
    FROM ProductAttributes
)
INSERT INTO dbo.DimProduct
(
    ProductID,
    ProductName,
    SKU,
    Brand,
    Category,
    Subcategory
)
SELECT
    CONCAT('PRD', RIGHT(CONCAT('00000', n), 5)),
    CONCAT(Category, N' ', Subcategory, N' Model ', n),
    CONCAT('SKU-', RIGHT(CONCAT('00000', n), 5)),
    CASE n % 6
        WHEN 0 THEN 'NovaWear'
        WHEN 1 THEN 'UrbanStyle'
        WHEN 2 THEN 'ModaLine'
        WHEN 3 THEN 'TrendHouse'
        WHEN 4 THEN 'ClassicFit'
        ELSE 'EverydayCo'
    END,
    Category,
    Subcategory
FROM Subcategories;
GO

-- Validate product volume and uniqueness
/*
SELECT
    COUNT(*) AS TotalProducts,
    COUNT(DISTINCT ProductID) AS UniqueProductIDs,
    COUNT(DISTINCT SKU) AS UniqueSKUs,
    COUNT(DISTINCT Category) AS TotalCategories,
    COUNT(DISTINCT Subcategory) AS TotalSubcategories,
    COUNT(DISTINCT Brand) AS TotalBrands
FROM dbo.DimProduct;
*/

-- Review product distribution
/*
SELECT
    Category,
    Subcategory,
    COUNT(*) AS ProductCount
FROM dbo.DimProduct
GROUP BY
    Category,
    Subcategory
ORDER BY
    Category,
    Subcategory;
*/