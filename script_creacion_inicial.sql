USE [GD2C2022]
GO

------------------ CREACION DE BASE DE DATOS -------------------

IF DB_ID('DATA4MIND') IS NULL
	CREATE DATABASE DATA4MIND;
GO

--------------------- CREACION DE TABLAS -----------------------

USE [DATA4MIND]
GO

IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='DROP_TABLES')
	DROP PROCEDURE DROP_TABLES;
GO

CREATE PROCEDURE DROP_TABLES
AS
BEGIN
	DECLARE @sql NVARCHAR(500) = ''
	DECLARE cursorTablas CURSOR FOR
	SELECT DISTINCT 'ALTER TABLE [' + tc.TABLE_SCHEMA + '].[' +  tc.TABLE_NAME + '] DROP [' + rc.CONSTRAINT_NAME + '];'
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
	LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
	ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME

	OPEN cursorTablas
	FETCH NEXT FROM cursorTablas INTO @sql

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXEC sp_executesql @sql
		FETCH NEXT FROM cursorTablas INTO @Sql
	END

	CLOSE cursorTablas
	DEALLOCATE cursorTablas
	
	EXEC sp_MSforeachtable 'DROP TABLE ?'
END
GO

IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='CREATE_TABLES')
   DROP PROCEDURE CREATE_TABLES;
GO

CREATE PROCEDURE CREATE_TABLES
AS
BEGIN
	CREATE TABLE provincia (
		provincia_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		nombre_provincia NVARCHAR(255)
	);

	CREATE TABLE cupon (
		venta_cupon_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		venta_cupon_fecha_desde DATE,
		venta_cupon_fecha_hasta DATE,
		venta_cupon_valor DECIMAL(18,2),
		venta_cupon_tipo NVARCHAR(50)
	);

	CREATE TABLE tipo_variante (
		tipo_variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		tipo_variante_descripcion NVARCHAR(255)
	);

	CREATE TABLE categoria (
		categoria_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		categoria NVARCHAR(50)

	);	

	CREATE TABLE marca (
		marca_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		marca NVARCHAR(50)
	);
	
	CREATE TABLE material (
		material_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		material NVARCHAR(50)
	);

	CREATE TABLE tipo_descuento_compra (
		tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		compra_descuento_concepto NVARCHAR(255) -- El concepto del descuento es el mismo que en la columna de "VENTA_DESCUENTO_CONCEPTO" --
	);

	CREATE TABLE tipo_descuento_venta (
		tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		venta_descuento_concepto NVARCHAR(255)
	);

	CREATE TABLE localidad (
		localidad_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		codigo_postal DECIMAL(18,0),
		provincia_codigo INTEGER REFERENCES provincia(provincia_codigo),
		nombre_localidad NVARCHAR(255)
	);

	CREATE TABLE cliente (
		cliente_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		cliente_nombre NVARCHAR(255),
		cliente_apellido NVARCHAR(255),
		cliente_dni DECIMAL(18,0),
		cliente_fecha_nac DATE,
		cliente_direccion NVARCHAR(255),		
		cliente_localidad INTEGER REFERENCES localidad,
		cliente_telefono DECIMAL(18,2),
		cliente_email NVARCHAR(255)
	);

	CREATE TABLE proveedor (
		proveedor_codigo INTEGER IDENTITY(1,1),
		proveedor_razon_social NVARCHAR(50),
		proveedor_cuit NVARCHAR(50) PRIMARY KEY,
		proveedor_mail NVARCHAR(50),
		proveedor_domicilio NVARCHAR(50),
		proveedor_localidad INTEGER REFERENCES localidad
	);

	CREATE TABLE producto (
		producto_codigo NVARCHAR(50) PRIMARY KEY,
		material_codigo NUMERIC(10),
		marca_codigo NUMERIC(10),
		categoria_codigo NUMERIC(10),
		producto_descripcion NVARCHAR(50)
	);
	
	CREATE TABLE variante (
		variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY, 
		tipo_variante_codigo INTEGER REFERENCES tipo_variante,
		variante_descripcion NVARCHAR(255)
	);

	CREATE TABLE producto_variante (
		producto_variante_codigo NVARCHAR(50) PRIMARY KEY,
		producto_codigo NVARCHAR(50) REFERENCES producto,
		variante_codigo INTEGER IDENTITY(1,1) REFERENCES variante,
		precio_actual DECIMAL(18,2),
		stock_disponible DECIMAL(18,0)
	);

	CREATE TABLE envio (
		envio_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		localidad_codigo INTEGER REFERENCES localidad,
		precio_envio DECIMAL(18,2),
		medio_envio NVARCHAR(255),
		importe DECIMAL(18,2),
	);
	
	CREATE TABLE canal (
		venta_canal_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		venta_canal NVARCHAR(2255),
		venta_canal_costo DECIMAL(18,2),
		importe DECIMAL(18,2)
	);

	CREATE TABLE medio_pago_venta (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		importe DECIMAL(18,2),
		medio_pago_costo DECIMAL(18,2),
		tipo_medio_pago NVARCHAR(255)
	);
	
	CREATE TABLE descuento_venta(
		descuento_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		venta_descuento_importe DECIMAL(18,2),		
		tipo_descuento_codigo NUMERIC(10) REFERENCES tipo_descuento_venta,
		importe DECIMAL(18,2)
	);

	CREATE TABLE venta (
		venta_codigo DECIMAL(19,0) PRIMARY KEY,
		venta_fecha DATE,
		cliente_codigo INTEGER REFERENCES cliente,
		venta_total DECIMAL(18,2),
		importe DECIMAL(18,2),
		medio_pago_codigo INTEGER REFERENCES medio_pago_venta,
		venta_canal_codigo DECIMAL(19,0) REFERENCES canal,
		descuento_codigo INTEGER REFERENCES descuento_venta,
		envio_codigo DECIMAL(19,0) REFERENCES envio  
	);
		
	CREATE TABLE medio_pago_compra (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		medio_pago_costo DECIMAL(18,2),	
		tipo_medio_pago NVARCHAR(255)
	);

	CREATE TABLE compra (
		compra_codigo DECIMAL(19,0) IDENTITY PRIMARY KEY,
		proovedor_codigo NVARCHAR(50) REFERENCES proveedor,
		medio_de_pago_codigo INTEGER REFERENCES medio_pago_compra,
		compra_fecha DATE NOT NULL,
		importe DECIMAL(18,2),
		compra_total DECIMAL(18,2)
	);

	CREATE TABLE descuento_de_compra (
		descuento_compra_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		compra_codigo DECIMAL(19,0) REFERENCES compra,
		descuento_compra_valor DECIMAL(18,2),
		tipo_descuento_concepto NUMERIC(10) REFERENCES tipo_descuento_compra,
		importe DECIMAL(18,2)
	);
	
	CREATE TABLE producto_comprado(
		compra_codigo DECIMAL(19,0) IDENTITY(1,1) REFERENCES compra,
		producto_variante_codigo NVARCHAR(50) REFERENCES producto_variante,
		compra_prod_cantidad DECIMAL(18,0),
		compra_prod_precio DECIMAL(18,2),
		PRIMARY KEY (compra_codigo, producto_variante_codigo)
	);

	CREATE TABLE producto_vendido (
		venta_codigo DECIMAL(19,0) REFERENCES venta,
		producto_variante_codigo NVARCHAR(50) REFERENCES producto_variante,
		venta_prod_cantidad DECIMAL(18,0),
		venta_prod_precio DECIMAL(18,2), 
		PRIMARY KEY(venta_codigo, producto_variante_codigo)
	);
	
	CREATE TABLE cupon_canjeado (
		venta_cupon_codigo DECIMAL(19,0) REFERENCES cupon,
		venta_codigo DECIMAL(19,0) REFERENCES venta,
		venta_cupon_importe DECIMAL(18,2),
		PRIMARY KEY(venta_cupon_codigo, venta_codigo)
	);
END
GO

IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='MIGRAR')
	DROP PROCEDURE MIGRAR;
GO

CREATE PROCEDURE MIGRAR 
AS
BEGIN
	INSERT INTO provincia (nombre_provincia)
	SELECT DISTINCT(cliente_provincia)
	FROM GD2C2022.gd_esquema.Maestra
	WHERE cliente_provincia IS NOT NULL

	INSERT INTO localidad (nombre_localidad, provincia_codigo, codigo_postal)
	SELECT DISTINCT cliente_localidad, provincia_codigo, CLIENTE_CODIGO_POSTAL
	FROM GD2C2022.gd_esquema.Maestra JOIN provincia ON cliente_provincia = nombre_provincia
	WHERE cliente_localidad IS NOT NULL

	INSERT INTO cliente (cliente_nombre, cliente_apellido, cliente_dni, cliente_fecha_nac, cliente_direccion, cliente_localidad, cliente_telefono, cliente_email)
	SELECT DISTINCT cliente_nombre, cliente_apellido, cliente_dni, cliente_fecha_nac, cliente_direccion, localidad_codigo, cliente_telefono, cliente_mail
	FROM GD2C2022.gd_esquema.Maestra JOIN localidad ON cliente_localidad = nombre_localidad AND cliente_codigo_postal = codigo_postal
	WHERE cliente_dni IS NOT NULL

END
GO

EXEC DROP_TABLES
GO

EXEC CREATE_TABLES
GO

EXEC MIGRAR
GO

/**
DROP TABLE producto_comprado
DROP TABLE descuento_de_compra
DROP TABLE compra
DROP TABLE medio_pago_compra
DROP TABLE proveedor
DROP TABLE tipo_descuento_compra
DROP TABLE producto_vendido
DROP TABLE producto_variante
DROP TABLE variante
DROP TABLE tipo_variante
DROP TABLE categoria
DROP TABLE marca
DROP TABLE material
DROP TABLE producto
DROP TABLE cupon_canjeado
DROP TABLE cupon
DROP TABLE venta
DROP TABLE descuento_venta
DROP TABLE tipo_descuento_venta
DROP TABLE canal
DROP TABLE envio
DROP TABLE medio_pago_venta
DROP TABLE cliente
DROP TABLE localidad
DROP TABLE provincia
**/