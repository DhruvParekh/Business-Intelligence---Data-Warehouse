create table TargetProductFact(
TargetProductIDKey int primary key identity(1,1),
ProductIDKey int foreign key references ProductDim(ProductIDKey),
SalesQuantityTarget numeric(16,4),
DimDateID int foreign key references DimDate(DimDateID)
)

create table TargetCSRFact(
TargetCSRIDKey int primary key identity(1,1),
ChannelIDKey int foreign key references ChannelDim(ChannelIDKey),
ResellerIDKey int foreign key references ResellerDim(ResellerIDKey),
StoreIDKey int foreign key references StoreDim(StoreIDKey),
TargetSalesAmount numeric(16,4),
DimDateID int foreign key references DimDate(DimDateID)
)

--Default values are given for the calculated field Extended Cost
create table SalesFact(
SalesIDKey int primary key identity(1,1),
ProductIDKey int foreign key references ProductDim(ProductIDKey),
CustomerIDKey int foreign key references CustomerDim(CustomerIDKey),
ResellerIDKey int foreign key references ResellerDim(ResellerIDKey),
StoreIDKey int foreign key references StoreDim(StoreIDKey),
ChannelIDKey int foreign key references ChannelDim(ChannelIDKey),
SalesHeaderID int,
SalesDetailID int,
SalesQuantity int,
SalesAmount numeric (18,2),
Price numeric (18,2),
Cost numeric (18,2),
ExtendedCost numeric (18,2),  
DimDateID int foreign key references DimDate(DimDateID)
)

--dropping the tables--
drop table SalesFact
drop table TargetCSRFact
drop table TargetProductFact

--select * from StageTargetProduct
--select * from StageTargetCSR

--select * from StageProduct
--select * from StageSalesDetail

select * from TargetCSRFact
select * from ResellerDim
select * from ChannelDim
select TargetSalesAmount/365 from StageTargetCSR
select * from CustomerDim
select * from ProductDim
select * from StageSalesDetail where ProductID is null


select * from StageSalesHeader
select * from DimDate
