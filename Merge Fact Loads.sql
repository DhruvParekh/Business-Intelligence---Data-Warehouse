/*Load of Target ProductFact table. Round function is used to avoid mismatch between values*/
merge TargetProductFact as Target using
(select ProductIDKey, DimDateID, (SalesQuantityTarget/(select datediff(day,cast( Year as char(4)),cast(Year +1 as char(4))))) as  SalesQuantityTarget
from ProductDim join StageTargetProduct on ProductDim.ProductID = StageTargetProduct.ProductID
join DimDate on  DimDate.CalendarYear = StageTargetProduct.Year)
as Source
on (Target.DimDateID = Source.DimDateID and round(Target.SalesQuantityTarget,2) = round(Source.SalesQuantityTarget,2) and Target.ProductIDKey = Source.ProductIDKey)
when matched and (round(Target.SalesQuantityTarget,2) <> round(Source.SalesQuantityTarget,2) or Target.DimDateID <> Source.DimDateID or Target.ProductIDKey <> Source.ProductIDKey) then
update  set Target.ProductIDKey = Source.ProductIDKey, Target.SalesQuantityTarget = Source.SalesQuantityTarget, Target.DimDateID = Source.DimDateID
when not matched by Target then insert (ProductIDKey, SalesQuantityTarget, DimDateID) values (Source.ProductIDKey, Source.SalesQuantityTarget, Source.DimDateID)
;

/* Load TargetCSR fact*/
merge TargetCSRFact as target using
(select TCSR.ChannelIDKey, TCSR.RIDKey, TCSR.StoreIDKey, D.DimDateID, TCSR.TargetSalesAmount from DimDate D join
(select TCSR.TargetSalesAmount, TCSR.Year, TCSR.ChannelIDKey, TCSR.RIDKey, S.StoreIDKey from StoreDim S
right join (select TCSR.TargetSalesAmount, TCSR.Year, TCSR.ChannelIDKey, isnull(R.ResellerIDKey,-1) as RIDKey,TCSR.TargetName from ResellerDim R
right join (select (TCSR.TargetSalesAmount/(select DATEDIFF(day,cast(TCSR.Year as char(4)),cast(TCSR.Year + 1 as char(4))))) as TargetSalesAmount, TCSR.Year,TCSR.TargetName, C.ChannelIDKey 
from ChannelDim C join StageTargetCSR TCSR on SUBSTRING(C.Channel,1,2) = SUBSTRING(TCSR.ChannelName,1,2)) as TCSR 
on SUBSTRING(R.ResellerName,1,5) = substring(TCSR.TargetName,1,5)) as TCSR
on case 
when isnumeric(substring(TCSR.Targetname,14,len(TCSR.TargetName))) =1 then substring(TCSR.Targetname,14,len(TCSR.TargetName))
	else -1
end
 = S.StoreNumber
) as TCSR
on TCSR.Year = D.CalendarYear) as Source 
on (Target.ChannelIDKey = Source.ChannelIDKey and Target.ResellerIDKey = Source.RIDKey and Target.StoreIDKey = Source.StoreIDKey and Target.DimDateID = Source.DimDateID and 
round(Target.TargetSalesAmount,2) = round(Source.TargetSalesAmount,2))
when matched and (Target.ChannelIDKey <> Source.ChannelIDKey or Target.ResellerIDKey <> Source.RIDKey or Target.StoreIDKey <> Source.StoreIDKey or Target.DimDateID <> Source.DimDateID or
round(Target.TargetSalesAmount,2) <> round(Source.TargetSalesAmount,2)) then 
update set Target.ChannelIDKey = Source.ChannelIDKey, Target.ResellerIDKey = Source.RIDKey, Target.StoreIDKey = Source.StoreIDKey, Target.DimDateID = Source.DimDateID, 
Target.TargetSalesAmount = Source.TargetSalesAmount
when not matched by Target then insert (ChannelIDKey,ResellerIDKey,StoreIDKey,TargetSalesAmount,DimDateID) 
values (Source.ChannelIDKey,Source.RIDKey,Source.StoreIDKey,Source.TargetSalesAmount,Source.DimDateID);


/* Load SalesFact table*/
merge SalesFact as Target using
(select isnull(P.ProductIDKey,-1) as ProductIdKey,isnull(C.CustomerIDKey,-1) as CustomerIDKey , isnull(R.ResellerIDKey,-1) as ResellerIDKey, isnull(S.StoreIDKey,-1) as StoreIDKey, 
isnull(CH.ChannelIDKey,-1) as ChannelIDKey, SH.SalesHeaderID as SalesHeaderID, SalesDetailID, SalesQuantity, SalesAmount, DimDateID, Price, Cost, (SalesQuantity * Cost) as ExtendedCost
from StageSalesHeader SH
join StageSalesDetail SD on SH.SalesHeaderID = SD.SalesHeaderID 
join ProductDim P on P.ProductID = SD.ProductID
join StageProduct SP on SP.ProductID = SD.ProductID
left join CustomerDim C on C.CustomerID = SH.CustomerID
join ChannelDim CH on CH.ChannelID = SH.ChannelID
left join StoreDim S on S.StoreID = SH.StoreID
left join ResellerDim R on R.ResellerID = SH.ResellerID
join DimDate D on D.FullDate = SH.Date) as Source
on (Target.ProductIDKey = Source.ProductIDKey and Target.CustomerIDKey = Source.CustomerIDKey and Target.ResellerIDKey = Source.ResellerIDKey and Target.StoreIDKey = Source.StoreIDKey and
Target.ChannelIDKey = Source.ChannelIDKey and Target.SalesHeaderID = Source.SalesHeaderID and Target.SalesDetailID = Source.SalesDetailID)
when matched and (Target.ProductIDKey <> Source.ProductIDKey or Target.CustomerIDKey <> Source.CustomerIDKey or Target.ResellerIDKey <> Source.ResellerIDKey or Target.StoreIDKey <> Source.StoreIDKey or
Target.ChannelIDKey <> Source.ChannelIDKey or Target.SalesHeaderID <> Source.SalesHeaderID or Target.SalesDetailID <> Source.SalesDetailID or Target.SalesQuantity <> Source.SalesQuantity or
Target.SalesAmount <> Source.SalesAmount or Target.DimDateID <> Source.DimDateID or Target.Price <> Source.Price or Target.Cost <> Source.Cost) then
update set Target.ProductIDKey = Source.ProductIDKey, Target.CustomerIDKey = Source.CustomerIDKey, Target.ResellerIDKey = Source.ResellerIDKey, Target.StoreIDKey = Source.StoreIDKey,
Target.ChannelIDKey = Source.ChannelIDKey, Target.SalesHeaderID = Source.SalesHeaderID, Target.SalesDetailID = Source.SalesDetailID, Target.SalesQuantity = Source.SalesQuantity,
Target.SalesAmount = Source.SalesAmount, Target.DimDateID = Source.DimDateID, Target.Price = Source.Price, Target.Cost = Source.Cost, Target.ExtendedCost = Source.ExtendedCost
when not matched by Target then insert (ProductIdKey, CustomerIDKey, ResellerIDKey, StoreIDKey, ChannelIDKey, SalesHeaderID, SalesDetailID, SalesQuantity, SalesAmount, DimDateID, Price, Cost, ExtendedCost) 
values (Source.ProductIdKey, Source.CustomerIDKey, Source.ResellerIDKey, Source.StoreIDKey, Source.ChannelIDKey, Source.SalesHeaderID, Source.SalesDetailID, Source.SalesQuantity, Source.SalesAmount, 
Source.DimDateID, Source.Price, Source.Cost, Source.ExtendedCost)
;


--select count(*) from TargetProductFact
--delete from TargetProductFact
--dbcc checkident ('TargetProductFact', RESEED, 0)
--delete from TargetCSRFact
--dbcc checkident ('TargetCSRFact', RESEED, 0)
--delete from SalesFact
--dbcc checkident ('SalesFact', RESEED, 0)

--select * from TargetProductFact where ProductIDKey = 1
--delete from TargetCSRFact
--delete from TargetProductFact
--delete from SalesFact
--select * from DimDate
--select * from StageTargetProduct


--select * from ProductDim
--select * from ChannelDim
--select * from SourceSystem.dbo.Reseller
--select * from StageTargetCSR
--select count(*) from TargetCSRFact
select * from TargetCSRFact
select * from TargetProductFact
select * from SalesFact
--select * from StageTargetCSR
--select * from ChannelDim
--select * from ResellerDim
--select * from StoreDim
--select * from StageTargetCSR
--select * from StageTargetProduct