using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using Microsoft.SqlServer.Server;

namespace OtusClrSql
{
    //медиана
    //число из середины отсортированного массива
    [Serializable]
    [SqlUserDefinedAggregate(Format.UserDefined, 
                                MaxByteSize = -1)]
    public struct Median : IBinarySerialize
    {
        private Int32 _numValues;
        private SortedDictionary<SqlInt32, Int32> _values;

        public void Init()
        {
            _numValues = 0;
            _values = new SortedDictionary<SqlInt32, Int32>();
        }

        public void Accumulate(SqlInt32 value)
        {
            if (!value.IsNull)
            {
                _numValues++;
                if (_values.ContainsKey(value))
                    _values[value]++;
                else
                    _values.Add(value, 1);
            }
        }

        public void Merge(Median group)
        {
            _numValues += group._numValues;
            if (group._values.Count > 0)
                foreach(var pair in group._values)
                    if (_values.ContainsKey(pair.Key))
                        _values[pair.Key] += pair.Value;
                    else
                        _values.Add(pair.Key, pair.Value);
        }

        public SqlInt32 Terminate()
        {
            var expectedCount = _numValues / 2;
            var count = 0;
            if (_values != null)
                foreach (var pair in _values)
                {
                    count += pair.Value;
                    if (count >= expectedCount)
                        return pair.Key;
                }
            return SqlInt32.Null;
        }

        public void Read(BinaryReader reader)
        {
            _numValues = reader.ReadInt32();
            _values = new SortedDictionary<SqlInt32, int>();
            if (_numValues != 0)
            {
                var count = reader.ReadInt32();
                for (var i = 0; i < count; i++)
                {
                    var key = reader.ReadInt32();
                    var value = reader.ReadInt32();
                    _values.Add(new SqlInt32(key), value);
                }
            }
        }

        public void Write(BinaryWriter writer)
        {
            writer.Write(_numValues);
            if (_numValues != 0)
            {
                writer.Write(_values.Count);
                foreach (var pair in _values)
                {
                    writer.Write(pair.Key.Value);
                    writer.Write(pair.Value);
                }
            }
        }
    }
}