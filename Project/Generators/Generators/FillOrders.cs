using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Generators;
using System.Collections.Generic;
using Microsoft.SqlServer.Server;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void FillBooking(SqlDateTime dateFrom)
    {
        var random = new Random((Int32)(DateTime.Now.Ticks % Int32.MaxValue));
        var startDate = dateFrom.IsNull ? DateTime.Today.AddMonths(-random.Next(5, 10)) : dateFrom.Value;
        while (startDate < DateTime.Today)
        {
            startDate = startDate.AddDays(random.Next(20, 30));
            var endDate = startDate.AddDays(random.Next(6, 20));
            var listRooms = GetEmptyRoomsForDates(startDate, endDate);
            foreach (var roomid in listRooms)
            {
                try
                {
                    var visitorId = AddNewVisitor(new PersonalData(random));
                    var booking = AddBooking(roomid.Key, startDate.AddDays(random.Next(2)).AddHours(random.Next(23)), endDate.AddDays(-random.Next(2)).AddHours(-random.Next(23)), visitorId);
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
    }

    public static Dictionary<Int32, Byte> GetEmptyRoomsForDates(DateTime dateFrom, DateTime dateTo)
    {
        var roomList = new Dictionary<Int32, Byte>();
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[Order].GetEmptyRoomsForDates", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@DateFrom", SqlDbType.DateTime2) { Value = dateFrom });
                cmd.Parameters.Add(new SqlParameter("@DateTo", SqlDbType.DateTime2) { Value = dateTo });
                connection.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    if (!reader.HasRows)
                    {
                        return roomList;
                    }
                    while (reader.Read())
                        roomList.Add(reader.GetInt32(0), reader.GetByte(1));
                }
            }
        return roomList;
    }

    public static Int64 AddNewVisitor(PersonalData data)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[People].AddNewVisitor", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@Name", SqlDbType.NVarChar) { Value = data.Name });
                cmd.Parameters.Add(new SqlParameter("@Surname", SqlDbType.NVarChar) { Value = data.Surname });
                cmd.Parameters.Add(new SqlParameter("@Patronymic", SqlDbType.NVarChar) { Value = data.Patronymic });
                cmd.Parameters.Add(new SqlParameter("@PasportSeries", SqlDbType.Decimal) { Value = (Decimal)data.PassportSeries });
                cmd.Parameters.Add(new SqlParameter("@PassportNumber", SqlDbType.Decimal) { Value = (Decimal)data.PassportNumber });
                cmd.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.Decimal) { Value = (Decimal)data.PhoneNumber });
                cmd.Parameters.Add(new SqlParameter("@Mail", SqlDbType.NVarChar) { Value = data.Mail });
                cmd.Parameters.Add(new SqlParameter("@VisitorId", SqlDbType.BigInt) { Direction = ParameterDirection.Output });
                connection.Open();
                cmd.ExecuteNonQuery();
                var visitorId = (Int64)cmd.Parameters["@VisitorId"].Value;
                return visitorId;
            }
    }

    public static Int64 AddBooking(Int32 roomId, DateTime arrivalDate, DateTime departureDate, Int64 visitorId)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[Order].AddBooking", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@RoomId", SqlDbType.Int) { Value = roomId });
                cmd.Parameters.Add(new SqlParameter("@ArrivalDate", SqlDbType.DateTime2) { Value = arrivalDate });
                cmd.Parameters.Add(new SqlParameter("@DepartureDate", SqlDbType.DateTime2) { Value = departureDate });
                cmd.Parameters.Add(new SqlParameter("@VisitorId", SqlDbType.BigInt) { Value = visitorId });
                cmd.Parameters.Add(new SqlParameter("@BookingId", SqlDbType.BigInt) { Direction = ParameterDirection.Output });
                connection.Open();
                cmd.ExecuteNonQuery();
                var bookingId = (Int64)cmd.Parameters["@BookingId"].Value;
                return visitorId;
            }
    }
}