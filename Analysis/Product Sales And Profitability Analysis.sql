/* ============================================================
   SALES ANALYTICS QUERIES
   Annotated version — short comment added above each query.
   Notes on fixes are marked with [FIX]; open questions to verify
   against the data are marked with [CHECK].

   Metric definitions:
   - Gross Sales = Quantity * Unit Price
   - Net Sales Before Returns = Gross Sales - Discount Amount
   - Gross Profit Before Returns = Net Sales Before Returns - COGS
   - Gross Margin % = Gross Profit / Net Sales * 100
   - Return events are analyzed separately to avoid double counting.
   - All monetary values use the dataset's arbitrary units.

   Data note: this dataset is synthetic. The patterns and trends
   surfaced by these queries are useful for practicing analysis and
   dashboard-building, but do not necessarily reflect how a real
   business would behave.

   Naming note: some queries use NetSales and others use
   NetSalesBeforeReturns for the same underlying figure (same for
   GrossProfit / GrossProfitBeforeReturns). Not a correctness issue,
   but when extending this file, prefer the explicit *BeforeReturns
   form so it's always clear whether a figure includes returns.
   ============================================================ */


-- Gross profit by product (all products), ranked highest first
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
    -- [FIX] Added NetSalesBeforeReturns and ProductKey as tie-breakers so
    -- the order is stable and reproducible when GrossProfit values tie.
    GrossProfitBeforeReturns DESC,
    NetSalesBeforeReturns DESC,
    P.ProductKey ASC;


-- Top 10 products by units sold (tie-break: net sales)
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
    -- [FIX] Added ProductKey as a final tie-breaker for full determinism.
    UnitsSold DESC,
    NetSalesBeforeReturns DESC,
    P.ProductKey ASC;


-- Gross profit rolled up by category
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


-- Category revenue/profit share of company total (window functions)
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


-- Discount rate by category, highest discount rate first
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


-- Category margin before vs. after discount, to isolate discount impact
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
    -- [FIX] Renamed from DiscountImpact to DiscountAmount: this is simply
    -- the discount amount given, not the net effect on business profit
    -- after all operational effects.
    CAST(
        SUM(S.[Discount Amount])
        AS DECIMAL(19, 2)
    ) AS DiscountAmount,
    -- [FIX] Added: the actual reduction in gross profit caused by the
    -- discount (GrossProfitBeforeDiscount - GrossProfitAfterDiscount).
    -- With COGS held constant in both calculations, this equals
    -- DiscountAmount, but naming it explicitly makes the profit-impact
    -- framing clear without relying on that assumption holding elsewhere.
    CAST(
        (SUM(S.[Gross Sales]) - SUM(S.COGS))
        - SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfitReductionFromDiscount
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.Category
ORDER BY
    GrossProfitAfterDiscount DESC;


-- Net sales and margin by sales channel
-- [FIX] This query was duplicated verbatim right after itself in the
-- original file — the duplicate has been removed, this is the one copy.
SELECT
    C.ChannelName,
    COUNT_BIG(*) AS SalesLines,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
    SUM(S.Quantity) AS UnitsSold,
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
INNER JOIN dbo.DimChannel AS C
    ON S.ChannelKey = C.ChannelKey
GROUP BY
    C.ChannelName
ORDER BY
    NetSalesBeforeReturns DESC;


-- Discount rate by channel, highest first
SELECT
    C.ChannelName,
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
INNER JOIN dbo.DimChannel AS C
    ON S.ChannelKey = C.ChannelKey
GROUP BY
    C.ChannelName
ORDER BY
    DiscountRatePct DESC;


-- Channel x Category cross-tab: sales, profit, margin
-- [FIX] The original file had this exact query duplicated immediately
-- after itself as well — duplicate removed, one copy kept.
SELECT
    C.ChannelName,
    P.Category,
    COUNT_BIG(*) AS SalesLines,
    SUM(S.Quantity) AS UnitsSold,
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
INNER JOIN dbo.DimChannel AS C
    ON S.ChannelKey = C.ChannelKey
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    C.ChannelName,
    P.Category
ORDER BY
    P.Category,
    C.ChannelName;


-- Channel x Category cross-tab: discount rate and margin
-- Intentionally kept alongside the sales/profit/margin cross-tab above:
-- that one serves sales & profit analysis, this one adds discount
-- metrics. They could be merged into a single query later, but neither
-- is redundant on its own.
SELECT
    C.ChannelName,
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
INNER JOIN dbo.DimChannel AS C
    ON S.ChannelKey = C.ChannelKey
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    C.ChannelName,
    P.Category
ORDER BY
    P.Category,
    C.ChannelName;


-- Within each channel, each category's share of that channel's net sales
WITH CategorySales AS
(
    SELECT
        C.ChannelName,
        P.Category,
        SUM(S.[Net Sales Before Returns]) AS NetSales
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimChannel AS C
        ON S.ChannelKey = C.ChannelKey
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    GROUP BY
        C.ChannelName,
        P.Category
)
SELECT
    ChannelName,
    Category,
    CAST(NetSales AS DECIMAL(19, 2)) AS NetSales,
    CAST(
        NetSales * 100.0
        / NULLIF(
            SUM(NetSales) OVER (PARTITION BY ChannelName),
            0
        )
        AS DECIMAL(6, 2)
    ) AS ChannelRevenueSharePct
FROM CategorySales
ORDER BY
    ChannelName,
    ChannelRevenueSharePct DESC;


-- Weighted margin contribution for Clothing/Footwear only, using a
-- common net-sales mix as weights (good for like-for-like channel compare)
WITH CategoryPerformance AS
(
    SELECT
        C.ChannelName,
        P.Category,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimChannel AS C
        ON S.ChannelKey = C.ChannelKey
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    WHERE P.Category IN ('Clothing', 'Footwear')
    GROUP BY
        C.ChannelName,
        P.Category
),
CategoryMargin AS
(
    SELECT
        ChannelName,
        Category,
        NetSales,
        GrossProfit,
        GrossProfit * 1.0
            / NULLIF(NetSales, 0) AS GrossMargin
    FROM CategoryPerformance
),
CommonMix AS
(
    SELECT
        Category,
        SUM(NetSales) AS CombinedNetSales
    FROM CategoryPerformance
    GROUP BY Category
),
CommonWeights AS
(
    SELECT
        Category,
        CombinedNetSales * 1.0
            / SUM(CombinedNetSales) OVER () AS CommonWeight
    FROM CommonMix
)
SELECT
    CM.ChannelName,
    CM.Category,
    CAST(CM.GrossMargin * 100 AS DECIMAL(6, 2)) AS GrossMarginPct,
    CAST(CW.CommonWeight * 100 AS DECIMAL(6, 2)) AS CommonMixWeightPct,
    CAST(
        CM.GrossMargin * CW.CommonWeight * 100
        AS DECIMAL(8, 4)
    ) AS WeightedMarginContribution
FROM CategoryMargin AS CM
INNER JOIN CommonWeights AS CW
    ON CM.Category = CW.Category
ORDER BY
    CM.Category,
    CM.ChannelName;


-- (Kept as reference) schema lookup for DimDate columns
/*
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'DimDate'
ORDER BY ORDINAL_POSITION;
*/


-- Monthly sales and margin trend
SELECT
    D.CalendarYear,
    D.MonthNumber,
    D.MonthName,
    COUNT_BIG(*) AS SalesLines,
    SUM(S.Quantity) AS UnitsSold,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
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
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear,
    D.MonthNumber,
    D.MonthName
ORDER BY
    D.CalendarYear,
    D.MonthNumber;


-- Annual performance with year-over-year growth (net sales & gross profit)
-- [CHECK] LAG()-based YoY assumes each CalendarYear is a complete,
-- comparable period. Before trusting these growth %, confirm the most
-- recent year in the data actually has a full year of activity (e.g. the
-- data may stop partway through December) — comparing a partial year
-- against a complete prior year will understate growth. If the latest
-- year is incomplete, either exclude it from YoY comparisons or state
-- explicitly that the comparison is over a partial period.
WITH AnnualPerformance AS
(
    SELECT
        D.CalendarYear,
        SUM(S.Quantity) AS UnitsSold,
        COUNT(DISTINCT S.OrderID) AS DistinctOrders,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    GROUP BY
        D.CalendarYear
),
AnnualGrowth AS
(
    SELECT
        CalendarYear,
        UnitsSold,
        DistinctOrders,
        NetSales,
        GrossProfit,
        LAG(NetSales) OVER (
            ORDER BY CalendarYear
        ) AS PreviousYearNetSales,
        LAG(GrossProfit) OVER (
            ORDER BY CalendarYear
        ) AS PreviousYearGrossProfit
    FROM AnnualPerformance
)
SELECT
    CalendarYear,
    UnitsSold,
    DistinctOrders,
    CAST(
        NetSales AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        GrossProfit AS DECIMAL(19, 2)
    ) AS GrossProfit,
    CAST(
        GrossProfit * 100.0
        / NULLIF(NetSales, 0)
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct,
    CAST(
        (NetSales - PreviousYearNetSales) * 100.0
        / NULLIF(PreviousYearNetSales, 0)
        AS DECIMAL(8, 2)
    ) AS NetSalesYoYGrowthPct,
    CAST(
        (GrossProfit - PreviousYearGrossProfit) * 100.0
        / NULLIF(PreviousYearGrossProfit, 0)
        AS DECIMAL(8, 2)
    ) AS GrossProfitYoYGrowthPct
FROM AnnualGrowth
ORDER BY CalendarYear;


-- Annual average order value (AOV)
SELECT
    D.CalendarYear,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.[Net Sales Before Returns])
        / NULLIF(COUNT(DISTINCT S.OrderID), 0)
        AS DECIMAL(19, 2)
    ) AS AverageOrderValue
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear
ORDER BY
    D.CalendarYear;


-- Annual units per order
-- [FIX] This query was duplicated verbatim right after itself in the
-- original file — duplicate removed, one copy kept.
SELECT
    D.CalendarYear,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
    SUM(S.Quantity) AS UnitsSold,
    CAST(
        SUM(S.Quantity) * 1.0
        / NULLIF(COUNT(DISTINCT S.OrderID), 0)
        AS DECIMAL(10, 2)
    ) AS UnitsPerOrder
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear
ORDER BY
    D.CalendarYear;


-- Annual average net sales per unit sold
SELECT
    D.CalendarYear,
    SUM(S.Quantity) AS UnitsSold,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.[Net Sales Before Returns])
        / NULLIF(SUM(S.Quantity), 0)
        AS DECIMAL(19, 2)
    ) AS AverageNetSalesPerUnit
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear
ORDER BY
    D.CalendarYear;


-- Annual discount rate
SELECT
    D.CalendarYear,
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
    ) AS NetSalesBeforeReturns
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear
ORDER BY
    D.CalendarYear;


-- Quarterly sales and margin trend
SELECT
    D.CalendarYear,
    D.QuarterNumber,
    COUNT_BIG(*) AS SalesLines,
    SUM(S.Quantity) AS UnitsSold,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
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
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear,
    D.QuarterNumber
ORDER BY
    D.CalendarYear,
    D.QuarterNumber;


-- Quarterly net sales & gross profit, YoY growth (same quarter, prior year)
-- [CHECK] PARTITION BY QuarterNumber ORDER BY CalendarYear correctly
-- compares each quarter to the same quarter one year earlier, but only
-- if every required quarter is actually present and complete in the
-- data (no partial quarters, no gaps). Verify this before interpreting
-- the growth percentages, especially for the most recent quarter.
WITH QuarterlySales AS
(
    SELECT
        D.CalendarYear,
        D.QuarterNumber,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    GROUP BY
        D.CalendarYear,
        D.QuarterNumber
),
QuarterlyGrowth AS
(
    SELECT
        CalendarYear,
        QuarterNumber,
        NetSales,
        GrossProfit,
        LAG(NetSales, 1) OVER (
            PARTITION BY QuarterNumber
            ORDER BY CalendarYear
        ) AS PreviousYearNetSales,
        LAG(GrossProfit, 1) OVER (
            PARTITION BY QuarterNumber
            ORDER BY CalendarYear
        ) AS PreviousYearGrossProfit
    FROM QuarterlySales
)
SELECT
    CalendarYear,
    QuarterNumber,
    CAST(
        NetSales AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        (NetSales - PreviousYearNetSales) * 100.0
        / NULLIF(PreviousYearNetSales, 0)
        AS DECIMAL(8, 2)
    ) AS NetSalesYoYGrowthPct,
    CAST(
        GrossProfit AS DECIMAL(19, 2)
    ) AS GrossProfit,
    CAST(
        (GrossProfit - PreviousYearGrossProfit) * 100.0
        / NULLIF(PreviousYearGrossProfit, 0)
        AS DECIMAL(8, 2)
    ) AS GrossProfitYoYGrowthPct
FROM QuarterlyGrowth
ORDER BY
    CalendarYear,
    QuarterNumber;


-- [FIX] Removed: a "simple summary" quarterly net sales/margin query that
-- was a strict subset of "Quarterly sales and margin trend" above (same
-- grouping, missing only SalesLines/DistinctOrders). Use that query instead.


-- Quarterly orders/units/net sales with YoY growth, same quarter prior year
WITH QuarterlyMetrics AS
(
    SELECT
        D.CalendarYear,
        D.QuarterNumber,
        COUNT(DISTINCT S.OrderID) AS DistinctOrders,
        SUM(S.Quantity) AS UnitsSold,
        SUM(S.[Net Sales Before Returns]) AS NetSales
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    GROUP BY
        D.CalendarYear,
        D.QuarterNumber
),
GrowthMetrics AS
(
    SELECT
        CalendarYear,
        QuarterNumber,
        DistinctOrders,
        UnitsSold,
        NetSales,
        LAG(DistinctOrders) OVER (
            PARTITION BY QuarterNumber
            ORDER BY CalendarYear
        ) AS PreviousYearOrders,
        LAG(UnitsSold) OVER (
            PARTITION BY QuarterNumber
            ORDER BY CalendarYear
        ) AS PreviousYearUnits,
        LAG(NetSales) OVER (
            PARTITION BY QuarterNumber
            ORDER BY CalendarYear
        ) AS PreviousYearNetSales
    FROM QuarterlyMetrics
)
SELECT
    CalendarYear,
    QuarterNumber,
    DistinctOrders,
    UnitsSold,
    CAST(
        (DistinctOrders - PreviousYearOrders) * 100.0
        / NULLIF(PreviousYearOrders, 0)
        AS DECIMAL(8, 2)
    ) AS OrdersYoYGrowthPct,
    CAST(
        (UnitsSold - PreviousYearUnits) * 100.0
        / NULLIF(PreviousYearUnits, 0)
        AS DECIMAL(8, 2)
    ) AS UnitsYoYGrowthPct,
    CAST(
        (NetSales - PreviousYearNetSales) * 100.0
        / NULLIF(PreviousYearNetSales, 0)
        AS DECIMAL(8, 2)
    ) AS NetSalesYoYGrowthPct
FROM GrowthMetrics
ORDER BY
    CalendarYear,
    QuarterNumber;


-- Quarterly AOV with YoY growth, same quarter prior year
WITH QuarterlyMetrics AS
(
    SELECT
        D.CalendarYear,
        D.QuarterNumber,
        COUNT(DISTINCT S.OrderID) AS DistinctOrders,
        SUM(S.[Net Sales Before Returns]) AS NetSales
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimDate AS D
        ON S.OrderDateKey = D.DateKey
    GROUP BY
        D.CalendarYear,
        D.QuarterNumber
),
AOVMetrics AS
(
    SELECT
        CalendarYear,
        QuarterNumber,
        DistinctOrders,
        NetSales,
        NetSales / NULLIF(DistinctOrders, 0) AS AOV
    FROM QuarterlyMetrics
)
SELECT
    CalendarYear,
    QuarterNumber,
    DistinctOrders,
    CAST(NetSales AS DECIMAL(19, 2)) AS NetSales,
    CAST(AOV AS DECIMAL(19, 2)) AS AOV,
    CAST(
        (
            AOV - LAG(AOV) OVER (
                PARTITION BY QuarterNumber
                ORDER BY CalendarYear
            )
        ) * 100.0
        / NULLIF(
            LAG(AOV) OVER (
                PARTITION BY QuarterNumber
                ORDER BY CalendarYear
            ),
            0
        )
        AS DECIMAL(8, 2)
    ) AS AOVYoYGrowthPct
FROM AOVMetrics
ORDER BY
    CalendarYear,
    QuarterNumber;


-- Quarterly discount rate and margin
SELECT
    D.CalendarYear,
    D.QuarterNumber,
    CAST(
        SUM(S.[Gross Sales])
        AS DECIMAL(19, 2)
    ) AS GrossSales,
    CAST(
        SUM(S.[Discount Amount])
        AS DECIMAL(19, 2)
    ) AS DiscountAmount,
    CAST(
        SUM(S.[Discount Amount]) * 100.0
        / NULLIF(SUM(S.[Gross Sales]), 0)
        AS DECIMAL(6, 2)
    ) AS DiscountRatePct,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimDate AS D
    ON S.OrderDateKey = D.DateKey
GROUP BY
    D.CalendarYear,
    D.QuarterNumber
ORDER BY
    D.CalendarYear,
    D.QuarterNumber;


-- Data-quality check: confirm ProductID is a 1:1 stand-in for ProductKey
-- before trusting the queries below, which join on ProductKey but group
-- by ProductID. If this returns any rows, a single ProductID maps to
-- more than one ProductKey, and grouping by ProductID would silently
-- merge what the join treated as separate product records.
SELECT
    ProductID,
    COUNT(DISTINCT ProductKey) AS ProductKeyCount
FROM dbo.DimProduct
GROUP BY ProductID
HAVING COUNT(DISTINCT ProductKey) > 1;


-- Top 20 products by net sales (product-level detail)
-- [FIX] From here on the queries join on P.ProductKey but then
-- GROUP BY / SELECT P.ProductID instead of P.ProductKey. Run the
-- data-quality check above first: if it returns no rows, ProductID is a
-- safe 1:1 key and this grouping is fine; if it returns rows, switch
-- these GROUP BY/SELECT lists to ProductKey to match the join column.
SELECT TOP (20)
    P.ProductID,
    P.ProductName,
    P.Category,
    P.Subcategory,
    COUNT_BIG(*) AS SalesLines,
    SUM(S.Quantity) AS UnitsSold,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.COGS)
        AS DECIMAL(19, 2)
    ) AS COGS,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfit,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.ProductID,
    P.ProductName,
    P.Category,
    P.Subcategory
ORDER BY
    -- [FIX] Added ProductID as a tie-breaker for stable ordering.
    NetSales DESC,
    P.ProductID ASC;


-- Top 20 products by gross profit
SELECT TOP (20)
    P.ProductID,
    P.ProductName,
    P.Category,
    P.Subcategory,
    SUM(S.Quantity) AS UnitsSold,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.COGS)
        AS DECIMAL(19, 2)
    ) AS COGS,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfit,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.ProductID,
    P.ProductName,
    P.Category,
    P.Subcategory
ORDER BY
    -- [FIX] Added ProductID as a tie-breaker for stable ordering.
    GrossProfit DESC,
    P.ProductID ASC;


-- Products in the upper tail of the net-sales distribution (PERCENT_RANK
-- >= 0.80) whose margin is below the overall product-average margin
-- [FIX] Original had "SELECT TOP (20)" placed before the WITH clause,
-- which is invalid T-SQL syntax (TOP belongs inside a SELECT, not before
-- a CTE). Removed — the final SELECT already has its own TOP (20).
-- Note: PERCENT_RANK() >= 0.80 selects products in the upper part of the
-- sales distribution; it does NOT guarantee exactly the top 20% of
-- products, especially with tied NetSales values. If the business
-- definition really is "exactly the top 20% of products by count", a
-- different ranking approach (e.g. NTILE, or a row-count-based cutoff)
-- is needed instead.
WITH ProductPerformance AS
(
    SELECT
        P.ProductID,
        P.ProductName,
        P.Category,
        P.Subcategory,
        SUM(S.Quantity) AS UnitsSold,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit,
        SUM(S.[Gross Profit Before Returns]) * 100.0
            / NULLIF(
                SUM(S.[Net Sales Before Returns]),
                0
            ) AS GrossMarginPct
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    GROUP BY
        P.ProductID,
        P.ProductName,
        P.Category,
        P.Subcategory
),
RankedProducts AS
(
    SELECT
        *,
        PERCENT_RANK() OVER (
            ORDER BY NetSales
        ) AS SalesPercentRank,
        AVG(GrossMarginPct) OVER () AS AverageProductMargin
    FROM ProductPerformance
)
SELECT TOP (20)
    ProductID,
    ProductName,
    Category,
    Subcategory,
    UnitsSold,
    CAST(NetSales AS DECIMAL(19, 2)) AS NetSales,
    CAST(GrossProfit AS DECIMAL(19, 2)) AS GrossProfit,
    CAST(GrossMarginPct AS DECIMAL(6, 2)) AS GrossMarginPct,
    CAST(
        AverageProductMargin
        AS DECIMAL(6, 2)
    ) AS AverageProductMarginPct
FROM RankedProducts
WHERE SalesPercentRank >= 0.80
  AND GrossMarginPct < AverageProductMargin
ORDER BY
    NetSales DESC;


-- All products ranked by lowest margin first (positive net sales only)
SELECT TOP (20)
    P.ProductID,
    P.ProductName,
    P.Category,
    P.Subcategory,
    SUM(S.Quantity) AS UnitsSold,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.COGS)
        AS DECIMAL(19, 2)
    ) AS COGS,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfit,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.ProductID,
    P.ProductName,
    P.Category,
    P.Subcategory
HAVING
    SUM(S.[Net Sales Before Returns]) > 0
ORDER BY
    GrossMarginPct ASC,
    NetSales DESC;


-- Count of products in the upper tail of net sales (PERCENT_RANK >= 0.80)
-- that also fall in the lower half by gross profit AMOUNT (not margin %)
-- [FIX] Renamed/clarified: this ranks by GrossProfit (an absolute dollar
-- amount), not by margin percentage. A product with low gross profit can
-- still have a high margin % if it simply has low sales volume — this
-- query does not measure margin. PERCENT_RANK() >= 0.80 also only
-- approximates "top 20% of products" (see note on the query above).
WITH ProductPerformance AS
(
    SELECT
        P.ProductID,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    GROUP BY
        P.ProductID
),
RankedProducts AS
(
    SELECT
        *,
        PERCENT_RANK() OVER (
            ORDER BY NetSales
        ) AS SalesPercentRank,
        PERCENT_RANK() OVER (
            ORDER BY GrossProfit
        ) AS ProfitPercentRank
    FROM ProductPerformance
)
SELECT
    COUNT(*) AS TotalProducts,
    SUM(CASE
        WHEN SalesPercentRank >= 0.80
        THEN 1 ELSE 0
    END) AS HighSalesProducts,
    SUM(CASE
        WHEN ProfitPercentRank < 0.50
        THEN 1 ELSE 0
    END) AS LowProfitProducts,
    SUM(CASE
        WHEN SalesPercentRank >= 0.80
         AND ProfitPercentRank < 0.50
        THEN 1 ELSE 0
    END) AS ProductsMeetingBothConditions
FROM RankedProducts;


-- Products in the upper tail of net sales (PERCENT_RANK >= 0.80, see note
-- above on what this does/doesn't guarantee) below their OWN category's
-- margin benchmark (vs. the earlier query, which used the overall average)
WITH ProductPerformance AS
(
    SELECT
        P.ProductID,
        P.ProductName,
        P.Category,
        P.Subcategory,
        SUM(S.Quantity) AS UnitsSold,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit,
        SUM(S.[Gross Profit Before Returns]) * 100.0
            / NULLIF(
                SUM(S.[Net Sales Before Returns]),
                0
            ) AS GrossMarginPct
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    GROUP BY
        P.ProductID,
        P.ProductName,
        P.Category,
        P.Subcategory
),
-- [FIX] AVG(GrossMarginPct) averages each product's margin % equally,
-- regardless of size — a tiny product and a huge one count the same.
-- The category's true aggregate margin is total category profit over
-- total category net sales, so it's computed directly from the summed
-- GrossProfit/NetSales columns instead.
CategoryBenchmarks AS
(
    SELECT
        Category,
        SUM(GrossProfit) * 100.0
            / NULLIF(SUM(NetSales), 0)
            AS AvgCategoryMargin
    FROM ProductPerformance
    GROUP BY Category
),
RankedProducts AS
(
    SELECT
        *,
        PERCENT_RANK() OVER (
            ORDER BY NetSales
        ) AS SalesPercentRank
    FROM ProductPerformance
)
SELECT TOP (20)
    R.ProductID,
    R.ProductName,
    R.Category,
    R.Subcategory,
    R.UnitsSold,
    CAST(R.NetSales AS DECIMAL(19, 2)) AS NetSales,
    CAST(R.GrossProfit AS DECIMAL(19, 2)) AS GrossProfit,
    CAST(R.GrossMarginPct AS DECIMAL(6, 2)) AS ProductMarginPct,
    CAST(B.AvgCategoryMargin AS DECIMAL(6, 2)) AS AvgCategoryMarginPct,
    CAST(
        R.GrossMarginPct - B.AvgCategoryMargin
        AS DECIMAL(6, 2)
    ) AS MarginDifferencePp
FROM RankedProducts AS R
INNER JOIN CategoryBenchmarks AS B
    ON R.Category = B.Category
WHERE
    R.SalesPercentRank >= 0.80
    AND R.GrossMarginPct < B.AvgCategoryMargin
ORDER BY
    R.NetSales DESC;


-- Same as above, plus discount metrics (gross sales, discount amount/rate,
-- net sales retention) alongside the margin-vs-category-benchmark view
WITH ProductPerformance AS
(
    SELECT
        P.ProductID,
        P.ProductName,
        P.Category,
        P.Subcategory,
        SUM(S.[Gross Sales]) AS GrossSales,
        SUM(S.[Discount Amount]) AS DiscountAmount,
        SUM(S.[Net Sales Before Returns]) AS NetSales,
        SUM(S.COGS) AS COGS,
        SUM(S.[Gross Profit Before Returns]) AS GrossProfit
    FROM dbo.vw_SalesAnalytics AS S
    INNER JOIN dbo.DimProduct AS P
        ON S.ProductKey = P.ProductKey
    GROUP BY
        P.ProductID,
        P.ProductName,
        P.Category,
        P.Subcategory
),
ProductMetrics AS
(
    SELECT
        *,
        GrossProfit * 100.0
            / NULLIF(NetSales, 0) AS GrossMarginPct,
        DiscountAmount * 100.0
            / NULLIF(GrossSales, 0) AS DiscountRatePct,
        NetSales * 100.0
            / NULLIF(GrossSales, 0) AS NetSalesRetentionPct
    FROM ProductPerformance
),
-- [FIX] Same issue as the previous query: AVG(GrossMarginPct) is an
-- unweighted average across products. Replaced with the aggregate
-- category margin (total profit / total net sales) so the benchmark
-- reflects the category's actual combined performance.
CategoryBenchmarks AS
(
    SELECT
        Category,
        SUM(GrossProfit) * 100.0
            / NULLIF(SUM(NetSales), 0)
            AS AvgCategoryMargin
    FROM ProductMetrics
    GROUP BY Category
),
RankedProducts AS
(
    SELECT
        M.*,
        B.AvgCategoryMargin,
        PERCENT_RANK() OVER (
            ORDER BY M.NetSales
        ) AS SalesPercentRank
    FROM ProductMetrics AS M
    INNER JOIN CategoryBenchmarks AS B
        ON M.Category = B.Category
)
SELECT TOP (20)
    ProductID,
    ProductName,
    Category,
    Subcategory,
    CAST(NetSales AS DECIMAL(19, 2)) AS NetSales,
    CAST(DiscountAmount AS DECIMAL(19, 2)) AS DiscountAmount,
    CAST(DiscountRatePct AS DECIMAL(6, 2)) AS DiscountRatePct,
    CAST(GrossMarginPct AS DECIMAL(6, 2)) AS GrossMarginPct,
    CAST(AvgCategoryMargin AS DECIMAL(6, 2)) AS AvgCategoryMarginPct,
    CAST(
        GrossMarginPct - AvgCategoryMargin
        AS DECIMAL(6, 2)
    ) AS MarginDifferencePp
FROM RankedProducts
WHERE
    SalesPercentRank >= 0.80
    AND GrossMarginPct < AvgCategoryMargin
ORDER BY
    NetSales DESC;


-- Category x Subcategory rollup, worst margin first within each category
SELECT
    P.Category,
    P.Subcategory,
    COUNT(DISTINCT P.ProductKey) AS ProductCount,
    SUM(S.Quantity) AS UnitsSold,
    COUNT(DISTINCT S.OrderID) AS DistinctOrders,
    CAST(
        SUM(S.[Gross Sales])
        AS DECIMAL(19, 2)
    ) AS GrossSales,
    CAST(
        SUM(S.[Discount Amount])
        AS DECIMAL(19, 2)
    ) AS DiscountAmount,
    CAST(
        SUM(S.[Discount Amount]) * 100.0
        / NULLIF(SUM(S.[Gross Sales]), 0)
        AS DECIMAL(6, 2)
    ) AS DiscountRatePct,
    CAST(
        SUM(S.[Net Sales Before Returns])
        AS DECIMAL(19, 2)
    ) AS NetSales,
    CAST(
        SUM(S.[Gross Profit Before Returns])
        AS DECIMAL(19, 2)
    ) AS GrossProfit,
    CAST(
        SUM(S.[Gross Profit Before Returns]) * 100.0
        / NULLIF(
            SUM(S.[Net Sales Before Returns]),
            0
        )
        AS DECIMAL(6, 2)
    ) AS GrossMarginPct
FROM dbo.vw_SalesAnalytics AS S
INNER JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey
GROUP BY
    P.Category,
    P.Subcategory
ORDER BY
    P.Category,
    GrossMarginPct ASC;


-- Data-quality check: sales rows with no matching product (orphaned FK)
SELECT
    COUNT_BIG(*) AS TotalSalesRows,
    COUNT_BIG(
        CASE
            WHEN P.ProductKey IS NULL THEN 1
        END
    ) AS SalesRowsWithoutMatchingProduct,
    COUNT(DISTINCT S.ProductKey) AS DistinctProductKeysInSales,
    COUNT(DISTINCT P.ProductKey) AS MatchedProductKeys
FROM dbo.vw_SalesAnalytics AS S
LEFT JOIN dbo.DimProduct AS P
    ON S.ProductKey = P.ProductKey;