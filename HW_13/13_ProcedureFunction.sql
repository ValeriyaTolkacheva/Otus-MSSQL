/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей invoces.InvoiceID.
*/
Go

Create Function Sales.LastCustomerPaid()
Returns Table
As
Return
(
	Select customers.CustomerID, customers.CustomerName, invoices.InvoiceID
	From Sales.Invoices invoices
	Inner Join Sales.Customers customers on invoices.CustomerID = customers.CustomerID
	Where invoices.InvoiceID = 
	(
		Select Max(InvoiceID)
		From Sales.Invoices
	)
)
Go

Select * From Sales.LastCustomerPaid()


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/
Go

Create Procedure Sales.CustomerAmount @CustomerId Int
As
Begin
	Select customers.CustomerID, customers.CustomerName, Sum(lines.ExtendedPrice) Amount
	From Sales.Invoices invoces 
	Inner Join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
	Inner Join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
	Where customers.CustomerID = @CustomerId
	Group By customers.CustomerID, customers.CustomerName
End

Exec Sales.CustomerAmount @CustomerId = 404

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
Go

--аналог процедуры из задания 2, результат табличный, но всего 1 строка
Create Function Sales.GetCustomerAmount (@CustomerId Int)
Returns Table
As
Return
(
	Select customers.CustomerID, customers.CustomerName, Sum(lines.ExtendedPrice) Amount
	From Sales.Invoices invoces 
	Inner Join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
	Inner Join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
	Where customers.CustomerID = @CustomerId
	Group By customers.CustomerID, customers.CustomerName
)
Go

 
--SET NOCOUNT ON
Print 'Procedure:'
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
Set statistics time, io on
Exec Sales.CustomerAmount @CustomerId = 405
Set statistics time, io off


print 'Function:'
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
Set statistics time, io on
Select * From Sales.GetCustomerAmount(405)
Set statistics time, io off
--табличные с 1 строкой в результате
--планы выполнения одинаковые
--по скорости работы тоже сопоставимы (1326мс в среднем против 1343мс)

Go
--создам одинаковые процедуру и скалярную функцию (в задании нет, но для полноты экспериментов)
Create Procedure Sales.CustomerAmountSum @CustomerId Int
As
Begin
	Select Sum(lines.ExtendedPrice) Amount
	From Sales.Invoices invoces 
	Inner Join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
	Inner Join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
	Where customers.CustomerID = @CustomerId
	Group By customers.CustomerID, customers.CustomerName
End
Go

Create Function Sales.GetCustomerAmountSum (@CustomerId Int)
Returns Decimal(18,2)
As
Begin
	Declare @result Decimal(18,2) = 
	(
		Select Sum(lines.ExtendedPrice) Amount
		From Sales.Invoices invoces 
		Inner Join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
		Inner Join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
		Where customers.CustomerID = @CustomerId
		Group By customers.CustomerID, customers.CustomerName
	)
	Return @result
End
Go


Print 'Procedure:'
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
Set statistics time, io on
Exec Sales.CustomerAmountSum @CustomerId = 405
Set statistics time, io off


print 'Function:'
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
Set statistics time, io on
Select Sales.GetCustomerAmountSum(405)
Set statistics time, io off
--скалярная функция и процедура, возвращающая 1 значение
--у функции простой и дешевый план выполнения, у процедуры наобор (стоимость в пакете: процедура 100%, скалярная функция 0%)
--по среднему времени выполенения они примерно одинаковык (2844мс процедура, 2871мс функция)
Go

--и теперь табличные с какой-то выборкой
Create Procedure Sales.InvoicesAmount @BeginDate DateTime2, @EndDate DateTime2
As
Begin
	Select invoices.InvoiceID, Sum(lines.ExtendedPrice) Amount
	From Sales.Invoices invoices 
	Inner Join Sales.InvoiceLines lines on invoices.InvoiceID = lines.InvoiceID
	Inner Join Sales.Customers customers on invoices.CustomerID = customers.CustomerID
	Where invoices.InvoiceDate Between @BeginDate and @EndDate
	Group By invoices.InvoiceID
End
Go


Create Function Sales.GetInvoicesAmount (@BeginDate DateTime2, @EndDate DateTime2)
Returns Table
As
Return
(
	Select invoices.InvoiceID, Sum(lines.ExtendedPrice) Amount
	From Sales.Invoices invoices 
	Inner Join Sales.InvoiceLines lines on invoices.InvoiceID = lines.InvoiceID
	Inner Join Sales.Customers customers on invoices.CustomerID = customers.CustomerID
	Where invoices.InvoiceDate Between @BeginDate and @EndDate
	Group By invoices.InvoiceID
)
Go


Print 'Procedure:'
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
Set statistics time, io on
Exec Sales.InvoicesAmount @BeginDate = '2014-01-01', @EndDate = '2016-01-01'
Set statistics time, io off

print 'Function:'
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
Set statistics time, io on
Select * From Sales.GetInvoicesAmount('2014-01-01', '2016-01-01')
Set statistics time, io off

--табличные с набором строк
--план выполнения одинаков
--скорость выполнения тоже одного порядка (7276мс и 7816мс)

--итог:
--в случае с табличными функциями и процедурами какой-то разницы в производительности и скорости нет
--так что выбираем форму в зависимости от бизнесс логики


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/
Go

Create Function Sales.CustomersForSalesPerson(@SalesPersonId Int)
Returns Table
As
Return
(
	Select Distinct customers.CustomerID, customers.CustomerName, customers.PhoneNumber
	From Sales.Invoices invoices
	Inner Join Sales.Customers customers on invoices.CustomerID = customers.CustomerID
	Where invoices.SalespersonPersonID = @SalesPersonId
)
Go

Select salesPerson.PersonID SalesPersonId, salesPerson.FullName SalesPersonName, customer.CustomerID, customer.CustomerName
From [Application].People salesPerson
Cross Apply Sales.CustomersForSalesPerson(salesPerson.PersonID) customer
Order by SalesPersonId, CustomerID

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/


