/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
SET STATISTICS TIME, IO ON


--Время ЦП = 2173 мс, затраченное время = 1620 мс.
;With sums as
(
	Select Year(invoices.InvoiceDate) [Year],
		   Month(invoices.InvoiceDate) [Month],
		   Sum(lines.ExtendedPrice) [Sum]
	From Sales.Invoices invoices
	Inner join Sales.InvoiceLines lines on invoices.InvoiceID = lines.InvoiceID
	Where Year(invoices.InvoiceDate) >= 2015
	Group by Year(invoices.InvoiceDate), Month(invoices.InvoiceDate)
),
total as
(
	Select sums.*, Sum(sums2.[Sum]) as Total
	From sums
	Inner Join sums sums2 on sums2.[Year] <= sums.[Year] and sums2.[Month] <= sums.[Month]
	Group By sums.[Year], sums.[Month], sums.[Sum]
)
Select distinct invoices.InvoiceDate, total.Total
From Sales.Invoices invoices
Inner join total on Year(invoices.InvoiceDate) = total.Year and Month(invoices.InvoiceDate) = total.Month
Order by invoices.InvoiceDate

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

--Время ЦП = 795 мс, затраченное время = 149 мс.
Select distinct invoices.InvoiceDate, Sum(lines.ExtendedPrice) Over (Order by Year(invoices.InvoiceDate), Month(invoices.InvoiceDate)) Total
From Sales.Invoices invoices
Inner join Sales.InvoiceLines lines on lines.InvoiceID = invoices.InvoiceID
Where Year(invoices.InvoiceDate) >= 2015 
Order by invoices.InvoiceDate

SET STATISTICS TIME, IO OFF

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
;With itemsCount as
(
	Select distinct Year(invoices.InvoiceDate) [Year], Month(invoices.InvoiceDate) [Month], 
				items.StockItemID, items.StockItemName, 
				Sum(lines.Quantity) Over (Partition by items.StockItemID, Year(invoices.InvoiceDate), Month(invoices.InvoiceDate)) [Count]
	From Sales.Invoices invoices
	Inner join Sales.InvoiceLines lines on invoices.InvoiceID = lines.InvoiceID
	Inner join Warehouse.StockItems items on lines.StockItemID = items.StockItemID
	Where Year(invoices.InvoiceDate) = 2016
),
itemsNum as
(
	Select items.*, Row_Number() Over (Partition by items.[Year], items.[Month] Order by items.[Count] desc) [Num]
	From itemsCount items
)
Select items.[Year], items.[Month], items.StockItemName, [Count]
From itemsNum items
Where items.Num <= 2
Order by [Year], [Month], [Count] desc

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново + SimbolRow
* посчитайте общее количество товаров и выведете полем в этом же запросе + TotalCount
* посчитайте общее количество товаров в зависимости от первой буквы названия товара + SimbolCount
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени + NextId
* предыдущий ид товара с тем же порядком отображения (по имени) + PrevId
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items" + PrevPrevName
* сформируйте 30 групп товаров по полю вес товара на 1 шт + WeightGroup

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

Select items.StockItemID, items.StockItemName, items.Brand, items.UnitPrice,
		Row_Number() Over (Partition by Left(items.StockItemName, 1) Order by items.StockItemName) SimbolRow,
		Count(*) Over () TotalCount,
		Count(*) Over (Partition by Left(items.StockItemName, 1)) SimbolCount,
		Lead(items.StockItemID) Over (Order by items.StockItemName) NextId,
		Lag(items.StockItemID) Over (Order by items.StockItemName) PrevId,
		Lag(items.StockItemName, 2, 'No items') Over (Order by items.StockItemName) PrevPrevName,
		Ntile(30) Over(Partition by items.TypicalWeightPerUnit Order by items.TypicalWeightPerUnit) WeightGroup
From Warehouse.StockItems items 
Order by items.StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;With invoicePrice as
(
	Select lines.InvoiceID, Sum(lines.ExtendedPrice) FullPrice
	From Sales.InvoiceLines lines
	Group by lines.InvoiceID
),
lastInvoice as
(
	Select distinct invoces.SalespersonPersonID, Last_Value(invoces.InvoiceID) Over (Partition by invoces.SalespersonPersonID Order by invoces.SalespersonPersonID) LastId
	From Sales.Invoices invoces
)
Select invoces.SalespersonPersonID, people.FullName SalespersonPersonName, customers.CustomerID, customers.CustomerName, invoces.InvoiceDate, invoicePrice.FullPrice
From Sales.Invoices invoces
Inner join [Application].People people on invoces.SalespersonPersonID = people.PersonID and people.IsSalesperson = 1
Inner join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
Inner join invoicePrice on invoces.InvoiceID = invoicePrice.InvoiceID
Inner join lastInvoice on  invoces.InvoiceID = lastInvoice.LastId
Order by invoces.SalespersonPersonID, invoces.InvoiceDate desc

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

;With orderUnits as
(
	Select invoces.CustomerID, customers.CustomerName, lines.StockItemID, lines.UnitPrice, invoces.InvoiceDate, 
			Dense_Rank() Over (Partition by invoces.CustomerID Order by lines.UnitPrice desc, lines.StockItemID) Num
	From Sales.Invoices invoces
	Inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
	Inner join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
)
Select orderUnits.CustomerID, orderUnits.CustomerName, orderUnits.StockItemID, orderUnits.UnitPrice, orderUnits.InvoiceDate
From orderUnits
Where orderUnits.Num <= 2
Order by orderUnits.CustomerID

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 