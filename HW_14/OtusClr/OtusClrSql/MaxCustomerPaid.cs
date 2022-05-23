using System.Data.SqlClient;
using Microsoft.SqlServer.Server;

namespace OtusClrSql
{
    public class MaxCustomerPaid
    {
        [SqlProcedure]
        public static void GetMaxCustomerPaid()
        {
            var query = @"Select Top 1 customers.CustomerID, customers.CustomerName, Sum(lines.ExtendedPrice) Amount
                From Sales.Invoices invoces
                Inner Join Sales.InvoiceLines lines on invoces.InvoiceID = lines.InvoiceID
                Inner Join Sales.Customers customers on invoces.CustomerID = customers.CustomerID
                Group By customers.CustomerID, customers.CustomerName
                Order by Amount desc";
            using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand(query, connection))
            {
                connection.Open();
                SqlContext.Pipe.ExecuteAndSend(cmd);
            }
        }
    }
}
