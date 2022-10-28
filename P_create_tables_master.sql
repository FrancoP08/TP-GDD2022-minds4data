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
			categoria_codigo NUMERIC(50) IDENTITY(1,1) PRIMARY KEY,
			categoria NVARCHAR(50)

		);	

	-- MARCA
	IF EXISTS(SELECT name from sys.objects WHERE name='marca' AND type='U')
		DROP TABLE marca;
		ELSE
			CREATE TABLE marca (
			marca_codigo NUMERIC(50) IDENTITY(1,1) PRIMARY KEY,
			marca NVARCHAR(50)
			);
	
	-- MATERIAL
	IF EXISTS(SELECT name from sys.objects WHERE name='material' AND type='U')
		DROP TABLE material;
		ELSE
			CREATE TABLE material (
			material_codigo NUMERIC(50) IDENTITY(1,1) PRIMARY KEY,
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

EXEC CREATE_MASTER_TABLES