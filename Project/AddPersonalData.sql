Use Hotels
Go

Create Procedure [People].AddPersonalData
				(
					@Name NVarChar(100), 
					@Surname NVarChar(100), 
					@Patronymic NVarChar(100), 
					@PasportSeries Decimal(4,0), 
					@PassportNumber Decimal(6,0), 
					@PhoneNumber Decimal(10,0),
					@Mail NVarChar(100),
					@PersonalDataId BigInt Output
				)
As
Begin
	Insert Into [People].[PersonalData] ([Name], Surname, Patronymic, PassportSeries, PassportNumber, PhoneNumber, Mail)
	Values(@Name, @Surname, @Patronymic, @PasportSeries, @PassportNumber, @PhoneNumber, @Mail)
	Set @PersonalDataId = Cast(Scope_Identity() As Bigint)
End