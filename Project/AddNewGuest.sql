Use Hotels
Go

Create Procedure [Order].AddNewGuest
				(
					@Name NVarChar(100), 
					@Surname NVarChar(100), 
					@Patronymic NVarChar(100), 
					@PasportSeries Decimal(4,0), 
					@PassportNumber Decimal(6,0), 
					@PhoneNumber Decimal(10,0),
					@Mail NVarChar(100),
					@BookingId BigInt
				)
As
Begin
	SET XACT_ABORT ON;  
	Begin Tran
		Declare @VisitorId Int
		Exec [People].AddNewVisitor 
					@Name = @Name, 
					@Surname = @Surname, 
					@Patronymic = @Patronymic, 
					@PasportSeries = @PasportSeries, 
					@PassportNumber = @PassportNumber, 
					@PhoneNumber = @PhoneNumber, 
					@Mail = @Mail,
					@VisitorId = @VisitorId OutPut
		Exec [Order].AddGuest @BookingId = @BookingId, @VisitorId = @VisitorId
	Commit Tran
End