Use Master 

ALTER DATABASE Hotels  
	SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE
ALTER DATABASE Hotels  
	SET TRUSTWORTHY ON;


ALTER DATABASE DWH_Hotels  
	SET ENABLE_BROKER
ALTER DATABASE DWH_Hotels  
	SET TRUSTWORTHY ON;


--настраиваем получателя
Use DWH_Hotels
CREATE MESSAGE TYPE [//DH/Message/Invoice/Request] 
	VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [//DH/Message/Invoice/Response] 
	VALIDATION = WELL_FORMED_XML
GO

--Create Contract in target database
CREATE CONTRACT [//DH/Contract/Invoice]
(
	[//DH/Message/Invoice/Request] 
		SENT BY INITIATOR,
	[//DH/Message/Invoice/Response] 
		SENT BY TARGET
);
GO

CREATE QUEUE InvoiceTargetQueue
WITH STATUS = ON
GO


CREATE SERVICE [//DH/Service/Invoice/Target]  
	ON QUEUE [InvoiceTargetQueue] ([//DH/Contract/Invoice])
GO


--настраиваем отправителя
Use Hotels
CREATE MESSAGE TYPE [//DH/Message/Invoice/Request] 
	VALIDATION = WELL_FORMED_XML
CREATE MESSAGE TYPE [//DH/Message/Invoice/Response] 
	VALIDATION = WELL_FORMED_XML
GO

CREATE CONTRACT [//DH/Contract/Invoice]
(
	[//DH/Message/Invoice/Request] 
		SENT BY INITIATOR,
	[//DH/Message/Invoice/Response] 
		SENT BY TARGET
);
GO

CREATE QUEUE InvoiceInitiatorQueue
WITH STATUS = ON
GO


CREATE SERVICE [//DH/Service/Invoice/Initiator]  
	ON QUEUE [InvoiceInitiatorQueue] ([//DH/Contract/Invoice])
GO


--создаём процедуры (отдельный файл)
--настраиваем обработку сообщений

Use Hotels
Go
Alter Queue [dbo].[InvoiceInitiatorQueue] With Status = On , Retention = Off , Poison_Message_Handling (Status = Off) 
	, Activation (Status = On ,
        Procedure_Name = [Order].ComfirmGuestInvoice, Max_Queue_Readers = 1, Execute As Owner) ; 

Go

Use DWH_Hotels
Alter Queue [dbo].[InvoiceTargetQueue] With Status = On , Retention = Off , Poison_Message_Handling (Status = Off) 
	, Activation (Status = On ,
        Procedure_Name = [Report].GetGuestInvoice,  Max_Queue_Readers = 1, Execute As Owner);

GO