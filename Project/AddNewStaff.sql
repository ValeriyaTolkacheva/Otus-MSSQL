Use Hotels 
Go

Create Procedure [People].AddNewStaff
							(
								@Name NVarChar(100), 
								@Surname NVarChar(100), 
								@Patronymic NVarChar(100), 
								@PasportSeries Decimal(4,0), 
								@PassportNumber Decimal(6,0), 
								@PhoneNumber Decimal(10,0),
								@Mail NVarChar(100),
								@StaffTypeId Int, 
								@HotelId Int
							)
As
Begin
	SET XACT_ABORT ON; 
	Begin Tran
		Declare @PersonalDataId BigInt;
		Exec [People].AddPersonalData 
							@Name = @Name, 
							@Surname = @Surname, 
							@Patronymic = @Patronymic, 
							@PasportSeries = @PasportSeries, 
							@PassportNumber = @PassportNumber, 
							@PhoneNumber = @PhoneNumber, 
							@Mail = @Mail,
							@PersonalDataId = @PersonalDataId OutPut
		Exec [People].AddStaff 
							@StaffTypeId = @StaffTypeId,
							@HotelId = @HotelId,
							@PersonalDataId = @PersonalDataId
	Commit Tran
End