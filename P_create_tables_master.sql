USE [DATA4MIND]
GO

CREATE PROCEDURE CREATE_MASTER_TABLES
AS
BEGIN
    -- PROVINCIA
    IF EXISTS (SELECT name FROM sys.objects WHERE name='provincia' AND type='U')   
        DROP TABLE provincia;
    ELSE
	    CREATE TABLE provincia (
		provincia_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
        nombre_provincia NVARCHAR(255)
		);

    -- LOCALIDAD
    IF EXISTS (SELECT name FROM sys.objects WHERE name='localidad' AND type='U')   
        DROP TABLE localidad;
     ELSE
	    CREATE TABLE localidad (
		localidad_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
        codigo_postal DECIMAL(18,0) UNIQUE,
        provincia_codigo DECIMAL(19,0) REFERENCES provincia,
        nombre_localidad NVARCHAR(255)
		);
    
    -- CLIENTE
    IF EXISTS (SELECT name FROM sys.objects WHERE name='cliente' AND type='U')   
        DROP TABLE cliente;
     ELSE
        CREATE TABLE cliente (
        cliente_codigo DECIMAL(19,0) PRIMARY KEY,
        cliente_nombre NVARCHAR(255),
        cliente_apellido NVARCHAR(255),
        cliente_dni DECIMAL(18,0) UNIQUE NOT NULL,
        cliente_fecha_nac DATE,
        cliente_direccion NVARCHAR(255) NOT NULL,
        cliente_localidad INTEGER REFERENCES localidad NOT NULL,
        cliente_telefono DECIMAL(18,2) NOT NULL,
        cliente_email NVARCHAR(255)
        );

	-- 

END 

EXEC CREATE_MASTER_TABLES