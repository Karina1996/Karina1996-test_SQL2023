
--проверка в MS SQL Server	v.19  
CREATE DATABASE ИМ2023_4
go
USE ИМ2023_4;

																		--СВЯЗЬ 1-N: у одной категории N подкатегорий  (self join)
CREATE TABLE Категории (
    Код int PRIMARY KEY identity(1,1),									--PK (not null + unique) с автоинкрементом
    Наименование text not null,
	Активность char(1) default '1',										--по умолчанию '1'
	РодительКод int														--по умолчанию is null значит нет родителя
);

CREATE TABLE Производители (
    Код int PRIMARY KEY identity(1,1),
    Наименование text not null,
	Активность char(1) default '1'
);

CREATE TABLE Продукты (
    Код int PRIMARY KEY identity(1,1),
    Наименование nvarchar(255) not null,
	Описание text,
	ФайлURL nvarchar(255),
	Активность char(1) default '1',
	Количество int check (Количество >= 0),								--простой учет товаров, кол-во не может быть отрицательным
	ЦенаРуб decimal(16,2) not null check (ЦенаРуб > 0),     			--без скидки, допустим, у нас не будет продуктов с нулевой стоимостью 
	ПроцентСкидки float,
	ПроизводительКод int FOREIGN KEY REFERENCES Производители(Код),		--СВЯЗЬ 1-N: один производитель ПРОИЗВОДИТ N продуктов
	КатегорияКод int FOREIGN KEY REFERENCES Категории(Код)				--СВЯЗЬ 1-N: одна категория СОДЕРЖИТ N продуктов
);

CREATE TABLE Справочники (	   
    Код int PRIMARY KEY identity(1,1), 	
    РодительКод int, 													--код родительской группы
    СтрокаКод int, 														--код внутри родительской группы
    Тип nvarchar(55) not null,
	Описание nvarchar(255) not null, 
	Параметр nvarchar(max),											    --любой текстовый объект
	Активность char(1) default '1', 
	--constraint comb_PK PRIMARY KEY(РодительКод, СтрокаКод)		    --ох, не поняла, почему не работает в MS Server  
);	

CREATE TABLE Магазины (	
    Код int PRIMARY KEY identity(1,1), 
    Наименование text not null,
	СубьектРФ nvarchar(25) not null default 'Рег',	
	Адрес nvarchar(255) not null,
	Телефон text not null,  												
	Активность char(1) default '1',
	РодительСправ_ГрафикКод int FOREIGN KEY REFERENCES Справочники(Код)	 --СВЯЗЬ 1-N: N графиков ОТНОСЯТСЯ к одному магазину (или N-N, тогда нужна связывающая таблица)
);

CREATE TABLE Должности (	
    Код int PRIMARY KEY identity(1,1), 
    Наименование text not null,
	ОкладПоМскРуб decimal(16,2) check (ОкладПоМскРуб >= 16242.00),		 --допустим, не может быть меньше МРОТ
	Активность char(1) default '1'
);

CREATE TABLE Сотрудники (	
    Код int PRIMARY KEY identity(1,1), 
    ФИО text not null,
	ГодРождения date, 
	ТипТрудоустройства nvarchar(10),									--если предусмотрено несколько вариантов 
	ДатаПриема date not null, 
	ДатаУвольнения date, 
	ДолжностьКод int FOREIGN KEY REFERENCES Должности(Код),				--СВЯЗЬ 1-N: одну должность ЗАНИМАЮТ N сотрудников (исключила замещение одним сотрудником N должностей)
	МагазинКод int FOREIGN KEY REFERENCES Магазины(Код)					--СВЯЗЬ N-1: N сотрудников РАБОТАЮТ в одном магазине
);
			
CREATE TABLE Пользователи (															
    Код int PRIMARY KEY identity(1,1), 
    ФИО nvarchar(55) not null,
	Телефон nvarchar(25), 
	Email nvarchar(25), 
	Пароль nvarchar(16),											
	Подписка char(1) default '1',												
);

CREATE TABLE КорзинаПродуктов (															
    Код int PRIMARY KEY identity(1,1), 	 
	ПродуктКод int FOREIGN KEY REFERENCES Продукты(Код),			   -- СВЯЗЬ N-N: пользователь ДОБАВЛЯЕТ N продуктов, а каждый продукт можно ПОЛОЖИТЬ N пользователями	
	Количество int not null,	
	Сумма decimal(16,2) not null										
);

CREATE TABLE КорзинаПользователей (															
    Код int PRIMARY KEY identity(1,1), 	 								--не обязателен, можно сделать primary key(КорзинаКод, ПользовательКод)
	КорзинаКод int FOREIGN KEY REFERENCES КорзинаПродуктов(Код),	    --ДВЕ СВЯЗИ 1-1: одна корзина, один пользователь (по идее, если связывающая таблица, то получается, что-то типа составного ключа..)
	ПользовательКод int FOREIGN KEY REFERENCES Пользователи(Код),
);

CREATE TABLE Клиенты (													
    Код int PRIMARY KEY identity(1,1), 
    Наименование nvarchar(150) not null,
	Телефон nvarchar(25), 
	Тип nvarchar(25),												   					
	ДоговорКод int														--для физ. и юр. лиц						   
);

CREATE TABLE Заказы (	   
    Код int PRIMARY KEY identity(1,1), 
	ДатаВремя datetime not null,											
	Сумма decimal(16,2) not null check (Сумма > 0),
	Комментарий	nvarchar(150),
	КлиентКод int FOREIGN KEY REFERENCES Клиенты(Код),				     --СВЯЗЬ 1-N: один клиент может оформить N заказов, но заказ может быть оформлен одним клиентом 
	МагазинКод int FOREIGN KEY REFERENCES Магазины(Код),			     --СВЯЗЬ N-1: N заказов ПОСТУПАЕТ в один магазин
	СотрудникКод int FOREIGN KEY REFERENCES Сотрудники(Код),		     --СВЯЗЬ 1-N: один сотрудник ОБРАБАТЫВАЕТ N заказов (например, менеджер)
	СтрокаКодСправ_Доставка int FOREIGN KEY REFERENCES Справочники(Код),  
	СтрокаКодСправ_СтатусОплаты int FOREIGN KEY REFERENCES Справочники(Код),		
	СтрокаКодСправ_СтатусЗаказа int FOREIGN KEY REFERENCES Справочники(Код),
	ЧекКод int														  
);

CREATE TABLE СоставЗаказа (	   
    Код int PRIMARY KEY identity(1,1), 
	ЗаказКод int FOREIGN KEY REFERENCES Заказы(Код),					  
	ПродуктКод int FOREIGN KEY REFERENCES Продукты(Код),  				  
	Количество int not null,	
	ЦенаРуб decimal(16,2) not null											  --не учли список валют (документации может не быть, по названию сразу понятно)
);

CREATE TABLE ДоставкаЗаказа (	   
    Код int PRIMARY KEY identity(1,1),
	ЗаказКод int FOREIGN KEY REFERENCES Заказы(Код),
	ДатаВремя datetime not null,												  --например, доставить 07.05 в 10:00
	ПунктДоставки nvarchar(512), 
	ПериодНачала datetime,												  --начал в 9:00 (можно ставить статус: у курьера)
	ПериодЗавершения datetime,											  --еще не завершил	=> null (курьер не информировал, что заказ доставлен)
	СотрудникКод int FOREIGN KEY REFERENCES Сотрудники(Код),			  --СВЯЗЬ 1-N: один сотрудник ДОСТАВЛЯЕТ N заказов (пешие курьеры, водители, если будет доставка дронами => можно пометить как "робот")
	СтрокаКодСправ_СтатусДоставки int FOREIGN KEY REFERENCES Справочники(Код)
);

CREATE TABLE Рейтинг (	   
    Код int PRIMARY KEY identity(1,1), 
	ДатаВремя datetime not null,
	Оценка decimal(2, 1),																													
	РодительКодСправ_Рейтинг int FOREIGN KEY REFERENCES Справочники(Код),		
	ЗаказКод int FOREIGN KEY REFERENCES Заказы(Код)						  --СВЯЗЬ 1-N: один заказ ОЦЕНИВАЮТ N раз (так как несколько вопросов по разным категориям - сохраняет каждую оценку)
);


--в реальных условиях всё учесть проектировщику, разработчику, администратору БД сложно, поэтому,
-- в существующую БД можно со временем, например: 
--добавлять таблицы: "Департаменты", "Элементы подкатегорий", "Параметры продукта", "Избранное",  "Договора",
--				"Платежи", "Складкой учет", "Учет продаж" и т.д.
-- изменять структуру таблиц, накладывать ограничения, управлять доступами и т.д.

