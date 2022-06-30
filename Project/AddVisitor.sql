Use Hotels
Go

Create Procedure [People].AddVisitor (@PersonalDataId BigInt, @Name NVarChar(100),  @VisitorId BigInt Output)
As
Begin
	Insert Into [People].[Visitor] (PersonalDataId, [Name])
	Values(@PersonalDataId, @Name)
	Set @VisitorId = Cast(Scope_Identity() As Bigint)
End