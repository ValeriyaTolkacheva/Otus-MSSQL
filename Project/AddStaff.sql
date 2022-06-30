Use Hotels
Go

Create Procedure [People].AddStaff(@StaffTypeId Int, @HotelId Int, @PersonalDataId BigInt)
As
Begin
	Insert Into [People].Staff(StaffTypeId, HotelId, PersonalDataId)
	Values					  (@StaffTypeId, @HotelId, @PersonalDataId)
End