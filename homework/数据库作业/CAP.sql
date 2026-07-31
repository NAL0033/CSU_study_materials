--CAP数据库
create database CAP;
use CAP;

--1.创建表
create table Customers(
cid char(4) primary key,
cname varchar(50) not null ,
city varchar(50),
discnt decimal(5,2)default 0 check (discnt>=0)
);

create table Agents(
aid char(4)primary key,
aname varchar(50)not null,
city varchar(50),
percen decimal(5,2) check (percen>=0)
);

create table Products(
pid char(4) primary key,
pname varchar(50) not null,
city varchar(50),
quantity int check(quantity>=0),
price decimal(10,2)check(price>=0)
);

create table Orders(
ordno int primary key,
month varchar(10),
cid char(4),
aid char(4),
pid char(4),
qty int check(qty>0),
dollars decimal(10,2)check(dollars>=0),
foreign key(cid)references Customers(cid),
foreign key(aid)references Agents(aid),
foreign key(pid)references Products(pid)
);

--2.创建用户并授权
create login cap_user with password ='Cap@123456';
go
use CAP
go
create user cap_user for login cap_user;
go
alter role db_owner add member cap_user;
go

--3.插入示例数据
insert into Customers Values
('C001','TipTop','Duluth',10.00),
('C002','Basics','Dallas',12.00),
('C003', 'Allied', 'Dallas', 8.00),
('C004', 'ACME', 'Duluth', 8.00),
('C006', 'ACME', 'Kyoto', 0.00);
SELECT * FROM Customers;

insert into Agents Values
('A01','smith','NewYork',6),
('A02', 'jones', 'Newark', 6),
('A03', 'Brown', 'Tokyo', 7),
('A04', 'Gray', 'New York', 6),
('A05', 'Otasi', 'Duluth', 5),
('A06', 'Smith', 'Dallas', 5);
select * from Agents;

insert into Products values
('P01', 'comb', 'Dallas', 111400, 0.50),
('P02', 'brush', 'Newark', 203000, 0.50),
('P03', 'razor', 'Duluth', 150600, 1.00),
('P04', 'Pen', 'Duluth', 125300, 1.00),
('P05', 'pencil', 'Dallas', 221400, 1.00),
('P06', 'folder', 'Dallas', 123100, 2.00),
('P07', 'case', 'Newark', 100500, NULL);
select * from Products;

insert into Orders values
(1011, 'jan', 'C001', 'A01', 'P01', 1000, 450.00),
(1012, 'jan', 'C001', 'A01', 'P01', 1000, 450.00),
(1019, 'feb', 'C001', 'A02', 'P02', 400, 180.00),
(1017, 'feb', 'C001', 'A06', 'P03', 600, 540.00),
(1018, 'Feb', 'C001', 'A03', 'P04', 600, 540.00),
(1023, 'Mar', 'C001', 'A04', 'P05', 500, 450.00),
(1022, 'Mar', 'C001', 'A05', 'P06', 400, 720.00);
select * from Orders;

--4.创建 Orders_Sta 并统计每月订单数和总金额
create table Orders_Sta(
month varchar (10)primary key,
order_count int,
total_dollars decimal(10,2)
);

insert into Orders_Sta
select lower(month)as month,count(*)as order_count,sum(dollars)as total_dollars
from Orders
group by lower(month);

select * from Orders_Sta ;

--5.删除month为Jan的订单
delete from Orders 
where lower(month)='jan';

select*from Orders;

--6.曾下过 dollars > 500 订单的客户，折扣增加 2
update Customers
set discnt = discnt+2
where cid in(
  select distinct cid
  from Orders
  where dollars>500
);

select * from Customers;