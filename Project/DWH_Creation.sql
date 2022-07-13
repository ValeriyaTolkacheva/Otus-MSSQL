Create DataBase DWH_Hotels
Go

Use DWH_Hotels
Go

Create Schema Facts
Go

Create Table Facts.Booking
(
	BookingId BigInt Not Null,
	RoomId Int Not Null,
	ArrivalDateKey Int Not Null,
	DepartureDateKey Int Not Null,
	BookingPrice Decimal(18,2) Not Null,
	Constraint PK_Booking Primary Key(BookingId)
)
Go

Create Schema Dimentions
Go

Create Table Dimentions.Dates
(
	DateKey Int Not Null,
	FullDateTime DateTime2 Not Null,
	[Hour] TinyInt Not Null,
	[DayNumberOfWeek] TinyInt Not Null,
    [DayNameOfWeek] NVarChar(11) Not Null,
    [DayNumberOfMonth] TinyInt Not Null,
    [DayNumberOfYear] SmallInt,
    [WeekNumberOfYear] TinyInt Not Null,
    [MonthName] NVarChar(10) Not Null,
    [MonthNumberOfYear] TinyInt Not Null,
    [Year] SmallInt Not Null,
	Constraint PK_Dates Primary Key(DateKey)
)
Go

Create Table Dimentions.Room
(
	RoomId Int Not Null,
	RoomTypeName NVarChar(300) Not Null,
	RoomPriceForDay Decimal(18,2) Not Null,
	CityName NVarChar(100) Not Null,
	LuxDegree TinyInt Not Null,
	Star TinyInt Not Null,
	[Square] Decimal(8,2) Not Null,
	MaxQuantityVisitors TinyInt Not Null,
	Constraint PK_Room Primary Key(RoomId)
)
Go

Create Table Dimentions.Guest
(
	GuestPk As BookingId * 100000 + PersonalDataId  PERSISTED,
	BookingId BigInt Not Null,
	PersonalDataId BigInt Not Null,
	Surname NVarChar(100) Not Null,
	[Name] NVarChar(100) Not Null,
	Patronymic NVarChar(100) Null,
	PassportSeries Decimal(4,0) Not Null,
	PassportNumber Decimal(6,0) Not Null,
	PhoneNumber Decimal(10,0) Not Null,
	Mail NVarChar(100) Null
	Constraint PK_Guest Primary Key(GuestPk)--(BookingId, PersonalDataId)
)
Go

Alter Table Facts.Booking Add Constraint FK_Booking_Arrival_Dates Foreign Key(ArrivalDateKey) References Dimentions.Dates(DateKey)
Alter Table Facts.Booking Add Constraint FK_Booking_Departure_Dates Foreign Key(DepartureDateKey) References Dimentions.Dates(DateKey)
Alter Table Facts.Booking Add Constraint FK_Booking_Room Foreign Key(RoomId) References Dimentions.Room(RoomId)
Alter Table Dimentions.Guest Add Constraint FK_Guest_Booking Foreign Key(BookingId) References Facts.Booking(BookingId)


Create Schema Report
Go

Create Table Report.Invoice
(
	GuestId BigInt Not Null,
	GuestName NVarChar(100) Not Null,
	GuestSurname NVarChar(100) Not Null,
	InvoiceAmount Decimal(18,2) Null,
	LastInvoiceDate DateTime2 Null
	Constraint PK_Invoice Primary Key(GuestId)
)