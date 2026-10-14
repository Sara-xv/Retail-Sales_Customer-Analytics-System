-- Insert sales channels
INSERT INTO dbo.DimChannel
(
    ChannelCode,
    ChannelName
)
VALUES
    ('STORE',  N'فروش حضوری'),
    ('ONLINE', N'فروش آنلاین');
GO

-- Insert return reasons
INSERT INTO dbo.DimReturnReason
(
    ReasonCode,
    ReasonName
)
VALUES
    ('WRONG_SIZE',   N'سایز نامناسب'),
    ('DEFECTIVE',    N'کالای معیوب'),
    ('WRONG_ITEM',   N'کالای اشتباه'),
    ('NOT_EXPECTED', N'عدم تطابق با انتظار'),
    ('CHANGED_MIND', N'انصراف مشتری');
GO

-- Validate inserted records
/*SELECT
    ChannelKey,
    ChannelCode,
    ChannelName
FROM dbo.DimChannel
ORDER BY ChannelKey;
*/

/*SELECT
    ReturnReasonKey,
    ReasonCode,
    ReasonName
FROM dbo.DimReturnReason
ORDER BY ReturnReasonKey;
*/
