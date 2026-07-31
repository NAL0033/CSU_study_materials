/*
此查询文本从显示计划 XML 检索获得，并可能会被截断。
*/

select * from Orders
;

--写一段程序，向表Orders中增加1000万条记录，要求订单尽可能均匀地分布在12个月中。（注意：如何实现cid,aid,pid三个外键的取值，如何实现12个月的均匀分布）
declare @i int = 1;

while @i<=10000000
end

--2、 假设在表Orders上经常要执行的一个查询是“根据给定的用户ID（cid）和月份（month），查询该用户在该月订单的总金额”。写出该查询的SQL语句，尝试通过创建索引提高查询的速度，通过查看执行计划了解查询的执行方式，并对比创建索引前后执行查询所消耗的时间。（注意：记录创建索引前后执行查询所消耗的时间）
select sum(dollars) totalDollars
from Orders
where month = 'Jan'and cid = 'c001';

create index idx_orders_cid_month
on Orders(month,cid);

drop index idx_orders_cid_month on Orders;

IF EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'idx_orders_month_cid'
      AND object_id = OBJECT_ID('Orders')
)
DROP INDEX idx_orders_month_cid ON Orders;
GO

SET STATISTICS TIME ON;
GO

SELECT SUM(dollars) AS TotalDollars
FROM Orders
WHERE cid = 'C001'
  AND month = 'Jan';
GO

SET STATISTICS TIME OFF;
GO

-- 3. 创建优化索引
CREATE INDEX idx_orders_month_cid
ON Orders(month, cid)
INCLUDE (dollars);
GO

-- 4. 创建索引后，再执行同一个查询
-- 观察执行计划是否从 Scan 变成 Seek
SET STATISTICS TIME ON;
GO

SELECT SUM(dollars) AS TotalDollars
FROM Orders
WHERE cid = 'C001'
  AND month = 'Jan';
GO

SET STATISTICS TIME OFF;
GO

--1、假设GlobalToyz数据库的用户经常需要查询某个购物者(shopper)的所有已送达订单的编号和待送达订单的编号。请通过定义视图解决这个问题。
create view v_OrderStatus
as
select
    o.cShopperId,
    o.cOrderNo,
    case
        when s.dActualDeliveryDate is not null then 'deliverd'
        else 'pending'
    end as Status
from Orders o
left join Shipment s on o.cOrderNo = s.cOrderNo;
select * from v_OrderStatus;

--2、基于（1）中定义的视图，根据给定的购物者Id查询该购物者所有待送达玩具的Id,名称和描述。
select t.cToyId,t.vToyName,t.vToyDescription
from v_OrderStatus v
join Orders o on v.cOrderNo=o.cOrderNo
join OrderDetail od on od.cOrderNo=o.cOrderNo
join Toys t on t.cToyId=od.cToyId
where v.Status ='pending'and v.cShopperId='000001';

--3、为系统创建两类用户角色，一类为系统管理员，拥有所有权限；另一类为购物者（Shopper），只能查看与之相关的信息，例如某购物者只能查看自己下的订单、自己的姓名、地址、邮件等信息。当系统中新增一个购物者（Shopper）的时候，需要为该购物者创建一个账号，并通过基于视图的授权机制实现权限的控制。请给出解决的方案。
create role admin_role;
create role shopper_role;
grant control on database::globaltoyz to admin_role;

create view v_my_info
as
select
    cShopperId,
    vFirstName,
    vLastName,
    vEmailId,
    vAddress
from Shopper
where cShopperId=SUSER_NAME();

--PickofMonth这张表是一张统计表，按年月统计某个玩具的销售总量。
create trigger trg_UpdatePickOfMonth
on OrderDetail
after insert
as
begin
    insert into PickOfMonth(cToyId,siMonth,iYear,iTotalSold)
    select
        i.cToyId,
        month(getdate()),
        year(getdate()),
        sum(i.siQty)
    from inserted i
    group by i.cToyId;
end
--审计
CREATE TABLE OrderDetail_Audit (
    id INT IDENTITY PRIMARY KEY,
    action_type VARCHAR(10),
    action_time DATETIME,
    old_data VARCHAR(MAX),
    new_data VARCHAR(MAX)
);

CREATE TRIGGER trg_AuditOrderDetail
ON OrderDetail
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    INSERT INTO OrderDetail_Audit
    SELECT 
        'UPDATE',
        GETDATE(),
        (SELECT * FROM deleted FOR JSON AUTO),
        (SELECT * FROM inserted FOR JSON AUTO);
END

--事务
create procedure sp_create_order
    @ccartid char(6),
    @cshopperid char(6)
as
begin
    set nocount on;

    begin transaction;

    -- 1. 生成订单号
    declare @corderno char(6);
    set @corderno = right('000000' + cast(abs(checksum(newid())) % 1000000 as varchar),6);

    -- 2. 插入 orders
    insert into orders
    (
        corderno,
        dorderdate,
        ccartid,
        cshopperid,
        cshippingmodeid,
        mshippingcharges,
        mgiftwrapcharges,
        corderprocessed,
        mtotalcost,
        dexpdeldate
    )
    values
    (
        @corderno,
        getdate(),
        @ccartid,
        @cshopperid,
        '01',
        0,
        0,
        'y',
        0,
        dateadd(day, 3, getdate())
    );

    -- 3. 插入 orderdetail
    insert into orderdetail (corderno, ctoyid, siqty, mtoycost)
    select 
        @corderno,
        sc.ctoyid,
        sc.siqty,
        sc.siqty * t.mtoyrate
    from shoppingcart sc
    join toys t on sc.ctoyid = t.ctoyid
    where sc.ccartid = @ccartid;

    -- 4. 更新库存
    update t
    set t.sitoyqoh = t.sitoyqoh - sc.siqty
    from toys t
    join shoppingcart sc on t.ctoyid = sc.ctoyid
    where sc.ccartid = @ccartid;

    -- 5. 生成 shipment
    insert into shipment (corderno, dshipmentdate, cdeliverystatus, dactualdeliverydate)
    values
    (
        @corderno,
        getdate(),
        'n',
        null
    );

    -- 6. 清空购物车
    delete from shoppingcart
    where ccartid = @ccartid;

    commit;
end;


--游标
DECLARE cur CURSOR FOR
SELECT cShopperId, vFirstName, vLastName, vAddress
FROM Shopper;

OPEN cur;

DECLARE @id CHAR(6), @name VARCHAR(50), @addr VARCHAR(100);

FETCH NEXT FROM cur INTO @id, @name, @name, @addr;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '购货人ID: ' + @id;
    PRINT '地址: ' + @addr;

    SELECT cOrderNo, dOrderDate, mTotalCost
    FROM Orders
    WHERE cShopperId = @id;

    FETCH NEXT FROM cur INTO @id, @name, @name, @addr;
END;

CLOSE cur;
DEALLOCATE cur;


--开放题
SELECT cCity, cCategoryId, COUNT(*) AS BuyCount
FROM Orders o
JOIN OrderDetail od ON o.cOrderNo = od.cOrderNo
JOIN Toys t ON od.cToyId = t.cToyId
JOIN Shopper s ON o.cShopperId = s.cShopperId
GROUP BY cCity, cCategoryId
ORDER BY BuyCount DESC;