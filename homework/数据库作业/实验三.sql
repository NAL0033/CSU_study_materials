create database PeninsulaCoffee;
--建表中...（忘记保存了，但幸好截图了，重新创建了一个）

CREATE DATABASE PeninsulaCoffeeDB;
GO
USE PeninsulaCoffeeDB;
GO

-- 1. 门店表
CREATE TABLE Store(
    StoreID INT PRIMARY KEY IDENTITY(1,1),
    StoreName NVARCHAR(50) NOT NULL,
    City NVARCHAR(30) NOT NULL,
    Address NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(11) UNIQUE NOT NULL,
    Status TINYINT DEFAULT 1 CHECK(Status IN (0,1)) -- 0:停业 1:营业
);

-- 2. 商品分类表
CREATE TABLE ProductCategory(
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(20) NOT NULL UNIQUE -- 咖啡、茶饮、甜点、轻食
);

-- 3. 商品表
CREATE TABLE Product(
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    ProductName NVARCHAR(50) NOT NULL,
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES ProductCategory(CategoryID),
    Price DECIMAL(10,2) NOT NULL CHECK(Price > 0),
    IsAvailable BIT DEFAULT 1 -- 0:下架 1:在售
);

-- 4. 会员等级表
CREATE TABLE MemberLevel(
    LevelID INT PRIMARY KEY IDENTITY(1,1),
    LevelName NVARCHAR(20) NOT NULL UNIQUE, -- 银卡、金卡、钻石卡
    DiscountRate DECIMAL(3,2) NOT NULL CHECK(DiscountRate BETWEEN 0.5 AND 1.0) -- 折扣率
);

-- 5. 会员表
CREATE TABLE Member(
    MemberID INT PRIMARY KEY IDENTITY(1,1),
    MemberName NVARCHAR(20) NOT NULL,
    Phone NVARCHAR(11) UNIQUE NOT NULL,
    LevelID INT NOT NULL DEFAULT 1 FOREIGN KEY REFERENCES MemberLevel(LevelID),
    Points INT NOT NULL DEFAULT 0 CHECK(Points >= 0),
    RegisterTime DATETIME DEFAULT GETDATE()
);

-- 6. 职位表
CREATE TABLE Position(
    PositionID INT PRIMARY KEY IDENTITY(1,1),
    PositionName NVARCHAR(20) NOT NULL UNIQUE -- 店长、收银员、咖啡师
);

-- 7. 员工表
CREATE TABLE Employee(
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeName NVARCHAR(20) NOT NULL,
    Phone NVARCHAR(11) UNIQUE NOT NULL,
    StoreID INT NOT NULL FOREIGN KEY REFERENCES Store(StoreID),
    PositionID INT NOT NULL FOREIGN KEY REFERENCES Position(PositionID),
    Status TINYINT DEFAULT 1 CHECK(Status IN (0,1)) -- 0:离职 1:在职
);

-- 8. 订单表
CREATE TABLE Orders(
    OrderID INT PRIMARY KEY IDENTITY(1,1),
    StoreID INT NOT NULL FOREIGN KEY REFERENCES Store(StoreID),
    MemberID INT NULL FOREIGN KEY REFERENCES Member(MemberID), -- NULL表示散客
    EmployeeID INT NOT NULL FOREIGN KEY REFERENCES Employee(EmployeeID),
    OrderTime DATETIME DEFAULT GETDATE(),
    OrderType TINYINT NOT NULL CHECK(OrderType IN (1,2,3)), -- 1:堂食 2:自取 3:外卖
    TotalAmount DECIMAL(10,2) NOT NULL CHECK(TotalAmount >= 0),
    PayAmount DECIMAL(10,2) NOT NULL CHECK(PayAmount >= 0),
    OrderStatus TINYINT NOT NULL DEFAULT 1 CHECK(OrderStatus IN (1,2,3,4)) -- 1:待支付 2:已支付 3:已完成 4:已取消
);

-- 9. 订单明细表
CREATE TABLE OrderItem(
    OrderItemID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID) ON DELETE CASCADE,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Product(ProductID),
    Quantity INT NOT NULL CHECK(Quantity > 0),
    UnitPrice DECIMAL(10,2) NOT NULL CHECK(UnitPrice > 0),
    Subtotal DECIMAL(10,2) NOT NULL CHECK(Subtotal > 0)
);

-- 10. 支付流水表
CREATE TABLE Payment(
    PaymentID INT PRIMARY KEY IDENTITY(1,1),
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID),
    PaymentMethod TINYINT NOT NULL CHECK(PaymentMethod IN (1,2,3)), -- 1:微信 2:支付宝 3:现金
    PayAmount DECIMAL(10,2) NOT NULL CHECK(PayAmount > 0),
    PayTime DATETIME DEFAULT GETDATE(),
    PaymentStatus TINYINT NOT NULL DEFAULT 1 CHECK(PaymentStatus IN (1,2)) -- 1:成功 2:失败
);

--插入数据
-- 1. 门店表
insert into store (storename, city, address, phone, status) values
('半岛咖啡岳麓山店', '长沙', '岳麓区麓山南路123号', '13800138001', 1),
('半岛咖啡五一广场店', '长沙', '芙蓉区五一广场7mall2楼', '13800138002', 1),
('半岛咖啡黄兴步行街店', '长沙', '天心区黄兴南路步行街456号', '13800138003', 1),
('半岛咖啡橘子洲店', '长沙', '岳麓区橘子洲头景区内', '13800138004', 1),
('半岛咖啡德思勤店', '长沙', '雨花区德思勤城市广场A座1楼', '13800138005', 0); -- 停业门店

-- 2. 商品分类表
insert into productcategory (categoryname) values
('咖啡'),
('茶饮'),
('甜点'),
('轻食');

-- 3. 商品表
insert into product (productname, categoryid, price, isavailable) values
('美式咖啡', 1, 22.00, 1),
('拿铁咖啡', 1, 28.00, 1),
('卡布奇诺', 1, 28.00, 1),
('摩卡咖啡', 1, 32.00, 1),
('冰美式', 1, 24.00, 1),
('柠檬茶', 2, 18.00, 1),
('蜜桃乌龙茶', 2, 20.00, 1),
('提拉米苏', 3, 35.00, 1),
('芝士蛋糕', 3, 32.00, 1),
('三明治', 4, 25.00, 1);

-- 4. 会员等级表
insert into memberlevel (levelname, discountrate) values
('银卡', 0.95),
('金卡', 0.90),
('钻石卡', 0.85);

-- 5. 会员表
insert into member (membername, phone, levelid, points, registertime) values
('张三', '13900139001', 1, 120, '2026-01-15'),
('李四', '13900139002', 2, 560, '2025-12-20'),
('王五', '13900139003', 3, 1280, '2025-10-08'),
('赵六', '13900139004', 1, 80, '2026-03-01'),
('孙七', '13900139005', 2, 420, '2026-02-10');

-- 6. 职位表
insert into position (positionname) values
('店长'),
('收银员'),
('咖啡师'),
('服务员');

-- 7. 员工表
insert into employee (employeename, phone, storeid, positionid, status) values
('王店长', '13700137001', 1, 1, 1),
('李收银', '13700137002', 1, 2, 1),
('张咖啡', '13700137003', 1, 3, 1),
('刘服务', '13700137004', 1, 4, 1),
('陈店长', '13700137005', 2, 1, 1),
('周收银', '13700137006', 2, 2, 1),
('吴咖啡', '13700137007', 2, 3, 1),
('郑服务', '13700137008', 2, 4, 1);

-- 8. 订单表
insert into orders (storeid, memberid, employeeid, ordertime, ordertype, totalamount, payamount, orderstatus) values
(1, 1, 2, '2026-05-20 09:30:00', 1, 22.00, 20.90, 3), -- 银卡95折
(1, 2, 2, '2026-05-20 10:15:00', 2, 56.00, 50.40, 3), -- 金卡9折
(1, null, 2, '2026-05-20 11:00:00', 3, 28.00, 28.00, 3), -- 散客
(2, 3, 6, '2026-05-20 14:20:00', 1, 67.00, 56.95, 3), -- 钻石卡85折
(2, 4, 6, '2026-05-20 15:45:00', 2, 40.00, 38.00, 3), -- 银卡95折
(1, 5, 2, '2026-05-21 08:50:00', 1, 32.00, 28.80, 3), -- 金卡9折
(2, null, 6, '2026-05-21 12:30:00', 3, 53.00, 53.00, 3), -- 散客
(1, 2, 2, '2026-05-21 16:10:00', 1, 60.00, 54.00, 2); -- 已支付未完成

-- 9. 订单明细表
insert into orderitem (orderid, productid, quantity, unitprice, subtotal) values
(1, 1, 1, 22.00, 22.00), -- 美式咖啡1杯
(2, 2, 1, 28.00, 28.00), -- 拿铁1杯
(2, 8, 1, 35.00, 35.00), -- 提拉米苏1份
(3, 3, 1, 28.00, 28.00), -- 卡布奇诺1杯
(4, 4, 1, 32.00, 32.00), -- 摩卡1杯
(4, 9, 1, 32.00, 32.00), -- 芝士蛋糕1份
(5, 6, 2, 18.00, 36.00), -- 柠檬茶2杯
(6, 5, 1, 24.00, 24.00), -- 冰美式1杯
(7, 10, 1, 25.00, 25.00), -- 三明治1份
(7, 7, 1, 20.00, 20.00), -- 蜜桃乌龙茶1杯
(8, 2, 2, 28.00, 56.00); -- 拿铁2杯

-- 10. 支付流水表
insert into payment (orderid, paymentmethod, payamount, paytime, paymentstatus) values
(1, 1, 20.90, '2026-05-20 09:30:15', 1), -- 微信支付
(2, 2, 50.40, '2026-05-20 10:15:30', 1), -- 支付宝支付
(3, 3, 28.00, '2026-05-20 11:00:20', 1), -- 现金支付
(4, 1, 56.95, '2026-05-20 14:20:45', 1), -- 微信支付
(5, 2, 38.00, '2026-05-20 15:45:10', 1), -- 支付宝支付
(6, 1, 28.80, '2026-05-21 08:50:35', 1), -- 微信支付
(7, 3, 53.00, '2026-05-21 12:30:50', 1), -- 现金支付
(8, 2, 54.00, '2026-05-21 16:10:25', 1); -- 支付宝支付

select * from store;
select * from productcategory;
select * from product;
select * from memberlevel;
select * from member;
select * from position;
select * from employee;
select * from orders;
select * from orderitem;
select * from payment;