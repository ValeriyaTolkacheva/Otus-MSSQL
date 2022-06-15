Create Database Hotels
Go

Use Hotels
Go

Create Schema Dictionary
Go

Create Table Dictionary.RoomType
(
	RoomTypeId Int Identity(1,1) Not Null,
	[Name] NVarChar(300) Not Null,
	Price Decimal(18,2) Null,
	[Description] NVarChar(Max) Null,
	Constraint PK_RoomType Primary Key(RoomTypeId)
)
Go

Create Table Dictionary.StaffType
(
	StaffTypeId Int Identity(1,1) Not Null,
	[Name] NVarChar(300) Not Null,
	Salary Decimal(18,2) Not Null
	Constraint PK_StaffType Primary Key(StaffTypeId)
)
Go

Create Table Dictionary.ServiceType
(
	ServiceTypeId Int Identity(1,1) Not Null,
	Price Decimal(18,2) Not Null,
	[Name] NVarChar(300) Not Null,
	Dyration TinyInt Null,
	[Description] NVarChar(Max) Null,
	RoomTypeId Int Null,
	Constraint PK_ServiceType Primary Key(ServiceTypeId),
	Constraint FK_ServiceType_RoomType Foreign Key(RoomTypeId) References Dictionary.RoomType(RoomTypeId)
)
Go

Create Table Dictionary.ServiceStaff
(
	ServiceTypeId Int Not Null,
	StaffTypeId Int Not Null,
	Quantity TinyInt Not Null,
	Constraint PK_ServiceStaff Primary Key(ServiceTypeId, StaffTypeId),
	Constraint FK_ServiceStaff_StaffType Foreign Key(StaffTypeId) References Dictionary.StaffType(StaffTypeId),
	Constraint FK_ServiceStaff_ServiceType Foreign Key(ServiceTypeId) References Dictionary.ServiceType(ServiceTypeId)
)
Go

Create Schema [Catalog]
Go

Create Table [Catalog].Hotel
(
	HotelId Int Identity(1,1) Not Null,
	[Name] NVarChar(300) Not Null,
	[Description] NVarChar(Max) Not Null,
	Star TinyInt Not Null,
	CityName NVarChar(100) Not Null,
	[Address] NVarChar(500) Not Null, 
	Constraint PK_Hotel Primary Key(HotelId)
)
Go

Create Table [Catalog].Room
(
	RoomId Int Identity(1,1) Not Null,
	HotelId Int Not Null,
	[Name] NVarChar(300) Not Null,
	[Square] Decimal(8,2) Not Null,
	MaxQuantityVisitors TinyInt Not Null,
	LuxDegree TinyInt Not Null,
	RoomTypeId Int Not Null,
	Constraint PK_Room Primary Key(RoomId),
	Constraint FK_Room_Hotel Foreign Key(HotelId) References [Catalog].Hotel(HotelId),
	Constraint FK_Room_RoomType Foreign Key(RoomTypeId) References Dictionary.RoomType(RoomTypeId)
)
Go

Create Schema People
Go

Create Table People.PersonalData
(
	PersonalDataId BigInt Identity(1,1) Not Null,
	Surname NVarChar(100) Not Null,
	[Name] NVarChar(100) Not Null,
	Patronymic NVarChar(100) Null,
	PassportSeries Decimal(4,0) Not Null,
	PassportNumber Decimal(6,0) Not Null,
	PhoneNumber Decimal(10,0) Not Null,
	Mail NVarChar(100) Null,
	[ValidFrom] DateTime2 Generated Always As Row Start Not Null,
	[ValidTo] DateTime2 Generated Always As Row End Not Null,
	Constraint PK_PersonalData Primary Key(PersonalDataId),
	Period For System_Time ([ValidFrom], [ValidTo])
)
With
(
	System_Versioning = On (History_table = People.PersonalData_Archive)
)
Go

Create Table People.Visitor
(
	VisitorId BigInt Identity(1,1) Not Null,
	PersonalDataId BigInt Not Null,
	[Name] NVarChar(100) Not Null,
	Constraint PK_Visitor Primary Key(VisitorId),
	Constraint FK_Visitor_PersonalData Foreign Key(PersonalDataId) References People.PersonalData(PersonalDataId)
)
Go

Create Table People.Staff
(
	StaffId Int Identity(1,1) Not Null,
	StaffTypeId Int Not Null,
	HotelId Int Not Null,
	PersonalDataId BigInt Not Null,
	Constraint PK_Staff Primary Key(StaffId),
	Constraint FK_Staff_StaffType Foreign Key(StaffTypeId) References Dictionary.StaffType(StaffTypeId),
	Constraint FK_Staff_Hotel Foreign Key(HotelId) References [Catalog].Hotel(HotelId),
	Constraint FK_Staff_PersonalData Foreign Key(PersonalDataId) References People.PersonalData(PersonalDataId)
)
Go

Create Schema [Order]
Go

Create Table [Order].Booking
(
	BookingId BigInt Identity(1,1) Not Null,
	RoomId Int Not Null,
	ArrivalDate DateTime2 Not Null,
	DepartureDate DateTime2 Not Null,
	Confirmed Bit Default(0) Not Null,
	Closed Bit Default(0) Not Null
	Constraint PK_Booking Primary Key(BookingId),
	Constraint FK_Booking_Room Foreign Key(RoomId) References [Catalog].Room(RoomId)
)
Go

Create Table [Order].Guest
(
	BookingId BigInt Not Null,
	VisitorId BigInt Not Null
	Constraint PK_Guest Primary Key(BookingId, VisitorId),
	Constraint FK_Guest_Booking Foreign Key(BookingId) References [Order].Booking(BookingId),
	Constraint FK_Guest_Visitor Foreign Key(VisitorId) References People.Visitor(VisitorId)
)
Go

Create Table [Order].Invoice
(
	InvoiceId BigInt Identity(1,1) Not Null,
	BookingId BigInt Not Null,
	VisitorId BigInt Not Null,
	Payment Decimal(18,2) Not Null,
	InvoiceDate DateTime2 Not Null,
	Constraint PK_Invoice Primary Key(InvoiceId),
	Constraint FK_Invoice_Booking Foreign Key(BookingId) References [Order].Booking(BookingId),
	Constraint FK_Invoice_Visitor Foreign Key(VisitorId) References People.Visitor(VisitorId)
)
Go

Create Table [Order].[Service]
(
	ServiceId BigInt Identity(1,1) Not Null,
	BookingId BigInt Not Null,
	ServiceTypeId Int Not Null,
	RoomId Int Null,
	StartTime DateTime2 Null,
	VisitorId BigInt Not Null,
	Constraint PK_Service Primary Key(ServiceId),
	Constraint FK_Service_Booking Foreign Key(BookingId) References [Order].Booking(BookingId),
	Constraint FK_Service_ServiceType Foreign Key(ServiceTypeId) References Dictionary.ServiceType(ServiceTypeId),
	Constraint FK_Service_Room Foreign Key(RoomId) References [Catalog].Room(RoomId),
	Constraint FK_Service_Visitor Foreign Key(VisitorId) References People.Visitor(VisitorId)
)
Go

Create Table [Order].[Shift]
(
	ShiftId BigInt Identity(1,1) Not Null,
	StaffId Int Not Null,
	ServiceId BigInt Not Null,
	Constraint PK_Shift Primary Key(ShiftId),
	Constraint FK_Shift_Staff Foreign Key(StaffId) References People.Staff(StaffId),
	Constraint FK_Shift_Service Foreign Key(ServiceId) References [Order].[Service](ServiceId)
)
Go