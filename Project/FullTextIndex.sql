Use Hotels

-- ������� �������������� �������
CREATE FULLTEXT CATALOG Hotels_FT_Catalog
WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

-- ������� �������������� ������ �� �������� ���������
CREATE FULLTEXT INDEX ON [Catalog].Hotel([Description] LANGUAGE Russian)
KEY INDEX PK_Hotel -- ��������� ����
ON (Hotels_FT_Catalog)
WITH (
  CHANGE_TRACKING = AUTO, 
  STOPLIST = SYSTEM 
);
GO

 --��������� ���
ALTER FULLTEXT INDEX ON [Catalog].Hotel
START FULL POPULATION

--���������, ��� ��������
Exec [Catalog].GetHotelsByDescription @SityName = '������', @Query = N'����������� ����'