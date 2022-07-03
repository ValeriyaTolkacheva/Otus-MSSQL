Use Hotels
Go

Create Procedure [Order].AddInvoice(@BookingId BigInt, @VisitorId BigInt, @Payment Decimal(18,2), @InvoiceDate DateTime2)
As
Begin
	Insert Into [Order].Invoice(BookingId, VisitorId, Payment, InvoiceDate)
	Values						(@BookingId, @VisitorId, @Payment, @InvoiceDate)
	Declare @Amount Decimal(18,2) = [Order].GetInvoices(@BookingId)
	Declare @BookingPrice Decimal(18,2) = [Order].GetBookingPrice(@BookingId)
	Declare @FullPrice decimal(18,2) = [Order].GetServicePrice(@BookingId) + @BookingPrice
	If (@InvoiceDate < 
					(
						Select ArrivalDate 
						From [Order].Booking 
						Where BookingId = @BookingId
					))
		If (@Amount >= @BookingPrice)
			Update [Order].Booking
			Set Confirmed = 1
			Where BookingId = @BookingId

	If (@InvoiceDate >= 
					(
						Select DepartureDate 
						From [Order].Booking 
						Where BookingId = @BookingId
					))
		If (@Amount >= @FullPrice)
			Update [Order].Booking
			Set Closed = 1
			Where BookingId = @BookingId
End


