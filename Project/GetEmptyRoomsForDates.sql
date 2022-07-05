Use Hotels
Go

Create Procedure [Order].GetEmptyRoomsForDates(@DateFrom DateTime2, @DateTo DateTime2)
As
Begin
	Select Distinct Room.RoomId, Room.MaxQuantityVisitors
	From [Catalog].Room
	Left Join [Order].Booking On Room.RoomId = Booking.RoomId
	Where Room.RoomTypeId In (1, 2, 3) And (BookingId Is Null Or Not
			( 
				@DateFrom Between ArrivalDate And DepartureDate Or
				@DateTo Between ArrivalDate And DepartureDate Or
				ArrivalDate Between @DateFrom And @DateTo Or
				DepartureDate Between @DateFrom And @DateTo
			))
End