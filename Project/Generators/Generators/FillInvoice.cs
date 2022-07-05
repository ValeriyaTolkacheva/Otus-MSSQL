using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void FillInvoice ()
    {
        var query = @"Select Booking.BookingId, 
	                    (
		                    Select Top 1 VisitorId
		                    From [Order].Guest 
		                    Where Guest.BookingId = Booking.BookingId
	                    ) VisitorId, 
	                    ArrivalDate, DepartureDate, [Order].GetBookingPrice(Booking.BookingId) BookingPrice, [Order].GetServicePrice(Booking.BookingId) ServicePrice, Case When [Order].GetInvoices(Booking.BookingId) Is Null Then 0.0 Else [Order].GetInvoices(Booking.BookingId) End Invoices
                    From [Order].Booking
                    Where Case When [Order].GetInvoices(Booking.BookingId) Is Null Then 0.0 Else [Order].GetInvoices(Booking.BookingId) End < 
	                    [Order].GetBookingPrice(Booking.BookingId) + [Order].GetServicePrice(Booking.BookingId)
                    Order By Booking.BookingId";
        var bookingList = new List<BookingInvoice>();
        using (SqlConnection connection = new SqlConnection("context connection=true"))
        using (SqlCommand cmd = new SqlCommand(query, connection))
        {
            connection.Open();
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                    bookingList.Add(new BookingInvoice(reader.GetInt64(0), reader.GetInt64(1),  reader.GetDateTime(2), reader.GetDateTime(3), reader.GetDecimal(4), reader.GetDecimal(5), reader.GetDecimal(6)));
            }
        }

        foreach (var booking in bookingList)
        {
            if (booking.Invoices < booking.BookingPrice)
            {
                AddInvoice(booking.BookingId, booking.VisitorId, booking.BookingPrice - booking.Invoices, booking.ArrivalDate.AddDays(-2));
                booking.Invoices += booking.BookingPrice - booking.Invoices;
            }
            if (booking.ServicePrice != 0 && booking.Invoices < (booking.BookingPrice + booking.ServicePrice))
                AddInvoice(booking.BookingId, booking.VisitorId, (booking.BookingPrice + booking.ServicePrice) - booking.Invoices, booking.DepartureDate.AddHours(1));
        }
    }

    public static void AddInvoice(Int64 bookingId, Int64 visitorId, Decimal payment, DateTime invoiceDate)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[Order].AddInvoice", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@BookingId", SqlDbType.BigInt) { Value = bookingId });
                cmd.Parameters.Add(new SqlParameter("@VisitorId", SqlDbType.BigInt) { Value = visitorId });
                cmd.Parameters.Add(new SqlParameter("@Payment", SqlDbType.Decimal) { Value = payment });
                cmd.Parameters.Add(new SqlParameter("@invoiceDate", SqlDbType.DateTime2) { Value = invoiceDate });
                connection.Open();
                cmd.ExecuteNonQuery();
            }
    }

    private class BookingInvoice
    {
        public Int64 BookingId { get; set; }
        public Int64 VisitorId { get; set; }
        public DateTime ArrivalDate { get; set; }
        public DateTime DepartureDate { get; set; }
        public Decimal BookingPrice { get; set; }
        public Decimal ServicePrice { get; set; }
        public Decimal Invoices { get; set; }

        public BookingInvoice(Int64 bookingId, Int64 visitorId, DateTime arrivalDate, DateTime departureDate, Decimal bookingPrice, Decimal servicePrice, Decimal invoices)
        {
            BookingId = bookingId;
            VisitorId = visitorId;
            ArrivalDate = arrivalDate;
            DepartureDate = departureDate;
            BookingPrice = bookingPrice;
            ServicePrice = servicePrice;
            Invoices = invoices;
        }
    }
}