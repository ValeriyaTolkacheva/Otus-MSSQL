Use WideWorldImporters

--��������
--���� HW_18_original
--����� �� = 969 ��, ����������� ����� = 6158 ��.
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
set statistics time on
Select ord.CustomerID, det.StockItemID, Sum(det.UnitPrice), Sum(det.Quantity), Count(ord.OrderID)
From Sales.Orders ord
Join Sales.OrderLines det On det.OrderID = ord.OrderID
Join Sales.Invoices Inv On Inv.OrderID = ord.OrderID
join Sales.CustomerTransactions Trans On Trans.InvoiceID = Inv.InvoiceID
Join Warehouse.StockItemTransactions ItemTrans On ItemTrans.StockItemID = det.StockItemID
Where Inv.BillToCustomerID != ord.CustomerID
	and 
	(
		Select SupplierId
		From Warehouse.StockItems It
		Where It.StockItemID = det.StockItemID
	) = 12
	and 
	(
		Select Sum(Total.UnitPrice * Total.Quantity)
		From Sales.OrderLines Total
		Inner Join Sales.Orders ordTotal On ordTotal.OrderID = Total.OrderID
		Where ordTotal.CustomerID = Inv.CustomerID
	) > 250000
	and DateDiff(dd, Inv.InvoiceDate, ord.OrderDate) = 0
Group By ord.CustomerID, det.StockItemID
Order By ord.CustomerID, det.StockItemID
set statistics time off

--������, ��� �������� - � join c Sales.CustomerTransactions ��� ������� �������������
--� ����� HW_18_original ���� Key LookUp �� ������� Sales.Invoices, ��� ���������� � Sales.Orders � ��������� Inv.BillToCustomerID != ord.CustomerID � DateDiff(dd, Inv.InvoiceDate, ord.OrderDate) = 0
--��-�� ����� ������� 2 ����������������� �������

Create Nonclustered Index IX_Sales_Invoices_BillToCustomerID_InvoiceDate
On Sales.Invoices (OrderID)
Include (BillToCustomerID, InvoiceDate)

Create Nonclustered Index IX_Sales_Orders_CustomerID_InvoiceDate
On Sales.Orders (OrderID)
Include (CustomerID, OrderDate)

--� ���������� ��������� ������:
--���� HW_18_result
--����� �� = 672 ��, ����������� ����� = 1059 ��.
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
set statistics time on
;With items as
(
	Select items.StockItemID, trans.StockItemTransactionID
	From Warehouse.StockItems items
	Inner Join Warehouse.StockItemTransactions trans on items.StockItemID = trans.StockItemID
	Where items.SupplierId = 12
),
customers as
(
	Select orders.CustomerID
	From Sales.OrderLines lines
	Inner Join Sales.Orders orders On lines.OrderID = orders.OrderID
	Group By orders.CustomerID
	Having Sum(lines.UnitPrice * lines.Quantity) > 250000
)
Select orders.CustomerID, lines.StockItemID, Sum(lines.UnitPrice) SummaryUnitPrice, Sum(lines.Quantity) Quantity, Count(orders.OrderID) Orders
From customers
Inner Join Sales.Orders orders on orders.CustomerID = customers.CustomerID
Inner Join Sales.OrderLines lines On lines.OrderID = orders.OrderID
Inner Join items On lines.StockItemID = items.StockItemID
Inner Join Sales.Invoices invoices On invoices.OrderID = orders.OrderID
Where invoices.BillToCustomerID != orders.CustomerID And DateDiff(dd, invoices.InvoiceDate, orders.OrderDate) = 0
Group By orders.CustomerID, lines.StockItemID
Order By orders.CustomerID, lines.StockItemID
set statistics time off

--���� � ����������� ������ - HW_18_compare