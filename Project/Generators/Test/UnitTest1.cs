using NUnit.Framework;
using System;
using Generators;
using System.Collections.Generic;

namespace Test
{
    public class Tests
    {
        [SetUp]
        public void Setup()
        {
        }

        [Test]
        public void Test1()
        {
            var rand = new Random((Int32)(DateTime.Now.Ticks % Int32.MaxValue));
            var datas = new List<PersonalData>();
            for(var i = 0; i < 10; i++)
                datas.Add(new PersonalData(rand));
            Assert.IsTrue(true);
        }
    }
}