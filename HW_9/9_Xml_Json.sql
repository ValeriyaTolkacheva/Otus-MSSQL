/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

--OpenXml
Declare @xmlId Int, @xmlText NVarChar(Max)
Set @xmlText = 
(
	Select *
	From OpenRowSet(Bulk 'D:\OtusHomeWork\StockItems.xml', Single_Clob) as XmlFile
)
Exec sp_xml_preparedocument @xmlId OutPut, @xmlText
;With insertRows as
(
	Select *
	From OpenXml(@xmlId, '/StockItems/Item', 2)
	With 
	(
		StockItemName			NVarChar(100)		'@Name',
		SupplierID				Int					'./SupplierID',
		UnitPackageID			Int					'./Package/UnitPackageID',
		OuterPackageID			Int					'./Package/OuterPackageID',
		QuantityPerOuter		Int					'./Package/QuantityPerOuter',
		TypicalWeightPerUnit	Decimal(18,3)		'./Package/TypicalWeightPerUnit',
		LeadTimeDays			Int					'./LeadTimeDays',
		IsChillerStock			Bit					'./IsChillerStock',
		TaxRate					Decimal(18,3)		'./TaxRate',
		UnitPrice				Decimal(18,2)		'./UnitPrice'
	)
)
Merge Warehouse.StockItems items
Using insertRows
On (items.StockItemName = insertRows.StockItemName)
When Matched
	Then Update Set							SupplierID = insertRows.SupplierID, 
																	UnitPackageID = insertRows.UnitPackageID, 
																								OuterPackageID = insertRows.UnitPackageID, 
																															QuantityPerOuter = insertRows.QuantityPerOuter, 
																																							TypicalWeightPerUnit = insertRows.TypicalWeightPerUnit, 
																																																LeadTimeDays = insertRows.LeadTimeDays, 
																																																							IsChillerStock = insertRows.IsChillerStock, 
																																																														TaxRate = insertRows.TaxRate, 
																																																																			UnitPrice = insertRows.UnitPrice
When Not Matched
	Then Insert	(StockItemName,				SupplierID,				UnitPackageID,				OuterPackageID,				QuantityPerOuter,				TypicalWeightPerUnit,				LeadTimeDays,				IsChillerStock,				TaxRate,			UnitPrice)
	Values		(insertRows.StockItemName,	insertRows.SupplierID,	insertRows.UnitPackageID,	insertRows.OuterPackageID,	insertRows.QuantityPerOuter,	insertRows.TypicalWeightPerUnit,	insertRows.LeadTimeDays,	insertRows.IsChillerStock,	insertRows.TaxRate, insertRows.UnitPrice)
;



--XQuery
Declare @itemsXml Xml =
(
	Select *
	From OpenRowSet(Bulk 'D:\OtusHomeWork\StockItems.xml', Single_Clob) as XmlFile
)
;With insertRows as
(
	Select 
		xmlTable.Item.value('./@Name', 'NVarChar(100)')									StockItemName,
		xmlTable.Item.value('./SupplierID[1]', 'Int')									SupplierID,
		xmlTable.Item.value('./Package[1]/UnitPackageID[1]', 'Int')						UnitPackageID,
		xmlTable.Item.value('./Package[1]/OuterPackageID[1]', 'Int')					OuterPackageID,
		xmlTable.Item.value('./Package[1]/QuantityPerOuter[1]', 'Int')					QuantityPerOuter,
		xmlTable.Item.value('./Package[1]/TypicalWeightPerUnit[1]', 'Decimal(18,3)')	TypicalWeightPerUnit,
		xmlTable.Item.value('./LeadTimeDays[1]', 'Int')									LeadTimeDays,
		xmlTable.Item.value('./IsChillerStock[1]', 'Bit')								IsChillerStock,
		xmlTable.Item.value('./TaxRate[1]', 'Decimal(18,3)')							TaxRate,
		xmlTable.Item.value('./UnitPrice[1]', 'Decimal(18,2)')							UnitPrice
	From @itemsXml.nodes('/StockItems/Item') as xmlTable(Item)
)
Merge Warehouse.StockItems items
Using insertRows
On (items.StockItemName = insertRows.StockItemName)
When Matched
	Then Update Set							SupplierID = insertRows.SupplierID, 
																	UnitPackageID = insertRows.UnitPackageID, 
																								OuterPackageID = insertRows.UnitPackageID, 
																															QuantityPerOuter = insertRows.QuantityPerOuter, 
																																							TypicalWeightPerUnit = insertRows.TypicalWeightPerUnit, 
																																																LeadTimeDays = insertRows.LeadTimeDays, 
																																																							IsChillerStock = insertRows.IsChillerStock, 
																																																														TaxRate = insertRows.TaxRate, 
																																																																			UnitPrice = insertRows.UnitPrice
When Not Matched
	Then Insert	(StockItemName,				SupplierID,				UnitPackageID,				OuterPackageID,				QuantityPerOuter,				TypicalWeightPerUnit,				LeadTimeDays,				IsChillerStock,				TaxRate,			UnitPrice)
	Values		(insertRows.StockItemName,	insertRows.SupplierID,	insertRows.UnitPackageID,	insertRows.OuterPackageID,	insertRows.QuantityPerOuter,	insertRows.TypicalWeightPerUnit,	insertRows.LeadTimeDays,	insertRows.IsChillerStock,	insertRows.TaxRate, insertRows.UnitPrice)
;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/


--посмотреть на запрос и формируемый xml
Select
	items.StockItemName				[@Name],
	items.SupplierID				[SupplierID],
	items.UnitPackageID				[Package/UnitPackageID],
	items.OuterPackageID			[Package/OuterPackageID],
	items.QuantityPerOuter			[Package/QuantityPerOuter],
	items.TypicalWeightPerUnit		[Package/TypicalWeightPerUnit],
	items.LeadTimeDays				[LeadTimeDays],
	items.IsChillerStock			[IsChillerStock],
	items.TaxRate					[TaxRate],
	items.UnitPrice					[UnitPrice]
From Warehouse.StockItems items
For Xml Path('Item'), Root('StockItems')
 

--с переносами строк не хочет работать, поэтому запрос с формированием xml выше
Declare @cmd VarChar(1000) = 'bcp "Select items.StockItemName [@Name], items.SupplierID [SupplierID], items.UnitPackageID [Package/UnitPackageID], items.OuterPackageID [Package/OuterPackageID], items.QuantityPerOuter [Package/QuantityPerOuter], items.TypicalWeightPerUnit [Package/TypicalWeightPerUnit], items.LeadTimeDays [LeadTimeDays], items.IsChillerStock [IsChillerStock], items.TaxRate [TaxRate], items.UnitPrice [UnitPrice] From Warehouse.StockItems items For Xml Path(''Item''), Root(''StockItems'')" queryout D:\OtusHomeWork\StockItems_Out.xml -w -r -T -S HOME-PC\SQL2019 -d WideWorldImporters'

Exec master..xp_cmdshell @cmd


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

--кривой способ
Select items.StockItemID, items.StockItemName, customJson.CountryOfManufacture, customJson.FirstTag
From Warehouse.StockItems items
Cross Apply OpenJson(items.CustomFields)
With 
(
	CountryOfManufacture VarChar(100),
	FirstTag VarChar(10) '$.Tags[0]'
) customJson

--руками из плеч
Select items.StockItemID, items.StockItemName, 
	Json_Value(items.CustomFields, '$.CountryOfManufacture') CountryOfManufacture, 
	Json_Value(items.CustomFields, '$.Tags[0]') FirstTag
From Warehouse.StockItems items

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

--просто
Select StockItemID, StockItemName
From Warehouse.StockItems 
Cross Apply OpenJson(CustomFields, '$.Tags') cust
Where cust.[Value] = 'Vintage'


--опционально
Select items.StockItemID, items.StockItemName, String_agg(customJson.[Value], ',') [Values]
From Warehouse.StockItems items
Cross Apply OpenJson(items.CustomFields, '$.Tags') customJson
Where items.StockItemID in 
(
	Select StockItemID
	From Warehouse.StockItems 
	Cross Apply OpenJson(CustomFields, '$.Tags') cust
	Where cust.[Value] = 'Vintage'
)
Group by items.StockItemID, items.StockItemName