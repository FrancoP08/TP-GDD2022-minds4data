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

EXEC DROP_TABLES
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
		venta_cupon_codigo NVARCHAR(255) PRIMARY KEY,
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
		cliente_mail NVARCHAR(255)
	);

	CREATE TABLE proveedor (
		proveedor_razon_social NVARCHAR(50),
		proveedor_cuit NVARCHAR(50) PRIMARY KEY,
		proveedor_mail NVARCHAR(50),
		proveedor_domicilio NVARCHAR(50),
		proveedor_localidad INTEGER REFERENCES localidad
	);

	CREATE TABLE producto (
		producto_codigo NVARCHAR(50) PRIMARY KEY,
		material_codigo NUMERIC(10) REFERENCES material,
		marca_codigo NUMERIC(10) REFERENCES marca,
		categoria_codigo NUMERIC(10) REFERENCES categoria,
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
		variante_codigo INTEGER REFERENCES variante,
		precio_actual DECIMAL(18,2),
		stock_disponible DECIMAL(18,0)
	);

	CREATE TABLE envio (
		envio_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		localidad_codigo INTEGER REFERENCES localidad,
		precio_envio DECIMAL(18,2),
		medio_envio NVARCHAR(255),
		importe DECIMAL(18,2),
	);
	
	CREATE TABLE venta_canal (
		venta_canal_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		venta_canal NVARCHAR(2255),
		venta_canal_costo DECIMAL(18,2),
		importe DECIMAL(18,2)
	);

	CREATE TABLE tipo_medio_pago (
	tipo_mp_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
	tipo_mp NVARCHAR(255)
	);

	CREATE TABLE medio_pago_venta (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		importe DECIMAL(18,2),
		medio_pago_costo DECIMAL(18,2),
		tipo_medio_pago INTEGER REFERENCES tipo_medio_pago
	);

	CREATE TABLE venta (
		venta_codigo DECIMAL(19,0) PRIMARY KEY,
		venta_fecha DATE,
		cliente_codigo INTEGER REFERENCES cliente,
		venta_total DECIMAL(18,2),
		importe DECIMAL(18,2),
		medio_pago_codigo INTEGER REFERENCES medio_pago_venta,
		venta_canal_codigo INTEGER REFERENCES venta_canal,
		envio_codigo INTEGER REFERENCES envio  
	);

	CREATE TABLE descuento_venta (
		descuento_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		venta_codigo DECIMAL(19,0) REFERENCES venta,
		tipo_descuento_codigo NUMERIC(10) REFERENCES tipo_descuento_venta,
		venta_descuento_importe DECIMAL(18,2),
		importe DECIMAL(18,2)
	);
		
	CREATE TABLE medio_pago_compra (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		importe DECIMAL(18,2),
		tipo_medio_pago INTEGER REFERENCES tipo_medio_pago
	);

	CREATE TABLE compra (
		compra_codigo DECIMAL(19,0) PRIMARY KEY,
		proveedor_codigo NVARCHAR(50) REFERENCES proveedor,
		medio_de_pago_codigo INTEGER REFERENCES medio_pago_compra,
		compra_fecha DATE NOT NULL,
		importe DECIMAL(18,2),
		compra_total DECIMAL(18,2)
	);

	CREATE TABLE descuento_compra (
		descuento_compra_codigo DECIMAL(19,0) PRIMARY KEY,
		compra_codigo DECIMAL(19,0) REFERENCES compra,
		descuento_compra_valor DECIMAL(18,2),
		tipo_descuento_codigo NUMERIC(10) REFERENCES tipo_descuento_compra,
		importe DECIMAL(18,2)
	);
	
	CREATE TABLE producto_comprado (
		compra_codigo DECIMAL(19,0) REFERENCES compra,
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
		venta_cupon_codigo NVARCHAR(255) REFERENCES cupon,
		venta_codigo DECIMAL(19,0) REFERENCES venta,
		venta_cupon_importe DECIMAL(18,2),
		PRIMARY KEY(venta_cupon_codigo, venta_codigo)
	);
END
GO

EXEC CREATE_TABLES
GO

IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='MIGRAR')
	DROP PROCEDURE MIGRAR;
GO

CREATE PROCEDURE MIGRAR 
AS
BEGIN
	
	-- PROVINCIA

	INSERT INTO provincia (nombre_provincia)
	SELECT DISTINCT CLIENTE_PROVINCIA
	FROM GD2C2022.gd_esquema.Maestra
	WHERE CLIENTE_PROVINCIA IS NOT NULL
	UNION
	SELECT DISTINCT PROVEEDOR_PROVINCIA
	FROM GD2C2022.gd_esquema.Maestra
	WHERE PROVEEDOR_PROVINCIA IS NOT NULL

	-- LOCALIDAD

	INSERT INTO localidad (nombre_localidad, provincia_codigo, codigo_postal)
	SELECT DISTINCT CLIENTE_LOCALIDAD, provincia_codigo, CLIENTE_CODIGO_POSTAL
	FROM GD2C2022.gd_esquema.Maestra JOIN provincia
	ON CLIENTE_PROVINCIA = nombre_provincia
	WHERE CLIENTE_LOCALIDAD IS NOT NULL
	UNION
	SELECT DISTINCT PROVEEDOR_LOCALIDAD, provincia_codigo, PROVEEDOR_CODIGO_POSTAL
	FROM GD2C2022.gd_esquema.Maestra JOIN provincia
	ON PROVEEDOR_PROVINCIA = nombre_provincia
	WHERE PROVEEDOR_LOCALIDAD IS NOT NULL

	--MATERIAL

	INSERT INTO material (material)
	SELECT DISTINCT PRODUCTO_MATERIAL
	FROM GD2C2022.gd_esquema.Maestra
	WHERE PRODUCTO_MATERIAL IS NOT NULL

	INSERT INTO marca (marca)
	SELECT DISTINCT PRODUCTO_MARCA
	FROM GD2C2022.gd_esquema.Maestra
	WHERE PRODUCTO_MARCA IS NOT NULL

	INSERT INTO categoria (categoria)
	SELECT DISTINCT PRODUCTO_CATEGORIA
	FROM GD2C2022.gd_esquema.Maestra
	WHERE PRODUCTO_CATEGORIA IS NOT NULL

	INSERT INTO producto
	SELECT DISTINCT PRODUCTO_CODIGO, material_codigo, marca_codigo, categoria_codigo, PRODUCTO_DESCRIPCION
	FROM GD2C2022.gd_esquema.Maestra maestra
	JOIN material ON maestra.PRODUCTO_MATERIAL = material.material
	JOIN marca ON maestra.PRODUCTO_MARCA = marca.marca
	JOIN categoria ON maestra.PRODUCTO_CATEGORIA = categoria.categoria

	INSERT INTO tipo_variante (tipo_variante_descripcion)
	SELECT DISTINCT PRODUCTO_TIPO_VARIANTE
	FROM GD2C2022.gd_esquema.Maestra
	WHERE PRODUCTO_TIPO_VARIANTE IS NOT NULL

	INSERT INTO variante (tipo_variante_codigo, variante_descripcion)
	SELECT DISTINCT tipo_variante_codigo, PRODUCTO_VARIANTE
	FROM GD2C2022.gd_esquema.Maestra JOIN tipo_variante
	ON PRODUCTO_TIPO_VARIANTE = tipo_variante_descripcion
	WHERE PRODUCTO_TIPO_VARIANTE IS NOT NULL

	INSERT INTO producto_variante (producto_variante_codigo, producto_codigo, variante_codigo)
	SELECT DISTINCT PRODUCTO_VARIANTE_CODIGO, PRODUCTO_CODIGO, variante_codigo
	FROM GD2C2022.gd_esquema.Maestra JOIN variante
	ON PRODUCTO_VARIANTE = variante_descripcion
	WHERE PRODUCTO_VARIANTE_CODIGO IS NOT NULL

	--ventas

	INSERT INTO cliente (cliente_nombre, cliente_apellido, cliente_dni, cliente_fecha_nac, cliente_direccion, cliente_localidad, cliente_telefono, cliente_mail)
	SELECT DISTINCT CLIENTE_NOMBRE, CLIENTE_APELLIDO, CLIENTE_DNI, CLIENTE_FECHA_NAC, CLIENTE_DIRECCION, localidad_codigo, CLIENTE_TELEFONO, CLIENTE_MAIL
	FROM GD2C2022.gd_esquema.Maestra JOIN localidad 
	ON CLIENTE_LOCALIDAD = nombre_localidad 
	AND CLIENTE_CODIGO_POSTAL = codigo_postal
	WHERE CLIENTE_DNI IS NOT NULL

	INSERT INTO venta_canal (venta_canal, venta_canal_costo)
	SELECT DISTINCT VENTA_CANAL, VENTA_CANAL_COSTO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE VENTA_CANAL IS NOT NULL

	INSERT INTO tipo_medio_pago (tipo_mp)
	SELECT DISTINCT COMPRA_MEDIO_PAGO FROM GD2C2022.gd_esquema.Maestra
	UNION SELECT DISTINCT VENTA_MEDIO_PAGO FROM GD2C2022.gd_esquema.Maestra

	INSERT INTO medio_pago_venta (medio_pago_costo, tipo_medio_pago)
	SELECT DISTINCT VENTA_MEDIO_PAGO_COSTO, VENTA_MEDIO_PAGO
	FROM GD2C2022.gd_esquema.Maestra JOIN tipo_medio_pago t 
	ON t.tipo_mp = VENTA_MEDIO_PAGO  

	INSERT INTO envio (precio_envio, medio_envio)
	SELECT DISTINCT VENTA_ENVIO_PRECIO, VENTA_MEDIO_ENVIO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE VENTA_MEDIO_ENVIO IS NOT NULL
	
	INSERT INTO venta (venta_codigo, venta_fecha, cliente_codigo, venta_total)
	SELECT DISTINCT VENTA_CODIGO, VENTA_FECHA, cliente_codigo, VENTA_TOTAL
	FROM GD2C2022.gd_esquema.Maestra m
	JOIN cliente c ON m.CLIENTE_NOMBRE = c.cliente_nombre
	AND m.CLIENTE_APELLIDO = c.cliente_apellido
	AND m.CLIENTE_DNI = c.cliente_dni
	WHERE VENTA_CODIGO IS NOT NULL

	
	INSERT INTO tipo_descuento_venta (venta_descuento_concepto)
	SELECT DISTINCT VENTA_DESCUENTO_CONCEPTO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE VENTA_DESCUENTO_CONCEPTO IS NOT NULL

	INSERT INTO descuento_venta (venta_codigo, venta_descuento_importe, tipo_descuento_codigo)
	SELECT DISTINCT VENTA_CODIGO, VENTA_DESCUENTO_IMPORTE, tipo_descuento_codigo
	FROM GD2C2022.gd_esquema.Maestra m JOIN tipo_descuento_venta d
	ON m.VENTA_DESCUENTO_CONCEPTO = d.venta_descuento_concepto
	WHERE VENTA_CODIGO IS NOT NULL

	INSERT INTO cupon
	SELECT DISTINCT VENTA_CUPON_CODIGO, VENTA_CUPON_FECHA_DESDE, VENTA_CUPON_FECHA_HASTA, VENTA_CUPON_VALOR, VENTA_CUPON_TIPO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE VENTA_CUPON_CODIGO IS NOT NULL

	INSERT INTO cupon_canjeado
	SELECT DISTINCT VENTA_CUPON_CODIGO, VENTA_CODIGO, VENTA_CUPON_IMPORTE
	FROM GD2C2022.gd_esquema.Maestra m
	WHERE VENTA_CODIGO IS NOT NULL AND VENTA_CUPON_CODIGO IS NOT NULL
	
	INSERT INTO producto_vendido
	SELECT DISTINCT VENTA_CODIGO, PRODUCTO_VARIANTE_CODIGO, SUM(VENTA_PRODUCTO_CANTIDAD), VENTA_PRODUCTO_PRECIO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE PRODUCTO_VARIANTE_CODIGO IS NOT NULL AND VENTA_CODIGO IS NOT NULL
	GROUP BY VENTA_CODIGO, PRODUCTO_VARIANTE_CODIGO, VENTA_PRODUCTO_PRECIO

	--compras

	INSERT INTO proveedor (proveedor_razon_social, proveedor_cuit, proveedor_mail, proveedor_domicilio, proveedor_localidad)
	SELECT DISTINCT PROVEEDOR_RAZON_SOCIAL, PROVEEDOR_CUIT, PROVEEDOR_MAIL, PROVEEDOR_DOMICILIO, localidad_codigo
	FROM GD2C2022.gd_esquema.Maestra JOIN localidad
	ON PROVEEDOR_LOCALIDAD = nombre_localidad
	AND PROVEEDOR_CODIGO_POSTAL = codigo_postal
	WHERE PROVEEDOR_CUIT IS NOT NULL

	INSERT INTO medio_pago_compra (tipo_medio_pago)
	SELECT DISTINCT tipo_mp_codigo FROM DATA4MIND.dbo.tipo_medio_pago t
	JOIN GD2C2022.gd_esquema.Maestra

	INSERT INTO compra (compra_codigo, proveedor_codigo, compra_fecha, compra_total)
	SELECT DISTINCT COMPRA_NUMERO, PROVEEDOR_CUIT, COMPRA_FECHA, COMPRA_TOTAL
	FROM GD2C2022.gd_esquema.Maestra m WHERE COMPRA_NUMERO IS NOT NULL

	INSERT INTO tipo_descuento_compra (compra_descuento_concepto)
	SELECT DISTINCT VENTA_DESCUENTO_CONCEPTO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE VENTA_DESCUENTO_CONCEPTO IS NOT NULL

	INSERT INTO descuento_compra (descuento_compra_codigo, compra_codigo, descuento_compra_valor)
	SELECT DISTINCT DESCUENTO_COMPRA_CODIGO, COMPRA_NUMERO, DESCUENTO_COMPRA_VALOR
	FROM GD2C2022.gd_esquema.Maestra
	WHERE DESCUENTO_COMPRA_CODIGO IS NOT NULL

	INSERT INTO producto_comprado (compra_codigo, producto_variante_codigo, compra_prod_cantidad, compra_prod_precio)
	SELECT COMPRA_NUMERO, PRODUCTO_VARIANTE_CODIGO, sum(COMPRA_PRODUCTO_CANTIDAD), COMPRA_PRODUCTO_PRECIO
	FROM GD2C2022.gd_esquema.Maestra
	WHERE COMPRA_NUMERO IS NOT NULL AND PRODUCTO_VARIANTE_CODIGO IS NOT NULL
	GROUP BY COMPRA_NUMERO, PRODUCTO_VARIANTE_CODIGO, COMPRA_PRODUCTO_PRECIO
END
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



select * from DATA4MIND.dbo.medio_pago_compra
select * from DATA4MIND.dbo.medio_pago_venta