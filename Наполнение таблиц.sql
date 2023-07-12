-- Наполнение таблицы Agents

INSERT INTO dbo.Agents (Name) VALUES 
	('Попов Дмитрий Олегович')
	,('Жуковский Василий Андреевич')
	,('Борисова Татьяна Олеговна')
	,('Журавлев Евгений Михалович')
	,('Гумилев Николай Степанович')
	,('Ходасевич Владислав Фелицианович')
	,('Ершов Пётр Павлович')
	,('Тургенев Иван Сергеевич')
	,('Чехов Антон Павлович')
	,('Давыдов Денис Васильевич')
	,('Чернышевский Николай Гаврилович')
	,('Шмелев Иван Сергеевич')
	,('Данилевский Григорий Петрович')
	,('Толстой Лев Николаевич')
	,('Добролюбов Николай Александрович')
	,('Цветаева Марина Ивановна')
	,('Шолохов Михаил Александрович')
	,('Чуковский Корней Иванович')
	,('Дружинин Александр Васильевич')
	,('Толстой Алексей Николаевич')
	,('Бальмонт Константин Дмитриевич')
	,('Державин Гавриил Романович')
	,('Меркурьева Вера Александровна')
	,('Новицкая Вера Сергеева')
	,('Достоевский Фёдор Михайлович')

-- Наполняем таблицу Colors

INSERT INTO dbo.Colors (Name) VALUES 
	('Белый')
	,('Черный')
	,('Красный')
	,('Зеленый')
	,('Синий')

-- Наполняем таблицу Goods

INSERT INTO dbo.Goods (Name) VALUES 
	('Стол')
	,('Диван')
	,('Табурет')
	,('Карандаш')
	,('Ведро')
	,('Кран')
	,('Дверь')
	,('Комод')
	,('Зеркало')
	,('Полка')
	,('Выключатель')
	,('Коврик')


-- Наполнение таблицы Orders. На каждого агента приходится от 10 до 40 заказов 
-- , диапазон дат заказов от 2020-01-01 по 2023-03-31. 
-- Изначально создаем временную таблицу и наполняем ее данными, далее переносим отсортированные данные по дате создания заказа в действующую таблицу
-- , чтобы сохранить логику нумерации заказов

CREATE TABLE #tempOrders (
		AgentId INT NOT NULL
	  , CreateDate DATETIME NOT NULL
	  )

DECLARE @Agent SMALLINT;  
DECLARE @Series SMALLINT;
SET @Agent = 1;  
WHILE @Agent <= (SELECT MAX(id) FROM Agents)  
   BEGIN  
	SET @Series = (ABS(CHECKSUM(NEWID()) % 31) + 10) --генерация от 10 до 40
	WHILE @Series > 0
	   BEGIN
		INSERT INTO #tempOrders VALUES (@Agent, DATEADD(SECOND, ABS(CHECKSUM(NEWID()) % (60*60*24 - 1) --это секунды в сутках как посчитали?
		), DATEADD(DAY, ABS(CHECKSUM(NEWID()) % DATEDIFF(DAY,'01.01.20','31.03.23') 
		), '2020-01-01'))) -- Генерируем дату со временем
		SET @Series = @Series - 1
       END;
    SET @Agent = @Agent + 1  
   
   END;  
GO  


INSERT INTO dbo.Orders 
SELECT * 
FROM #tempOrders
ORDER BY CreateDate

-- Проверка количества заказов на каждого агента (от 10 до 40 вкл):
IF NOT EXISTS (
SELECT AgentId, COUNT(AgentId) as count_orders
FROM Orders 
GROUP BY AgentId
HAVING COUNT(AgentId) > 40 OR COUNT(AgentId) < 10)
PRINT 'У всех агентов от 10 до 40 заказов'

-- Проверка дат создания заказов (01.01.2020-31.03.2023):

IF NOT EXISTS (
SELECT CreateDate
FROM Orders 
WHERE CreateDate >= '01-04-23' OR CreateDate < '01-01-20')
PRINT 'Все заказы были созданы в период 01.01.2020-31.03.2023'

-- теперь не нужна #tempOrders
DROP TABLE if exists #tempOrders


-- Наполняем таблицу OrderDetails, для каждого заказа должна быть заполнена детализация
-- , в которой от 1 до 5 строчек ссылающихся на разные товары
-- , в рамках одного заказа не должно быть одинаковых товаров.
-- Также кол-во единиц товара в диапазоне от 1 до 10.


DECLARE @OrdId SMALLINT;  
DECLARE @Series SMALLINT;
DECLARE @IGoods SMALLINT;
SET @OrdId = 1;   
WHILE @OrdId <= (SELECT MAX(id) FROM Orders)  -- Цикл по каждому ID заказа
   BEGIN  
	SET @Series = ABS(CHECKSUM(NEWID()) % 5)+1 -- Генерация значения сколько строк будет создано в детализации (1-5)
	WHILE @Series > 0
	  BEGIN
	   SET @IGoods = ABS(CHECKSUM(NEWID()) % (select count(*)from goods))+1 -- Генерация продукта из таблицы Goods
	   IF NOT EXISTS (SELECT GoodId FROM dbo.OrderDetails WHERE OrderId = @OrdId AND GoodID = @IGoods) -- Проверка наличия этого продукта уже в таблице детализации в наполняемом заказе
	    INSERT INTO dbo.OrderDetails VALUES (@OrdId, @IGoods, ABS(CHECKSUM(NEWID()) % 10)+1)
		SET @Series = @Series - 1;
	 END;
    SET @OrdId = @OrdId + 1;  
   
   END;  
GO  

-- Проверка количества товаров в каждом заказе (1-5 вкл):

IF NOT EXISTS (
SELECT OrderID, COUNT(GoodId) AS CountGoods
FROM OrderDetails
GROUP BY OrderID
HAVING COUNT(GoodId) < 1 OR COUNT(GoodId) > 5)
PRINT 'Во всех заказах от 1 до 5 (включительно) товаров'

-- Проверка наличия одинаковых товаров в рамках одного заказа:

IF NOT EXISTS (
SELECT OrderID, COUNT(GoodId) AS QGoodID, COUNT(DISTINCT GoodId) AS UniqueQGoodID
FROM OrderDetails
GROUP BY OrderId
HAVING COUNT(GoodId) != COUNT(DISTINCT GoodId))
PRINT 'Дублей нет'

-- Проверка кол-ва товаров в каждой строке:

IF NOT EXISTS (
SELECT OrderID, GoodID, GoodCount
FROM OrderDetails
WHERE GoodCount < 1 OR GoodCount > 10)
PRINT 'Кол-во товаров в каждой строке от 1 до 10 вкл.'


-- Наполняем таблицу GoodProperties, 
-- Создается для 8 произвольных товаров от 1 до 5 записей изменения свойства


-- Изначально создаем временную таблицу и наполняем ее данными, далее переносим отсортированные данные по дате 
-- создания записи изменения свойства в действующую таблицу, чтобы сохранить логику нумерации записей
-- Шаблон генерации дат сделан специально с возможностью пересечения дат в рамках товара (для дальнейших заданий)

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

-- Переносим данные отсортированные по датам окончания действия свойства

INSERT INTO dbo.GoodProperties
SELECT * 
FROM #GoodProperties
ORDER BY EDate

-- Далее временная таблица не нужна, удаляем

DROP TABLE #GoodProperties


