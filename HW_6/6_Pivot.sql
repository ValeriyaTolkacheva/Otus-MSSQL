/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
;With pivotData as
(
	Select customer.CustomerID, Format(invoce.InvoiceDate, '01.MM.yy') [Month],
		SubString(customer.CustomerName, CharIndex('(', customer.CustomerName) + 1, CharIndex(')', customer.CustomerName) - CharIndex('(', customer.CustomerName) - 1) CustomerName
	From Sales.Customers customer
	Inner join Sales.Invoices invoce on customer.CustomerID = invoce.CustomerID
	Where customer.CustomerID between 2 and 6
)
Select * 
From pivotData
Pivot 
(
	Count(pivotData.CustomerID) 
	For pivotData.CustomerName 
	in ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])
) pvt
Order by [Month]

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

;With fullUnPivot as
(
	Select CustomerName, AddressLine, AddressType
	From 
	(
		Select CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
		From Sales.Customers 
		Where CustomerName like('Tailspin Toys%')
	) customers
	UnPivot 
	(
		AddressLine 
		For AddressType 
		in ([DeliveryAddressLine1], [DeliveryAddressLine2], [PostalAddressLine1], [PostalAddressLine2])
	) unP
)
Select CustomerName, AddressLine
From fullUnPivot

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

;With fullUnPivot as
(
	Select CountryID, CountryName, Code, CodeType
	From
	(
		Select CountryID, CountryName, IsoAlpha3Code, Cast(IsoNumericCode as nvarchar(3)) IsoNumericCode
		From [Application].Countries 
	) countries
	UnPivot
	(
		Code 
		For CodeType
		in ([IsoAlpha3Code], [IsoNumericCode])
	) unP
)
Select CountryID, CountryName, Code
From fullUnPivot

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

Select customers.CustomerID, customers.CustomerName, applyLines.StockItemID, applyLines.UnitPrice, applyLines.InvoiceDate
From Sales.Customers customers
Cross apply 
(
	Select top 2 lines.StockItemID, lines.UnitPrice, invoces.InvoiceDate
	From Sales.Invoices invoces
	Inner join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
	Where invoces.CustomerID = customers.CustomerID
	Order by lines.UnitPrice desc
) as applyLines