/**
USE [GD2C2022]
GO
------------------ CREACION DE BASE DE DATOS -------------------
-- DROP DATABASE DATA4MIND; --
CREATE DATABASE DATA4MIND;
GO
**/
--------------------- CREACION DE TABLAS -----------------------
USE [GD2C2022]

USE [DATA4MIND]
GO


IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='CREATE_MASTER_TABLES')
   DROP PROCEDURE CREATE_MASTER_TABLES;
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

	-- CUPON 
	IF EXISTS(SELECT name from sys.objects WHERE name='cupon' AND type='U')
		DROP TABLE cupon;
		ELSE
			CREATE TABLE cupon (
			venta_cupon_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
			venta_cupon_fecha_desde DATE,
			venta_cupon_fecha_hasta DATE,
			venta_cupon_valor DECIMAL(18,2),
			venta_cupon_tipo NVARCHAR(50)
		);

	-- TIPO VARIANTE
	IF EXISTS(SELECT name from sys.objects WHERE name='tipo_variante' AND type='U')
		DROP TABLE tipo_variante;
		ELSE
			CREATE TABLE tipo_variante (
			tipo_variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
			tipo_variante_descripcion NVARCHAR(255)
		);

	-- CATEGORIA
	IF EXISTS(SELECT name from sys.objects WHERE name='categoria' AND type='U')
		DROP TABLE categoria;
		ELSE
			CREATE TABLE categoria (
			categoria_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
			categoria NVARCHAR(50)

		);	

	-- MARCA
	IF EXISTS(SELECT name from sys.objects WHERE name='marca' AND type='U')
		DROP TABLE marca;
		ELSE
			CREATE TABLE marca (
			marca_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
			marca NVARCHAR(50)
			);
	
	-- MATERIAL
	IF EXISTS(SELECT name from sys.objects WHERE name='material' AND type='U')
		DROP TABLE material;
		ELSE
			CREATE TABLE material (
			material_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
			material NVARCHAR(50)
			);

	-- TIPO DESCUENTO COMPRA
	IF EXISTS(SELECT name from sys.objects WHERE name='tipo_descuento_compra' AND type='U')
		DROP TABLE tipo_descuento_compra;
		ELSE
			CREATE TABLE tipo_descuento_compra (
			tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
			compra_descuento_concepto NVARCHAR(255) -- El concepto del descuento es el mismo que en la columna de "VENTA_DESCUENTO_CONCEPTO" --
			);

	-- TIPO DESCUENTO VENTA
	IF EXISTS(SELECT name from sys.objects WHERE name='tipo_descuento_venta' AND type='U')
		DROP TABLE tipo_descuento_compra;
		ELSE
			CREATE TABLE tipo_descuento_venta (
			tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
			venta_descuento_concepto NVARCHAR(255)
			);	
END 
GO

IF EXISTS(SELECT [name] FROM sys.procedures WHERE [name]='CREATE_TRANSACTIONAL_TABLES')
   DROP PROCEDURE CREATE_TRANSACTIONAL_TABLES;
GO

CREATE PROCEDURE CREATE_TRANSACTIONAL_TABLES 
AS
BEGIN
  -- LOCALIDAD
    IF EXISTS (SELECT name FROM sys.objects WHERE name='localidad' AND type='U')   
        DROP TABLE localidad;
     ELSE
	    CREATE TABLE localidad (
		localidad_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
        codigo_postal DECIMAL(18,0),
        provincia_codigo INTEGER REFERENCES provincia(provincia_codigo),
        nombre_localidad NVARCHAR(255)
		);


	-- ORDEN: Cliente, Proveedor, Producto, Variante, Producto_variante, (Venta, envio, canal, medio_pago_venta) ALTER, (compra, medio_pago_compra) ALTER, producto_comprado, producto_vendido, descuento_venta, descuento_compra--
	/** ALTER TABLE [nombre]
	    ADD CONSTRAINT FK_[tablaOrigen]_[tablaDestino]
		FOREIGN KEY [nombreColumna] REFERENCES [tablaDestino]([PKDestino])
	  **/

	-- CLIENTE
	 IF EXISTS (SELECT name FROM sys.objects WHERE name='cliente' AND type='U')   
        DROP TABLE cliente;
     ELSE
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

	-- PROVEEDOR
	IF EXISTS (SELECT name FROM sys.objects WHERE name='proveedor' AND type='U')   
        DROP TABLE proveedor;
     ELSE
		CREATE TABLE proveedor (
		proveedor_codigo INTEGER IDENTITY(1,1),
		proveedor_razon_social NVARCHAR(50),
		proveedor_cuit NVARCHAR(50) PRIMARY KEY,
		proveedor_mail NVARCHAR(50),
		proveedor_domicilio NVARCHAR(50),
		proveedor_localidad INTEGER REFERENCES localidad
		);

	-- PRODUCTO
	IF EXISTS (SELECT name FROM sys.objects WHERE name='producto' AND type='U')   
        DROP TABLE producto;
     ELSE
		CREATE TABLE producto (
		producto_codigo NVARCHAR(50) PRIMARY KEY,
		material_codigo NUMERIC(10),
		marca_codigo NUMERIC(10),
		categoria_codigo NUMERIC(10),
		producto_descripcion NVARCHAR(50)
		);
	
	-- VARIANTE
	IF EXISTS (SELECT name FROM sys.objects WHERE name='variante' AND type='U')   
        DROP TABLE variante;
     ELSE
		CREATE TABLE variante (
		variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY, 
		tipo_variante_codigo INTEGER REFERENCES tipo_variante,
		variante_descripcion NVARCHAR(255)
		);

	-- PRODUCTO_VARIANTE
	IF EXISTS (SELECT name FROM sys.objects WHERE name='producto_variante' AND type='U')   
        DROP TABLE producto_variante;
     ELSE
		CREATE TABLE producto_variante (
		producto_variante_codigo NVARCHAR(50) PRIMARY KEY,
		producto_codigo NVARCHAR(50) REFERENCES producto,
		variante_codigo INTEGER IDENTITY(1,1) REFERENCES variante,
		precio_actual DECIMAL(18,2),
		stock_disponible DECIMAL(18,0)
		);

	-- ENVIO
	IF EXISTS (SELECT name FROM sys.objects WHERE name='envio' AND type='U')   
        DROP TABLE envio;
     ELSE
		CREATE TABLE envio (
		envio_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		localidad_codigo INTEGER REFERENCES localidad,
		precio_envio DECIMAL(18,2),
		medio_envio NVARCHAR(255),
		importe DECIMAL(18,2),
		);
	
	-- CANAL
	IF EXISTS (SELECT name FROM sys.objects WHERE name='canal' AND type='U')   
        DROP TABLE canal;
     ELSE
		CREATE TABLE canal (
		venta_canal_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		venta_canal NVARCHAR(2255),
		venta_canal_costo DECIMAL(18,2),
		importe DECIMAL(18,2)
		);

	-- MEDIO PAGO VENTA
	IF EXISTS (SELECT name FROM sys.objects WHERE name='medio_pago_venta' AND type='U')   
        DROP TABLE medio_pago_venta;
     ELSE
		CREATE TABLE medio_pago_venta (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		importe DECIMAL(18,2),
		medio_pago_costo DECIMAL(18,2),
		tipo_medio_pago NVARCHAR(255)
		);
	
	--DESCUENTO VENTA
	IF EXISTS (SELECT name FROM sys.objects WHERE name='descuento_venta' AND type='U')   
        DROP TABLE descuento_venta;
     ELSE
		CREATE TABLE descuento_venta(
		descuento_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		venta_descuento_importe DECIMAL(18,2),		
		tipo_descuento_codigo NUMERIC(10) REFERENCES tipo_descuento_venta,
		importe DECIMAL(18,2)
		);

	-- VENTA
	IF EXISTS (SELECT name FROM sys.objects WHERE name='venta' AND type='U')   
        DROP TABLE venta;
     ELSE
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
		
	-- MEDIO_PAGO_COMPRA
	IF EXISTS (SELECT name FROM sys.objects WHERE name='medio_pago_compra' AND type='U')   
        DROP TABLE medio_pago_compra;
     ELSE
		CREATE TABLE medio_pago_compra (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		medio_pago_costo DECIMAL(18,2),	
		tipo_medio_pago NVARCHAR(255)
		);


	-- COMPRA
	IF EXISTS (SELECT name FROM sys.objects WHERE name='compra' AND type='U')   
        DROP TABLE compra;
     ELSE
		CREATE TABLE compra (
		compra_codigo DECIMAL(19,0) IDENTITY PRIMARY KEY,
		proovedor_codigo NVARCHAR(50) REFERENCES proveedor,
		medio_de_pago_codigo INTEGER REFERENCES medio_pago_compra,
		compra_fecha DATE NOT NULL,
		importe DECIMAL(18,2),
		compra_total DECIMAL(18,2)
		);

	-- DESCUENTO COMPRA
	IF EXISTS (SELECT name FROM sys.objects WHERE name='descuento_de_compra' AND type='U')   
        DROP TABLE descuento_de_compra;
     ELSE
		CREATE TABLE descuento_de_compra (
		descuento_compra_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
		compra_codigo DECIMAL(19,0) REFERENCES compra,
		descuento_compra_valor DECIMAL(18,2),
		tipo_descuento_concepto NUMERIC(10) REFERENCES tipo_descuento_compra,
		importe DECIMAL(18,2)
		);
	
	-- PRODUCTO COMPRADO
	IF EXISTS (SELECT name FROM sys.objects WHERE name='producto_comprado' AND type='U')   
        DROP TABLE producto_comprado;
     ELSE
		CREATE TABLE producto_comprado(
		compra_codigo DECIMAL(19,0) IDENTITY(1,1) REFERENCES compra,
		producto_variante_codigo NVARCHAR(50) REFERENCES producto_variante,
		compra_prod_cantidad DECIMAL(18,0),
		compra_prod_precio DECIMAL(18,2),
		PRIMARY KEY (compra_codigo, producto_variante_codigo)
		);

	-- PRODUCTO VENDIDO 
	IF EXISTS (SELECT name FROM sys.objects WHERE name='producto_vendido' AND type='U')   
        DROP TABLE producto_vendido;
     ELSE
		CREATE TABLE producto_vendido (
		venta_codigo DECIMAL(19,0) REFERENCES venta,
		producto_variante_codigo NVARCHAR(50) REFERENCES producto_variante,
		venta_prod_cantidad DECIMAL(18,0),
		venta_prod_precio DECIMAL(18,2), 
		PRIMARY KEY(venta_codigo, producto_variante_codigo)
		);
	
	-- CUPON CANJEADO
	IF EXISTS (SELECT name FROM sys.objects WHERE name='cupon_canjeado' AND type='U')   
        DROP TABLE cupon_canjeado;
     ELSE
		CREATE TABLE cupon_canjeado (
		venta_cupon_codigo DECIMAL(19,0) REFERENCES cupon,
		venta_codigo DECIMAL(19,0) REFERENCES venta,
		venta_cupon_importe DECIMAL(18,2),
		PRIMARY KEY(venta_cupon_codigo, venta_codigo)
		);
END 
GO

EXEC CREATE_MASTER_TABLES;
GO

EXEC CREATE_TRANSACTIONAL_TABLES;
GO

/**

CREATE PROCEDURE migrar 
AS
BEGIN

INSERT INTO provincia (nombre_provincia)
SELECT DISTINCT(cliente_provincia)
FROM GD2C2022.gd_esquema.Maestra
WHERE cliente_provincia is not null

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


DROP TABLE descuento_de_compra;
DROP TABLE tipo_descuento_compra;
DROP TABLE producto_comprado;
DROP TABLE compra;
DROP TABLE medio_pago_compra;
DROP TABLE proveedor;
DROP TABLE producto_vendido;
DROP TABLE producto_variante;
DROP TABLE producto;
DROP TABLE categoria;
DROP TABLE marca;
DROP TABLE material;
DROP TABLE variante;
DROP TABLE tipo_variante;
DROP TABLE cupon_canjeado;
DROP TABLE cupon;
DROP TABLE venta;
DROP TABLE canal;
DROP TABLE descuento_venta;
DROP TABLE tipo_descuento_venta;
DROP TABLE medio_pago_venta;
DROP TABLE envio;
DROP TABLE cliente;
DROP TABLE localidad;
DROP TABLE provincia;

**/