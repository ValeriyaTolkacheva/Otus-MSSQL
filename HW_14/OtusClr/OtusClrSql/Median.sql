Use WideWorldImporters

--для TotalDryItems из Sales.Invoices
--запросом
;With numbers as
(
	Select Row_Number() Over(Order by TotalDryItems) RowNumber, InvoiceId, TotalDryItems, Count(*) Over() Total
	From Sales.Invoices
)
Select TotalDryItems Median, RowNumber, Total
From numbers
Where RowNumber = Total / 2

--функцией
Select dbo.Median(TotalDryItems) Median
From Sales.Invoices

--для Quantity из Sales.InvoiceLines
--запросом
;With numbers as
(
	Select Row_Number() Over(Order by Quantity) RowNumber, InvoiceLineID, Quantity, Count(*) Over() Total
	From Sales.InvoiceLines
)
Select Quantity Median, RowNumber, Total
From numbers
Where RowNumber = Total / 2

--функцией
Select dbo.Median(Quantity) Median
From Sales.InvoiceLines