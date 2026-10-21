
SELECT
    COUNT_BIG(*) AS TotalReturnRows,
    COUNT_BIG(S.SalesLineID) AS MatchedSalesRows,
    COUNT_BIG(*) - COUNT_BIG(S.SalesLineID) AS UnmatchedReturnRows,
    SUM(R.ReturnQuantity) AS TotalReturnedUnits
FROM dbo.FactReturns AS R
LEFT JOIN dbo.FactSales AS S
    ON R.SalesLineID = S.SalesLineID;




SELECT
    D.CalendarYear,
    D.MonthNumber,
    D.MonthName,
    COUNT_BIG(*) AS SalesLines,
    SUM(S.Quantity) AS UnitsSold,
    COUNT_BIG(R.ReturnEventID) AS ReturnEvents,
    COALESCE(SUM(R.ReturnQuantity), 0) AS ReturnedUnits
FROM dbo.FactSales AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
LEFT JOIN dbo.FactReturns AS R
    ON S.SalesLineID = R.SalesLineID
WHERE D.CalendarYear = 2025
  AND D.MonthNumber = 12
GROUP BY
    D.CalendarYear,
    D.MonthNumber,
    D.MonthName;




SELECT
    DATEDIFF(
        DAY,
        SaleDate.FullDate,
        ReturnDate.FullDate
    ) AS DaysToReturn,
    COUNT_BIG(*) AS ReturnEvents,
    SUM(R.ReturnQuantity) AS ReturnedUnits
FROM dbo.FactReturns AS R
INNER JOIN dbo.FactSales AS S
    ON R.SalesLineID = S.SalesLineID
INNER JOIN dbo.DimDate AS SaleDate
    ON S.OrderDateKey = SaleDate.DateKey
INNER JOIN dbo.DimDate AS ReturnDate
    ON R.ReturnDateKey = ReturnDate.DateKey
GROUP BY
    DATEDIFF(
        DAY,
        SaleDate.FullDate,
        ReturnDate.FullDate
    )
ORDER BY
    DaysToReturn;




SELECT
    MIN(
        DATEDIFF(
            DAY,
            SaleDate.FullDate,
            ReturnDate.FullDate
        )
    ) AS MinDaysToReturn,
    MAX(
        DATEDIFF(
            DAY,
            SaleDate.FullDate,
            ReturnDate.FullDate
        )
    ) AS MaxDaysToReturn,
    COUNT_BIG(*) AS TotalReturnEvents,
    SUM(R.ReturnQuantity) AS TotalReturnedUnits
FROM dbo.FactReturns AS R
INNER JOIN dbo.FactSales AS S
    ON R.SalesLineID = S.SalesLineID
INNER JOIN dbo.DimDate AS SaleDate
    ON S.OrderDateKey = SaleDate.DateKey
INNER JOIN dbo.DimDate AS ReturnDate
    ON R.ReturnDateKey = ReturnDate.DateKey;


