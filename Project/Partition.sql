Use Hotels

Alter Database Hotels Add Filegroup [HotelsNums]
GO

--добавляем файл БД
Alter DataBase Hotels Add File 
( Name = N'HotelsNums', FileName = N'D:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\DATA\HotelsNums.ndf' , 
Size = 1097152KB , Filegrowth = 65536KB ) To Filegroup [HotelsNums]
GO

--создаю функцию партиционирования 
Create Partition Function [fnHotelId](Int) As Range For Values
(10, 20, 30, 40, 50, 60, 70, 80, 90);																																																									
Go

--создаю схему
Create Partition Scheme [schmHotelPartition] As Partition [fnHotelId] 
ALL TO ([HotelsNums])
GO

--убираю кластеризованный индекс и связанный с ним FK
Alter Table [Order].[Shift] Drop Constraint FK_Shift_Staff
Alter Table People.Staff Drop Constraint PK_Staff

--создаю кластеризованный индекс с секционированием и новый некластерный PK
Create Clustered Index IX_HotelId On People.Staff(HotelId) On [schmHotelPartition](HotelId)
Alter Table People.Staff Add Constraint PK_Staff Primary Key Nonclustered(StaffId, HotelId)




--возвращаю FK на [Order].[Shift]
Alter Table [Order].[Shift] Add HotelId Int Null
Update [Order].[Shift] 
	Set [Shift].HotelId = Staff.HotelId
From [Order].[Shift]
Inner Join [People].Staff On [Shift].StaffId = Staff.StaffId
Alter Table [Order].[Shift] Alter Column HotelId Int Not Null
Alter Table [Order].[Shift] Add Constraint FK_Shift_Staff Foreign Key(StaffId, HotelId) References People.Staff(StaffId, HotelId)

