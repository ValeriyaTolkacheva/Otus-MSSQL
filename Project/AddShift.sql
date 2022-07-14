Use Hotels
Go

Create Procedure [Order].AddShift(@StaffId Int, @ServiceId BigInt, @HotelId Int)
As
Begin
	Insert Into [Order].[Shift](StaffId, ServiceId, HotelId)
	Values (@StaffId, @ServiceId, @HotelId)
End