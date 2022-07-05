using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void FillService()
    {
        var random = new Random((Int32)(DateTime.Now.Ticks % Int32.MaxValue));
        var query = @"Select Distinct Booking.BookingId, Booking.ArrivalDate, Booking.DepartureDate, Guest.VisitorId, ServiceType.ServiceTypeId, ServiceRoom.RoomId, ServiceType.Dyration
                    From [Order].Booking
                    Inner Join [Order].Guest On Booking.BookingId = Guest.BookingId
                    Inner Join [Catalog].Room On Booking.RoomId = Room.RoomId
                    Inner Join [Catalog].Hotel On Room.HotelId = Hotel.HotelId
                    Inner Join [Catalog].Room ServiceRoom On Hotel.HotelId = ServiceRoom.HotelId
                    Inner Join [Dictionary].RoomType On ServiceRoom.RoomTypeId = RoomType.RoomTypeId
                    Inner Join [Dictionary].ServiceType On RoomType.RoomTypeId = ServiceType.RoomTypeId
                    Inner Join [Order].[Service] On Booking.BookingId = [Service].BookingId
                    Where ServiceType.Price != 0.0
                    Group By Booking.BookingId, Booking.ArrivalDate, Booking.DepartureDate, Guest.VisitorId, ServiceType.ServiceTypeId, ServiceRoom.RoomId, ServiceType.Dyration
                    Having Count(Distinct [Service].ServiceTypeId) = 3
                    Order By Booking.BookingId";
        var bookingList = new List<BookingService>();
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand(query, connection))
            {
                connection.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                        bookingList.Add(new BookingService(reader.GetInt64(0), reader.GetDateTime(1), reader.GetDateTime(2),
                                                            reader.GetInt64(3), reader.GetInt32(4), reader.GetInt32(5), reader.GetByte(6)));
                }
            }
        for (var i = 0; i < bookingList.Count; i++)
        {
            var booking = bookingList[i];
            var hours = (booking.DepartureDate - booking.ArrivalDate).Hours;
            if (hours < 5)
                continue;
            var startDate = booking.ArrivalDate.AddHours(random.Next(2, hours - 2));
            i += random.Next(15, 25);
            try
            {
                AddService(booking.BookingId, booking.ServiceTypeId, booking.RoomId, startDate, booking.VisitorId);
            }
            catch (Exception ex)
            {
                using (SqlConnection connection = new SqlConnection("context connection=true"))
                {
                    connection.Open();
                    SqlContext.Pipe.Send($"{ex.Message}\n{ex.StackTrace}");
                }
            }
        }
    }

    public static void AddService(Int64 bookingId, Int32 serviceTypeId, Int32? roomId, DateTime? startTime, Int64 visitorId)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[Order].AddService", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@BookingId", SqlDbType.BigInt) { Value = bookingId });
                cmd.Parameters.Add(new SqlParameter("@ServiceTypeId", SqlDbType.Int) { Value = serviceTypeId });
                cmd.Parameters.Add(new SqlParameter("@RoomId", SqlDbType.Int) { Value = (Object)roomId ?? DBNull.Value });
                cmd.Parameters.Add(new SqlParameter("@StartTime", SqlDbType.DateTime2) { Value = (Object)startTime ?? DBNull.Value });
                cmd.Parameters.Add(new SqlParameter("@VisitorId", SqlDbType.BigInt) { Value = visitorId });
                connection.Open();
                cmd.ExecuteNonQuery();
            }
    }

    private class BookingService
    {
        public Int64 BookingId { get; set; }
        public DateTime ArrivalDate { get; set; }
        public DateTime DepartureDate { get; set; }
        public Int64 VisitorId { get; set; }
        public Int32 ServiceTypeId { get; set; }
        public Int32 RoomId { get; set; }
        public Byte Dyration { get; set; }

        public BookingService(Int64 bookingId, DateTime arrivalDate, DateTime departureDate, Int64 visitorId, Int32 serviceTypeId, Int32 roomId, Byte dyration)
        {
            BookingId = bookingId;
            ArrivalDate = arrivalDate;
            DepartureDate = departureDate;
            VisitorId = visitorId;
            ServiceTypeId = serviceTypeId;
            RoomId = roomId;
            Dyration = dyration;
        }
    }
}