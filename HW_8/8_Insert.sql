/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

Insert into Sales.Customers 
	(
		[CustomerName]
	  ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	)
Select Top 5 
	 'Customer' + Cast( Row_Number() Over(Order by customers.CustomerId) as varchar(100)) [CustomerName]
	  ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
From Sales.Customers

/*
Select * From Sales.Customers
Where CustomerName like ('Customer%')
*/

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

Delete From Sales.Customers
Where CustomerName = 'Customer1'

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

Update Sales.Customers
	Set CustomerName = 'Customer55'
Where CustomerName = 'Customer5'


/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

;With insertRows as
(
	Select Top 4 
	 'Customer' + Cast( Row_Number() Over(Order by customers.CustomerId) + 3 as varchar(100)) [CustomerName]
	  ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
		From Sales.Customers
)
Merge Sales.Customers customers
Using insertRows
On (customers.CustomerName = insertRows.CustomerName)
When Matched
	Then Update Set CustomerName = insertRows.CustomerName + Right(insertRows.CustomerName, 1) + Right(insertRows.CustomerName, 1)
When Not Matched 
	Then Insert ([CustomerName] ,[BillToCustomerID] ,[CustomerCategoryID] ,[BuyingGroupID] ,[PrimaryContactPersonID] ,[AlternateContactPersonID] ,[DeliveryMethodID] ,[DeliveryCityID] ,[PostalCityID] ,[CreditLimit] ,[AccountOpenedDate] ,[StandardDiscountPercentage] ,[IsStatementSent] ,[IsOnCreditHold] ,[PaymentDays] ,[PhoneNumber] ,[FaxNumber] ,[DeliveryRun] ,[RunPosition] ,[WebsiteURL] ,[DeliveryAddressLine1] ,[DeliveryAddressLine2] ,[DeliveryPostalCode] ,[DeliveryLocation] ,[PostalAddressLine1] ,[PostalAddressLine2] ,[PostalPostalCode] ,[LastEditedBy])
	Values (insertRows.[CustomerName] ,insertRows.[BillToCustomerID] ,insertRows.[CustomerCategoryID] ,insertRows.[BuyingGroupID] ,insertRows.[PrimaryContactPersonID] ,insertRows.[AlternateContactPersonID] ,insertRows.[DeliveryMethodID] ,insertRows.[DeliveryCityID] ,insertRows.[PostalCityID] ,insertRows.[CreditLimit] ,insertRows.[AccountOpenedDate] ,insertRows.[StandardDiscountPercentage] ,insertRows.[IsStatementSent] ,insertRows.[IsOnCreditHold] ,insertRows.[PaymentDays] ,insertRows.[PhoneNumber] ,insertRows.[FaxNumber] ,insertRows.[DeliveryRun] ,insertRows.[RunPosition] ,insertRows.[WebsiteURL] ,insertRows.[DeliveryAddressLine1] ,insertRows.[DeliveryAddressLine2] ,insertRows.[DeliveryPostalCode] ,insertRows.[DeliveryLocation] ,insertRows.[PostalAddressLine1] ,insertRows.[PostalAddressLine2] ,insertRows.[PostalPostalCode] ,insertRows.[LastEditedBy])
Output deleted.*, $action, inserted.*;

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Application].[Countries]" out  "D:\OtusHomeWork\Countries.txt" -T -w -t; -S HOME-PC\SQL2019'

Drop Table If Exists [WideWorldImporters].[Application].[Countries_BulkInsert]
Create Table [WideWorldImporters].[Application].[Countries_BulkInsert]
(
	  [CountryID] Int Not Null
      ,[CountryName] NVarChar(60) Not Null
      ,[FormalName] NVarChar(60) Not Null
      ,[IsoAlpha3Code] NVarChar(3) Null
      ,[IsoNumericCode] Int Null
      ,[CountryType] NVarChar(20) Null
      ,[LatestRecordedPopulation] BigInt Null
      ,[Continent] NVarChar(30) Not Null
      ,[Region] NVarChar(30) Not Null
      ,[Subregion] NVarChar(30) Not Null
      ,[Border] Geography Null
      ,[LastEditedBy] Int Not Null
      ,[ValidFrom] DateTime2 Not Null
      ,[ValidTo] DateTime2 Not Null
)

Bulk Insert [WideWorldImporters].[Application].[Countries_BulkInsert]
			From "D:\OtusHomeWork\Countries.txt"
			With 
				(
				Batchsize = 1000, 
				DataFileType = 'widechar',
				FieldTerminator = ';',
				RowTerminator ='\n',
				KeepNulls,
				TabLock        
				);

Select Count(*) 
From [Application].[Countries_BulkInsert];

Truncate Table [Application].[Countries_BulkInsert];