Use Hotels
Go

Create Procedure [Catalog].AddHotel 
	@Name NVarChar(300), 
	@Description NVarChar(Max), 
	@Star TinyInt, 
	@CityName NVarChar(100), 
	@Address NVarChar(500)
As
Begin
	Insert Into [Catalog].Hotel ([Name], [Description], Star, CityName, [Address])
	Values(@Name, @Description, @Star, @CityName, @Address)
End
