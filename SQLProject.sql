--drop DATABASE Hotel
--GO

CREATE DATABASE Hotel
GO

USE Hotel
GO

SET LANGUAGE polski
GO

-------- Usuwanie tabel ----------------------------------------------------------------

--IF OBJECT_ID('Rezerwacje', 'U') IS NOT NULL 
--	DROP TABLE Rezerwacje;

--IF OBJECT_ID('Platnosci', 'U') IS NOT NULL 
--	DROP TABLE Platnosci;

--IF OBJECT_ID('Klienci', 'U') IS NOT NULL 
--	DROP TABLE Klienci;

--IF OBJECT_ID('PokojeInfo', 'U') IS NOT NULL 
--	DROP TABLE PokojeInfo;

--IF OBJECT_ID('Pokoje', 'U') IS NOT NULL 
--	DROP TABLE Pokoje;

--IF OBJECT_ID('Dodatki', 'U') IS NOT NULL 
--	DROP TABLE Dodatki;

--------- CREATE - tworzenie tabel i powi¹zañ ---------------------------------------------

CREATE TABLE Klienci(
	email		VARCHAR(30) PRIMARY KEY,
    imie		VARCHAR(30) NOT NULL,
    nazwisko	VARCHAR(30) NOT NULL,
	CHECK (imie LIKE '[A-Z]%'),
	CHECK (nazwisko LIKE '[A-Z]%')
);


CREATE TABLE PokojeInfo(
	rodzaj_pokoju	VARCHAR(30) PRIMARY KEY,
	cena_doba		MONEY NOT NULL,
	ilosc_osob		INT NOT NULL,
	CHECK(cena_doba>0)
);

CREATE TABLE Pokoje(
    nr_pokoju		INT IDENTITY(1,1) PRIMARY KEY,
    rodzaj			VARCHAR(30) REFERENCES PokojeInfo(rodzaj_pokoju)
);

CREATE TABLE Rezerwacje(
    nr_rezerwacji	INT IDENTITY(1,1) PRIMARY KEY,
	klient			VARCHAR(30) REFERENCES Klienci(email),
    nr_pokoju		INT REFERENCES Pokoje(nr_pokoju),
    data_od			DATE NOT NULL,
    data_do			DATE NOT NULL,
	dod1			BIT DEFAULT '0',
	dod2			BIT DEFAULT '0',
	dod3			BIT DEFAULT '0',
	CHECK (data_od < data_do)
);

CREATE TABLE Archiwum(
    nr_rezerwacji	INT IDENTITY(1,1) PRIMARY KEY,
	klient			VARCHAR(30) REFERENCES Klienci(email),
    nr_pokoju		INT REFERENCES Pokoje(nr_pokoju),
    data_od			DATE NOT NULL,
    data_do			DATE NOT NULL,
	dod1			BIT DEFAULT '0',
	dod2			BIT DEFAULT '0',
	dod3			BIT DEFAULT '0'
);

CREATE TABLE Dodatki(
    id_dodatku		INT IDENTITY(1,1) PRIMARY KEY,
    nazwa			VARCHAR(30) NOT NULL,
    cena_doba		MONEY NOT NULL
);

CREATE TABLE Platnosci(
	nr_rezerwacji	INT REFERENCES Rezerwacje(nr_rezerwacji),
	do_zaplaty		MONEY,
);

GO

--WIDOKI-----------------------------------------------------------------------------------


--DROP VIEW rezerwacje_info;
CREATE VIEW rezerwacje_info 

AS

SELECT R.nr_rezerwacji,nr_pokoju,klient,data_od,data_do,P.do_zaplaty 
FROM Rezerwacje R JOIN Platnosci P ON P.nr_rezerwacji=R.nr_rezerwacji

GO
	

--DROP VIEW cennikpokoje;
CREATE VIEW cennikpokoje

AS

SELECT DISTINCT rodzaj_pokoju,cena_doba,ilosc_osob FROM PokojeInfo

GO

--DROP VIEW cennikdodatki;
CREATE VIEW cennikdodatki

AS

SELECT * FROM Dodatki
	
GO

--TRIGGERY-----------------------------------------------------------------------------------

--DROP TRIGGER oplata;
CREATE TRIGGER oplata 
ON Rezerwacje AFTER INSERT

AS

DECLARE @do_zaplaty MONEY = 0;
DECLARE @rodzaj VARCHAR(30) = (SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted));
DECLARE @dni INT = DATEDIFF(day,(SELECT data_od FROM inserted),(SELECT data_do FROM inserted));


IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'jednoosobowy'
BEGIN
SET @do_zaplaty=@do_zaplaty+(150*@dni)
END

IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'dwuosobowy'
BEGIN
SET @do_zaplaty=@do_zaplaty+(300*@dni)
END

IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'sredni'
BEGIN
SET @do_zaplaty=@do_zaplaty+(500*@dni)
END

IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'rodzinny'
BEGIN
SET @do_zaplaty=@do_zaplaty+(700*@dni)
END

IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'duzy rodzinny'
BEGIN
SET @do_zaplaty=@do_zaplaty+(900*@dni)
END

IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'apartament'
BEGIN
SET @do_zaplaty=@do_zaplaty+(1600*@dni)
END

IF(SELECT rodzaj FROM Pokoje WHERE nr_pokoju = (SELECT nr_pokoju FROM inserted)) = 'apartament lux'
BEGIN
SET @do_zaplaty=@do_zaplaty+(2000*@dni)
END

IF(SELECT dod1 FROM inserted) = '1'
BEGIN
SET @do_zaplaty=@do_zaplaty+(30*@dni)
END

IF(SELECT dod2 FROM inserted) = '1'
BEGIN
SET @do_zaplaty=@do_zaplaty+(25*@dni)
END

IF(SELECT dod3 FROM inserted) = '1'
BEGIN
SET @do_zaplaty=@do_zaplaty+(10*@dni)
END

INSERT INTO Platnosci(nr_rezerwacji,do_zaplaty)
VALUES ((SELECT nr_rezerwacji FROM inserted),@do_zaplaty);

GO


--FUNKCJE-----------------------------------------------------------------------------------


--DROP FUNCTION znajdz_pokoj;
CREATE FUNCTION znajdz_pokoj(@poczatek DATE,@koniec DATE,@rodz VARCHAR(30))
RETURNS TABLE 
AS RETURN
	SELECT P.nr_pokoju as 'Wolne pokoje' FROM Pokoje P LEFT JOIN Rezerwacje R ON P.nr_pokoju=R.nr_pokoju WHERE @rodz=P.rodzaj AND ((@koniec<=R.data_od AND @poczatek<=R.data_od) OR (@poczatek>=R.data_do AND @koniec>=R.data_do) OR (R.data_od IS NULL));

GO
--SELECT * FROM REZERWACJE
--SELECT * FROM znajdz_pokoj('2013-02-12','2018-02-19','jednoosobowy');

--PROCEDURY-----------------------------------------------------------------------------------


--DROP PROCEDURE cennik;
CREATE PROCEDURE cennik
AS
SELECT * FROM cennikpokoje
SELECT * FROM cennikdodatki

GO

--DROP PROCEDURE rezerwacje_klienta;
CREATE PROCEDURE rezerwacje_klienta

@klient VARCHAR(30) = NULL

AS

DECLARE @blad AS NVARCHAR(50);
 
IF @klient IS NULL OR (SELECT email FROM Klienci WHERE email=@klient) IS NULL
BEGIN
     SET @blad = 'Nie ma takiego klienta!';
     RAISERROR(@blad, 16,1);
     RETURN;
END
SELECT * FROM Rezerwacje WHERE klient=@klient;

GO

--DROP PROCEDURE nowy_klient;
CREATE PROCEDURE nowy_klient

@email VARCHAR(30) = NULL,
@imie VARCHAR(30) = NULL,
@nazwisko VARCHAR(30) = NULL

AS

DECLARE @blad AS NVARCHAR(50);
 
IF @email IS NULL OR @imie IS NULL OR @nazwisko IS NULL
BEGIN
     SET @blad = 'B³êdne dane!';
     RAISERROR(@blad, 16,1);
     RETURN;
END
 
INSERT INTO Klienci(email,imie,nazwisko)
VALUES (@email,@imie,@nazwisko);
 
GO

--DROP PROCEDURE usun_rezerwacje;
CREATE PROCEDURE usun_rezerwacje

@nr_rezerwacji INT = NULL

AS

DECLARE @blad AS NVARCHAR(50);
 
IF @nr_rezerwacji IS NULL
BEGIN
     SET @blad = 'Brakuje danych!';
     RAISERROR(@blad, 16,1);
     RETURN;
END

IF (SELECT nr_rezerwacji FROM Rezerwacje WHERE nr_rezerwacji=@nr_rezerwacji) IS NULL
BEGIN
     SET @blad = 'Nie ma takiej rezerwacji!';
     RAISERROR(@blad, 16,1);
     RETURN;
END

DELETE FROM Rezerwacje WHERE nr_rezerwacji=@nr_rezerwacji;

GO

--DROP PROCEDURE rezerwacja;
CREATE PROCEDURE rezerwacja

@klient VARCHAR(30) = NULL,
@nr_pokoju INT = NULL,
@data_od DATE = NULL,
@data_do DATE = NULL,
@dod1 INT = NULL,
@dod2 INT = NULL,
@dod3 INT = NULL

AS

DECLARE @blad AS NVARCHAR(50);
 
IF @klient IS NULL OR @nr_pokoju IS NULL OR @data_od IS NULL OR @data_do IS NULL OR @dod1 IS NULL OR @dod2 IS NULL OR @dod3 IS NULL
BEGIN
     SET @blad = 'Brakuje danych!';
     RAISERROR(@blad, 16,1);
     RETURN;
END

IF (SELECT email FROM Klienci WHERE email=@klient) IS NULL
BEGIN
     SET @blad = 'Nie ma takiego klienta';
     RAISERROR(@blad, 16,1);
     RETURN;
END

IF (SELECT nr_pokoju FROM Pokoje WHERE nr_pokoju=@nr_pokoju) IS NULL
BEGIN
     SET @blad = 'Nie ma takiego pokoju';
     RAISERROR(@blad, 16,1);
     RETURN;
END

IF (SELECT * FROM znajdz_pokoj(@data_od,@data_do,(SELECT rodzaj FROM Pokoje WHERE nr_pokoju=@nr_pokoju))) IS NULL
BEGIN
	SET @blad = 'Brak dostepnych pokoi!';
	RAISERROR(@blad, 16,1);
	RETURN;
END
 
INSERT INTO Rezerwacje(klient,nr_pokoju,data_od,data_do,dod1,dod2,dod3)
VALUES (@klient,@nr_pokoju,@data_od,@data_do,@dod1,@dod2,@dod3);

INSERT INTO Archiwum(klient,nr_pokoju,data_od,data_do,dod1,dod2,dod3)
VALUES (@klient,@nr_pokoju,@data_od,@data_do,@dod1,@dod2,@dod3);
 
GO

--INSERT-------------------------------------

INSERT INTO Klienci(email,imie,nazwisko)
VALUES 
('jankow@wp.pl','Jan','Kowalski'),
('halyna@onet.pl','Halina','Nowacka'),
('adas@wp.pl','Adam','Nowak'),
('ania@onet.pl','Anna','Adamiak'),
('adamx@wp.pl','Adam','Iksinski');

INSERT INTO PokojeInfo(rodzaj_pokoju,cena_doba,ilosc_osob)
VALUES 
('apartament lux',2000,10),
('apartament',1600,8),
('duzy rodzinny',900,5),
('rodzinny',700,4),
('sredni',500,3),
('dwuosobowy',300,2),
('jednoosobowy',150,1);

INSERT INTO Pokoje(rodzaj)
VALUES 
('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),('jednoosobowy'),
('jednoosobowy'),('jednoosobowy'),
('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),('dwuosobowy'),
('sredni'),('sredni'),('sredni'),('sredni'),('sredni'),('sredni'),('sredni'),('sredni'),
('rodzinny'),('rodzinny'),('rodzinny'),('rodzinny'),('rodzinny'),('rodzinny'),('rodzinny'),
('duzy rodzinny'),('duzy rodzinny'),('duzy rodzinny'),('duzy rodzinny'),('duzy rodzinny'),
('apartament'),('apartament'),('apartament'),('apartament'),
('apartament lux'),('apartament lux');

INSERT INTO Dodatki(nazwa,cena_doba)
VALUES
('wyzywienie',30),
('fitness',25),
('basen',10);



SELECT * FROM Pokoje
SELECT * FROM PokojeInfo
SELECT * FROM Klienci
SELECT * FROM Dodatki
