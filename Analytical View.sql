CREATE OR ALTER VIEW dbo.vw_SalesAnalytics AS 
SELECT 
	F.SalesLineID,
	F.OrderID,
	F.SalesLineNumber,
	F.OrderDateKey,
	F.CustomerKey,
	F.ProductKey,
	F.StoreKey,
	F.ChannelKey,
	F.Quantity,
	F.UnitPrice,
	F.DiscountRate,
	F.UnitCost,
	CAST(F.UnitPrice * F.Quantity AS DECIMAL(19,2)) [Gross Sales],
	CAST(F.UnitPrice * F.Quantity * F.DiscountRate AS DECIMAL(19,2))[Discount Amount],
	CAST(F.UnitPrice * F.Quantity * (1 - F.DiscountRate)AS DECIMAL(19,2)) [Net Sales Before Returns],
	CAST(F.UnitCost *  F.Quantity AS DECIMAL(19,2))  COGS,
	CAST(F.UnitPrice * F.Quantity * (1 - F.DiscountRate) - (F.Quantity * F.UnitCost) AS DECIMAL(19,2)) AS [Gross Profit Before Returns],
	CAST(
    (
        F.UnitPrice * F.Quantity * (1 - F.DiscountRate)
        - F.Quantity * F.UnitCost
    )
    / NULLIF(
        F.Quantity * F.UnitPrice * (1 - F.DiscountRate),
        0
    ) * 100
    AS DECIMAL(9,2)
) AS [Gross MarginPct]

FROM FactSales F

--check view 
/*

SELECT TOP (10)
    SalesLineID,
    OrderID,
    Quantity,
    UnitPrice,
    DiscountRate,
    [Gross Sales],
    [Discount Amount],
    [Net Sales Before Returns],
    COGS,
    [Gross Profit Before Returns],
    [Gross MarginPct]
FROM dbo.vw_SalesAnalytics
ORDER BY SalesLineID;


-- Compare row counts
SELECT
    (SELECT COUNT_BIG(*)
     FROM dbo.FactSales) AS FactSalesRows,

    (SELECT COUNT_BIG(*)
     FROM dbo.vw_SalesAnalytics) AS ViewRows;
*/

/*
SELECT TOP (10)
    SalesLineID,
    [Net Sales Before Returns],
    [Gross Profit Before Returns],
    [Gross MarginPct]
FROM dbo.vw_SalesAnalytics
ORDER BY SalesLineID;
*/


SELECT
    COUNT_BIG(*) AS TotalSalesLines,
    SUM(Quantity) AS TotalUnitsSold,

    CAST(SUM([Gross Sales]) AS DECIMAL(19,2))
        AS TotalGrossSales,

    CAST(SUM([Discount Amount]) AS DECIMAL(19,2))
        AS TotalDiscountAmount,

    CAST(SUM([Net Sales Before Returns]) AS DECIMAL(19,2))
        AS TotalNetSalesBeforeReturns,

    CAST(SUM(COGS) AS DECIMAL(19,2))
        AS TotalCOGS,

    CAST(SUM([Gross Profit Before Returns]) AS DECIMAL(19,2))
        AS TotalGrossProfitBeforeReturns,

    CAST(
        SUM([Gross Profit Before Returns])
        / NULLIF(SUM([Net Sales Before Returns]), 0)
        * 100
        AS DECIMAL(9,2)
    ) AS OverallGrossMarginPct

FROM dbo.vw_SalesAnalytics;
GO
