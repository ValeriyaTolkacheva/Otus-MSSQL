using System;

namespace Generators
{
    public class Staff
    {
        public PersonalData PersonalData { get; set; }
        public Int32 StaffTypeId { get; set; }
        public Int32 HotelId { get; set; }

        public Staff(Int32 staffTypeId, Int32 hotelId, Random random)
        {
            PersonalData = new PersonalData(random);
            StaffTypeId = staffTypeId;
            HotelId = hotelId;
        }
    }
}