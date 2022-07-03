Use Hotels
Go

Create Function [Order].GetBookingPrice(@BookingId BigInt)
Returns Decimal(18,2)
As
Begin
	Declare @Price Decimal(18,2) = 
	(
		Select Room.[Square] * RoomType.Price * (1 + Hotel.Star / 10) * (1 + Room.LuxDegree / 10) 
		From [Order].Booking
		Inner Join [Catalog].Room On Booking.RoomId = Room.RoomId
		Inner Join [Catalog].Hotel On Room.HotelId = Hotel.HotelId
		Inner Join [Dictionary].RoomType On Room.RoomTypeId = RoomType.RoomTypeId
		Where BookingId = @BookingId
	)
	Return @Price
End