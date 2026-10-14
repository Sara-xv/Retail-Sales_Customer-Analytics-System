CREATE VIEW dbo.vw_SalesAnalytics AS 
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
	CAST(F.UnitCost * F.Quantity AS DECIMAL(19,2)) COGS,
FROM FactSales F