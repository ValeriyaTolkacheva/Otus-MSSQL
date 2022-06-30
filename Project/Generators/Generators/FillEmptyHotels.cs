using System;
using System.Data;
using System.Data.SqlClient;
using Microsoft.SqlServer.Server;
using Generators;
using System.Collections.Generic;

public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void FillEmptyHotels ()
    {
        var query = @"Select Hotel.HotelId
                      From [Catalog].Hotel
                      Left Join [Catalog].Room on Hotel.HotelId = Room.HotelId
                      Where Room.HotelId Is Null";
        var hotelsList = new List<Int32>();
        using (SqlConnection connection = new SqlConnection("context connection=true"))
        using (SqlCommand cmd = new SqlCommand(query, connection))
        {
            connection.Open();
            using (var reader = cmd.ExecuteReader())
            {
                if (!reader.HasRows)
                {
                    SqlContext.Pipe.Send("Нет пустых отелей");
                    return;
                }
                while (reader.Read())
                    hotelsList.Add(reader.GetInt32(0));
            }
        }

        foreach(var hotelId in hotelsList)
        {
            var random = new Random((Int32)(DateTime.Now.Ticks % Int32.MaxValue));
            var roomCount = 0;
            for (var roomT = 1; roomT <= 3; roomT++)//жилые комнаты
            {
                var roomTypeCount = random.Next(7, 20);
                for (var i = 0; i < roomTypeCount; i++)
                    AddRoom(new Room(hotelId, roomT, $"{roomT} {++roomCount}", random));
            }

            for (var i = 0; i < (roomCount / 50 + 1); i++)
                AddNewStaff(new Staff(1, hotelId, random));//хостес

            for (var i = 0; i < (roomCount / 4 + 1); i++)
                AddNewStaff(new Staff(2, hotelId, random));//горничная

            var massCount = random.Next(7);//массажные кабинеты и массажисты
            for (var i = 0; i < massCount; i++)
            {
                var room = new Room(hotelId, 4, $"Массажный кабинет {i}", random);
                AddRoom(room);
                for (var j = 0; j < room.MaxQuantityVisitors; j++)
                    AddNewStaff(new Staff(4, hotelId, random));
            }

            var spaCount = random.Next(3);//спа и банщики
            for (var i = 0; i < spaCount; i++)
            {
                var room = new Room(hotelId, 5, $"Спа {i}", random, 5);
                AddRoom(room);
                for (var j = 0; j < room.MaxQuantityVisitors; j++)
                    AddNewStaff(new Staff(5, hotelId, random));
            }

            var restCount = random.Next(4);//рестораны
            for (var i = 0; i < restCount; i++)
            {
                var room = new Room(hotelId, 6, $"Ресторан {i}", random, 7);
                AddRoom(room);
                for (var j = 0; j < room.MaxQuantityVisitors; j++)
                    AddNewStaff(new Staff(3, hotelId, random));
                for (var j = 0; j < room.MaxQuantityVisitors; j++)
                    AddNewStaff(new Staff(6, hotelId, random));
            }
        }
    }

    public static void AddRoom(Room room)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[Catalog].AddRoom", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@HotelId", SqlDbType.Int) { Value = room.HotelId });
                cmd.Parameters.Add(new SqlParameter("@Name", SqlDbType.NVarChar) { Value = room.Name });
                cmd.Parameters.Add(new SqlParameter("@Square", SqlDbType.Decimal) { Value = room.Square });
                cmd.Parameters.Add(new SqlParameter("@MaxQuantityVisitors", SqlDbType.TinyInt) { Value = room.MaxQuantityVisitors });
                cmd.Parameters.Add(new SqlParameter("@LuxDegree", SqlDbType.TinyInt) { Value = room.LuxDegree });
                cmd.Parameters.Add(new SqlParameter("@RoomTypeId", SqlDbType.Int) { Value = room.RoomTypeId });   
                connection.Open();
                cmd.ExecuteNonQuery();
            }
    }

    public static void AddNewStaff(Staff staff)
    {
        using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("[People].AddNewStaff", connection))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add(new SqlParameter("@Name", SqlDbType.NVarChar) { Value = staff.PersonalData.Name });
                cmd.Parameters.Add(new SqlParameter("@Surname", SqlDbType.NVarChar) { Value = staff.PersonalData.Surname });
                cmd.Parameters.Add(new SqlParameter("@Patronymic", SqlDbType.NVarChar) { Value = staff.PersonalData.Patronymic });
                cmd.Parameters.Add(new SqlParameter("@PasportSeries", SqlDbType.Decimal) { Value = (Decimal)staff.PersonalData.PassportSeries });
                cmd.Parameters.Add(new SqlParameter("@PassportNumber", SqlDbType.Decimal) { Value = (Decimal)staff.PersonalData.PassportNumber });
                cmd.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.Decimal) { Value = (Decimal)staff.PersonalData.PhoneNumber });
                cmd.Parameters.Add(new SqlParameter("@Mail", SqlDbType.NVarChar) { Value = staff.PersonalData.Mail });
                cmd.Parameters.Add(new SqlParameter("@StaffTypeId", SqlDbType.Int) { Value = staff.StaffTypeId });
                cmd.Parameters.Add(new SqlParameter("@HotelId", SqlDbType.Int) { Value = staff.HotelId });
                connection.Open();
                cmd.ExecuteNonQuery();
            }
    }
}