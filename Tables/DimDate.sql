;WITH DateSeries AS
(
    SELECT CAST('20230101' AS DATE) AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < '20251231'
)
INSERT INTO dbo.DimDate
(
    DateKey,
    FullDate,
    CalendarYear,
    QuarterNumber,
    MonthNumber,
    MonthName,
    DayOfMonth,
    DayOfWeekNumber
)


SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)),
    FullDate,
    YEAR(FullDate),
    DATEPART(QUARTER, FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    DAY(FullDate),
    (DATEDIFF(DAY, '19000101', FullDate) % 7) + 1
FROM DateSeries
OPTION (MAXRECURSION 0);

