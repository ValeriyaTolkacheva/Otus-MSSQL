Use Hotels
Go

Create Function [Order].GetInvoices(@BookingId BigInt)
Returns Decimal(18,2)
As
Begin
	Declare @Amount Decimal(18,2) =
	(
		Select Sum(Payment)
		From [Order].Invoice
		Where BookingId = @BookingId
	)
	Return @Amount
End

