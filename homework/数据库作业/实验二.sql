select * from Orders ;

--写一段程序，向表Orders中增加1000万条记录，要求订单尽可能均匀地分布在12个月中。（注意：如何实现cid,aid,pid三个外键的取值，如何实现12个月的均匀分布）
declare @i int = 1;
while @i<=10000000
begin
	insert into Orders
	values(
		@i,
		choose((@i % 12) + 1,'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'),
		(select top 1 cid from Customers order by newid()),
		(select top 1 aid from Agents order by newid()),
		(select top 1 pid from Products order by newid()),
		abs(checksum(newid()))%100+1,
		abs(checksum(newid()))%1000+10
	);
	set @i=@i+1;
end
