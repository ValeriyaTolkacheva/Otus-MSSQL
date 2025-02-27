Declare @str NVarChar(100) = 'The quick brown fox jumps over the lazy dog'
Declare @pass NVarChar(20) = 'big bad wolf'

Select dbo.Xor(@str, @pass) Xored

Select dbo.Xor(dbo.Xor(@str, @pass), @pass) DoubleXored

Select dbo.PBKDF2_Encrypt(@str, @pass) PBKDF2_Encrypted
Select dbo.PBKDF2_Decrypt(dbo.PBKDF2_Encrypt(@str, @pass), @pass) PBKDF2_Decrypted

Select * 
From dbo.XorTable(@pass)