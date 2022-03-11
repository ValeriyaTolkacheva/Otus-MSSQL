/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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


--таблица для года\месяца
Select [Year], [Month] from
(Select Distinct
	DatePart(yy, invoces.InvoiceDate) [Year]
From Sales.Invoices invoces) as table1
cross join
(Select 
	[Month]
From (values(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) as tab([Month])) as table2


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
	DateTable.[Year], 
	DateTable.[Month], 
	Sum(IsNull(lines.ExtendedPrice,0)) [Sum]
From Sales.Invoices invoces
inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
right join 
(
	--таблица для года\месяца
	Select [Year], [Month] from
	(Select Distinct
		DatePart(yy, invoces.InvoiceDate) [Year]
	From Sales.Invoices invoces) as table1
	cross join
	(Select 
		[Month]
	From (values(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) as tab([Month])) as table2
) as DateTable on DateTable.[Year] = DatePart(yy, invoces.InvoiceDate) and DateTable.[Month] = DatePart(m, invoces.InvoiceDate)
Group by DateTable.[Year], DateTable.[Month]
Having Sum(lines.ExtendedPrice)  > 10000 or Sum(IsNull(lines.ExtendedPrice,0)) = 0
Order by [Year], [Month]

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
	DateTable.[Year], 
	DateTable.[Month],  
	IsNull(items.StockItemName, '---') StockItemName, 
	Sum(IsNull(lines.ExtendedPrice, 0)) [Sum], 
	Min(invoces.InvoiceDate) FirstInvoice,
	Sum(IsNull(lines.Quantity, 0)) [Count]
From Sales.Invoices invoces
inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
inner join Warehouse.StockItems items on lines.StockItemID = items.StockItemID
right join 
(
	--таблица для года\месяца
	Select [Year], [Month] from
	(Select Distinct
		DatePart(yy, invoces.InvoiceDate) [Year]
	From Sales.Invoices invoces) as table1
	cross join
	(Select 
		[Month]
	From (values(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) as tab([Month])) as table2
) as DateTable on DateTable.[Year] = DatePart(yy, invoces.InvoiceDate) and DateTable.[Month] = DatePart(m, invoces.InvoiceDate)
Group by  DateTable.[Year], DateTable.[Month], items.StockItemName
Having Sum(IsNull(lines.Quantity, 0)) < 50
Order by DateTable.[Year], DateTable.[Month], items.StockItemName

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
