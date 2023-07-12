--C������� ������ �������� ������������ �����
-- �������� ������� ������


CREATE TABLE Agents
   (
      Id int NOT NULL IDENTITY (1, 1)
	  , [Name] nvarchar(50) NOT NULL
	  , CONSTRAINT PK_Agents PRIMARY KEY CLUSTERED (Id)
   )


-- �������� ������� ������

CREATE TABLE Goods 
   (
      Id int NOT NULL IDENTITY (1, 1)
	  , [Name] nvarchar(30) NOT NULL
      , CONSTRAINT PK_Goods PRIMARY KEY CLUSTERED (Id)
    )


-- �������� ������� ������
-- ������� ���� �� ������� AgentID ������� �� ������� ID ������� Agents


CREATE TABLE Orders
   (
      Id int NOT NULL IDENTITY (1, 1)
	  , AgentId int NOT NULL
	  , CreateDate datetime NOT NULL
	  , CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (Id)
	  , CONSTRAINT FK_Orders_Agents FOREIGN KEY (AgentId)
        REFERENCES Agents (Id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
   )


-- �������� ������� �����


CREATE TABLE Colors 
   (
      Id int NOT NULL IDENTITY (1, 1)
	  , [Name] nvarchar(30) NOT NULL
      , CONSTRAINT PK_Colors PRIMARY KEY CLUSTERED (Id)
    )


-- �������� ������� ����������� �������
-- ������� ���� �� ������� GoodID ������� �� ������� ID ������� Goods
-- ������� ���� �� ������� OrderID ������� �� ������� ID ������� Orders


CREATE TABLE OrderDetails
   (
      Id int NOT NULL IDENTITY (1, 1)
	  , OrderId int NOT NULL
	  , GoodId int NOT NULL
	  , GoodCount int NOT NULL
      , CONSTRAINT PK_OrderDetails PRIMARY KEY CLUSTERED (Id)
      , CONSTRAINT FK_OrderDetails_Goods FOREIGN KEY (GoodId)
        REFERENCES Goods (Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
	  , CONSTRAINT FK_OrderDetails_Orders FOREIGN KEY (OrderId)
        REFERENCES Orders (Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
   )


-- �������� ������� �������� �������
-- ������� ���� �� ������� GoodID ������� �� ������� ID ������� Goods
-- ������� ���� �� ������� ColorID ������� �� ������� ID ������� Colors


CREATE TABLE GoodProperties
   (
      Id int NOT NULL IDENTITY (1, 1)
	  , GoodId int NOT NULL
	  , ColorId int 
	  , BDate datetime NOT NULL
	  , EDate datetime
      , CONSTRAINT PK_GoodProperties PRIMARY KEY CLUSTERED (Id)
      , CONSTRAINT FK_GoodProperties_Goods FOREIGN KEY (GoodId)
        REFERENCES Goods (Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
	  , CONSTRAINT FK_GoodProperties_Colors FOREIGN KEY (ColorId)
        REFERENCES Colors (Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
   )