-- Sophia Masone
-- Relational Database Project
-- 5/6/2025

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP VIEW IF EXISTS ClothesDetails;
DROP VIEW IF EXISTS FurnitureDetails;
DROP VIEW IF EXISTS ValidPlayers;

DROP TABLE IF EXISTS Bans;
DROP TABLE IF EXISTS Reports;
DROP TABLE IF EXISTS EarnedStamps;
DROP TABLE IF EXISTS Stamps;
DROP TABLE IF EXISTS Highscores;
DROP TABLE IF EXISTS Minigames;
DROP TABLE IF EXISTS PetPuffles;
DROP TABLE IF EXISTS Puffles;
DROP TABLE IF EXISTS FurnitureInventory;
DROP TABLE IF EXISTS Furniture;
DROP TABLE IF EXISTS ClothesInventory;
DROP TABLE IF EXISTS Clothes;
DROP TABLE IF EXISTS ItemAvailability;
DROP TABLE IF EXISTS Items;
DROP TABLE IF EXISTS Catalogs;
DROP TABLE IF EXISTS Rooms;
DROP TABLE IF EXISTS Parties;
DROP TABLE IF EXISTS Players;


--------------------
-- Table Creation --
--------------------

CREATE TABLE Players (
	playerID char(10)    not null unique,
	username text        not null unique,
	userPassword text    not null,
	email text           not null unique,
	joinDate timestamp   not null,
	isVerified boolean   not null,
	isMember boolean     not null,
  primary key(playerID)
);

CREATE TABLE Parties (
	partyID int          not null unique,
	partyName text       not null,
	startDate timestamp  not null,
	endDate timestamp    not null,
  primary key(partyID)
);

CREATE TABLE Rooms (
	roomID int       not null unique,
	roomName text    not null unique,
	maxCapacity int  not null,
  primary key(roomID)
);

CREATE TABLE Catalogs (
	catalogID int      not null unique,
	catalogName text   not null unique,
	roomID int         references Rooms(roomID),
  primary key(catalogID)
);

CREATE TABLE Items (
	itemID int           not null unique,
	itemName text        not null unique,
	priceCoins int,
	isMemberItem boolean not null,
  primary key(itemID)
);

CREATE TABLE ItemAvailability (
	itemID int       not null references Items(itemID),
	startDate date   not null,
	endDate date,
	catalogID int    references Catalogs(catalogID),
	roomID int       references Rooms(roomID)
	                 CHECK (catalogID is not null or roomID is not null),
  primary key(itemID, startDate)
);

CREATE TABLE Clothes (
	clothesID int      not null unique references Items(itemID),
	clothesType text   not null 
	                   CHECK(lower(clothesType) in ('head', 'face', 'neck', 'body', 'feet', 'hand', 'color', 'background', 'pin')),
  primary key(clothesID)
);

CREATE TABLE ClothesInventory (
	playerID char(10)    not null references Players(playerID),
	clothesID int        not null references Clothes(clothesID),
	isEquipped boolean   default FALSE,
  primary key(playerID, clothesID)
);

CREATE TABLE Furniture (
	furnitureID int      not null unique references Items(itemID),
	furnitureType text   not null 
	                     CHECK(lower(furnitureType) in ('wall', 'room', 'floor', 'pet')),
  primary key(furnitureID)
);

CREATE TABLE FurnitureInventory (
	playerID char(10)   not null references Players(playerID),
	furnitureID int     not null references Furniture(furnitureID),
	qtyOwned int        not null,
	numPlaced int       default 0, 
	CHECK(numPlaced <= qtyOwned),
  primary key(playerID, furnitureID)
);

CREATE TABLE Puffles (
	puffleID int       not null unique references Items(itemID),
	favoriteToy text,
	speed text,
  primary key(puffleID)
);

CREATE TABLE PetPuffles (
	petID int             not null unique,
	playerID char(10)     not null references Players(playerID),
	puffleID int          not null references Puffles(puffleID),
	puffleName text       not null,
	adoptDate timestamp   not null,
  primary key(petID)
);

CREATE TABLE Minigames (
	gameID int      not null unique,
	gameName text   not null unique,
	roomID int      not null references Rooms(roomID),
  primary key(gameID)
);

CREATE TABLE Highscores (
	playerID char(10)      not null references Players(playerID),
	gameID int             not null references Minigames(gameID),
	score int              not null,
	dateScored timestamp   not null,
  primary key(playerID, gameID)
);

CREATE TABLE Stamps (
	stampID int       not null unique,
	stampName text    not null unique,
	category text     not null 
	                  CHECK(lower(category) in ('characters', 'party', 'activities', 'games')),
	description text,  
	difficulty text   not null
	                  CHECK(lower(difficulty) in ('easy', 'medium', 'hard', 'extreme')),
	gameID int        references Minigames(gameID),
  primary key(stampID)
);

CREATE TABLE EarnedStamps (
	playerID char(10)      not null references Players(playerID),
	stampID int            not null references Stamps(stampID),
	dateEarned timestamp   not null,
  primary key(playerID, stampID)
);

CREATE TABLE Reports (
	complainantID char(10)   not null references Players(playerID),
	reportedID char(10)      not null references Players(playerID),
	dateFiled timestamp      not null,
	reportReason text        not null 
	                         CHECK(lower(reportReason) in ('bad words', 'personal information', 'rude or mean', 'bad penguin name')),
  primary key(complainantID, reportedID, dateFiled)
);

CREATE TABLE Bans (
	playerID char(10)   not null references Players(playerID),
	banDate timestamp   not null,
	banReason text      not null,
	endDate timestamp,
  primary key(playerID, banDate)
);


--------------
-- Triggers --
--------------

CREATE OR REPLACE FUNCTION hashPassword () 
returns TRIGGER as $$
begin
	new.userPassword = crypt(new.userPassword, gen_salt('md5'));
	return new;
end;
$$
language plpgsql;

CREATE OR REPLACE TRIGGER hashPassword
before INSERT OR UPDATE on Players
for each row
execute procedure hashPassword(userPassword);

CREATE OR REPLACE FUNCTION uniqueTypeEquipped () 
returns TRIGGER as $$
begin
	if new.isEquipped then
		UPDATE ClothesInventory inv
		set isEquipped = FALSE
		from Clothes c
		where inv.clothesID = c.clothesID
			and inv.clothesID != new.clothesID
			and inv.playerID = new.playerID
			and c.clothesType ilike (select clothesType from Clothes where clothesID = new.clothesID)
			and inv.isEquipped;
	end if;
	return new;
end;
$$
language plpgsql;

CREATE OR REPLACE TRIGGER uniqueTypeEquipped
after INSERT OR UPDATE of isEquipped
						on ClothesInventory
for each row
execute procedure uniqueTypeEquipped();


-----------------------
-- Insert Statements --
-----------------------

INSERT INTO Players (playerID,      username,     userPassword, email,                 joinDate,             isVerified,  isMember)
VALUES				('p123456789', 'databasegod', 'alpaca',     'labouseur@email.com', '01.01.2025 12:30:43', TRUE,        TRUE),
					('p000000000', 'penguin',     'abcdefg',    'penguin@email.com',   '10.04.2005 00:00:00', FALSE,       FALSE),
					('p777777777', 'birdy14193',  'yay!yay',    'bird@birdy.com',      '08.08.2010 14:12:48', TRUE,        TRUE),
					('p111222333', 'EVILPENGUIN', '12345',      'someone@gmail.com',   '05.27.2008 22:09:52', TRUE,        FALSE),
					('p002000001', 'happyguy',    'password',   'sunshine@yahoo.com',  '02.12.2010 06:31:09', TRUE,        TRUE);

select * from Players;

INSERT INTO Parties (partyID,   partyName,                startDate,             endDate)
VALUES				(00000,     'Beta Test Party',        '09.21.2005 15:00:00', '09.21.2005 17:00:00'),
					(12345,     'April Fools Party 2009', '03.28.2009 00:00:00', '04.02.2009 00:00:00'),
					(55555,     'Operation: Blackout',    '11.15.2012 00:00:00', '12.04.2012 00:00:00');

INSERT INTO Rooms (roomID, roomName,      maxCapacity)
VALUES		      (110,    'Coffee Shop', 80),
				  (130,    'Gift Shop',   80),
				  (100,    'Town',        120),
				  (310,    'Pet Shop',    80),
				  (808,    'Mine',        80),
				  (340,    'Stage',       80);

INSERT INTO Catalogs (catalogID, catalogName,                 roomID)
VALUES				 (00,        'Furniture & Igloo Catalog',  null),
					 (01,        'Penguin Style',              130),
					 (02,        'Puffle Catalog',             310),
					 (03,        'Costume Trunk',              340);

INSERT INTO Items (itemID, itemName,                priceCoins, isMemberItem)
VALUES			  (477,    'Court Jester Hat',      250,         TRUE),
				  (204,    'Astro Barrier T-Shirt', 200,         TRUE),
				  (5588,   'Fruitcake',             null,        FALSE),
				  (112,    'Light Blue',            20,          FALSE),
				  (7259,   'Herbertech Pin',        null,        FALSE),
				  (5189,   'Cool Mittens',          200,         TRUE),
				  (106,    'Mona Lisa',             3000,        TRUE),
				  (893,    'Banana Couch',          null,        FALSE),
				  (617,    'Salon Chair',           400,         TRUE),
				  (750,    'Blue Puffle',           400,         FALSE),
				  (759,    'Brown Puffle',          400,         TRUE),
				  (5230,   'Rainbow Puffle',        null,        TRUE);

INSERT INTO ItemAvailability (itemID, startDate,    endDate,       catalogID, roomID)
VALUES						 (477,    '12.14.2007',  '01.11.2008',  03,        null),
							 (477,    '05.01.2009',  '09.04.2009',  01,        null),
							 (112,    '08.22.2005',   null,         01,        null),
							 (7259,   '02.17.2016',  '03.02.2016',  null,      100),
							 (106,    '08.22.2005',  '10.20.2006',  00,        null),
							 (750,    '03.17.2006',   null,         02,        null);

INSERT INTO Clothes (clothesID, clothesType)
VALUES				(477,       'Head'),
					(204,       'body'),
					(5588,      'hand'),
					(112,       'color'),
					(5189,      'hand');

INSERT INTO ClothesInventory (playerID,     clothesID, isEquipped)
VALUES						 ('p777777777',  477,       TRUE),
							 ('p123456789',  204,       TRUE),
							 ('p123456789',  477,       FALSE),
							 ('p000000000',  112,       TRUE),
							 ('p777777777',  5588,      TRUE);

INSERT INTO Furniture (furnitureID, furnitureType)
VALUES				  (106,         'wall'),
					  (893,         'floor'),
					  (617,         'pet');

INSERT INTO FurnitureInventory (playerID,      furnitureID, qtyOwned, numPlaced)
VALUES							('p123456789',  106,         1,        0),
								('p111222333',  106,         5,        3),
								('p777777777',  893,         2,        2);

INSERT INTO Puffles (puffleID, favoriteToy,  speed)
VALUES				(750,      'Beach ball', 'Slow'),
					(759,      'Rocket',      null),
					(5230,     'Cloud',      'Fast');

INSERT INTO PetPuffles (petID, playerID,     puffleID, puffleName, adoptDate)
VALUES					(00,   'p777777777',  759,     'Cookie',   '08.10.2010 11:19:35'),
						(01,   'p777777777',  5230,    'Lucky',    '09.05.2014 19:05:44'),
						(02,   'p002000001',  750,     'Sky',      '10.31.2015');

INSERT INTO Minigames (gameID, gameName,         roomID)
VALUES				  (00,     'Bean Counters',   110),
					  (01,     'Smoothie Smash',  110),
					  (02,     'Puffle Launch',   310),
					  (03,     'Pufflescapes',    310),
					  (04,     'Cart Surfer',     808);

INSERT INTO Highscores (playerID,    gameID, score, dateScored)
VALUES				   ('p123456789', 04,     2100,  '01.02.2025 20:05:28'),
					   ('p777777777', 01,     110,   '12.23.2015 14:54:19'),
					   ('p777777777', 04,     2300,  '04.17.2013 18:04:52'),
					   ('p000000000', 01,     160,   '05.05.2009 13:02:55'),
					   ('p002000001', 01,     220,   '09.12.2012 15:09:28');

INSERT INTO Stamps (stampID, stampName,             category,     description,                                    difficulty, gameID)
VALUES			   (212,     'Great Balance stamp', 'Games',      'Recover from a wobble',                         'Easy',     04),
				   (439,     'Mountaineer stamp',   'Party',      'Reach a mountain peak',                         'Hard',     null),
				   (466,     'Herbert stamp',       'characters', 'Be in the same room as Herbert',                'extreme',  null),
				   (15,      'Going Places stamp',  'Activities', 'Waddle around 30 rooms without using the map',  'medium',   null);

INSERT INTO EarnedStamps (playerID,     stampID,  dateEarned)
VALUES					 ('p002000001',  15,      '3.12.2013 14:16:25'),
						 ('p123456789',  439,     '01.05.2025 00:04:54'),
						 ('p777777777',  466,     '08.08.2015 15:29:38'),
						 ('p111222333',  15,      '05.28.2008 02:05:33');

INSERT INTO Reports (complainantID, reportedID,   dateFiled,             reportReason)
VALUES				('p002000001',  'p111222333', '05.07.2011 10:26:32',  'rude or mean'),
					('p777777777',  'p111222333', '10.12.2012 20:54:09',  'bad words'),
					('p111222333',  'p000000000', '11.01.2012 08:05:33',  'personal information');
 
INSERT INTO Bans (playerID,     banDate,               banReason,       endDate)
VALUES			 ('p111222333', '05.08.2011 08:17:11', 'rude or mean',  '05.09.2011 08:17:11'),
				 ('p111222333', '10.12.2012 22:58:12', 'bad words',     '10.15.2012 22:58:12'),
				 ('p111222333', '10.16.2012 14:45:43', 'bad words',      null);


-------------
-- Reports --
-------------

-- Report 1
select count(playerID) as "Number of players"
from Players
where date_part('year', joinDate) = 2010;

-- Report 2
select i.itemName, coalesce(r1.roomName, r2.roomName) as roomName, i.priceCoins, i.isMemberItem
from Items i inner join ItemAvailability ia on i.itemID = ia.itemID
			 left outer join Rooms r1 on ia.roomID = r1.roomID
			 left outer join Catalogs c on ia.catalogID = c.catalogID
			 left outer join Rooms r2 on c.roomID = r2.roomID
where ia.endDate is null or ia.endDate > now()
order by itemName ASC;

-- Report 3
select playerID, sum(numClothes) as "Clothes owned", sum(numFurn) as "Furniture owned"
from (
	  select playerID, 1 as numClothes, 0 as numFurn
	  from ClothesInventory
	  union
	  select playerID, 0 as numClothes, qtyOwned as numFurn
	  from FurnitureInventory
)
group by playerID;


-----------------------
-- Stored Procedures --
-----------------------

CREATE OR REPLACE FUNCTION checkPlayerOutfit (pid char(10)) 
returns table (clothesType text, clothesName text) as $$
begin
	return query
		select c.clothesType, c.itemName
		from clothesInventory inv inner join ClothesDetails c on inv.clothesID = c.clothesID
		where pid = inv.playerID and inv.isEquipped;
end;
$$ 
language plpgsql;

select * from checkPlayerOutfit('p777777777');

CREATE OR REPLACE FUNCTION minigameLeaderboard (minigameID int)
returns table (username text, score int) as $$
begin
	return query
		select p.username, h.score
		from Highscores h inner join Players p on h.playerID = p.playerID
		where h.gameID = minigameID
		order by score DESC;
end;
$$
language plpgsql;


-----------
-- Views --
-----------

CREATE OR REPLACE VIEW ClothesDetails as (
	select c.clothesID, i.itemName,  c.clothesType, i.priceCoins, i.isMemberItem
	from Clothes c inner join Items i on c.clothesID = i.itemID
);


CREATE OR REPLACE VIEW FurnitureDetails as (
	select f.furnitureID, i.itemName,  f.furnitureType, i.priceCoins, i.isMemberItem
	from Furniture f inner join Items i on f.furnitureID = i.itemID
);


CREATE OR REPLACE VIEW ValidPlayers as (
	select p.playerID, p.username, p.userPassword, p.email, p.joinDate, p.isMember
	from Players as p
	where p.isVerified and p.playerID not in (select playerID
	                                          from Bans
											   where endDate is null or endDate > now())
);


-------------------------
-- Security/User Roles --
-------------------------

CREATE ROLE admin;
grant all on all tables in schema public to admin;

CREATE ROLE gameDeveloper;
grant SELECT, INSERT, UPDATE on Parties to gameDeveloper;
grant SELECT, INSERT, UPDATE on Rooms to gameDeveloper;
grant SELECT, INSERT, UPDATE on Catalogs to gameDeveloper;
grant SELECT, INSERT, UPDATE on Items to gameDeveloper;
grant SELECT, INSERT, UPDATE on ItemAvailability to gameDeveloper;
grant SELECT, INSERT, UPDATE on Clothes to gameDeveloper;
grant SELECT, INSERT, UPDATE on Furniture to gameDeveloper;
grant SELECT, INSERT, UPDATE on Puffles to gameDeveloper;
grant SELECT, INSERT, UPDATE on Minigames to gameDeveloper;
grant SELECT, INSERT, UPDATE on Stamps to gameDeveloper;

CREATE ROLE gameWriter;
grant SELECT on Parties to gameWriter;
grant SELECT on Rooms to gameWriter;
grant SELECT on Catalogs to gameWriter;
grant SELECT on Items to gameWriter;
grant SELECT on ItemAvailability to gameWriter;
grant SELECT on Clothes to gameWriter;
grant SELECT on Furniture to gameWriter;
grant SELECT on Puffles to gameWriter;
grant SELECT on Minigames to gameWriter;
grant SELECT on Stamps to gameWriter;

CREATE ROLE playerManager;
grant SELECT, INSERT, UPDATE on Players to playerManager;
grant SELECT, INSERT, UPDATE on ClothesInventory to playerManager;
grant SELECT, INSERT, UPDATE on FurnitureInventory to playerManager;
grant SELECT, INSERT, UPDATE on PetPuffles to playerManager;
grant SELECT, INSERT, UPDATE on Highscores to playerManager;
grant SELECT, INSERT, UPDATE on EarnedStamps to playerManager;
grant SELECT, INSERT, UPDATE on Reports to playerManager;
grant SELECT, INSERT, UPDATE on Bans to playerManager;

CREATE ROLE moderator;
grant SELECT on Players to moderator;
grant SELECT on Reports to moderator;
grant SELECT, INSERT, UPDATE on Bans to moderator;

revoke all on Players from moderator;