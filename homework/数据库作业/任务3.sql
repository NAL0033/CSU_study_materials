use GlobalToyz 
go

select * from Shopper;

select vFirstname,vLastname,vEmailId
from Shopper
where vCreditCardType='Master Card'and cState = 'California';

select * from Orders;
select cShopperId,sum(mTotalCost)as 订单总额
from Orders 
where year(dOrderDate)=2021
group by cShopperId 
order by 订单总额 asc;

select * from OrderDetail
select * from OrderDetail
where vMessage is null;

select vFirstname,vLastname,vEmailId
from Shopper
where len(cPassword)<6; 

select * from Recipient ;
select * from Country ;

select r.vFirstName, r.vLastName, c.cCountry
from Recipient r
join Country c on r.cCountryId = c.cCountryId
where r.cPhone like '123%';

select top 3 cToyId
from PickOfMonth
where iYear=2020
order by iTotalSold desc;

--8.	根据OrderDetail表，查找玩具总价值大于￥50的定单的号码和玩具总价值。
select cOrderNo,sum(mToyCost) 玩具总价值
from OrderDetail
group by cOrderNo having sum(mToyCost)>50;

--9.	查找一份包含所有装运信息的报表，包括：Order Number, Shipment Date, Actual Delivery Date, Days in Transit. (提示：Days in Transit = Actual Delivery Date – Shipment Date) 
select 
    cOrderNo as [Order Number],
    dShipmentDate as [Shipment Date],
    dActualDeliveryDate as [Actual Delivery Date],
    DATEDIFF(DAY, dShipmentDate, dActualDeliveryDate) as [Days in Transit]
from Shipment;

--10.	查找所有玩具的名称、品牌和类别（Toy Name, Brand, Category）。
SELECT 
    t.vToyName AS [Toy Name],
    b.cBrandName AS [Brand],
    c.cCategory AS [Category]
FROM Toys t
JOIN ToyBrand b ON t.cBrandId = b.cBrandId
JOIN Category c ON t.cCategoryId = c.cCategoryId;

--11.	查找“Activity”这个类别的玩具的最高价格、最低价格和平均价格。
SELECT 
    MAX(t.mToyRate) AS MaxPrice,
    MIN(t.mToyRate) AS MinPrice,
    AVG(t.mToyRate) AS AvgPrice
FROM Toys t
JOIN Category c ON t.cCategoryId = c.cCategoryId
WHERE c.cCategory = 'Activity';

--12.	查找玩具的名称和所有玩具的购物车ID。如果玩具不在购物车中，也需在结果中出现。
SELECT 
    t.vToyName,
    sc.cCartId
FROM Toys t
LEFT JOIN ShoppingCart sc ON t.cToyId = sc.cToyId;

--13.	以下列格式查找所有购物者的名字和他们的简称：（Initials, vFirstName, vLastName）,例如Angela Smith的Initials为A.S。
select 
    left(vFirstName, 1) + '.' + left(vLastName, 1) + '.' AS Initials,
    vFirstName,
    vLastName
from Shopper;

--14.	查找“Standard Shipping”这种快递模式的单价最低的国家的名称。
select top 1 c.cCountry
from ShippingRate sr
join Country c on sr.cCountryId = c.cCountryId
join ShippingMode sm on sr.cModeId = sm.cModeId
where sm.cMode = 'Standard Shipping'
order by sr.mRatePerPound ASC;

--15.	查找买过名称为“Kitchen Set”的玩具的购物者的ID、姓名、邮件地址及所在的城市。
SELECT DISTINCT
    s.cShopperId,
    s.vFirstName,
    s.vLastName,
    s.vEmailId,
    s.cCity
FROM Shopper s
JOIN Orders o ON s.cShopperId = o.cShopperId
JOIN OrderDetail od ON o.cOrderNo = od.cOrderNo
JOIN Toys t ON od.cToyId = t.cToyId
WHERE t.vToyName = 'Kitchen Set';

--16.	查找所有购物者和收货人的名、姓、地址和所在城市，要求保留结果中的重复记录。
SELECT vFirstName, vLastName, vAddress, cCity
FROM Shopper

UNION all

SELECT vFirstName, vLastName, vAddress, cCity
FROM Recipient;

--17.	查找没有包装的所有玩具的名称。（要求用子查询实现）
SELECT vToyName
FROM Toys
WHERE cToyId NOT IN (
    SELECT cToyId
    FROM OrderDetail
    WHERE cWrapperId IS NOT NULL
);

--18.	查找已收货定单的定单号码以及下定单的时间。（要求用子查询实现）
SELECT cOrderNo, dOrderDate
FROM Orders
WHERE cOrderNo IN (
    SELECT cOrderNo
    FROM Shipment
    WHERE dActualDeliveryDate IS NOT NULL
);

--19.	查找从来没有下过订单的购物者。
SELECT *
FROM Shopper
WHERE cShopperId NOT IN (
    SELECT DISTINCT cShopperId
    FROM Orders
);

--20.	删除“Largo”牌的所有玩具。

DELETE pom
FROM PickOfMonth pom
JOIN Toys t ON pom.cToyId = t.cToyId
JOIN ToyBrand b ON t.cBrandId = b.cBrandId
WHERE b.cBrandName = 'Largo';

DELETE od
FROM OrderDetail od
JOIN Toys t ON od.cToyId = t.cToyId
JOIN ToyBrand b ON t.cBrandId = b.cBrandId
WHERE b.cBrandName = 'Largo';

DELETE sc
FROM ShoppingCart sc
JOIN Toys t ON sc.cToyId = t.cToyId
JOIN ToyBrand b ON t.cBrandId = b.cBrandId
WHERE b.cBrandName = 'Largo';

DELETE t
FROM Toys t
JOIN ToyBrand b ON t.cBrandId = b.cBrandId
WHERE b.cBrandName = 'Largo';