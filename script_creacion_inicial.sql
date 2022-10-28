USE [GD2C2022]
GO
------------------ CREACION DE BASE DE DATOS -------------------
-- DROP DATABASE DATA4MIND; --
CREATE DATABASE DATA4MIND;
GO

-- DROP SCHEMA esquema;
CREATE SCHEMA esquema;
GO

--comentario
--------------------- CREACION DE TABLAS -----------------------

USE [DATA4MIND]
GO
EXEC DROP_ALL 
GO

IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='CREATE_MASTER_TABLES')
   DROP PROCEDURE CREATE_MASTER_TABLES;
GO
EXEC PROCEDURE CREATE_MASTER_TABLES;


SELECT * FROM GD2C2022.gd_esquema.Maestra;