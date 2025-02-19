Use WideWorldImporters
GO

Declare @num IPv4 = '74.83.234.83'
Select @num.Ip
Go

Declare @num IPv4 = null
Select @num
Go

Create Table dbo.Ips
(
	Id Int Not Null Identity(1,1),
	IpAddress IPv4 Null 
)
Go

Insert Into dbo.Ips (IpAddress)
Values('74.83.234.83'),
		('64.83.94.73'),
		('125.84.33.0'),
		(Null)
Go

--ошибка
Insert Into dbo.Ips (IpAddress)
Values('64.256.84.0')
Go

--ошибка
Insert Into dbo.Ips (IpAddress)
Values('64.255,84.0')
Go

Select Id, IpAddress.Ip IpAddress
From dbo.Ips
Go

Drop table dbo.Ips
Go