Use Hotels

;With insertRows as
(
	Select Convert(Int, Format(ArrivalDate, 'yyMMddHH')) DateKey, ArrivalDate FullDateTime, DatePart(hour, ArrivalDate) [Hour],
		DatePart(dw, ArrivalDate) DayNumberOfWeek, DateName(weekday, ArrivalDate) DayNameOfWeek, DatePart(d, ArrivalDate) DayNumberOfMonth,
        DatePart(dy, ArrivalDate) DayNumberOfYear, DatePart(wk, ArrivalDate) WeekNumberOfYear, DateName(month, ArrivalDate) [MonthName],
        Month(ArrivalDate) MonthNumberOfYear,Year(ArrivalDate) [Year]
	From [Order].Booking
	Union
	Select Convert(Int, Format(DepartureDate, 'yyMMddHH')) DateKey, DepartureDate FullDateTime, DatePart(hour, DepartureDate) [Hour],
		DatePart(dw, DepartureDate) DayNumberOfWeek, DateName(weekday, DepartureDate) DayNameOfWeek, DatePart(d, DepartureDate) DayNumberOfMonth,
        DatePart(dy, DepartureDate) DayNumberOfYear, DatePart(wk, DepartureDate) WeekNumberOfYear, DateName(month, DepartureDate) [MonthName],
        Month(DepartureDate) MonthNumberOfYear,Year(DepartureDate) [Year]
	From [Order].Booking
)
Merge DWH_Hotels.Dimentions.Dates dwh_dates
Using insertRows
On (dwh_dates.DateKey = insertRows.DateKey)
When Not Matched 
	Then Insert (DateKey, FullDateTime, [Hour], DayNumberOfWeek, DayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, [MonthName], MonthNumberOfYear, [Year])
	Values (insertRows.DateKey, insertRows.FullDateTime, insertRows.[Hour], insertRows.DayNumberOfWeek, insertRows.DayNameOfWeek, insertRows.DayNumberOfMonth, insertRows.DayNumberOfYear, insertRows.WeekNumberOfYear, insertRows.[MonthName], insertRows.MonthNumberOfYear, insertRows.[Year]);





;With insertRows as
(
	Select Distinct Room.RoomId, RoomType.[Name] RoomTypeName, RoomType.Price * Room.[Square] RoomPriceForDay, Hotel.CityName, Room.LuxDegree,
				Hotel.Star, Room.[Square], Room.MaxQuantityVisitors
	From 
	[Catalog].Room 
	Inner Join [Catalog].Hotel On Room.HotelId = Hotel.HotelId
	Inner Join [Dictionary].RoomType On Room.RoomTypeId = RoomType.RoomTypeId
	Where RoomType.Price Is Not Null
)
Merge DWH_Hotels.Dimentions.Room dwh_room
Using insertRows
On (dwh_room.RoomId = insertRows.RoomId)
When Not Matched 
	Then Insert (RoomId, RoomTypeName, RoomPriceForDay, CityName, LuxDegree, Star, [Square], MaxQuantityVisitors)
	Values (insertRows.RoomId, insertRows.RoomTypeName, insertRows.RoomPriceForDay, insertRows.CityName, insertRows.LuxDegree, insertRows.Star, insertRows.[Square], insertRows.MaxQuantityVisitors);


;With insertRows as
(
	Select BookingId, RoomId, Convert(Int, Format(ArrivalDate, 'yyMMddHH')) ArrivalDateKey, Convert(Int, Format(DepartureDate, 'yyMMddHH')) DepartureDateKey, [Order].GetBookingPrice(BookingId) BookingPrice
	From [Order].Booking
)
Merge DWH_Hotels.Facts.Booking dwh_booking
Using insertRows
On (dwh_booking.BookingId = insertRows.BookingId)
When Not Matched 
	Then Insert (BookingId, RoomId, ArrivalDateKey, DepartureDateKey, BookingPrice)
	Values (insertRows.BookingId, insertRows.RoomId, insertRows.ArrivalDateKey, insertRows.DepartureDateKey, insertRows.BookingPrice);

;With insertRows as
(
	Select Booking.BookingId, PersonalData.PersonalDataId, PersonalData.Surname, PersonalData.[Name], PersonalData.Patronymic, PersonalData.PassportSeries, PersonalData.PassportNumber, PersonalData.PhoneNumber, PersonalData.Mail
	From [Order].Booking
	Inner Join  [Order].Guest On Booking.BookingId = Guest.BookingId
	Inner Join [People].Visitor On Guest.VisitorId = Visitor.VisitorId
	Inner Join [People].PersonalData On Visitor.PersonalDataId = PersonalData.PersonalDataId
)
Merge DWH_Hotels.Dimentions.Guest dwh_guest
Using insertRows
On (dwh_guest.BookingId = insertRows.BookingId and dwh_guest.PersonalDataId = insertRows.PersonalDataId)
When Not Matched
	Then Insert (BookingId, PersonalDataId, Surname, [Name], Patronymic, PassportSeries, PassportNumber, PhoneNumber, Mail)
	Values (insertRows.BookingId, insertRows.PersonalDataId, insertRows.Surname, insertRows.[Name], insertRows.Patronymic, insertRows.PassportSeries, insertRows.PassportNumber, insertRows.PhoneNumber, insertRows.Mail);
