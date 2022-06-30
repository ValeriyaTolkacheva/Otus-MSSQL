Use Hotels
Go

Create Procedure [Catalog].AddRoom(@HotelId Int, @Name NVarChar(300), @Square Decimal(8,2), @MaxQuantityVisitors TinyInt, @LuxDegree TinyInt, @RoomTypeId Int)
As
Begin
	Insert Into [Catalog].[Room](HotelId, [Name], [Square], MaxQuantityVisitors, LuxDegree, RoomTypeId)
	Values						(@HotelId, @Name, @Square, @MaxQuantityVisitors, @LuxDegree, @RoomTypeId)
End