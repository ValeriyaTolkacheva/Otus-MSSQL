using System;

namespace Generators
{
    public class Room
    {
        public Int32 HotelId { get; set; }
        public String Name { get; set; }
        public Decimal Square { get; set; }
        public Int16 MaxQuantityVisitors { get; set; }
        public Int16 LuxDegree { get; set; }
        public Int32 RoomTypeId { get; set; }

        public Room(Int32 hotelId, Int32 roomTypeId, String name, Random random, Int32 coeff = 1)
        {
            HotelId = hotelId;
            RoomTypeId = roomTypeId;
            Name = name;
            MaxQuantityVisitors = (Int16)random.Next(1 * coeff, 5 * coeff);
            Square = random.Next(15, 30) * MaxQuantityVisitors;
            LuxDegree = (Int16)random.Next(1, 6);
        }
    }
}
