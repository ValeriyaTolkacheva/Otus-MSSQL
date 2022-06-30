using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web;
using Newtonsoft.Json.Linq;

namespace HotelsGenerator
{
    public class Program
    {
        static void Main(String[] args)
        {
            if (args.Length == 0)
                Console.WriteLine("Городов для записи отелей нет.");
            foreach (var city in args)
            {
                var hotels = GetHotelsForCity(city).GetAwaiter().GetResult(); ;
                foreach (var hotel in hotels)
                    AddHotel(hotel);
                Console.WriteLine($"В город {city} добавлено {hotels.Count()} отелей");
            }
            Console.WriteLine("Выполнение окончено, для выхода нажмите любую кнопку");
            Console.ReadLine();
        }

        public static async Task<IEnumerable<Hotel>> GetHotelsForCity(String cityName)
        {
            var hotelIds = await GetHotelIdList(cityName);
            var tasks = hotelIds.Select(async id => await GetHotel(id));
            return await Task.WhenAll(tasks);
        }

        public static void AddHotel(Hotel hotel)
        {
            using (SqlConnection connection = new SqlConnection(ConfigurationManager.ConnectionStrings["Generator"].ConnectionString))
                using (SqlCommand cmd = new SqlCommand("[Catalog].AddHotel", connection))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.Add(new SqlParameter("@Name", SqlDbType.NVarChar) { Value = hotel.Name });
                    cmd.Parameters.Add(new SqlParameter("@Description", SqlDbType.NVarChar) { Value = hotel.Description });
                    cmd.Parameters.Add(new SqlParameter("@Star", SqlDbType.TinyInt) { Value = hotel.Star });
                    cmd.Parameters.Add(new SqlParameter("@CityName", SqlDbType.NVarChar) { Value = hotel.CityName });
                    cmd.Parameters.Add(new SqlParameter("@Address", SqlDbType.NVarChar) { Value = hotel.Address });
                    connection.Open();
                    cmd.ExecuteNonQuery();
                }
        }

        public static async Task<IEnumerable<String>> GetHotelIdList(String cityName)
        {
            using (var client = new OstrovokClient())
            {
                client.SetHeaders(@"Host: ostrovok.ru
                                User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0
                                Accept-Language: en-US,en;q=0.5
                                Accept-Encoding: utf-8
                                Accept: application/json, text/plain, */*
                                Sec-Fetch-Dest: empty
                                Sec-Fetch-Mode: cors
                                Sec-Fetch-Site: same-origin
                                TE: trailers");
                var url = $"https://ostrovok.ru/api/site/multicomplete.json?query={HttpUtility.UrlEncode(cityName)}&locale=ru";
                try
                {
                    var strJson = await client.GetStringAsync(url);
                    var jObj = JObject.Parse(strJson);
                    return ((JArray)jObj["hotels"]).Select(token => token["otahotel_id"].Value<String>());
                }
                catch (Exception ex)
                {
                    throw new ApplicationException($"Не удалось получить данные с сайта {url}, ошибка:\n{ex.Message}", ex);
                }
            }
        }

        public static async Task<Hotel> GetHotel(String hotelId)
        {
            using (var client = new OstrovokClient())
            {
                client.SetHeaders(@"Host: ostrovok.ru
                                User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0
                                Accept-Language: en-US,en;q=0.5
                                Accept-Encoding: utf-8
                                Accept: */*
                                Sec-Fetch-Dest: empty
                                Sec-Fetch-Mode: cors
                                Sec-Fetch-Site: same-origin
                                TE: trailers");
                var url = $"https://ostrovok.ru/hotel/search/v2/site/hp/content?lang=ru&hotel={hotelId}";
                try
                {
                    var strJson = await client.GetStringAsync(url);
                    var jObj = JObject.Parse(strJson);
                    var description = "";
                    AllText(jObj["data"]["hotel"]["description_struct"], ref description);
                    return new Hotel
                    {
                        Name = jObj["data"]["hotel"]["name"].Value<String>(),
                        Description = description.Trim(),
                        Star = (Int16)(jObj["data"]["hotel"]["master_id"].Value<Int32>() % 6),
                        CityName = jObj["data"]["hotel"]["city"].Value<String>(),
                        Address = jObj["data"]["hotel"]["address"].Value<String>()
                    };

                }
                catch (Exception ex)
                {
                    throw new ApplicationException($"Не удалось получить данные с сайта {url}, ошибка:\n{ex.Message}", ex);
                }
            }
        }

        public static void AllText(JToken token, ref String text)
        {
            if (token.Type == JTokenType.String)
                text += $"\n{Regex.Replace(token.Value<String>(), "<.*?>", String.Empty)}";
            else
                foreach (var child in token.Children())
                    AllText(child, ref text);
        }
    }
}
