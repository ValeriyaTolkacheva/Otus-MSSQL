Use Hotels
Go

Create Function [Order].GetServicePrice(@BookingId BigInt)
Returns Decimal(18,2)
As
Begin
	Declare @Price Decimal(18,2) = 
	(
		Select ServiceType.Price * (1 + Hotel.Star / 10) * (1 + (Case When ServiceRoom.LuxDegree Is Null Then 0 Else ServiceRoom.LuxDegree End) / 10)
		From [Order].Booking
		Inner Join [Catalog].Room On Booking.RoomId = Room.RoomId
		Inner Join [Catalog].Hotel On Room.HotelId = Hotel.HotelId
		Inner Join [Order].[Service] On Booking.BookingId = [Service].ServiceId
		Inner Join [Dictionary].ServiceType On [Service].ServiceTypeId = ServiceType.ServiceTypeId
		Left Join [Catalog].Room ServiceRoom On Room.RoomId = [Service].RoomId
		Where Booking.BookingId = @BookingId
	)
	Return @Price
End