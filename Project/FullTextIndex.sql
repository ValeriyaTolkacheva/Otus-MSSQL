Use Hotels

-- Создаем полнотекстовый каталог
CREATE FULLTEXT CATALOG Hotels_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

-- Создаем полнотекстовый индекс на описание гостиницы
CREATE FULLTEXT INDEX ON [Catalog].Hotel([Description] LANGUAGE Russian)
KEY INDEX PK_Hotel -- первичный ключ
ON (Hotels_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, 
  STOPLIST = SYSTEM 
);
GO

 --Заполнчем его
ALTER FULLTEXT INDEX ON [Catalog].Hotel
START FULL POPULATION

--проверяем, что работает
Exec [Catalog].GetHotelsByDescription @SityName = 'Алушта', @Query = N'центральный парк'