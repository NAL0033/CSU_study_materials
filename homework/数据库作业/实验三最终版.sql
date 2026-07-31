create database bandao_coffee;
go

use bandao_coffee;
go

create table city (
    city_id int primary key,
    city_name varchar(50) not null
);

create table store (
    store_id int primary key,
    store_name varchar(100) not null,
    city_id int not null,
    address varchar(200),
    foreign key (city_id) references city(city_id)
);

create table employee (
    employee_id int primary key,
    employee_name varchar(50) not null,
    store_id int not null,
    position varchar(50),
    phone varchar(20),
    foreign key (store_id) references store(store_id)
);

create table member (
    member_id int primary key,
    member_name varchar(50) not null,
    phone varchar(20),
    points int default 0,
    register_time datetime default getdate()
);

create table product (
    product_id int primary key,
    product_name varchar(100) not null,
    category varchar(50),
    price decimal(10,2) not null
);

create table inventory (
    inventory_id int primary key,
    store_id int not null,
    product_id int not null,
    quantity int not null,
    foreign key (store_id) references store(store_id),
    foreign key (product_id) references product(product_id)
);

create table coupon (
    coupon_id int primary key,
    coupon_name varchar(100) not null,
    discount_amount decimal(10,2) not null,
    min_amount decimal(10,2) default 0
);

create table orders (
    order_id int primary key,
    store_id int not null,
    member_id int,
    employee_id int,
    coupon_id int,
    order_type varchar(20) not null,
    order_status varchar(20) not null,
    total_amount decimal(10,2) not null,
    actual_amount decimal(10,2) not null,
    order_time datetime default getdate(),
    foreign key (store_id) references store(store_id),
    foreign key (member_id) references member(member_id),
    foreign key (employee_id) references employee(employee_id),
    foreign key (coupon_id) references coupon(coupon_id)
);

create table order_detail (
    detail_id int primary key,
    order_id int not null,
    product_id int not null,
    quantity int not null,
    unit_price decimal(10,2) not null,
    subtotal decimal(10,2) not null,
    foreign key (order_id) references orders(order_id),
    foreign key (product_id) references product(product_id)
);

create table payment (
    payment_id int primary key,
    order_id int not null,
    pay_method varchar(20) not null,
    pay_amount decimal(10,2) not null,
    pay_time datetime default getdate(),
    foreign key (order_id) references orders(order_id)
);

create table refund (
    refund_id int primary key,
    order_id int not null,
    refund_amount decimal(10,2) not null,
    refund_reason varchar(200),
    refund_time datetime default getdate(),
    foreign key (order_id) references orders(order_id)
);

create table schedule (
    schedule_id int primary key,
    employee_id int not null,
    work_date date not null,
    start_time time not null,
    end_time time not null,
    foreign key (employee_id) references employee(employee_id)
);

--截图
select name from sys.databases;
--数据
insert into city values
(1, '北京'),
(2, '上海'),
(3, '杭州');

insert into store values
(1, '半岛咖啡北京朝阳店', 1, '北京市朝阳区'),
(2, '半岛咖啡上海浦东店', 2, '上海市浦东新区'),
(3, '半岛咖啡杭州西湖店', 3, '杭州市西湖区');

insert into employee values
(1, '张明', 1, '店长', '13800000001'),
(2, '李芳', 1, '收银员', '13800000002'),
(3, '王强', 2, '咖啡师', '13800000003'),
(4, '赵敏', 3, '店员', '13800000004');

insert into member values
(1, '刘洋', '13900000001', 120, '2024-01-10'),
(2, '陈晨', '13900000002', 80, '2024-02-15'),
(3, '周宁', '13900000003', 200, '2024-03-20');

insert into product values
(1, '美式咖啡', '咖啡', 18.00),
(2, '拿铁', '咖啡', 26.00),
(3, '摩卡', '咖啡', 28.00),
(4, '芝士蛋糕', '甜品', 32.00),
(5, '三明治', '轻食', 25.00);

insert into inventory values
(1, 1, 1, 100),
(2, 1, 2, 80),
(3, 1, 4, 30),
(4, 2, 1, 120),
(5, 2, 3, 60),
(6, 3, 2, 90),
(7, 3, 5, 40);

insert into coupon values
(1, '满50减10', 10.00, 50.00),
(2, '满80减20', 20.00, 80.00),
(3, '新人优惠券', 8.00, 30.00);

insert into orders values
(1, 1, 1, 2, 1, '堂食', '已支付', 58.00, 48.00, '2025-05-01 10:20:00'),
(2, 1, 2, 2, null, '自取', '已支付', 26.00, 26.00, '2025-05-01 11:10:00'),
(3, 2, 3, 3, 2, '线上', '已支付', 88.00, 68.00, '2025-05-02 14:30:00'),
(4, 3, 1, 4, null, '堂食', '已退款', 50.00, 50.00, '2025-05-03 09:40:00'),
(5, 3, 2, 4, 3, '线上', '已支付', 57.00, 49.00, '2025-05-04 16:00:00');

insert into order_detail values
(1, 1, 1, 1, 18.00, 18.00),
(2, 1, 4, 1, 32.00, 32.00),
(3, 2, 2, 1, 26.00, 26.00),
(4, 3, 3, 2, 28.00, 56.00),
(5, 3, 4, 1, 32.00, 32.00),
(6, 4, 5, 2, 25.00, 50.00),
(7, 5, 2, 1, 26.00, 26.00),
(8, 5, 5, 1, 25.00, 25.00);

insert into payment values
(1, 1, '微信', 48.00, '2025-05-01 10:21:00'),
(2, 2, '支付宝', 26.00, '2025-05-01 11:12:00'),
(3, 3, '微信', 68.00, '2025-05-02 14:32:00'),
(4, 4, '银行卡', 50.00, '2025-05-03 09:42:00'),
(5, 5, '支付宝', 49.00, '2025-05-04 16:02:00');

insert into refund values
(1, 4, 50.00, '顾客取消订单', '2025-05-03 10:00:00');

insert into schedule values
(1, 1, '2025-05-01', '08:00', '16:00'),
(2, 2, '2025-05-01', '10:00', '18:00'),
(3, 3, '2025-05-02', '09:00', '17:00'),
(4, 4, '2025-05-03', '12:00', '20:00');

select * from store;
select * from product;
select * from orders;
select * from order_detail;


--20条查询语句
SELECT product_id AS 编号, product_name AS 名称, category AS 类别, price AS 价格
FROM product;
SELECT product_id, product_name, category, price
FROM product
WHERE price > 25
ORDER BY price DESC;
SELECT 
    s.store_id,
    s.store_name,
    ISNULL(SUM(i.quantity), 0) AS total_inventory
FROM store s
LEFT JOIN inventory i ON s.store_id = i.store_id
GROUP BY s.store_id, s.store_name
ORDER BY s.store_id;
SELECT 
    pay_method,
    SUM(pay_amount) AS total_pay_amount
FROM payment
GROUP BY pay_method
ORDER BY pay_method;
SELECT o.order_id, m.member_name, s.store_name, o.order_type, o.actual_amount FROM orders o JOIN member m ON o.member_id = m.member_id JOIN store s ON o.store_id = s.store_id;
SELECT p.product_name, s.store_name, i.quantity FROM inventory i JOIN product p ON i.product_id = p.product_id JOIN store s ON i.store_id = s.store_id WHERE i.quantity < 50;
SELECT TOP 1 WITH TIES p.product_name, SUM(od.quantity) AS total_sales_qty FROM order_detail od JOIN orders o ON od.order_id = o.order_id JOIN product p ON od.product_id = p.product_id WHERE o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY p.product_name ORDER BY total_sales_qty DESC;
SELECT s.store_id, s.store_name, CASE WHEN COUNT(DISTINCT o.order_id) = 0 THEN 0 ELSE SUM(o.actual_amount) / CAST(COUNT(DISTINCT o.order_id) AS DECIMAL(10,2)) END AS avg_order_value FROM store s LEFT JOIN orders o ON s.store_id = o.store_id AND o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY s.store_id, s.store_name;
SELECT * FROM orders WHERE coupon_id IS NULL;
SELECT * FROM orders WHERE order_status = '已退款';
SELECT m.member_id, m.member_name, COUNT(o.order_id) AS order_count FROM member m LEFT JOIN orders o ON m.member_id = o.member_id GROUP BY m.member_id, m.member_name;
SELECT s.store_id, s.store_name, ISNULL(SUM(o.actual_amount), 0) AS actual_sales FROM store s LEFT JOIN orders o ON s.store_id = o.store_id AND o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY s.store_id, s.store_name;
SELECT o.order_id, p.product_name, od.quantity, od.unit_price, od.subtotal FROM orders o JOIN order_detail od ON o.order_id = od.order_id JOIN product p ON od.product_id = p.product_id;
SELECT o.order_id, m.member_name, c.coupon_name, c.discount_amount AS coupon_discount FROM orders o JOIN member m ON o.member_id = m.member_id JOIN coupon c ON o.coupon_id = c.coupon_id;
SELECT TOP 1 WITH TIES m.member_name, SUM(o.actual_amount) AS total_spent FROM member m JOIN orders o ON m.member_id = o.member_id WHERE o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY m.member_name ORDER BY total_spent DESC;
SELECT s.store_name, SUM(o.actual_amount) AS sales FROM store s JOIN orders o ON s.store_id = o.store_id WHERE o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY s.store_name HAVING SUM(o.actual_amount) > 50;
SELECT member_name, phone, points FROM member;
DECLARE @Date DATE = '2026-01-01'; SELECT * FROM orders WHERE order_time > @Date;
SELECT p.product_id, p.product_name, ISNULL(SUM(od.quantity), 0) AS total_sold FROM product p LEFT JOIN order_detail od ON p.product_id = od.product_id LEFT JOIN orders o ON od.order_id = o.order_id AND o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY p.product_id, p.product_name;
SELECT e.employee_id, e.employee_name, COUNT(DISTINCT o.order_id) AS order_count, ISNULL(SUM(o.actual_amount), 0) AS total_sales FROM employee e LEFT JOIN orders o ON e.employee_id = o.employee_id AND o.order_status = '已支付' AND NOT EXISTS (SELECT 1 FROM refund r WHERE r.order_id = o.order_id) GROUP BY e.employee_id, e.employee_name;