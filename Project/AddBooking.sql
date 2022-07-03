Use Hotels
Go

--�������� visitorId ��� Service
Alter Procedure [Order].AddBookig(@RoomId Int, @ArrivalDate DateTime2, @DepartureDate DateTime2, @VisitorId BigInt, @BookingId BigInt OutPut)
As
Begin
	SET XACT_ABORT ON;
	Declare @roomTypeId Int =
	(
		Select RoomTypeId
		From [Catalog].Room
		Where RoomId = @RoomId
	)
	If (@roomTypeId not in (1, 2, 3))
		Throw 50001, '������ ������������� ������� ���������', 1

	Begin Tran
	If Exists
	(
		Select BookingId
		From [Order].Booking
		Where RoomId = @RoomId And
			(
				ArrivalDate Between @ArrivalDate And @DepartureDate Or
				DepartureDate Between @ArrivalDate And @DepartureDate Or
				@ArrivalDate Between ArrivalDate And DepartureDate Or
				@DepartureDate Between ArrivalDate And DepartureDate
			)
	)
		Throw 50001, '� ��������� ������ ����� �� ��� ���� ��� ������������', 2

	Insert Into [Order].[Booking](RoomId, ArrivalDate, DepartureDate)
	Values (@RoomId, @ArrivalDate, @DepartureDate)
	Set @BookingId = Cast(Scope_Identity() As Bigint)
	Exec [Order].AddGuest @BookingId = @BookingId, @VisitorId = @VisitorId
	Declare @serviceTypeId Int = 
	(
		Select ServiceTypeId
		From [Dictionary].ServiceType
		Where RoomTypeId = @roomTypeId
	)
	--���������
	Exec [Order].AddService @BookingId = @BookingId, @ServiceTypeId = 1, @RoomId = @RoomId, @StartDate = @ArrivalDate, @VisitorId = @VisitorId
	--���������
	Exec [Order].AddService @BookingId = @BookingId, @ServiceTypeId = 2, @RoomId = @RoomId, @StartDate = @DepartureDate, @VisitorId = @VisitorId
	Declare @date DateTime2 = DateAdd(HH, -2, @ArrivalDate)
	--������
	Exec [Order].AddService @BookingId = @BookingId, @ServiceTypeId = @serviceTypeId, @RoomId = @RoomId, @StartDate = @date, @VisitorId = @VisitorId
	If (@roomTypeId = 3)
	Begin
		Set @date = DateAdd(DD, 1, @date)
		While (@date < @DepartureDate)
		Begin
			Exec [Order].AddService @BookingId = @BookingId, @ServiceTypeId = @serviceTypeId, @RoomId = @RoomId, @StartDate = @date, @VisitorId = @VisitorId
			Set @date = DateAdd(DD, 1, @date)
		End
	End
	Commit Tran
End