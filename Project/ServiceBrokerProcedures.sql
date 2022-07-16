Use Hotels
Go

Create Procedure [Order].SendGuestInvoice(@GuestId BigInt)
As
Begin
	SET XACT_ABORT ON;
	Declare @InitDlgHandle Uniqueidentifier;
	DECLARE @RequestMessage NVarChar(4000);

	Begin Tran
	Set @RequestMessage = 
	(
		Select Distinct Visitor.VisitorId GuestId, PersonalData.[Name] GuestName, PersonalData.Surname GuestSurname, Sum(Invoice.Payment) Over() InvoiceAmount, Max(Invoice.InvoiceDate) Over() LastInvoiceDate
		From [Order].Invoice
		Inner Join [People].Visitor On Invoice.VisitorId = Visitor.VisitorId
		Inner Join [People].PersonalData On Visitor.PersonalDataId = PersonalData.PersonalDataId
		Where Visitor.VisitorId = @GuestId
		For Xml Auto
	)
	If (@RequestMessage Is Null)
		Throw 50014, 'Нет данных для отчета', 1
	Begin Dialog @InitDlgHandle
	From Service
	[//DH/Service/Invoice/Initiator]
	To Service
	'//DH/Service/Invoice/Target'
	On Contract
	[//DH/Contract/Invoice]
	With Encryption=Off; 

	Send On Conversation @InitDlgHandle 
	Message Type
	[//DH/Message/Invoice/Request]
	(@RequestMessage);
	Commit Tran
End
Go

Use DWH_Hotels
Go

Create Procedure [Report].GetGuestInvoice
As
Begin
	Declare @TargetDlgHandle Uniqueidentifier,
			@Message NVarChar(4000),
			@MessageType Sysname,
			@ReplyMessage NVarChar(4000),
			@ReplyMessageName Sysname,
			@GuestId BigInt,
			@GuestName NVarChar(100),
			@GuestSurname NVarChar(100),
			@InvoiceAmount Decimal(18,2),
			@LastInvoiceDate DateTime2,
			@xml Xml; 
	
	Begin Tran; 

	--Receive message from Initiator
	Receive Top(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	From dbo.[InvoiceTargetQueue]; 

	Set @xml = Cast(@Message as Xml);

	Select @GuestId = Inv.Report.value('./@GuestId', 'BigInt'),
			@GuestName = Inv.Report.value('./People.PersonalData[1]/@GuestName', 'NVarChar(100)'),
			@GuestSurname = Inv.Report.value('./People.PersonalData[1]/@GuestSurname', 'NVarChar(100)'),
			@InvoiceAmount = Inv.Report.value('./People.PersonalData[1]/@InvoiceAmount', 'Decimal(18,2)'),
			@LastInvoiceDate = Inv.Report.value('./People.PersonalData[1]/@LastInvoiceDate', 'DateTime2')
	From @xml.nodes('People.Visitor') Inv(Report)

	If Exists (SELECT * FROM Report.Invoice WHERE GuestId = @GuestId)
	Begin
		Update Report.Invoice
		Set GuestName = @GuestName, GuestSurname = @GuestSurname, InvoiceAmount = @InvoiceAmount, LastInvoiceDate = @LastInvoiceDate
		Where GuestId = @GuestId;
	End
	Else
	Begin
		Insert Into Report.Invoice(GuestId, GuestName, GuestSurname, InvoiceAmount, LastInvoiceDate)
		Values (@GuestId, @GuestName, @GuestSurname, @InvoiceAmount, @LastInvoiceDate)
	End;
	
	Select @Message As ReceivedRequestMessage, @MessageType; 
	
	-- Confirm and Send a reply
	If @MessageType=N'//DH/Message/Invoice/Request'
	Begin
		Set @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; 
	
		Send On Conversation @TargetDlgHandle
		Message Type
		[//DH/Message/Invoice/Response]
		(@ReplyMessage);
		End Conversation @TargetDlgHandle;
	End 
	
	Select @ReplyMessage As SentReplyMessage; 
	Commit Tran;
End
Go

Use Hotels
Go

Create Procedure [Order].ComfirmGuestInvoice
As
Begin
	Declare @InitiatorReplyDlgHandle Uniqueidentifier,
			@ReplyReceivedMessage NVarChar(1000) 
	Begin Tran; 
		Receive Top(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		From dbo.[InvoiceInitiatorQueue]; 
		End Conversation @InitiatorReplyDlgHandle; 
		Select @ReplyReceivedMessage As ReceivedRepliedMessage; 
	Commit Tran; 
End
Go