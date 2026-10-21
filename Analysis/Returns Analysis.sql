
USE RetailIntelligence;
GO

-- Step 1: Inspect the Returns table
SELECT TOP (20)
    *
FROM dbo.FactReturns;



-- Step 1.2: Inspect column names and data types
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'FactReturns'
ORDER BY ORDINAL_POSITION;




-- Step 2: Understand return records

SELECT
    COUNT_BIG(*) AS TotalReturnEvents,

    COUNT(DISTINCT ReturnID) AS DistinctReturnIDs,

    COUNT(DISTINCT SalesLineID) AS DistinctSalesLines,

    SUM(ReturnQuantity) AS TotalReturnedQuantity,

    SUM(RefundAmount) AS TotalRefundAmount,

    MIN(ReturnDateKey) AS FirstReturnDateKey,

    MAX(ReturnDateKey) AS LastReturnDateKey

FROM dbo.FactReturns;




-- Step 3: Validate return-to-sales relationships

SELECT
    COUNT_BIG(*) AS TotalReturnRows,

    SUM(
        CASE
            WHEN S.SalesLineID IS NULL THEN 1
            ELSE 0
        END
    ) AS OrphanReturnRows,

    SUM(
        CASE
            WHEN R.ReturnQuantity <= 0 THEN 1
            ELSE 0
        END
    ) AS InvalidReturnQuantityRows,

    SUM(
        CASE
            WHEN R.RefundAmount < 0 THEN 1
            ELSE 0
        END
    ) AS NegativeRefundRows,

    SUM(
        CASE
            WHEN R.ReturnQuantity > S.Quantity THEN 1
            ELSE 0
        END
    ) AS ReturnsExceedSoldQuantityRows

FROM dbo.FactReturns AS R
LEFT JOIN dbo.FactSales AS S
    ON R.SalesLineID = S.SalesLineID;

    



-- Step 4: Check cumulative returns per sales line

WITH ReturnsBySalesLine AS
(
    SELECT
        SalesLineID,
        SUM(ReturnQuantity) AS TotalReturnedQuantity
    FROM dbo.FactReturns
    GROUP BY SalesLineID
)
SELECT
    COUNT_BIG(*) AS SalesLinesWithReturns,

    SUM(
        CASE
            WHEN R.TotalReturnedQuantity > S.Quantity THEN 1
            ELSE 0
        END
    ) AS SalesLinesWithExcessReturns,

    MAX(R.TotalReturnedQuantity) AS MaxReturnedQuantityPerSalesLine,

    MAX(S.Quantity) AS MaxSoldQuantityPerSalesLine

FROM ReturnsBySalesLine AS R
INNER JOIN dbo.FactSales AS S
    ON R.SalesLineID = S.SalesLineID;
