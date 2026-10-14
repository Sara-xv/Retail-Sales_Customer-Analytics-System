INSERT INTO dbo.DimStore
(
    StoreID,
    StoreName,
    City,
    Region,
    StoreType
)
VALUES
    ('ST001', N'شعبه تجریش',           N'تهران',       N'شمال',       'Physical'),
    ('ST002', N'شعبه ونک',             N'تهران',       N'مرکز',       'Physical'),
    ('ST003', N'شعبه صادقیه',          N'تهران',       N'غرب',        'Physical'),
    ('ST004', N'شعبه نازی‌آباد',       N'تهران',       N'جنوب',       'Physical'),
    ('ST005', N'شعبه پیروزی',          N'تهران',       N'شرق',        'Physical'),
    ('ST006', N'شعبه کرج',             N'کرج',         N'البرز',      'Physical'),
    ('ST007', N'شعبه اصفهان',          N'اصفهان',      N'مرکز',       'Physical'),
    ('ST008', N'شعبه شیراز',           N'شیراز',       N'جنوب',       'Physical'),
    ('ST009', N'شعبه مشهد',            N'مشهد',        N'شرق',        'Physical'),
    ('ST010', N'شعبه تبریز',           N'تبریز',       N'شمال‌غرب',   'Physical'),
    ('ST011', N'شعبه رشت',             N'رشت',         N'شمال',       'Physical'),
    ('ST012', N'شعبه ساری',            N'ساری',        N'شمال',       'Physical'),
    ('ST013', N'شعبه اهواز',           N'اهواز',       N'جنوب‌غرب',   'Physical'),
    ('ST014', N'شعبه کرمان',           N'کرمان',       N'جنوب‌شرق',   'Physical'),
    ('ST015', N'شعبه یزد',             N'یزد',         N'مرکز',       'Physical'),
    ('ST016', N'شعبه قم',              N'قم',          N'مرکز',       'Physical'),
    ('ST017', N'شعبه ارومیه',          N'ارومیه',      N'شمال‌غرب',   'Physical'),
    ('ST018', N'شعبه همدان',           N'همدان',       N'غرب',        'Physical'),
    ('ST019', N'شعبه بندرعباس',        N'بندرعباس',    N'جنوب',       'Physical'),
    ('ST020', N'مرکز پردازش سفارش آنلاین', N'تهران',   N'عملیات آنلاین', 'OnlineFulfillment');
GO

-- Validate store records
/*SELECT
    COUNT(*) AS TotalStores,
    COUNT(DISTINCT StoreID) AS UniqueStoreIDs,
    SUM(CASE WHEN StoreType = 'Physical' THEN 1 ELSE 0 END)
        AS PhysicalStores,
    SUM(CASE WHEN StoreType = 'OnlineFulfillment' THEN 1 ELSE 0 END)
        AS OnlineFulfillmentCenters
FROM dbo.DimStore;
*/

/*SELECT
    StoreID,
    StoreName,
    City,
    Region,
    StoreType
FROM dbo.DimStore
ORDER BY StoreID;
*/
