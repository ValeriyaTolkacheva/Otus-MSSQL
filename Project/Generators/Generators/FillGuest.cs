using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Generators;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void FillGuest()
    {
        var random = new Random((Int32)(DateTime.Now.Ticks % Int32.MaxValue));
        var query = @"Select Booking.BookingId, MaxQuantityVisitors, Count(VisitorId) VisitorsCount
                        From [Order].Booking
                        Inner Join [Catalog].Room On Booking.RoomId = Room.RoomId
                        Inner Join [Order].Guest On Booking.BookingId = Guest.BookingId
                        Group By Booking.BookingId, MaxQuantityVisitors
                        Having MaxQuantityVisitors > 1 And Count(VisitorId) = 1";
        var bookingList = new List<BookingGuest>();
        using (SqlConnection connection = new SqlConnection("context connection=true"))
        using (SqlCommand cmd = new SqlCommand(query, connection))
        {
            connection.Open();
            using (var reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                    bookingList.Add(new BookingGuest(reader.GetInt64(0), reader.GetByte(1), reader.GetInt32(2)));
            }
        }

        foreach (var booking in bookingList)
        {
            var visitorsCount = random.Next(booking.VisitorsCount, booking.MaxQuantityVisitors);
            for (var i = booking.VisitorsCount; i < visitorsCount; i++)
                AddNewGuest(new PersonalData(random), booking.BookingId);
        }
    }

    public static void AddNewGuest(PersonalData data, Int64 bookingId)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[Order].AddNewGuest", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@Name", SqlDbType.NVarChar) { Value = data.Name });
                cmd.Parameters.Add(new SqlParameter("@Surname", SqlDbType.NVarChar) { Value = data.Surname });
                cmd.Parameters.Add(new SqlParameter("@Patronymic", SqlDbType.NVarChar) { Value = data.Patronymic });
                cmd.Parameters.Add(new SqlParameter("@PasportSeries", SqlDbType.Decimal) { Value = (Decimal)data.PassportSeries });
                cmd.Parameters.Add(new SqlParameter("@PassportNumber", SqlDbType.Decimal) { Value = (Decimal)data.PassportNumber });
                cmd.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.Decimal) { Value = (Decimal)data.PhoneNumber });
                cmd.Parameters.Add(new SqlParameter("@Mail", SqlDbType.NVarChar) { Value = data.Mail });
                cmd.Parameters.Add(new SqlParameter("@BookingId", SqlDbType.BigInt) { Value = bookingId });
                connection.Open();
                cmd.ExecuteNonQuery();
            }
    }

    private class BookingGuest
    {
        public Int64 BookingId { get; set; }
        public Byte MaxQuantityVisitors { get; set; }
        public Int32 VisitorsCount { get; set; }

        public BookingGuest(Int64 bookingId, Byte maxQuantityVisitors, Int32 visitorsCount)
        {
            BookingId = bookingId;
            MaxQuantityVisitors = maxQuantityVisitors;
            VisitorsCount = visitorsCount;
        }
    }
}