using System;
using System.Data.SqlTypes;
using System.IO;
using System.Text.RegularExpressions;
using Microsoft.SqlServer.Server;

namespace OtusClrSql
{
    [Serializable]
    [SqlUserDefinedType(Format.UserDefined,
                        IsByteOrdered = true,
                        IsFixedLength = false,
                        MaxByteSize = 5)]
    public class IPv4 : INullable, IBinarySerialize
    {
        // храним данных
        private Byte?[] _ipArr;

        // работа с пользователем, валидация
        public SqlString Ip
        {
            get 
            {
                return IsNull ? new SqlString() : new SqlString(String.Join(".", _ipArr));
            }
            set
            {
                if (value == SqlString.Null)
                {
                    _ipArr = null;
                    return;
                }
                var match = Regex.Match(value.Value, @"^(((?<num>25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))\.){3}(?<num>25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");
                if (match?.Success ?? false && match.Groups["num"]?.Captures.Count == 4)
                {
                    _ipArr = new Byte?[4];
                    for (var i = 0; i < 4; i++)
                        _ipArr[i] = Convert.ToByte(match.Groups["num"]?.Captures[i].Value);
                }
                else
                {
                    throw new ArgumentException("IPv4 address must be [0-255].[0-255].[0-255].[0-255]");
                }
            }
        }

        public override string ToString()
        {
            return Ip.IsNull ? String.Empty : Ip.Value;
        }

        //работа с Null
        public Boolean IsNull 
            => _ipArr == null; 

        public static IPv4 Null
        {
            get 
            {
                var ip = new IPv4();
                ip._ipArr = null;
                return ip;
            }
        }

        //инициализация через String
        public static IPv4 Parse(SqlString str)
        {
            if (str.IsNull)
                return Null;
            var ip = new IPv4();
            ip.Ip = str;
            return ip;
        }

        //сериализация типа
        public void Read(BinaryReader reader)
        {
            if (reader.ReadBoolean())//не пустое
            {
                _ipArr = new Byte?[4];
                for (var i = 0; i < 4; i++)
                    _ipArr[i] = reader.ReadByte();
            }
        }

        public void Write(BinaryWriter writer)
        {
            var notNull = !IsNull;
            writer.Write(notNull);
            if (notNull)//не пустое
                for (var i = 0; i < 4; i++)
                    writer.Write(_ipArr[i].Value);
        }
    }
}
