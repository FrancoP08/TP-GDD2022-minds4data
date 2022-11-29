USE [GD2C2022]
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DATA4MIND')
	EXEC('CREATE SCHEMA DATA4MIND')
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='DROP_TABLES_BI')
	EXEC('CREATE PROCEDURE [DATA4MIND].[DROP_TABLES_BI] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[DROP_TABLES_BI]
AS
BEGIN
	DECLARE @sql NVARCHAR(500) = ''
	
	DECLARE cursorTablas CURSOR FOR
	SELECT DISTINCT 'ALTER TABLE [' + tc.TABLE_SCHEMA + '].[' +  tc.TABLE_NAME + '] DROP [' + rc.CONSTRAINT_NAME + '];'
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
	LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
	ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
	WHERE tc.TABLE_SCHEMA = 'DATA4MIND'

	OPEN cursorTablas
	FETCH NEXT FROM cursorTablas INTO @sql

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXEC sp_executesql @sql
		FETCH NEXT FROM cursorTablas INTO @Sql
	END

	CLOSE cursorTablas
	DEALLOCATE cursorTablas
	
	EXEC sp_MSforeachtable 'DROP TABLE ?', @whereand ='AND schema_name(schema_id) = ''DATA4MIND'' AND o.NAME LIKE ''BI_%'''
END
GO

EXEC [DATA4MIND].[DROP_TABLES_BI]
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='CREATE_TABLES_BI')
   EXEC('CREATE PROCEDURE [DATA4MIND].[CREATE_TABLES_BI] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[CREATE_TABLES_BI] 
AS 
BEGIN
	-- COMPARTIDAS
	
	CREATE TABLE [DATA4MIND].[BI_provincia](
		idProvincia INTEGER PRIMARY KEY,
		nombreProvincia NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_tiempo](
		fecha VARCHAR(7) PRIMARY KEY,
		anio INT, 
		mes INT
	)

	CREATE TABLE [DATA4MIND].[BI_tipo_descuento](
		idTipoDescuento NUMERIC(10,0) PRIMARY KEY,
		tipoDescuento NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_medio_pago](
		idMedioPago INTEGER  PRIMARY KEY,
		tipoMedioPago NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_rango_etario](
		idRango INTEGER IDENTITY(1,1) PRIMARY KEY,
		clasificacion NVARCHAR(255)
	)

	-- PRODUCTO

	CREATE TABLE [DATA4MIND].[BI_producto](
		idProducto NVARCHAR(50) PRIMARY KEY,
		descripcion NVARCHAR(50)
	)

	CREATE TABLE [DATA4MIND].[BI_categoria_producto](
		idCategoriaProducto INTEGER PRIMARY KEY,
		categoria NVARCHAR(50)
	)

	CREATE TABLE [DATA4MIND].[BI_marca_producto](
		idMarcaProducto INTEGER PRIMARY KEY,
		marca NVARCHAR(50)
	)

	CREATE TABLE [DATA4MIND].[BI_material_producto](
		idMaterialProducto INTEGER PRIMARY KEY, 
		material NVARCHAR(50)
	)

	-- VENTA

	CREATE TABLE [DATA4MIND].[BI_canal_venta](
		idCanal INTEGER PRIMARY KEY, 
		detalle NVARCHAR(2255),
		costo DECIMAL(18,2)
	)

	CREATE TABLE [DATA4MIND].[BI_tipo_envio](
		idTipoEnvio INTEGER PRIMARY KEY,
		medioEnvio NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_hechos_venta](
		codigo_venta INTEGER IDENTITY(1,1) PRIMARY KEY,
		idProvincia INTEGER REFERENCES [DATA4MIND].[BI_provincia],
		idTipoEnvio INTEGER REFERENCES [DATA4MIND].[BI_tipo_envio],
		idCanal INTEGER REFERENCES [DATA4MIND].[BI_canal_venta],
		idMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
		idRango INTEGER REFERENCES [DATA4MIND].[BI_rango_etario],
		fecha VARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
		idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
		idCategoriaProducto INTEGER REFERENCES [DATA4MIND].[BI_categoria_producto],
		idMarcaProducto INTEGER REFERENCES [DATA4MIND].[BI_marca_producto],
		idMaterialProducto INTEGER REFERENCES [DATA4MIND].[BI_material_producto],
		idTipoDescuento NUMERIC(10,0) REFERENCES [DATA4MIND].[BI_tipo_descuento],
		ventaProductoTotal DECIMAL(18,2),
		costoMedioPago DECIMAL (18,2),
		costoEnvio DECIMAL(18,2),
		costoCanal DECIMAL(18,2),
		descuentoAplicable DECIMAL(18,2)
	)
	
	-- COMPRA

	CREATE TABLE [DATA4MIND].[BI_hechos_compra](
		idCompra INTEGER IDENTITY(1,1) PRIMARY KEY,
		fecha VARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
		idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
		idCategoriaProducto INTEGER REFERENCES [DATA4MIND].[BI_categoria_producto],
		idMarcaProducto INTEGER REFERENCES [DATA4MIND].[BI_marca_producto],
		idMaterialProducto INTEGER REFERENCES [DATA4MIND].[BI_material_producto],
		idMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
		compraProductoTotal DECIMAL(18,2),
		descuentoAplicable DECIMAL(18,2)
	)
END
GO

EXEC [DATA4MIND].[CREATE_TABLES_BI]
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='MIGRAR_BI')
	EXEC('CREATE PROCEDURE [DATA4MIND].[MIGRAR_BI] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[MIGRAR_BI]
AS
BEGIN
	-- DIMENSIONES COMPARTIDAS

	INSERT INTO [DATA4MIND].[BI_provincia]
	SELECT * FROM [DATA4MIND].[provincia]

	INSERT INTO [DATA4MIND].[BI_tiempo] (fecha, anio, mes)
	SELECT DISTINCT FORMAT(venta_fecha, 'yyyy-MM'), YEAR(venta_fecha), MONTH(venta_fecha)
	FROM [DATA4MIND].[venta]
	UNION
	SELECT DISTINCT FORMAT(compra_fecha, 'yyyy-MM'), YEAR(compra_fecha), MONTH(compra_fecha)
	FROM [DATA4MIND].[compra]

	INSERT INTO [DATA4MIND].[BI_tipo_descuento]
	SELECT * FROM [DATA4MIND].[tipo_descuento_venta]

	INSERT INTO [DATA4MIND].[BI_medio_pago]
	SELECT * FROM [DATA4MIND].[medio_pago]

	INSERT INTO [DATA4MIND].[BI_rango_etario] (clasificacion)
	VALUES ('Menores a 25'), ('Entre 25 a 35'), ('Entre 35 a 55'), ('Mayores a 55')

	-- PRODUCTO

	INSERT INTO [DATA4MIND].[BI_producto] (idProducto, descripcion)
	SELECT producto_codigo, producto_descripcion
	FROM [DATA4MIND].[producto]

	INSERT INTO [DATA4MIND].[BI_categoria_producto]
	SELECT * FROM [DATA4MIND].[categoria]

	INSERT INTO [DATA4MIND].[BI_marca_producto]
	SELECT * FROM [DATA4MIND].[marca]

	INSERT INTO [DATA4MIND].[BI_material_producto]
	SELECT * FROM [DATA4MIND].[material]

	-- VENTA

	INSERT INTO [DATA4MIND].[BI_canal_venta]
	SELECT * FROM [DATA4MIND].[venta_canal]

	INSERT INTO [DATA4MIND].[BI_tipo_envio]
	SELECT * FROM [DATA4MIND].[medio_envio]

	INSERT INTO [DATA4MIND].[BI_hechos_venta]
	SELECT provincia_codigo, medio_envio_codigo, venta_canal_codigo, medio_pago_codigo, idRango, 
		venta_fecha, p.producto_codigo, categoria_codigo, marca_codigo, material_codigo, NULL, venta_total, 
		medio_pago_costo, v.costo_envio, venta_canal_costo, total_descuentos
	FROM [DATA4MIND].[venta] v
	JOIN (
		SELECT cliente_codigo, provincia_codigo, DATEDIFF(YEAR, cliente_fecha_nac, GETDATE()) edad
		FROM [DATA4MIND].[cliente] cc
		JOIN [DATA4MIND].[localidad] ll ON cc.cliente_localidad = localidad_codigo
	) c ON v.cliente_codigo = c.cliente_codigo
	JOIN [DATA4MIND].[envio] e ON e.venta_codigo = v.venta_codigo
	JOIN [DATA4MIND].[BI_rango_etario] r ON
		CASE
			WHEN edad < 25 THEN 'Menores a 25'
			WHEN edad >= 25 AND edad <= 35 THEN 'Entre 25 a 35'
			WHEN edad > 35 AND edad <= 55 THEN 'Entre 35 a 55'
			ELSE 'Mayores a 55'
		END = r.clasificacion
	JOIN [DATA4MIND].[producto_vendido] pv ON pv.venta_codigo = v.venta_codigo
	JOIN [DATA4MIND].[producto_variante] pp ON pp.producto_variante_codigo = pv.producto_variante_codigo
	JOIN [DATA4MIND].[producto] p ON p.producto_codigo = pp.producto_codigo

	-- COMPRA
  
	INSERT INTO [DATA4MIND].[BI_Hechos_compra] (fecha, idProducto, idCategoriaProducto, idMarcaProducto, idMaterialProducto, idMedioPago, compraProductoTotal, descuentoAplicable)
	SELECT c.compra_fecha, p.producto_codigo, p.categoria_codigo, p.marca_codigo, p.material_codigo, c.medio_pago_codigo, c.compra_total, c.descuento
	FROM [DATA4MIND].[compra] c
	JOIN [DATA4MIND].[producto_comprado] pc ON c.compra_codigo = pc.compra_codigo
	JOIN [DATA4MIND].[producto_variante] pv ON pc.producto_variante_codigo = pv.producto_variante_codigo
	JOIN [DATA4MIND].[producto] p ON pv.producto_codigo = p.producto_codigo
	JOIN [DATA4MIND].[descuento_compra] d ON c.compra_codigo = d.compra_codigo
END
GO

EXEC [DATA4MIND].[MIGRAR_BI]
GO

DROP VIEW GANANCIAS_CANAL
GO

CREATE VIEW GANANCIAS_CANAL AS
SELECT idCanal, v.fecha, SUM(ventaProductoTotal - compraProductoTotal - costoMedioPago) ganancias
FROM [DATA4MIND].[BI_hechos_venta] v JOIN [DATA4MIND].[BI_hechos_compra] c ON v.idProducto = c.idProducto
GROUP BY idCanal, v.fecha
GO