Use Hotels
Go

Create Procedure [Catalog].GetHotelsByDescription(@SityName NVarChar(300), @Query NVarChar(500))
As
Begin
	Select *
	From [Catalog].Hotel
	Inner Join FreeTextTable([Catalog].Hotel, [Description],  @Query) As t On Hotel.HotelId=t.[KEY]
	Where Hotel.CityName = @SityName
	Order By t.Rank Desc;
End