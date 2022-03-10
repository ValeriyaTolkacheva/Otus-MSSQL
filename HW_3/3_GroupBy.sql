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

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
	DatePart(yy, invoces.InvoiceDate) [Year], 
	DatePart(m, invoces.InvoiceDate) [Month], 
	Avg(lines.ExtendedPrice) [Avg], 
	Sum(lines.ExtendedPrice) [Sum]
From Sales.Invoices invoces
inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
Group by DatePart(yy, invoces.InvoiceDate), DatePart(m, invoces.InvoiceDate)
Order by [Year], [Month]

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

Select 
	DatePart(yy, invoces.InvoiceDate) [Year], 
	DatePart(m, invoces.InvoiceDate) [Month], 
	Sum(lines.ExtendedPrice) [Sum]
From Sales.Invoices invoces
inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
Group by DatePart(yy, invoces.InvoiceDate), DatePart(m, invoces.InvoiceDate)
Having Sum(lines.ExtendedPrice)  > 10000
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
	DatePart(yy, invoces.InvoiceDate) [Year], 
	DatePart(m, invoces.InvoiceDate) [Month], 
	items.StockItemName, 
	Sum(lines.ExtendedPrice) [Sum], 
	Min(invoces.InvoiceDate) FirstInvoice,
	Sum(lines.Quantity) [Count]
From Sales.Invoices invoces
inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
inner join Warehouse.StockItems items on lines.StockItemID = items.StockItemID
Group by DatePart(yy, invoces.InvoiceDate), DatePart(m, invoces.InvoiceDate), items.StockItemName
Having Sum(lines.Quantity) < 50
Order by [Year], [Month], items.StockItemName

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
