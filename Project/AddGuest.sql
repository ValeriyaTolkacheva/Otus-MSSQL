Use Hotels
Go

Create Procedure [Order].AddGuest(@BookingId BigInt, @VisitorId BigInt)
As
Begin
	Insert Into [Order].Guest(BookingId, VisitorId)
	Values(@BookingId, @VisitorId)
End