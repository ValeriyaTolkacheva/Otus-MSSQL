use Hotels
Go
--в комментариях перед созданием индекса название процедуры\функции, где он может быть применим

--AddBooking
--GetBookingPrice
--GetEmptyRoomsForDates
Create Nonclustered Index IX_Booking_RoomId_Arrival_Departure
On [Order].Booking (RoomId)
Include (ArrivalDate, DepartureDate)
Go

--AddService
Create Nonclustered Index IX_Service_RoomId_ServiceTypeId
On [Order].[Service] (RoomId, ServiceTypeId)
Go

--AddService
Create Nonclustered Index IX_Service_StartTime
On [Order].[Service] (StartTime)
Go

--GetServicePrice
Create Nonclustered Index IX_Service_BookingId
On [Order].[Service] (BookingId)
Go

--AddService
--GetBookingPrice
Create Nonclustered Index IX_Room_HootelId_RoomTypeId_Square
On [Catalog].Room (HotelId)
Include(RoomTypeId, [Square])
Go

--AddService
Create Nonclustered Index IX_Staff_HotelId_StaffTypeId
On People.Staff (HotelId, StaffTypeId)
Go

--AddService
Create Nonclustered Index IX_Shift_StaffId
On [Order].[Shift] (StaffId)
Go

--AddService
Create Nonclustered Index IX_Shift_ServiceId
On [Order].[Shift] (ServiceId)
Go

--GetBookingPrice
Create NonClustered Index IX_Invoice_BookingId
On [Order].Invoice (BookingId)
Go