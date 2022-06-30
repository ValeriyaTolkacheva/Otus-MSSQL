Use Hotels
Go

Create Procedure [People].AddNewVisitor
				(
					@Name NVarChar(100), 
					@Surname NVarChar(100), 
					@Patronymic NVarChar(100), 
					@PasportSeries Decimal(4,0), 
					@PassportNumber Decimal(6,0), 
					@PhoneNumber Decimal(10,0),
					@Mail NVarChar(100),
					@VisitorId BigInt OutPut
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
		Exec [People].AddVisitor 
							@PersonalDataId = @PersonalDataId, 
							@Name = @Name,
							@VisitorId = @VisitorId OutPut
	Commit Tran
End