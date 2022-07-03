Use Hotels
Go

Create Procedure [Order].AddShift(@StaffId Int, @ServiceId BigInt)
As
Begin
	Insert Into [Order].[Shift](StaffId, ServiceId)
	Values (@StaffId, @ServiceId)
End