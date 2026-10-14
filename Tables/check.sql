
USE RetailIntelligence;
GO

-- 1. Check return quantity against sold quantity
SELECT
    COUNT_BIG(*) AS InvalidQuantityRows
FROM dbo.FactReturns AS r
INNER JOIN dbo.FactSales AS s
    ON r.SalesLineID = s.SalesLineID
WHERE r.ReturnQuantity > s.Quantity;
GO

-- 2. Check that return dates are not before sales dates
SELECT
    COUNT_BIG(*) AS InvalidReturnDateRows
FROM dbo.FactReturns AS r
INNER JOIN dbo.FactSales AS s
    ON r.SalesLineID = s.SalesLineID
WHERE r.ReturnDateKey < s.OrderDateKey;
GO

-- 3. Check refund amount calculation
SELECT
    COUNT_BIG(*) AS InvalidRefundAmountRows
FROM dbo.FactReturns AS r
INNER JOIN dbo.FactSales AS s
    ON r.SalesLineID = s.SalesLineID
WHERE r.RefundAmount <>
      CONVERT(
          DECIMAL(12,2),
          ROUND(
              r.ReturnQuantity
              * s.UnitPrice
              * (1 - s.DiscountRate),
              2
          )
      );
GO

-- 4. Check date and reason dimension references
SELECT
    SUM(CASE WHEN d.DateKey IS NULL THEN 1 ELSE 0 END)
        AS MissingReturnDates,
    SUM(CASE WHEN rr.ReturnReasonKey IS NULL THEN 1 ELSE 0 END)
        AS MissingReturnReasons
FROM dbo.FactReturns AS r
LEFT JOIN dbo.DimDate AS d
    ON r.ReturnDateKey = d.DateKey
LEFT JOIN dbo.DimReturnReason AS rr
    ON r.ReturnReasonKey = rr.ReturnReasonKey;
GO
