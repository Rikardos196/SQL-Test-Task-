-- ���������� ������� Agents

INSERT INTO dbo.Agents (Name) VALUES 
	('����� ������� ��������')
	,('��������� ������� ���������')
	,('�������� ������� ��������')
	,('�������� ������� ���������')
	,('������� ������� ����������')
	,('��������� ��������� ������������')
	,('����� ϸ�� ��������')
	,('�������� ���� ���������')
	,('����� ����� ��������')
	,('������� ����� ����������')
	,('������������ ������� ����������')
	,('������ ���� ���������')
	,('����������� �������� ��������')
	,('������� ��� ����������')
	,('���������� ������� �������������')
	,('�������� ������ ��������')
	,('������� ������ �������������')
	,('��������� ������ ��������')
	,('�������� ��������� ����������')
	,('������� ������� ����������')
	,('�������� ���������� ����������')
	,('�������� ������� ���������')
	,('���������� ���� �������������')
	,('�������� ���� ��������')
	,('����������� Ը��� ����������')

-- ��������� ������� Colors

INSERT INTO dbo.Colors (Name) VALUES 
	('�����')
	,('������')
	,('�������')
	,('�������')
	,('�����')

-- ��������� ������� Goods

INSERT INTO dbo.Goods (Name) VALUES 
	('����')
	,('�����')
	,('�������')
	,('��������')
	,('�����')
	,('����')
	,('�����')
	,('�����')
	,('�������')
	,('�����')
	,('�����������')
	,('������')


-- ���������� ������� Orders. �� ������� ������ ���������� �� 10 �� 40 ������� 
-- , �������� ��� ������� �� 2020-01-01 �� 2023-03-31. 
-- ���������� ������� ��������� ������� � ��������� �� �������, ����� ��������� ��������������� ������ �� ���� �������� ������ � ����������� �������
-- , ����� ��������� ������ ��������� �������

CREATE TABLE #tempOrders (
		AgentId INT NOT NULL
	  , CreateDate DATETIME NOT NULL
	  )

DECLARE @Agent SMALLINT;  
DECLARE @Series SMALLINT;
SET @Agent = 1;  
WHILE @Agent <= (SELECT MAX(id) FROM Agents)  
   BEGIN  
	SET @Series = (ABS(CHECKSUM(NEWID()) % 31) + 10) --��������� �� 10 �� 40
	WHILE @Series > 0
	   BEGIN
		INSERT INTO #tempOrders VALUES (@Agent, DATEADD(SECOND, ABS(CHECKSUM(NEWID()) % (60*60*24 - 1) --��� ������� � ������ ��� ���������?
		), DATEADD(DAY, ABS(CHECKSUM(NEWID()) % DATEDIFF(DAY,'01.01.20','31.03.23') 
		), '2020-01-01'))) -- ���������� ���� �� ��������
		SET @Series = @Series - 1
       END;
    SET @Agent = @Agent + 1  
   
   END;  
GO  


INSERT INTO dbo.Orders 
SELECT * 
FROM #tempOrders
ORDER BY CreateDate

-- �������� ���������� ������� �� ������� ������ (�� 10 �� 40 ���):
IF NOT EXISTS (
SELECT AgentId, COUNT(AgentId) as count_orders
FROM Orders 
GROUP BY AgentId
HAVING COUNT(AgentId) > 40 OR COUNT(AgentId) < 10)
PRINT '� ���� ������� �� 10 �� 40 �������'

-- �������� ��� �������� ������� (01.01.2020-31.03.2023):

IF NOT EXISTS (
SELECT CreateDate
FROM Orders 
WHERE CreateDate >= '01-04-23' OR CreateDate < '01-01-20')
PRINT '��� ������ ���� ������� � ������ 01.01.2020-31.03.2023'

-- ������ �� ����� #tempOrders
DROP TABLE if exists #tempOrders


-- ��������� ������� OrderDetails, ��� ������� ������ ������ ���� ��������� �����������
-- , � ������� �� 1 �� 5 ������� ����������� �� ������ ������
-- , � ������ ������ ������ �� ������ ���� ���������� �������.
-- ����� ���-�� ������ ������ � ��������� �� 1 �� 10.


DECLARE @OrdId SMALLINT;  
DECLARE @Series SMALLINT;
DECLARE @IGoods SMALLINT;
SET @OrdId = 1;   
WHILE @OrdId <= (SELECT MAX(id) FROM Orders)  -- ���� �� ������� ID ������
   BEGIN  
	SET @Series = ABS(CHECKSUM(NEWID()) % 5)+1 -- ��������� �������� ������� ����� ����� ������� � ����������� (1-5)
	WHILE @Series > 0
	  BEGIN
	   SET @IGoods = ABS(CHECKSUM(NEWID()) % (select count(*)from goods))+1 -- ��������� �������� �� ������� Goods
	   IF NOT EXISTS (SELECT GoodId FROM dbo.OrderDetails WHERE OrderId = @OrdId AND GoodID = @IGoods) -- �������� ������� ����� �������� ��� � ������� ����������� � ����������� ������
	    INSERT INTO dbo.OrderDetails VALUES (@OrdId, @IGoods, ABS(CHECKSUM(NEWID()) % 10)+1)
		SET @Series = @Series - 1;
	 END;
    SET @OrdId = @OrdId + 1;  
   
   END;  
GO  

-- �������� ���������� ������� � ������ ������ (1-5 ���):

IF NOT EXISTS (
SELECT OrderID, COUNT(GoodId) AS CountGoods
FROM OrderDetails
GROUP BY OrderID
HAVING COUNT(GoodId) < 1 OR COUNT(GoodId) > 5)
PRINT '�� ���� ������� �� 1 �� 5 (������������) �������'

-- �������� ������� ���������� ������� � ������ ������ ������:

IF NOT EXISTS (
SELECT OrderID, COUNT(GoodId) AS QGoodID, COUNT(DISTINCT GoodId) AS UniqueQGoodID
FROM OrderDetails
GROUP BY OrderId
HAVING COUNT(GoodId) != COUNT(DISTINCT GoodId))
PRINT '������ ���'

-- �������� ���-�� ������� � ������ ������:

IF NOT EXISTS (
SELECT OrderID, GoodID, GoodCount
FROM OrderDetails
WHERE GoodCount < 1 OR GoodCount > 10)
PRINT '���-�� ������� � ������ ������ �� 1 �� 10 ���.'


-- ��������� ������� GoodProperties, 
-- ��������� ��� 8 ������������ ������� �� 1 �� 5 ������� ��������� ��������


-- ���������� ������� ��������� ������� � ��������� �� �������, ����� ��������� ��������������� ������ �� ���� 
-- �������� ������ ��������� �������� � ����������� �������, ����� ��������� ������ ��������� �������
-- ������ ��������� ��� ������ ���������� � ������������ ����������� ��� � ������ ������ (��� ���������� �������)

CREATE TABLE #GoodProperties (GoodId int NOT NULL
	  , ColorId int 
	  , BDate datetime NOT NULL
	  , EDate datetime)

DECLARE @SeriesGoods SMALLINT;
DECLARE @SeriesColors SMALLINT;
DECLARE @IColor SMALLINT;
DECLARE @IGoods SMALLINT;
DECLARE @BDate DATETIME;
DECLARE @EDate DATETIME;
SET @SeriesGoods = 0;
WHILE @SeriesGoods < 8
   BEGIN
    SET @IGoods = ABS(CHECKSUM(NEWID()) % (SELECT COUNT(*) FROM Goods))+1 
	IF NOT EXISTS (SELECT GoodId FROM #GoodProperties WHERE GoodID = @IGoods)
	BEGIN 
	SET @SeriesColors = ABS(CHECKSUM(NEWID()) % 5) + 1 
	WHILE @SeriesColors > 0
	   BEGIN
		SET @IColor = ABS(CHECKSUM(NEWID()) % (SELECT COUNT(*) FROM Colors))+1;
		SET @BDate = DATEADD(SECOND, ABS(CHECKSUM(NEWID()) % 86399), DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 1185 ), '2020-01-01'));
		SET @EDate = DATEADD(SECOND, ABS(CHECKSUM(NEWID()) % cast('01.04.23' - @BDate as INT)*86399) , @BDate)
		INSERT INTO #GoodProperties VALUES (@IGoods , @IColor, @BDate, @EDate)
		SET @SeriesColors = @SeriesColors - 1;
	   END
	  SET @SeriesGoods = @SeriesGoods + 1;
	  END
	 ELSE
	  CONTINUE
   END
GO

-- ��������� ������ ��������������� �� ����� ��������� �������� ��������

INSERT INTO dbo.GoodProperties
SELECT * 
FROM #GoodProperties
ORDER BY EDate

-- ����� ��������� ������� �� �����, �������

DROP TABLE #GoodProperties


