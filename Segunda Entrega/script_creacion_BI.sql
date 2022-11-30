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
	
	EXEC sp_MSforeachtable 'DROP TABLE ?', @whereand ='AND schema_name(schema_id) = ''DATA4MIND'' AND o.name LIKE ''BI_%'''
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
		idProvincia INTEGER IDENTITY(1,1) PRIMARY KEY,
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

	-- PRODUCTO

	CREATE TABLE [DATA4MIND].[BI_producto](
		idProducto NVARCHAR(50) PRIMARY KEY,
		descripcion NVARCHAR(50)
	)

	CREATE TABLE [DATA4MIND].[BI_categoria](
		idCategoria INTEGER PRIMARY KEY,
		categoria NVARCHAR(50)
	)

	-- VENTA

	CREATE TABLE [DATA4MIND].[BI_canal](
		idCanal INTEGER PRIMARY KEY, 
		detalle NVARCHAR(2255),
		costo DECIMAL(18,2)
	)

	CREATE TABLE [DATA4MIND].[BI_medio_envio](
		idTipoEnvio INTEGER PRIMARY KEY,
		medioEnvio NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_rango_etario](
		idRangoEtario INTEGER IDENTITY(1,1) PRIMARY KEY,
		rangoEtario NVARCHAR(255)
	)


	CREATE TABLE [DATA4MIND].[BI_venta] (
		idVenta DECIMAL(19,0) PRIMARY KEY,
		costoMedioPago DECIMAL (18,2),
		costoEnvio DECIMAL(18,2),
		costoCanal DECIMAL(18,2)
	)

	CREATE TABLE [DATA4MIND].[BI_descuento_venta] (
		idDescuento INT IDENTITY PRIMARY KEY,
		idVenta DECIMAL(19,0),
		importe DECIMAL(18,2)
	)

	CREATE TABLE [DATA4MIND].[BI_cupon] (
		idCupon INT IDENTITY PRIMARY KEY,
		idVenta DECIMAL(19,0),
		importe DECIMAL(18,2)
	)

	CREATE TABLE [DATA4MIND].[BI_hechos_venta](
		idHechoVenta INTEGER IDENTITY(1,1) PRIMARY KEY,
		idVenta DECIMAL(19,0) REFERENCES [DATA4MIND].[BI_venta],
		idProvincia INTEGER REFERENCES [DATA4MIND].[BI_provincia],
		idTipoEnvio INTEGER REFERENCES [DATA4MIND].[BI_medio_envio],
		idCanal INTEGER REFERENCES [DATA4MIND].[BI_canal],
		idMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
		idRangoEtario INTEGER REFERENCES [DATA4MIND].[BI_rango_etario],
		idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
		idCategoria INTEGER REFERENCES [DATA4MIND].[BI_categoria],
		idTipoDescuento NUMERIC(10,0) REFERENCES [DATA4MIND].[BI_tipo_descuento],
		costoEnvio DECIMAL(18,2),
		fecha VARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
		cantidad INT,
		precio DECIMAL(18,2)
	)
	
	-- COMPRA

	CREATE TABLE [DATA4MIND].[BI_proveedor](
	    cuit NVARCHAR(50) PRIMARY KEY,
		razonSocial NVARCHAR(50),
		mail NVARCHAR(50), 
		domicilio NVARCHAR(50)
	)

	CREATE TABLE [DATA4MIND].[BI_hechos_compra](
		idCompra INTEGER IDENTITY(1,1) PRIMARY KEY,
		fecha VARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
		idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
		idCategoria INTEGER REFERENCES [DATA4MIND].[BI_categoria],
		idMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
		idProveedor NVARCHAR(50) REFERENCES [DATA4MIND].[BI_proveedor],
		cantidad INT,
		precio DECIMAL(18,2),
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

	INSERT INTO [DATA4MIND].[BI_provincia] (nombreProvincia)
	SELECT p.provincia FROM [DATA4MIND].[provincia] p 

	INSERT INTO [DATA4MIND].[BI_tiempo] (fecha, anio, mes)
	SELECT DISTINCT FORMAT(fecha, 'yyyy-MM'), YEAR(fecha), MONTH(fecha)
	FROM [DATA4MIND].[venta]
	UNION
	SELECT DISTINCT FORMAT(fecha, 'yyyy-MM'), YEAR(fecha), MONTH(fecha)
	FROM [DATA4MIND].[compra]

	INSERT INTO [DATA4MIND].[BI_medio_pago]
	SELECT * FROM [DATA4MIND].[medio_pago]

	INSERT INTO [DATA4MIND].[BI_rango_etario] (rangoEtario)
	VALUES ('Menores a 25'), ('Entre 25 a 35'), ('Entre 35 a 55'), ('Mayores a 55')

	-- PRODUCTO

	INSERT INTO [DATA4MIND].[BI_producto] (idProducto, descripcion)
	SELECT producto_codigo, descripcion
	FROM [DATA4MIND].[producto]

	INSERT INTO [DATA4MIND].[BI_categoria]
	SELECT * FROM [DATA4MIND].[categoria]

	-- VENTA

	INSERT INTO [DATA4MIND].[BI_canal]
	SELECT * FROM [DATA4MIND].[canal]

	INSERT INTO [DATA4MIND].[BI_medio_envio]
	SELECT * FROM [DATA4MIND].[medio_envio]

	INSERT INTO [DATA4MIND].[BI_tipo_descuento]
	SELECT * FROM [DATA4MIND].[tipo_descuento]

	INSERT INTO [DATA4MIND].[BI_venta]
	SELECT venta_codigo, costo_envio, canal_costo, medio_pago_costo
	FROM [DATA4MIND].[venta]

	INSERT INTO [DATA4MIND].[BI_descuento_venta] (idVenta, importe)
	SELECT venta_codigo, importe
	FROM [DATA4MIND].[descuento_venta]

	INSERT INTO [DATA4MIND].[BI_cupon] (idVenta, importe)
	SELECT venta_codigo, importe FROM [DATA4MIND].[cupon_canjeado]

	INSERT INTO [DATA4MIND].[BI_hechos_venta] (idVenta, idProvincia, idTipoEnvio, idCanal, idMedioPago, 
		idRangoEtario, idProducto, idCategoria, idTipoDescuento, fecha, costoEnvio, cantidad, precio)
	SELECT v.venta_codigo, provincia_codigo, medio_envio_codigo, canal_codigo, medio_pago_codigo, idRangoEtario, 
		p.producto_codigo, categoria_codigo, tipo_descuento_codigo, fecha, e.costo,  cantidad, precio
	FROM [DATA4MIND].[venta] v
	JOIN (
		SELECT cliente_codigo, provincia_codigo, DATEDIFF(YEAR, fecha_de_nacimiento, GETDATE()) edad
		FROM [DATA4MIND].[cliente] cc
		JOIN [DATA4MIND].[localidad] ll ON cc.localidad_codigo = ll.localidad_codigo
	) c ON v.cliente_codigo = c.cliente_codigo
	JOIN [DATA4MIND].[envio] e ON e.venta_codigo = v.venta_codigo
	JOIN [DATA4MIND].[BI_rango_etario] r ON
		CASE
			WHEN edad < 25 THEN 'Menores a 25'
			WHEN edad >= 25 AND edad <= 35 THEN 'Entre 25 a 35'
			WHEN edad > 35 AND edad <= 55 THEN 'Entre 35 a 55'
			ELSE 'Mayores a 55'
		END = r.rangoEtario
	JOIN [DATA4MIND].[producto_vendido] pv ON pv.venta_codigo = v.venta_codigo
	JOIN [DATA4MIND].[producto_variante] pp ON pp.producto_variante_codigo = pv.producto_variante_codigo
	JOIN [DATA4MIND].[producto] p ON p.producto_codigo = pp.producto_codigo
	JOIN [DATA4MIND].[descuento_venta] d ON v.venta_codigo = d.venta_codigo

	-- COMPRA

	INSERT INTO [DATA4MIND].[BI_proveedor] (cuit, razonSocial, mail, domicilio)
	SELECT p.proveedor_cuit, p.razon_social, p.mail, p.domicilio FROM [DATA4MIND].[proveedor] p 
  
	INSERT INTO [DATA4MIND].[BI_hechos_compra] (fecha, idProducto, idCategoria, idMedioPago, idProveedor, cantidad, precio, descuentoAplicable)
	SELECT c.fecha, p.producto_codigo, p.categoria_codigo, c.medio_pago_codigo, pe.cuit, cantidad, precio, c.descuento
	FROM [DATA4MIND].[compra] c
	JOIN [DATA4MIND].[producto_comprado] pc ON c.compra_codigo = pc.compra_codigo
	JOIN [DATA4MIND].[producto_variante] pv ON pc.producto_variante_codigo = pv.producto_variante_codigo
	JOIN [DATA4MIND].[producto] p ON pv.producto_codigo = p.producto_codigo
	JOIN [DATA4MIND].[descuento_compra] d ON c.compra_codigo = d.compra_codigo
	JOIN [DATA4MIND].[BI_proveedor] pe ON (c.proveedor_cuit=pe.cuit)
END
GO

EXEC [DATA4MIND].[MIGRAR_BI]
GO

IF EXISTS(SELECT 1 FROM sys.views WHERE name='GANANCIAS_CANAL' AND type='v')
	DROP VIEW [DATA4MIND].[GANANCIAS_CANAL]
GO

CREATE VIEW [DATA4MIND].[GANANCIAS_CANAL] AS

SELECT detalle, v.fecha, ventas - compras ganancias
FROM (
	SELECT idCanal, fecha, SUM(cantidad * precio) ventas
	FROM [DATA4MIND].[BI_hechos_venta]
	GROUP BY idCanal, fecha
) v JOIN (
	SELECT fecha, SUM(cantidad * precio) compras
	FROM [DATA4MIND].[BI_hechos_compra]
	GROUP BY fecha
) c ON v.fecha = c.fecha
JOIN [DATA4MIND].[BI_canal] cc ON cc.idCanal = v.idCanal
GO

IF EXISTS(SELECT 1 FROM sys.views WHERE name='RENTABILIDAD' AND type='v')
	DROP VIEW [DATA4MIND].[RENTABILIDAD]
GO

CREATE VIEW [DATA4MIND].[RENTABILIDAD] AS
SELECT TOP 5 descripcion, v.fecha periodo, (ventas - compras) / ventas * 100 rentabilidad
FROM (
	SELECT idProducto, fecha, SUM(cantidad * precio) ventas
	FROM [DATA4MIND].[BI_hechos_venta]
	GROUP BY idProducto, fecha
) v JOIN (
	SELECT idProducto, fecha, SUM(cantidad * precio) compras
	FROM [DATA4MIND].[BI_hechos_compra]
	GROUP BY idProducto, fecha
) c ON v.idProducto = c.idProducto AND v.fecha = c.fecha
JOIN [DATA4MIND].[BI_producto] p ON p.idProducto = v.idProducto
ORDER BY 3 DESC
GO

IF EXISTS(SELECT 1 FROM sys.views WHERE name='MAS_VENDIDOS' AND type='v')
	DROP VIEW [DATA4MIND].[MAS_VENDIDOS]
GO


CREATE VIEW [DATA4MIND].[MAS_VENDIDOS] AS
SELECT rangoEtario, fecha, categoria, SUM(cantidad) ventas
FROM [DATA4MIND].[BI_hechos_venta] v
JOIN [DATA4MIND].[BI_categoria] c ON v.idCategoria = c.idCategoria
JOIN [DATA4MIND].[BI_rango_etario] r ON v.idRangoEtario = r.idRangoEtario
WHERE v.idCategoria IN (
	SELECT TOP 5 idCategoria
	FROM [DATA4MIND].[BI_hechos_venta]
	WHERE idRangoEtario = v.idRangoEtario AND fecha = v.fecha
	GROUP BY idCategoria
	ORDER BY SUM(cantidad) DESC
)
GROUP BY rangoEtario, fecha, categoria
GO

IF EXISTS(SELECT 1 FROM sys.views WHERE name='PORCENTAJE_ENVIOS' AND type='v')
	DROP VIEW [DATA4MIND].[PORCENTAJE_ENVIOS]
GO

CREATE VIEW [DATA4MIND].[PORCENTAJE_ENVIOS] AS
(SELECT t.fecha Fecha, p.nombreProvincia Provincia, ROUND(100*(SELECT COUNT(v.costoEnvio)/SUM(v.costoEnvio) FROM [DATA4MIND].[BI_hechos_venta] v WHERE v.idProvincia=p.idProvincia AND v.costoEnvio IS NOT NULL), 3) Porcentaje 
FROM [DATA4MIND].[BI_hechos_venta] hv 
JOIN [DATA4MIND].[BI_provincia] p ON (hv.idProvincia=p.idProvincia)
JOIN [DATA4MIND].[BI_tiempo] t ON (hv.fecha=t.fecha)
GROUP BY p.idProvincia, t.fecha, p.nombreProvincia)
GO

IF EXISTS(SELECT 1 FROM sys.views WHERE name='PROMEDIO_ENVIOS' AND type='v')
	DROP VIEW [DATA4MIND].[PROMEDIO_ENVIOS]
GO

CREATE VIEW [DATA4MIND].[PROMEDIO_ENVIOS] AS
(SELECT prom.fecha Mes, p.nombreProvincia Provincia, me.medioEnvio Medio_de_Envio, prom.Suma_Costos_Envios Promedio FROM 
(SELECT v.fecha, v.idProvincia Nro_Provincia, AVG(v.costoEnvio) Suma_Costos_Envios FROM [DATA4MIND].[BI_hechos_venta] v GROUP BY v.idProvincia, v.fecha) prom 
JOIN [DATA4MIND].[BI_provincia] p ON (prom.Nro_Provincia=p.idProvincia)
JOIN [DATA4MIND].[BI_hechos_venta] hv ON (prom.Nro_Provincia=hv.idProvincia)
JOIN [DATA4MIND].[BI_medio_envio] me ON (hv.idTipoEnvio=me.idTipoEnvio))



SELECT COUNT(v.costoEnvio) Suma_Costos_Envios FROM [DATA4MIND].[BI_hechos_venta] v GROUP BY v.idProvincia
SELECT SUM(v.costoEnvio) Suma_Costos_Envios FROM [DATA4MIND].[BI_hechos_venta] v GROUP BY v.idProvincia
SELECT COUNT(costoEnvio) FROM [DATA4MIND].[BI_hechos_venta]

-- select * from [DATA4MIND].[GANANCIAS_CANAL] order by 1,2
--select * from [DATA4MIND].[PORCENTAJE_ENVIOS] order by 1, 2
--select * from [DATA4MIND].[PROMEDIO_ENVIOS] order by 1, 2
