using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Linq;
using Microsoft.SqlServer.Server;
using System.Data.SqlClient;

namespace OtusClrSql
{
    public class Encryption
    {
        #region Functions
        // Скалярные функция
        [SqlFunction]
        public static SqlString Xor(SqlString str, SqlString password)
        {
            var strBytes = Encoding.UTF8.GetBytes(str.Value);
            var passwordBytes = Encoding.UTF8.GetBytes(password.Value);
            for (var i = 0; i < strBytes.Length; i++)
                strBytes[i] ^= passwordBytes[i % passwordBytes.Length];
            var result = new SqlString(Encoding.UTF8.GetString(strBytes));
            return result;
        }

        [SqlFunction]
        public static SqlString PBKDF2_Encrypt(SqlString str, SqlString password)
        {
            var result = new SqlString(StringCipher.Encrypt(str.Value, password.Value));
            return result;
        }

        [SqlFunction]
        public static SqlString PBKDF2_Decrypt(SqlString str, SqlString password)
        {
            var result = new SqlString(StringCipher.Decrypt(str.Value, password.Value));
            return result;
        }

        // Табличная функция
        [SqlFunction(TableDefinition = "Original NVarChar(max), Xor NVarChar(max), DoubleXor NVarChar(max)", 
            FillRowMethodName = "MakeRow", DataAccess = DataAccessKind.Read)]
        public static System.Collections.IEnumerable XorTable(SqlString password)
        {
            var result = new List<Object[]>();
            using (SqlConnection connection = new SqlConnection("context connection=true"))
            using (SqlCommand cmd = new SqlCommand("Select top 10 [StockItemName], " +
                                                                    "dbo.Xor([StockItemName], @Password), " +
                                                                    "dbo.Xor(dbo.Xor([StockItemName], @Password), @Password) " +
                                                                    "From [Warehouse].[StockItems]", connection))
            {
                cmd.Parameters.AddWithValue("Password", password);
                connection.Open();
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var row = new Object[3];
                        row[0] = new SqlString(reader.GetString(0));
                        row[1] = new SqlString(reader.GetString(1));
                        row[2] = new SqlString(reader.GetString(2));
                        result.Add(row);
                    }
                }
            }
            return result;
        }
        #endregion

        #region Methods
        public static void MakeRow(Object obj, out SqlString original, out SqlString xor, out SqlString doubleXor)
        {
            var row = obj as object[];
            original = (SqlString)row[0];
            xor = (SqlString)row[1];
            doubleXor = (SqlString)row[2];
        }
        #endregion


        #region PrivateClass
        private static class StringCipher
        {
            // This constant is used to determine the keysize of the encryption algorithm in bits.
            // We divide this by 8 within the code below to get the equivalent number of bytes.
            private const int Keysize = 256;

            // This constant determines the number of iterations for the password bytes generation function.
            private const int DerivationIterations = 1000;

            public static string Encrypt(string plainText, string passPhrase)
            {
                // Salt and IV is randomly generated each time, but is preprended to encrypted cipher text
                // so that the same Salt and IV values can be used when decrypting.  
                var saltStringBytes = Generate256BitsOfRandomEntropy();
                var ivStringBytes = Generate256BitsOfRandomEntropy();
                var plainTextBytes = Encoding.UTF8.GetBytes(plainText);
                using (var password = new Rfc2898DeriveBytes(passPhrase, saltStringBytes, DerivationIterations))
                {
                    var keyBytes = password.GetBytes(Keysize / 8);
                    using (var symmetricKey = new RijndaelManaged())
                    {
                        symmetricKey.BlockSize = 256;
                        symmetricKey.Mode = CipherMode.CBC;
                        symmetricKey.Padding = PaddingMode.PKCS7;
                        using (var encryptor = symmetricKey.CreateEncryptor(keyBytes, ivStringBytes))
                        {
                            using (var memoryStream = new MemoryStream())
                            {
                                using (var cryptoStream = new CryptoStream(memoryStream, encryptor, CryptoStreamMode.Write))
                                {
                                    cryptoStream.Write(plainTextBytes, 0, plainTextBytes.Length);
                                    cryptoStream.FlushFinalBlock();
                                    // Create the final bytes as a concatenation of the random salt bytes, the random iv bytes and the cipher bytes.
                                    var cipherTextBytes = saltStringBytes;
                                    cipherTextBytes = cipherTextBytes.Concat(ivStringBytes).ToArray();
                                    cipherTextBytes = cipherTextBytes.Concat(memoryStream.ToArray()).ToArray();
                                    memoryStream.Close();
                                    cryptoStream.Close();
                                    return Convert.ToBase64String(cipherTextBytes);
                                }
                            }
                        }
                    }
                }
            }

            public static string Decrypt(string cipherText, string passPhrase)
            {
                // Get the complete stream of bytes that represent:
                // [32 bytes of Salt] + [32 bytes of IV] + [n bytes of CipherText]
                var cipherTextBytesWithSaltAndIv = Convert.FromBase64String(cipherText);
                // Get the saltbytes by extracting the first 32 bytes from the supplied cipherText bytes.
                var saltStringBytes = cipherTextBytesWithSaltAndIv.Take(Keysize / 8).ToArray();
                // Get the IV bytes by extracting the next 32 bytes from the supplied cipherText bytes.
                var ivStringBytes = cipherTextBytesWithSaltAndIv.Skip(Keysize / 8).Take(Keysize / 8).ToArray();
                // Get the actual cipher text bytes by removing the first 64 bytes from the cipherText string.
                var cipherTextBytes = cipherTextBytesWithSaltAndIv.Skip((Keysize / 8) * 2).Take(cipherTextBytesWithSaltAndIv.Length - ((Keysize / 8) * 2)).ToArray();

                using (var password = new Rfc2898DeriveBytes(passPhrase, saltStringBytes, DerivationIterations))
                {
                    var keyBytes = password.GetBytes(Keysize / 8);
                    using (var symmetricKey = new RijndaelManaged())
                    {
                        symmetricKey.BlockSize = 256;
                        symmetricKey.Mode = CipherMode.CBC;
                        symmetricKey.Padding = PaddingMode.PKCS7;
                        using (var decryptor = symmetricKey.CreateDecryptor(keyBytes, ivStringBytes))
                        {
                            using (var memoryStream = new MemoryStream(cipherTextBytes))
                            {
                                using (var cryptoStream = new CryptoStream(memoryStream, decryptor, CryptoStreamMode.Read))
                                {
                                    var plainTextBytes = new byte[cipherTextBytes.Length];
                                    var decryptedByteCount = cryptoStream.Read(plainTextBytes, 0, plainTextBytes.Length);
                                    memoryStream.Close();
                                    cryptoStream.Close();
                                    return Encoding.UTF8.GetString(plainTextBytes, 0, decryptedByteCount);
                                }
                            }
                        }
                    }
                }
            }

            private static byte[] Generate256BitsOfRandomEntropy()
            {
                var randomBytes = new byte[32]; // 32 Bytes will give us 256 bits.
                using (var rngCsp = new RNGCryptoServiceProvider())
                {
                    // Fill the array with cryptographically secure random bytes.
                    rngCsp.GetBytes(randomBytes);
                }
                return randomBytes;
            }
        }
        #endregion
    }
}