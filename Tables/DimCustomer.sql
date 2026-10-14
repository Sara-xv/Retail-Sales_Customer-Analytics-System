;WITH Numbers AS
(
    SELECT TOP (20000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b
),
CustomerDates AS
(
    SELECT
        n,

        -- Synthetic birth date: ages approximately 18 to 75
        DATEADD
        (
            DAY,
            -(
                18 * 365
                + ABS(CHECKSUM(NEWID())) % (58 * 365)
            ),
            CAST('20251231' AS DATE)
        ) AS BirthDate,

        -- Synthetic membership date: 2018 to 2025
        DATEADD
        (
            DAY,
            ABS(CHECKSUM(NEWID())) % 2922,
            CAST('20180101' AS DATE)
        ) AS ProposedJoinDate
    FROM Numbers
),
ValidCustomerDates AS
(
    SELECT
        n,
        BirthDate,
        CASE
            WHEN ProposedJoinDate <= BirthDate
                THEN DATEADD(DAY, 1, BirthDate)
            ELSE ProposedJoinDate
        END AS JoinDate
    FROM CustomerDates
)
INSERT INTO dbo.DimCustomer
(
    CustomerID,
    Gender,
    BirthDate,
    City,
    JoinDate
)
SELECT
    CONCAT('CUS', RIGHT(CONCAT('000000', n), 6)),

    CASE ABS(CHECKSUM(NEWID())) % 3
        WHEN 0 THEN 'Female'
        WHEN 1 THEN 'Male'
        ELSE 'Other'
    END,

    BirthDate,

    CASE ABS(CHECKSUM(NEWID())) % 10
        WHEN 0 THEN N'تهران'
        WHEN 1 THEN N'کرج'
        WHEN 2 THEN N'اصفهان'
        WHEN 3 THEN N'شیراز'
        WHEN 4 THEN N'مشهد'
        WHEN 5 THEN N'تبریز'
        WHEN 6 THEN N'رشت'
        WHEN 7 THEN N'اهواز'
        WHEN 8 THEN N'قم'
        ELSE N'یزد'
    END,

    JoinDate
FROM ValidCustomerDates;
GO

-- Validate customer volume and key uniqueness
/*
SELECT
    COUNT(*) AS TotalCustomers,
    COUNT(DISTINCT CustomerID) AS UniqueCustomerIDs,
    MIN(BirthDate) AS EarliestBirthDate,
    MAX(BirthDate) AS LatestBirthDate,
    MIN(JoinDate) AS EarliestJoinDate,
    MAX(JoinDate) AS LatestJoinDate,
    SUM
    (
        CASE
            WHEN BirthDate >= JoinDate THEN 1
            ELSE 0
        END
    ) AS InvalidBirthJoinDates
FROM dbo.DimCustomer;
*/

-- Review customer distribution
/*
SELECT
    City,
    Gender,
    COUNT(*) AS CustomerCount
FROM dbo.DimCustomer
GROUP BY
    City,
    Gender
ORDER BY
    City,
    Gender;
*/
