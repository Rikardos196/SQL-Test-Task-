-- Запрос выводящий список товаров, у которых на заданную дату не задан цвет

DECLARE @Date DATETIME;

SET @Date = '20221201' 

SELECT *
FROM Goods AS goodsoid
WHERE NOT EXISTS (SELECT *
		FROM GoodProperties
		WHERE @Date BETWEEN BDate and EDate and GoodId = goodsoid.id)

------------------------------------------------------------------------------------

-- Запрос на проверку корректности заведённых данных: 
-- у каждого товара на любом периоде должен быть задан только один цвет. 
-- Вывести товары, у которых есть пересечение периодов действия цвета.

SELECT id
	, goodid
	, colorid
	, bdate
	, edate
	, bbdate AS last_value
	, eedate AS next_value
	, CASE WHEN bbdate IS NULL THEN 'Есть пересечение с ранней записью' WHEN eedate IS NULL THEN 'Есть пересечение с поздней записью' ELSE 'Пересечение с обеих сторон' END AS Result
	FROM (SELECT id, goodid, colorid, bdate, edate, rank
			,LAG(edate) OVER (PARTITION BY RANK ORDER BY bdate) bbdate
			,LEAD(bdate) OVER (PARTITION BY RANK ORDER BY bdate) eedate
		  FROM (SELECT id, goodid, colorid, bdate, edate, DENSE_RANK() OVER (ORDER BY goodid) AS Rank FROM GoodProperties) AS A
		  ) AS ranked_date
WHERE  (eedate BETWEEN bdate AND edate) OR (bbdate BETWEEN bdate AND edate)



--------------------------------------------------------------------------------------


-- Запрос на получение списка агентов, количество заказов у которых за 2022 год более 10


SELECT agentid, Name, count(o.id) QuantityOrders2022
FROM Agents AS a
JOIN Orders o on a.Id=o.AgentId
	WHERE CreateDate>= '20220101 00:00' AND CreateDate< '20230101 00:00' 
GROUP BY agentid, Name
	HAVING COUNT(o.id) > 10


---------------------------------------------------------------------------------------


--	Список агентов, у которых в последнем заказе не было Товара1 Цветом2. 
--  Также указать суммарное количество единиц товаров в этом заказе.

DECLARE @Color varchar(50);
DECLARE @Goods varchar(50);
SET @Color = 'Черный'   -- указать название товара
SET @Goods = 'Стол'     --   

IF NOT EXISTS (SELECT Name FROM Colors WHERE Name = @Color)
PRINT 'Указанного цвета нет в таблице Colors';
IF NOT EXISTS (SELECT Name FROM Goods WHERE Name = @Goods)
PRINT 'Указанного товара нет в таблице Goods';

WITH lastorders (mCreateDate, OrderId, GoodId, GoodCount, agentID) AS
	(
	SELECT mCreateDate, OrderId, GoodId, GoodCount, agentID
	FROM OrderDetails AS od 
	JOIN (SELECT MAX(Id) AS mId, AgentID, MAX(CreateDate) AS mCreateDate
	FROM Orders
	GROUP BY AgentID) AS o ON mId=od.OrderId
	),

	GoodsFilter (GoodId, ColorId, BDate, EDate) AS 
	(
	SELECT GoodId, ColorId, BDate, EDate
	FROM GoodProperties AS gp JOIN Colors AS c ON Colorid=c.id
	JOIN goods AS g ON goodid=g.id
	WHERE g.name = @Goods AND c.name = @Color
    )

SELECT orderID AS LastOrders, agentID, SUM(goodcount) AS TotalGoods
FROM lastorders
GROUP BY orderID, AgentID 
HAVING orderid NOT IN (SELECT OrderId FROM lastorders AS l left 
						JOIN GoodsFilter AS gf ON l.GoodId=gf.GoodId
						WHERE mCreateDate BETWEEN bdate AND edate
						)
ORDER BY agentID


---------------------------------------------------------------------------------------

-- e)	Вывести количество купленных товаров накопительным итогом помесячно за период с 01.01.2023 по 31.03.2023. 
-- Пример: Товар1 был куплен 2 раза в январе, 3 раза в феврале, 1 раз в марте. Результат должен быть следующим


SELECT dtime AS 'Дата', gname AS 'Наименование', SUM(goodCount) AS 'Кол-во в месяце', MAX(total) AS 'Итог'
FROM (SELECT OrderId
		, GoodId
		, GoodCount
		, EOMONTH(CreateDate) AS dtime
		, g.name AS gname
		, SUM(GoodCount) OVER (PARTITION BY goodid ORDER BY g.name,EOMONTH(CreateDate) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total 
		FROM OrderDetails AS od
		JOIN Orders AS o ON OrderId=o.Id
		JOIN Goods AS g ON GoodId=g.Id) AS a
GROUP BY gname, dtime
HAVING gname = 'Зеркало' -- Тут указать интересующий товар, если фильтр по товару не нужен, то запуск скрипта без этой строки
