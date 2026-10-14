
USE RetailIntelligence;
GO

CREATE OR ALTER VIEW dbo.vw_ReturnsAnalytics
AS
SELECT
    R.ReturnEventID,
    R.ReturnID,
    R.ReturnLineNumber,

    R.SalesLineID,
    R.ReturnDateKey,
    R.ReturnReasonKey,

    R.ReturnQuantity,
    R.RefundAmount

FROM dbo.FactReturns AS R;
GO


-- Inspect sample return records
SELECT TOP (10)
    ReturnEventID,
    ReturnID,
    SalesLineID,
    ReturnDateKey,
    ReturnReasonKey,
    ReturnQuantity,
    RefundAmount
FROM dbo.vw_ReturnsAnalytics
ORDER BY ReturnEventID;
GO

-- Compare source and view row counts
SELECT
    (SELECT COUNT_BIG(*)
     FROM dbo.FactReturns)  FactReturnsRows,

    (SELECT COUNT_BIG(*)
     FROM dbo.vw_ReturnsAnalytics)  ViewRows;
GO

-- Check aggregate values
SELECT
    COUNT_BIG(*)  TotalReturnEvents,
    SUM(ReturnQuantity)  TotalReturnedUnits,
    CAST(SUM(RefundAmount) AS DECIMAL(19,2))
        AS TotalRefundAmount
FROM dbo.vw_ReturnsAnalytics;
GO


SELECT
    RR.ReasonCode,
    RR.ReasonName,

    COUNT_BIG(*)  ReturnEvents,

    SUM(R.ReturnQuantity) AS ReturnedUnits,

    CAST(
        SUM(R.RefundAmount)
        AS DECIMAL(19,2)
    )  TotalRefundAmount,

    CAST(
        COUNT_BIG(*) * 100.0
        / SUM(COUNT_BIG(*)) OVER ()
        AS DECIMAL(6,2)
    )  ReturnEventSharePct

FROM dbo.vw_ReturnsAnalytics AS R
INNER JOIN dbo.DimReturnReason AS RR
    ON R.ReturnReasonKey = RR.ReturnReasonKey

GROUP BY
    RR.ReasonCode,
    RR.ReasonName

ORDER BY
    ReturnEvents DESC;

