
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



 

-- Step 5: Calculate Unit Return Rate

WITH SalesSummary AS
(
    SELECT
        SUM(Quantity) AS TotalSoldQuantity
    FROM dbo.FactSales
),
ReturnsSummary AS
(
    SELECT
        SUM(ReturnQuantity) AS TotalReturnedQuantity,
        SUM(RefundAmount) AS TotalRefundAmount
    FROM dbo.FactReturns
)
SELECT
    S.TotalSoldQuantity,
    R.TotalReturnedQuantity,

    CAST(
        R.TotalReturnedQuantity * 100.0
        / NULLIF(S.TotalSoldQuantity, 0)
        AS DECIMAL(10, 2)
    ) AS UnitReturnRatePct,

    R.TotalRefundAmount

FROM SalesSummary AS S
CROSS JOIN ReturnsSummary AS R;



-- Step 6: Annual Unit Return Rate by Original Sales Year

WITH ReturnsBySalesLine AS
(
    SELECT
        SalesLineID,
        SUM(ReturnQuantity) AS ReturnedQuantity,
        SUM(RefundAmount) AS RefundAmount
    FROM dbo.FactReturns
    GROUP BY SalesLineID
),
SalesByYear AS
(
    SELECT
        D.CalendarYear,
        SUM(S.Quantity) AS SoldQuantity,
        SUM(COALESCE(R.ReturnedQuantity, 0)) AS ReturnedQuantity,
        SUM(COALESCE(R.RefundAmount, 0)) AS RefundAmount
    FROM dbo.FactSales AS S
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    LEFT JOIN ReturnsBySalesLine AS R
        ON S.SalesLineID = R.SalesLineID
    GROUP BY D.CalendarYear
)
SELECT
    CalendarYear,
    SoldQuantity,
    ReturnedQuantity,
    CAST(
        ReturnedQuantity * 100.0
        / NULLIF(SoldQuantity, 0)
        AS DECIMAL(10, 2)
    ) AS UnitReturnRatePct,
    RefundAmount
FROM SalesByYear
ORDER BY CalendarYear;


-- Step 7: Unit Return Rate by Product Category

WITH ReturnsBySalesLine AS
(
    SELECT
        SalesLineID,
        SUM(ReturnQuantity) AS ReturnedQuantity,
        SUM(RefundAmount) AS RefundAmount
    FROM dbo.FactReturns
    GROUP BY SalesLineID
)
SELECT
    P.Category,
    SUM(S.Quantity) AS SoldQuantity,
    SUM(COALESCE(R.ReturnedQuantity, 0)) AS ReturnedQuantity,
    CAST(
        SUM(COALESCE(R.ReturnedQuantity, 0)) * 100.0
        / NULLIF(SUM(S.Quantity), 0)
        AS DECIMAL(10, 2)
    ) AS UnitReturnRatePct,
    SUM(COALESCE(R.RefundAmount, 0)) AS TotalRefundAmount
FROM dbo.FactSales AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
LEFT JOIN ReturnsBySalesLine AS R
    ON S.SalesLineID = R.SalesLineID
GROUP BY
    P.Category
ORDER BY
    UnitReturnRatePct DESC;



-- Step 8: Return Reasons Analysis

 SELECT
    RR.ReasonCode,
    RR.ReasonName,
    COUNT_BIG(*) AS ReturnEvents,
    SUM(R.ReturnQuantity) AS ReturnedQuantity,
    SUM(R.RefundAmount) AS TotalRefundAmount,
    CAST(
        COUNT_BIG(*) * 100.0
        / SUM(COUNT_BIG(*)) OVER ()
        AS DECIMAL(10, 2)
    ) AS ReturnEventSharePct
FROM dbo.FactReturns AS R
INNER JOIN dbo.DimReturnReason AS RR
    ON R.ReturnReasonKey = RR.ReturnReasonKey
GROUP BY
    RR.ReasonCode,
    RR.ReasonName
ORDER BY
    ReturnEvents DESC;


-- Step 9: Return Rate by Sales Channel

WITH ReturnsBySalesLine AS
(
    SELECT
        SalesLineID,
        SUM(ReturnQuantity) AS ReturnedQuantity,
        SUM(RefundAmount) AS RefundAmount
    FROM dbo.FactReturns
    GROUP BY SalesLineID
)
SELECT
    C.ChannelName,
    SUM(S.Quantity) AS SoldQuantity,
    SUM(COALESCE(R.ReturnedQuantity, 0)) AS ReturnedQuantity,
    CAST(
        SUM(COALESCE(R.ReturnedQuantity, 0)) * 100.0
        / NULLIF(SUM(S.Quantity), 0)
        AS DECIMAL(10, 2)
    ) AS UnitReturnRatePct,
    SUM(COALESCE(R.RefundAmount, 0)) AS TotalRefundAmount
FROM dbo.FactSales AS S
INNER JOIN dbo.DimChannel AS C
    ON S.ChannelKey = C.ChannelKey
LEFT JOIN ReturnsBySalesLine AS R
    ON S.SalesLineID = R.SalesLineID
GROUP BY
    C.ChannelName
ORDER BY
    UnitReturnRatePct DESC;



-- Step 10: Products with the Highest Return Rates

WITH ReturnsBySalesLine AS
(
    SELECT
        SalesLineID,
        SUM(ReturnQuantity) AS ReturnedQuantity,
        SUM(RefundAmount) AS RefundAmount
    FROM dbo.FactReturns
    GROUP BY SalesLineID
),
ProductReturns AS
(
    SELECT
        P.ProductKey,
        P.ProductID,
        P.ProductName,
        P.Category,
        SUM(S.Quantity) AS SoldQuantity,
        SUM(COALESCE(R.ReturnedQuantity, 0)) AS ReturnedQuantity,
        SUM(COALESCE(R.RefundAmount, 0)) AS TotalRefundAmount
    FROM dbo.FactSales AS S
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    LEFT JOIN ReturnsBySalesLine AS R
        ON S.SalesLineID = R.SalesLineID
    GROUP BY
        P.ProductKey,
        P.ProductID,
        P.ProductName,
        P.Category
)
SELECT TOP (10)
    ProductID,
    ProductName,
    Category,
    SoldQuantity,
    ReturnedQuantity,
    CAST(
        ReturnedQuantity * 100.0
        / NULLIF(SoldQuantity, 0)
        AS DECIMAL(10, 2)
    ) AS UnitReturnRatePct,
    TotalRefundAmount
FROM ProductReturns
WHERE SoldQuantity >= 500
ORDER BY
    UnitReturnRatePct DESC,
    ReturnedQuantity DESC;