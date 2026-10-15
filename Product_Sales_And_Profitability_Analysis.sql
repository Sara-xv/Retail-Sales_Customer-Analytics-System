
SELECT
    P.ProductKey,
    P.ProductName,
    P.Category,
    SUM(S.Quantity) AS UnitsSold,
    COUNT_BIG(*) AS SalesLines,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSalesBeforeReturns,
    CAST(
        SUM(S.COGS)
        AS DECIMAL(19, 2)
    ) AS TotalCOGS,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfitBeforeReturns,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(SUM(S.[Net Sales Before Returns]), 0)
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.ProductKey,
    P.ProductName,
    P.Category
ORDER BY
    GrossProfitBeforeReturns DESC;




SELECT TOP (10)
    P.ProductKey,
    P.ProductName,
    P.Category,
    SUM(S.Quantity) AS UnitsSold,
    COUNT_BIG(*) AS SalesLines,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSalesBeforeReturns,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfitBeforeReturns,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(SUM(S.[Net Sales Before Returns]), 0)
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.ProductKey,
    P.ProductName,
    P.Category
ORDER BY
    UnitsSold DESC,
    NetSalesBeforeReturns DESC;




SELECT
    P.Category,
    COUNT(DISTINCT P.ProductKey) AS ProductCount,
    SUM(S.Quantity) AS UnitsSold,
    COUNT_BIG(*) AS SalesLines,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSalesBeforeReturns,
    CAST(
        SUM(S.COGS)
        AS DECIMAL(19, 2)
    ) AS TotalCOGS,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfitBeforeReturns,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(SUM(S.[Net Sales Before Returns]), 0)
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.Category
ORDER BY
    GrossProfitBeforeReturns DESC;





WITH CategoryPerformance AS
(
    SELECT
        P.Category,
        SUM(S.Quantity) AS UnitsSold,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    GROUP BY
        P.Category
)
SELECT
    Category,
    UnitsSold,
    CAST(NetSales AS DECIMAL(19, 2)) AS NetSales,
    CAST(GrossProfit AS DECIMAL(19, 2)) AS GrossProfit,
    CAST(
        NetSales * 100.0
        / NULLIF(SUM(NetSales) OVER (), 0)
        AS DECIMAL(6, 2)
    ) AS RevenueSharePct,
    CAST(
        GrossProfit * 100.0
        / NULLIF(SUM(GrossProfit) OVER (), 0)
        AS DECIMAL(6, 2)
    ) AS ProfitSharePct
FROM CategoryPerformance
ORDER BY
    GrossProfit DESC;





SELECT
    P.Category,
    CAST(
        SUM(S.[Gross Sales])
        AS DECIMAL(19, 2)
    ) AS GrossSales,
    CAST(
        SUM(S.[Discount Amount])
        AS DECIMAL(19, 2)
    ) AS TotalDiscount,
    CAST(
        SUM(S.[Discount Amount]) * 100.0
        / NULLIF(SUM(S.[Gross Sales]), 0)
        AS DECIMAL(6, 2)
    ) AS DiscountRatePct,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSalesBeforeReturns,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfitBeforeReturns,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(SUM(S.[Net Sales Before Returns]), 0)
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.Category
ORDER BY
    DiscountRatePct DESC;



SELECT
    P.Category,
    CAST(
        SUM(S.[Gross Sales]) AS DECIMAL(19, 2)
    ) AS GrossSalesBeforeDiscount,
    CAST(
        SUM(S.[Gross Sales]) - SUM(S.COGS)
        AS DECIMAL(19, 2)
    ) AS GrossProfitBeforeDiscount,
    CAST(
        (
            SUM(S.[Gross Sales]) - SUM(S.COGS)
        ) * 100.0
        / NULLIF(SUM(S.[Gross Sales]), 0)
        AS DECIMAL(6, 2)
    ) AS GrossMarginBeforeDiscountPct,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfitAfterDiscount,
    CAST(
        SUM(S.[Discount Amount])
        AS DECIMAL(19, 2)
    ) AS DiscountImpact
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.Category
ORDER BY
    GrossProfitAfterDiscount DESC;

