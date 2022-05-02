/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

Select people.PersonID, people.FullName 
From [Application].People people
Where people.IsSalesperson = 1 and people.PersonID not in 
	(Select SalespersonPersonID 
	From Sales.Invoices invoces
	Where InvoiceDate = '2015-07-04')


;With invoces as
(
	Select SalespersonPersonID 
	From Sales.Invoices invoces
	Where InvoiceDate = '2015-07-04'
)
Select people.PersonID, people.FullName
From [Application].People people
Left join invoces on people.PersonID = invoces.SalespersonPersonID
Where people.IsSalesperson = 1 and invoces.SalespersonPersonID is Null

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

Select items.StockItemID, items.StockItemName, minPrices.MinPrice
From Warehouse.StockItems items
inner join 
(
	Select min(lines.ExtendedPrice) MinPrice, lines.StockItemID
	from Sales.InvoiceLines lines
	Group by lines.StockItemID
) minPrices on items.StockItemID = minPrices.StockItemID
order by items.StockItemID


;With minPrices as
(
	Select min(lines.ExtendedPrice) MinPrice, lines.StockItemID
	from Sales.InvoiceLines lines
	Group by lines.StockItemID
) 
Select items.StockItemID, items.StockItemName, minPrices.MinPrice
From Warehouse.StockItems items
inner join minPrices on items.StockItemID = minPrices.StockItemID
order by items.StockItemID

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--вариант без подзапросов
--??
Select top 5 customers.CustomerID, customers.CustomerName, customers.PhoneNumber, transactions.TransactionAmount
From Sales.Customers customers
inner join Sales.CustomerTransactions transactions on customers.CustomerID = transactions.CustomerID
Order by transactions.TransactionAmount desc

--если очень хочется подзапросы, то вот
Select top 5 customers.CustomerID, customers.CustomerName, customers.PhoneNumber, prices.InvocePrice
From Sales.Customers customers
inner join Sales.CustomerTransactions transactions on customers.CustomerID = transactions.CustomerID
inner join
(
	Select lines.InvoiceID, Sum(lines.ExtendedPrice) InvocePrice
	From Sales.InvoiceLines lines 
	Group by lines.InvoiceID
) prices on transactions.InvoiceID = prices.InvoiceID
Order by prices.InvocePrice desc

;With prices as 
(
	Select lines.InvoiceID, Sum(lines.ExtendedPrice) InvocePrice
	From Sales.InvoiceLines lines 
	Group by lines.InvoiceID
) 
Select top 5 customers.CustomerID, customers.CustomerName, customers.PhoneNumber, prices.InvocePrice
From Sales.Customers customers
inner join Sales.CustomerTransactions transactions on customers.CustomerID = transactions.CustomerID
inner join prices on transactions.InvoiceID = prices.InvoiceID
Order by prices.InvocePrice desc

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

Select distinct cities.CityID, cities.CityName, people.FullName
From Sales.Invoices invoces
Inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID and lines.StockItemID in 
(
	Select top 3 items.StockItemID
	From Warehouse.StockItems items
	Order by items.UnitPrice desc
)
Inner join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
Inner join [Application].Cities cities on customers.DeliveryCityID = cities.CityID
Inner join [Application].People people on invoces.PackedByPersonID = people.PersonID 


;With topItems as
(
	Select top 3 items.StockItemID
	From Warehouse.StockItems items
	Order by items.UnitPrice desc
)
Select distinct cities.CityID, cities.CityName, people.FullName
From Sales.Invoices invoces
Inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
Inner join topItems on lines.StockItemID = topItems.StockItemID
Inner join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
Inner join [Application].Cities cities on customers.DeliveryCityID = cities.CityID
Inner join [Application].People people on invoces.PackedByPersonID = people.PersonID 


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

--выбираются заказы, с ценой товаров более 27000
--выводится: InvoiceID - id счета, InvoiceDate - дата создания счета, SalesPersonName - продавец, TotalSummByInvoice - общая цена товара из заказа, TotalSummForPickedItems - общая цена уже собранных позиций

SET STATISTICS IO, TIME ON

--План HW_4_5_original
--Время ЦП = 324 мс, затраченное время = 150 мс.
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC


-- --
--выбираются заказы, с ценой товаров более 27000
--выводится: InvoiceID - id заказа, InvoiceDate - дата заказа, SalesPersonName - продавец, TotalSummByInvoice - общая цена товара из заказа, TotalSummForPickedItems - общая цена уже собранных позиций

--план HW_4_5_var1
--Время ЦП = 156 мс, затраченное время = 467 мс.
--наиболее читабельный вариант запроса
;With fullPrice as
(
	Select lines.InvoiceID, invoices.InvoiceDate, invoices.SalespersonPersonID, invoices.OrderId, Sum(lines.Quantity * lines.UnitPrice) AS TotalSummByInvoice
	From Sales.InvoiceLines lines
	Inner join Sales.Invoices invoices on lines.InvoiceID = invoices.InvoiceID
	Group by lines.InvoiceID, invoices.InvoiceDate, invoices.SalespersonPersonID, invoices.OrderId
),
pickedPrice as
(
	Select lines.OrderID, Sum(lines.PickedQuantity * lines.UnitPrice) As TotalSummForPickedItems
	From Sales.OrderLines lines
	Inner join Sales.Orders orders on lines.OrderID = orders.OrderID 
										and orders.PickingCompletedWhen is not null
	Group by lines.OrderID
)
Select fullPrice.InvoiceID, fullPrice.InvoiceDate, people.FullName SalesPersonName, fullPrice.TotalSummByInvoice, pickedPrice.TotalSummForPickedItems
From fullPrice
Inner join [Application].People people on fullPrice.SalespersonPersonID = people.PersonID
Inner join pickedPrice on fullPrice.OrderID = pickedPrice.OrderID and fullPrice.TotalSummByInvoice > 27000
Order by fullPrice.TotalSummByInvoice desc


--план HW_4_5_var2
--Время ЦП = 157 мс, затраченное время = 223 мс.
--немного переработанная версия - пыталась уменьшить выборки данных, некторые условия вынесены в CTE
--по соотношению время работы\читаемость выбрала бы его
;With fullPrice as
(
	Select lines.InvoiceID, invoices.InvoiceDate, invoices.SalespersonPersonID, invoices.OrderId, Sum(lines.Quantity * lines.UnitPrice) AS TotalSummByInvoice
	From Sales.InvoiceLines lines
	Inner join Sales.Invoices invoices on lines.InvoiceID = invoices.InvoiceID
	Group by lines.InvoiceID, invoices.InvoiceDate, invoices.SalespersonPersonID, invoices.OrderId
	Having Sum(lines.Quantity * lines.UnitPrice) > 27000
),
pickedPrice as
(
	Select lines.OrderID, Sum(lines.PickedQuantity * lines.UnitPrice) As TotalSummForPickedItems
	From Sales.OrderLines lines
	Inner join Sales.Orders orders on lines.OrderID = orders.OrderID 
										and orders.PickingCompletedWhen is not null
	Inner join fullPrice on fullPrice.OrderId = lines.OrderID
	Group by lines.OrderID
)
Select fullPrice.InvoiceID, fullPrice.InvoiceDate, people.FullName SalesPersonName, fullPrice.TotalSummByInvoice, pickedPrice.TotalSummForPickedItems
From fullPrice
Inner join [Application].People people on fullPrice.SalespersonPersonID = people.PersonID
Inner join pickedPrice on fullPrice.OrderID = pickedPrice.OrderID
Order by fullPrice.TotalSummByInvoice desc

SET STATISTICS IO, TIME OFF