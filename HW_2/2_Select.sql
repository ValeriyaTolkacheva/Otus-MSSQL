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
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

Select StockItemId, StockItemName
From Warehouse.StockItems
Where StockItemName like('%urgent%') or StockItemName like('Animal%') 

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

Select suppliers.SupplierId, suppliers.SupplierName
From Purchasing.Suppliers suppliers
left join Purchasing.PurchaseOrders ordrers 
	on suppliers.SupplierId = ordrers.SupplierId
Where ordrers.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

Select 
	orders.OrderID, 
	Format(orders.OrderDate, 'dd.MM.yyyy') [Date], 
	Format(orders.OrderDate, 'MMMM') [Month], 
	DatePart(q, orders.OrderDate) [Quarter],
	Case 
		When DatePart(m, orders.OrderDate) between 1 and 4 then 1
		When DatePart(m, orders.OrderDate) between 5 and 8 then 2
		When DatePart(m, orders.OrderDate) between 9 and 12 then 3
	End [Third],
	customers.CustomerName
From Sales.Orders orders
inner join Sales.OrderLines lines on orders.OrderID = lines.OrderID
inner join Sales.Customers customers on orders.CustomerID = customers.CustomerID
Where (lines.UnitPrice > 100 or lines.Quantity > 20) and orders.PickingCompletedWhen is not null
Order by [Quarter], [Third], orders.OrderDate
Offset 1000 rows Fetch next 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

Select delivery.DeliveryMethodName, orders.ExpectedDeliveryDate, suppliers.SupplierName Supplier, people.FullName Contact 
From Purchasing.Suppliers suppliers
inner join Purchasing.PurchaseOrders orders on suppliers.SupplierID = orders.SupplierID
inner join [Application].DeliveryMethods delivery on orders.DeliveryMethodID = delivery.DeliveryMethodID
inner join [Application].People people on orders.ContactPersonID = people.PersonID
Where delivery.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
	and orders.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
	and orders.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

Select Top 10 invoces.InvoiceID, invoces.InvoiceDate, contactPeople.FullName ContactPerson, salesPeople.FullName Salesperson
From Sales.Invoices invoces
inner join [Application].People contactPeople on invoces.ContactPersonID = contactPeople.PersonID
inner join [Application].People salesPeople on invoces.SalespersonPersonID = salesPeople.PersonID
order by invoces.InvoiceDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

Select people.PersonID, people.FullName, people.PhoneNumber
From Sales.Orders orders
inner join Sales.OrderLines lines on orders.OrderID = lines.OrderID
inner join Warehouse.StockItems items on lines.StockItemID = items.StockItemID
inner join [Application].People people on orders.CustomerID = people.PersonID
Where items.StockItemName = 'Chocolate frogs 250g'
