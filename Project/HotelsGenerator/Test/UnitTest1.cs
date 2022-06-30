using NUnit.Framework;
using HotelsGenerator;
using System.Linq;

namespace Test
{
    public class Tests
    {
        [Test]
        public void IsGetIds()
        {
            var hotels = Program.GetHotelIdList("Москва").GetAwaiter().GetResult();
            Assert.IsTrue((hotels?.Count() ?? 0) != 0);
        }

        [Test]
        public void ISGetHotel()
        {
            var hotel = Program.GetHotel("otel_izmailovo_beta").GetAwaiter().GetResult();
            Assert.IsTrue(hotel.Name == "Отель Измайлово Бета");
        }

        [Test]
        public void IsGetHotels()
        {
            var hotels = Program.GetHotelsForCity("Москва").GetAwaiter().GetResult();
            Assert.IsTrue((hotels?.Count() ?? 0) != 0);
        }
    }
}