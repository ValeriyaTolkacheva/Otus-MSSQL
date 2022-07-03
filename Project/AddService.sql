Use Hotels
Go

Create Procedure [Order].AddService(@BookingId BigInt, @ServiceTypeId Int, @RoomId Int, @StartTime DateTime2, @VisitorId BigInt)
As
Begin
	SET XACT_ABORT ON;
	--�������� ���� ������� � ���� �������
	If (@RoomId Is Not Null)
	Begin
		Declare @checkTypeId Int = 
		(
			Select ServiceTypeId
			From [Catalog].Room
			Inner Join [Dictionary].ServiceType On Room.RoomTypeId = ServiceType.RoomTypeId
			Where RoomId = @RoomId And ServiceTypeId = @ServiceTypeId
		);
		If (@checkTypeId Is Null)
			throw 50002, '� ��������� ��������� �� ����� ���� ��������� ������', 1
	End
	Begin Tran
	--�������� ����������� �� ���������� ������������
	If (@VisitorId Is Not Null)
	Begin
		Declare @checkVisitor BigInt =
		(
			Select VisitorId
			From [Order].Guest
			Where BookingId = @BookingId And VisitorId = @VisitorId
		)
		If (@checkVisitor is null)
			throw 50002, '������ ������� ����� �� ������������ ����������', 2
	End
	--�������� ������� � ���
	Declare @checkDates Int = 
	(
		Select BookingId
		From [Order].Booking
		Where BookingId = @BookingId And DateAdd(HH, -5, ArrivalDate) < @StartTime And DateAdd(HH, 5, DepartureDate) > @StartTime
	)
	If (@checkDates is null)
		throw 50002, '������ ������� ����� ��� ��� ������������', 2
	--�������� �������� �� ������� �� ��� �����
	Declare @endTime DateTime2 =
	(
		Select Case When Dyration Is Not Null Then DateAdd(HH, Dyration, @StartTime) Else @StartTime End
		From [Dictionary].ServiceType
		Where ServiceTypeId = @ServiceTypeId
	)

	Declare @getRoom Int = 
	(
		Select RoomId
		From [Order].[Service]
		Inner Join [Dictionary].ServiceType On [Service].ServiceTypeId = ServiceType.ServiceTypeId
		Where RoomId = @RoomId And
								(
									@StartTime Between StartTime And Case When Dyration Is Not Null Then DateAdd(HH, Dyration, StartTime) Else StartTime End Or
									@endTime Between StartTime And Case When Dyration Is Not Null Then DateAdd(HH, Dyration, StartTime) Else StartTime End Or
									StartTime Between @StartTime And @endTime Or
									Case When Dyration Is Not Null Then DateAdd(HH, Dyration, StartTime) Else StartTime End Between @StartTime And @endTime
								)
	)
	If (@getRoom Is Not Null)
		throw 50002, '��������� ��� ������', 3

	--������� ������
	Insert Into [Order].[Service](BookingId, ServiceTypeId, RoomId, StartTime, VisitorId)
	Values						(@BookingId, @ServiceTypeId, @RoomId, @StartTime, @VisitorId)
	Declare @ServiceId BigInt = Cast(Scope_Identity() As Bigint)

	Declare @staffType Int
	Declare staffTypesCursor Cursor For
		Select StaffTypeId
		From [Dictionary].ServiceStaff
		Where ServiceTypeId = @ServiceTypeId
	Open staffTypesCursor
	Fetch Next From staffTypesCursor Into @staffType
	While @@Fetch_Status = 0
	Begin
		--����� �����������, ���� ��� ���, �� ������
		Declare @staffId Int = 
		(
			Select Staff.StaffId
			From [People].Staff
			Inner Join [Catalog].Room On Staff.HotelId = Room.HotelId And Room.RoomId = @RoomId
			Inner Join [Order].[Shift] On Staff.StaffId = [Shift].StaffId
			Inner Join [Order].[Service] On [Shift].ServiceId = [Service].ServiceId
			Inner Join [Dictionary].ServiceType On [Service].ServiceTypeId = ServiceType.ServiceTypeId
			Where Not
					(
						@StartTime Between StartTime And Case When Dyration Is Not Null Then DateAdd(HH, Dyration, StartTime) Else StartTime End Or
						@endTime Between StartTime And Case When Dyration Is Not Null Then DateAdd(HH, Dyration, StartTime) Else StartTime End Or
						StartTime Between @StartTime And @endTime Or
						Case When Dyration Is Not Null Then DateAdd(HH, Dyration, StartTime) Else StartTime End Between @StartTime And @endTime
					)
		)
		If (@staffId Is Null)
			Throw 50003, '������������ ��������� ��� ������', 4
		--������� ����� 
		Exec [Order].AddShift @StaffId = @staffId, @ServiceId = @ServiceId
	End
	Close staffTypesCursor
	Deallocate staffTypesCursor
	Commit Tran
End