/*
SELECT
    C.name AS ColumnName,
    TYPE_NAME(C.user_type_id) AS DataType
FROM sys.columns AS C
INNER JOIN sys.tables AS T
    ON C.object_id = T.object_id
INNER JOIN sys.schemas AS S
    ON T.schema_id = S.schema_id
WHERE T.name = 'FactSales'
  AND S.name = 'dbo'
  AND (
      C.name LIKE '%Date%'
      OR C.name LIKE '%Quantity%'
      OR C.name = 'SalesLineID'
  )
ORDER BY C.column_id;

*/


WITH MonthlySales AS
(
    SELECT
        D.CalendarYear,
        D.MonthNumber,
        D.MonthName,
        SUM(S.Quantity) AS UnitsSold
    FROM dbo.FactSales AS S
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    GROUP BY
        D.CalendarYear,
        D.MonthNumber,
        D.MonthName
),
MonthlyReturnsBySaleDate AS
(
    SELECT
        D.CalendarYear,
        D.MonthNumber,
        SUM(R.ReturnQuantity) AS ReturnedUnits
    FROM dbo.FactReturns AS R
    INNER JOIN dbo.FactSales AS S
        ON R.SalesLineID = S.SalesLineID
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    GROUP BY
        D.CalendarYear,
        D.MonthNumber
)
SELECT
    MS.CalendarYear,
    MS.MonthNumber,
    MS.MonthName,
    MS.UnitsSold,
    COALESCE(MR.ReturnedUnits, 0) AS ReturnedUnits,
    CAST(
        COALESCE(MR.ReturnedUnits, 0) * 100.0
        / NULLIF(MS.UnitsSold, 0)
        AS DECIMAL(6,2)
    ) AS UnitReturnRatePct
FROM MonthlySales AS MS
LEFT JOIN MonthlyReturnsBySaleDate AS MR
    ON MS.CalendarYear = MR.CalendarYear
    AND MS.MonthNumber = MR.MonthNumber
ORDER BY
    MS.CalendarYear,
    MS.MonthNumber;
