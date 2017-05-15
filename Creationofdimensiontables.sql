--Creating Location dimension
create table LocationDim(
LocationKey	int identity (1,1) primary key,
Address nvarchar(255),
City	nvarchar(255),
StateProvince nvarchar(255),
PostalCode nvarchar(255),
Country nvarchar(255)
)

--Creating Customer dimension--might have to add phone number (need to check this)
create table CustomerDim(
CustomerIDKey	int identity (1,1) primary key,
CustomerID	uniqueidentifier,
FirstName nvarchar(255),
LastName nvarchar(255),
Gender nvarchar(1),
PhoneNumber nvarchar(20),
EmailAddress nvarchar(255),
LocationKey int foreign key references LocationDim(LocationKey)
)

--Creating Store dimension
create table StoreDim(
StoreIDKey	int identity (1,1) primary key,
StoreID	int,
StoreNumber int,
StoreManager nvarchar(255),
PhoneNumber nvarchar(20),
LocationKey int foreign key references LocationDim(LocationKey)
)

--Creating Channel dimension
create table ChannelDim(
ChannelIDKey int identity (1,1) primary key,
ChannelID int,
ChannelCategoryID int,
Channel nvarchar(50),
ChannelCategory nvarchar(50)
)

--Creating Reseller dimension
create table ResellerDim(
ResellerIDKey int identity (1,1) primary key,
ResellerID uniqueidentifier,
ResellerName nvarchar(255),
Contact nvarchar(255),
EmailAddress nvarchar(255),
PhoneNumber nvarchar(20),
LocationKey int foreign key references LocationDim(LocationKey)
)

--Creating Product dimension
create table ProductDim(
ProductIDKey int identity (1,1) primary key,
ProductID int,
Product nvarchar(50),
ProductCategoryID int,
ProductCategory nvarchar(50),
ProductTypeID int,
ProductType nvarchar(25),
Weight numeric(16,4),
Color nvarchar(50),
Style nvarchar(50)
)

----------------------------------------------------------------------
--Dropping tables
drop table ProductDim
drop table ResellerDim
drop table ChannelDim
drop table StoreDim
drop table CustomerDim
drop table LocationDim
-----------------------------------------------------------------------

--Load Location Dimension table---

merge LocationDim as Target
using (select Address,City,StateProvince,PostalCode,Country from StageCustomer
union
select Address,City,StateProvince,PostalCode,Country from StageStore
Union
select Address,City,StateProvince,PostalCode,Country from StageReseller
) as Source
on (Target.Address  = Source.Address and Target.City = Source.City and Target.StateProvince = Source.StateProvince and Target.PostalCode = Source.PostalCode and Target.Country = Source.Country)
when matched and 
(Target.Address <> Source.Address or Target.City <> Source.City or Target.StateProvince <> Source.StateProvince or Target.PostalCode <> Source.PostalCode or Target.Country <> Source.Country) then
update set Target.Address = Source.Address, Target.City = Source.City , Target.StateProvince = Source.StateProvince , Target.Country = Source.Country
when not matched by Target then
insert (Address, City, StateProvince, PostalCode, Country) values (Source.Address, Source.City, Source.StateProvince, Source.PostalCode,Source.Country);
set identity_insert LocationDim on
insert into LocationDim (LocationKey,Address,City,StateProvince,PostalCode,Country) values (-1,'Unknown','Unknown','Unknown','Unknown','Unknown')
set identity_insert LocationDim off
--select @@ROWCOUNT;

--Load Customer Dimension table--

merge CustomerDim as Target 
using (select CustomerID, FirstName, LastName, Gender, PhoneNumber, EmailAddress,LocationKey from StageCustomer as SC join LocationDim as LD on
SC.Address =  LD.Address and SC.City = LD.City and SC.StateProvince = LD.StateProvince and SC.PostalCode = LD.PostalCode and SC.Country = LD.Country) as Source
on (Target.CustomerID = Source.CustomerID and Target.FirstName = Source.FirstName and Target.LastName = Source.LastName and Target.Gender = Source.Gender and Target.PhoneNumber = Source.PhoneNumber
and Target.EmailAddress = Source.EmailAddress and Target.LocationKey = Source.LocationKey)
when matched and (Target.CustomerID <> Source.CustomerID or Target.FirstName <> Source.FirstName or Target.LastName <> Source.LastName or Target.Gender <> Source.Gender or 
Target.PhoneNumber <> Source.PhoneNumber or Target.EmailAddress <> Source.EmailAddress or Target.LocationKey <> Source.LocationKey) then
update set Target.CustomerID = Source.CustomerID, Target.FirstName = Source.FirstName, Target.LastName = Source.LastName, Target.Gender = Source.Gender, Target.PhoneNumber = Source.PhoneNumber,
Target.EmailAddress = Source.EmailAddress, Target.LocationKey  = Source.LocationKey
when not matched by Target then insert (CustomerID, FirstName, LastName, Gender, PhoneNumber, EmailAddress, LocationKey) values 
(Source.CustomerID, Source.FirstName, Source.LastName, Source.Gender, Source.PhoneNumber, Source.EmailAddress, Source.LocationKey);
set identity_insert CustomerDim on
insert into CustomerDim (CustomerIDKey, CustomerID, FirstName, LastName, Gender, PhoneNumber, EmailAddress,LocationKey) 
values (-1,'00000000-0000-0000-0000-000000000000','Unknown','Unknown','U','Unknown','Unknown',-1)
set identity_insert CustomerDim off;

--select @@ROWCOUNT;


--Load Store dimension table---------

merge StoreDim as Target
using (select StoreID, StoreNumber, StoreManager, PhoneNumber, LocationKey from StageStore as SS join LocationDim as LD on
SS.Address =  LD.Address and SS.City = LD.City and SS.StateProvince = LD.StateProvince and SS.PostalCode = LD.PostalCode and SS.Country = LD.Country) as Source
on (Target.StoreID = Source.StoreID and Target.StoreNumber = Source.StoreNumber and Target.StoreManager = Source.StoreManager and Target.PhoneNumber = Source.PhoneNumber and 
Target.LocationKey = Source.LocationKey)
when matched and (Target.StoreID <> Source.StoreID or Target.StoreNumber <> Source.StoreNumber or Target.StoreManager <> Source.StoreManager or Target.PhoneNumber <> Source.PhoneNumber or 
Target.LocationKey <> Source.LocationKey) then 
update set Target.StoreID = Source.StoreID, Target.StoreNumber = Source.StoreNumber, Target.StoreManager = Source.StoreManager, Target.PhoneNumber = Source.PhoneNumber, Target.LocationKey = Source.LocationKey
when not matched by target then insert (StoreID, StoreNumber, StoreManager, PhoneNumber, LocationKey) values (Source.StoreID, Source.StoreNumber, Source.StoreManager, Source.PhoneNumber, Source.LocationKey);
set identity_insert StoreDim on
insert into StoreDim (StoreIDKey, StoreID, StoreNumber, StoreManager, PhoneNumber, LocationKey) values (-1,-1,-1,'Unknown','Unknown',-1)
set identity_insert StoreDim off;

--select @@ROWCOUNT;

--Load Reseller Dimension Table--

merge ResellerDim as Target 
using (select ResellerID, ResellerName, Contact, EmailAddress, PhoneNumber, LocationKey from StageReseller as SR join LocationDim as LD on
SR.Address =  LD.Address and SR.City = LD.City and SR.StateProvince = LD.StateProvince and SR.PostalCode = LD.PostalCode and SR.Country = LD.Country) as Source
on (Target.ResellerID = Source.ResellerID and Target.ResellerName = Source.ResellerName and Target.Contact = Source.Contact and Target.EmailAddress = Source.EmailAddress and
Target.PhoneNumber  = Source.PhoneNumber and Target.LocationKey = Source.LocationKey)
when matched and (Target.ResellerID <> Source.ResellerID or Target.ResellerName <> Source.ResellerName or Target.Contact <> Source.Contact or Target.EmailAddress <> Source.EmailAddress or
Target.PhoneNumber <> Source.PhoneNumber or Target.LocationKey <> Source.LocationKey) then
update set Target.ResellerID = Source.ResellerID, Target.ResellerName = Source.ResellerName, Target.Contact = Source.Contact, Target.EmailAddress = Source.EmailAddress, Target.PhoneNumber = Source.PhoneNumber,
Target.LocationKey = Source.LocationKey
when not matched by Target then insert (ResellerID, ResellerName, Contact, EmailAddress, PhoneNumber, LocationKey) values
(Source.ResellerID, Source.ResellerName, Source.Contact, Source.EmailAddress, Source.PhoneNumber, Source.LocationKey);
set identity_insert ResellerDim on
insert into ResellerDim (ResellerIDKey, ResellerID, ResellerName, Contact, EmailAddress, PhoneNumber, LocationKey) values (-1,'00000000-0000-0000-0000-000000000000','Unknown','Unknown','Unknown','Unknown',-1)
set identity_insert ResellerDim off;

--select @@ROWCOUNT;


--Load Channel Dimension Table--

merge ChannelDim as Target 
using (select ChannelID, SC.ChannelCategoryID, Channel, ChannelCategory from StageChannel SC join StageChannelCategory SCC on SC.ChannelCategoryID = SCC.ChannelCategoryID) as source
on (Target.ChannelID = Source.ChannelID and Target.ChannelCategoryID = Source.ChannelCategoryID and Target.Channel = Source.Channel and Target.ChannelCategory = Source.ChannelCategory)
when matched and (Target.ChannelID <> Source.ChannelID or Target.ChannelCategoryID <> Source.ChannelCategoryID or Target.Channel <> Source.Channel or Target.ChannelCategory <> Source.ChannelCategory) then
update set Target.ChannelID = Source.ChannelID, Target.ChannelCategoryID = Source.ChannelCategoryID, Target.Channel = Source.Channel, Target.ChannelCategory = Source.ChannelCategory
when not matched by target then insert (ChannelID, ChannelCategoryID, Channel, ChannelCategory) values (Source.ChannelID, Source.ChannelCategoryID, Source.Channel, Source.ChannelCategory);
set identity_insert ChannelDim on
insert into ChannelDim (ChannelIDKey,ChannelID, ChannelCategoryID, Channel,ChannelCategory ) values (-1,-1,-1,'Unknown','Unknown')
set identity_insert ChannelDim off;

--select @@ROWCOUNT;

--Load the Product Dimension Table--

merge ProductDim as Target
using (select P.ProductID, P.Product, PCT.ProductCategoryID, PCT.ProductCategory, PCT.ProductTypeID, PCT.ProductType, P.Weight, P.Color, P.Style from StageProduct P join
(select PC.ProductCategoryID, PC.ProductCategory, PT.ProductTypeID, PT.ProductType from StageProductCategory PC join StageProductType PT on PT.ProductCategoryID = PC.ProductCategoryID) as PCT
on P.ProductTypeID = PCT.ProductTypeID) as Source
on (Target.ProductId = Source.ProductId and Target.Product = Source.Product and Target.ProductCategoryId = Source.ProductCategoryId and Target.ProductCategory = Source.ProductCategory and 
Target.ProductTypeId = Source.ProductTypeId and Target.ProductType = Source.ProductType and Target.Weight = Source.Weight and Target.Color = Source.Color and Target.Style = Source.Style)
when matched and  (Target.ProductId <> Source.ProductId or Target.Product <> Source.Product or Target.ProductCategoryId <> Source.ProductCategoryId or Target.ProductCategory <> Source.ProductCategory or
Target.ProductTypeId <> Source.ProductTypeId or Target.ProductType <> Source.ProductType or Target.Weight <> Source.Weight or Target.Color <> Source.Color or Target.Style <> Source.Style) then
update set Target.ProductId = Source.ProductId, Target.Product = Source.Product, Target.ProductCategoryId = Source.ProductCategoryId, Target.ProductCategory = Source.ProductCategory, 
Target.ProductTypeId = Source.ProductTypeId, Target.ProductType = Source.ProductType, Target.Weight = Source.Weight, Target.Color = Source.Color, Target.Style = Source.Style
when not matched by target then insert (ProductID, Product, ProductCategoryID, ProductCategory, ProductTypeID, ProductType, Weight, Color, Style) values (Source.ProductID, Source.Product,
Source.ProductCategoryID, Source.ProductCategory, Source.ProductTypeID, Source.ProductType, Source.Weight, Source.Color, Source.Style);
set identity_insert ProductDim on
insert into ProductDim (ProductIDKey,ProductID, Product, ProductCategoryID, ProductCategory,ProductTypeID, ProductType,Weight,Color,Style) 
values (-1,-1,'Unknown',-1,'Unknown',-1, 'Unknown', NULL,NULL,NULL)
set identity_insert ProductDim off;

--select @@rowcount;


merge ProductDim as Target
using (select P.ProductID, P.Product, PCT.ProductCategoryID, PCT.ProductCategory, PCT.ProductTypeID, PCT.ProductType, P.Weight, P.Color, P.Style from StageProduct P join
(select PC.ProductCategoryID, PC.ProductCategory, PT.ProductTypeID, PT.ProductType from StageProductCategory PC join StageProductType PT on PT.ProductCategoryID = PC.ProductCategoryID) as PCT
on P.ProductTypeID = PCT.ProductTypeID) as Source
on Target.ProductId = Source.ProductId
when matched and  (Target.ProductId <> Source.ProductId or Target.Product <> Source.Product or Target.ProductCategoryId <> Source.ProductCategoryId or Target.ProductCategory <> Source.ProductCategory or
Target.ProductTypeId <> Source.ProductTypeId or Target.ProductType <> Source.ProductType or Target.Weight <> Source.Weight or Target.Color <> Source.Color or Target.Style <> Source.Style) then
update set Target.ProductId = Source.ProductId, Target.Product = Source.Product, Target.ProductCategoryId = Source.ProductCategoryId, Target.ProductCategory = Source.ProductCategory, 
Target.ProductTypeId = Source.ProductTypeId, Target.ProductType = Source.ProductType, Target.Weight = Source.Weight, Target.Color = Source.Color, Target.Style = Source.Style
when not matched by target then insert (ProductID, Product, ProductCategoryID, ProductCategory, ProductTypeID, ProductType, Weight, Color, Style) values (Source.ProductID, Source.Product,
Source.ProductCategoryID, Source.ProductCategory, Source.ProductTypeID, Source.ProductType, Source.Weight, Source.Color, Source.Style);
set identity_insert ProductDim on
insert into ProductDim (ProductIDKey,ProductID, Product, ProductCategoryID, ProductCategory,ProductTypeID, ProductType,Weight,Color,Style) 
select -1,-1,'Unknown',-1,'Unknown',-1, 'Unknown', NULL,NULL,NULL where not exists (select 1 from ProductDim where ProductIDKey = -1)
set identity_insert ProductDim off;
