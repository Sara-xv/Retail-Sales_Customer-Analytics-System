-- Create a database
CREATE DATABASE RetailIntelligence;
GO

USE RetailIntelligence;
GO

-- Create Dimension tables 
CREATE TABLE dbo.DimDate
(
    DateKey           INT           NOT NULL,
    FullDate          DATE          NOT NULL,
    CalendarYear      SMALLINT      NOT NULL,
    QuarterNumber     TINYINT       NOT NULL,
    MonthNumber       TINYINT       NOT NULL,
    MonthName         NVARCHAR(20)  NOT NULL,
    DayOfMonth        TINYINT       NOT NULL,
    DayOfWeekNumber   TINYINT       NOT NULL,

    CONSTRAINT PK_DimDate
        PRIMARY KEY (DateKey),

    CONSTRAINT UQ_DimDate_FullDate
        UNIQUE (FullDate),

    CONSTRAINT CK_DimDate_DateKey
        CHECK (DateKey BETWEEN 19000101 AND 99991231),

    CONSTRAINT CK_DimDate_Month
        CHECK (MonthNumber BETWEEN 1 AND 12),

    CONSTRAINT CK_DimDate_Quarter
        CHECK (QuarterNumber BETWEEN 1 AND 4),

    CONSTRAINT CK_DimDate_Day
        CHECK (DayOfMonth BETWEEN 1 AND 31)
);
GO

CREATE TABLE dbo.DimCustomer
(
    CustomerKey  INT IDENTITY(1,1) NOT NULL,
    CustomerID   VARCHAR(30)       NOT NULL,
    Gender       VARCHAR(20)       NULL,
    BirthDate    DATE              NULL,
    City         NVARCHAR(100)     NULL,
    JoinDate     DATE              NULL,

    CONSTRAINT PK_DimCustomer
        PRIMARY KEY (CustomerKey),

    CONSTRAINT UQ_DimCustomer_CustomerID
        UNIQUE (CustomerID)
);
GO

-- Create fact tables 
CREATE TABLE dbo.DimProduct
(
    ProductKey    INT IDENTITY(1,1) NOT NULL,
    ProductID     VARCHAR(30)       NOT NULL,
    ProductName   NVARCHAR(200)     NOT NULL,
    SKU           VARCHAR(50)       NOT NULL,
    Brand         NVARCHAR(100)     NULL,
    Category      NVARCHAR(100)     NOT NULL,
    Subcategory   NVARCHAR(100)     NULL,

    CONSTRAINT PK_DimProduct
        PRIMARY KEY (ProductKey),

    CONSTRAINT UQ_DimProduct_ProductID
        UNIQUE (ProductID),

    CONSTRAINT UQ_DimProduct_SKU
        UNIQUE (SKU)
);
GO

CREATE TABLE dbo.DimStore
(
    StoreKey    INT IDENTITY(1,1) NOT NULL,
    StoreID     VARCHAR(30)       NOT NULL,
    StoreName   NVARCHAR(150)     NOT NULL,
    City        NVARCHAR(100)     NULL,
    Region      NVARCHAR(100)     NULL,
    StoreType   VARCHAR(30)       NOT NULL,

    CONSTRAINT PK_DimStore
        PRIMARY KEY (StoreKey),

    CONSTRAINT UQ_DimStore_StoreID
        UNIQUE (StoreID)
);
GO

CREATE TABLE dbo.DimChannel
(
    ChannelKey   TINYINT IDENTITY(1,1) NOT NULL,
    ChannelCode  VARCHAR(20)           NOT NULL,
    ChannelName  NVARCHAR(50)          NOT NULL,

    CONSTRAINT PK_DimChannel
        PRIMARY KEY (ChannelKey),

    CONSTRAINT UQ_DimChannel_ChannelCode
        UNIQUE (ChannelCode)
);
GO

CREATE TABLE dbo.DimReturnReason
(
    ReturnReasonKey  SMALLINT IDENTITY(1,1) NOT NULL,
    ReasonCode       VARCHAR(30)            NOT NULL,
    ReasonName       NVARCHAR(100)          NOT NULL,

    CONSTRAINT PK_DimReturnReason
        PRIMARY KEY (ReturnReasonKey),

    CONSTRAINT UQ_DimReturnReason_ReasonCode
        UNIQUE (ReasonCode)
);
GO


CREATE TABLE dbo.FactSales
(
    SalesLineID      BIGINT IDENTITY(1,1) NOT NULL,
    OrderID          VARCHAR(30)          NOT NULL,
    SalesLineNumber  SMALLINT             NOT NULL,

    OrderDateKey     INT                  NOT NULL,
    CustomerKey      INT                  NOT NULL,
    ProductKey       INT                  NOT NULL,
    StoreKey         INT                  NOT NULL,
    ChannelKey       TINYINT              NOT NULL,

    Quantity         INT                  NOT NULL,
    UnitPrice        DECIMAL(12,2)        NOT NULL,
    DiscountRate     DECIMAL(5,4)         NOT NULL
        CONSTRAINT DF_FactSales_DiscountRate DEFAULT (0),
    UnitCost         DECIMAL(12,2)        NOT NULL,

    CONSTRAINT PK_FactSales
        PRIMARY KEY (SalesLineID),

    CONSTRAINT UQ_FactSales_OrderLine
        UNIQUE (OrderID, SalesLineNumber),

    CONSTRAINT FK_FactSales_Date
        FOREIGN KEY (OrderDateKey)
        REFERENCES dbo.DimDate(DateKey),

    CONSTRAINT FK_FactSales_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES dbo.DimCustomer(CustomerKey),

    CONSTRAINT FK_FactSales_Product
        FOREIGN KEY (ProductKey)
        REFERENCES dbo.DimProduct(ProductKey),

    CONSTRAINT FK_FactSales_Store
        FOREIGN KEY (StoreKey)
        REFERENCES dbo.DimStore(StoreKey),

    CONSTRAINT FK_FactSales_Channel
        FOREIGN KEY (ChannelKey)
        REFERENCES dbo.DimChannel(ChannelKey),

    CONSTRAINT CK_FactSales_Quantity
        CHECK (Quantity > 0),

    CONSTRAINT CK_FactSales_UnitPrice
        CHECK (UnitPrice >= 0),

    CONSTRAINT CK_FactSales_UnitCost
        CHECK (UnitCost >= 0),

    CONSTRAINT CK_FactSales_Discount
        CHECK (DiscountRate BETWEEN 0 AND 1),

    CONSTRAINT CK_FactSales_LineNumber
        CHECK (SalesLineNumber > 0)
);
GO

/*
SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'dbo'
ORDER BY t.name;
*/
