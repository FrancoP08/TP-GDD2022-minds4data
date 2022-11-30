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
		canal NVARCHAR(2255),
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
		importe DECIMAL(18,2),
		tipoCupon NVARCHAR(50)
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
	SELECT venta_codigo, medio_pago_costo, costo_envio, canal_costo
	FROM [DATA4MIND].[venta]

	INSERT INTO [DATA4MIND].[BI_descuento_venta] (idVenta, importe)
	SELECT venta_codigo, importe
	FROM [DATA4MIND].[descuento_venta]

	INSERT INTO [DATA4MIND].[BI_cupon] (idVenta, importe, tipoCupon)
	SELECT venta_codigo, importe, tipo
	FROM [DATA4MIND].[cupon_canjeado] cc
	JOIN [DATA4MIND].[cupon] c ON cc.cupon_codigo = c.cupon_codigo

	INSERT INTO [DATA4MIND].[BI_hechos_venta] (idVenta, idProvincia, idTipoEnvio, idCanal, idMedioPago, 
		idRangoEtario, idProducto, idCategoria, idTipoDescuento, fecha, cantidad, precio)
	SELECT v.venta_codigo, provincia_codigo, medio_envio_codigo, canal_codigo, medio_pago_codigo, idRangoEtario, 
		p.producto_codigo, categoria_codigo, tipo_descuento_codigo, fecha, cantidad, precio
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

--Las ganancias mensuales de cada canal de venta.
--Se entiende por ganancias al total de las ventas, menos el total de las
--compras, menos los costos de transacción totales aplicados asociados los
--medios de pagos utilizados en las mismas.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='GANANCIAS_CANAL' AND type='v')
	DROP VIEW [DATA4MIND].[GANANCIAS_CANAL]
GO

CREATE VIEW [DATA4MIND].[GANANCIAS_CANAL] AS
SELECT canal, v.fecha, ventas - SUM(c.cantidad * c.precio) ganancias
FROM (
	SELECT idCanal, fecha, SUM(ingresos) ventas
	FROM (
		SELECT idCanal, fecha, SUM(cantidad * precio) - SUM(costoMedioPago) ingresos
		FROM [DATA4MIND].[BI_hechos_venta] hv
		JOIN [DATA4MIND].[BI_venta] v ON hv.idVenta = v.idVenta
		GROUP BY idCanal, fecha, v.idVenta
	) vv
	GROUP BY idCanal, fecha
) v
JOIN [DATA4MIND].[BI_hechos_compra] c ON v.fecha = c.fecha
JOIN [DATA4MIND].[BI_canal] cc ON cc.idCanal = v.idCanal
GROUP BY canal, v.fecha, ventas
GO

--Los 5 productos con mayor rentabilidad anual, con sus respectivos %
--Se entiende por rentabilidad a los ingresos generados por el producto
--(ventas) durante el periodo menos la inversión realizada en el producto
--(compras) durante el periodo, todo esto sobre dichos ingresos.
--Valor expresado en porcentaje.
--Para simplificar, no es necesario tener en cuenta los descuentos aplicados.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='RENTABILIDAD' AND type='v')
	DROP VIEW [DATA4MIND].[RENTABILIDAD]
GO

CREATE VIEW [DATA4MIND].[RENTABILIDAD] AS
SELECT TOP 5 descripcion, v.anio periodo, (ventas - compras) / ventas * 100 rentabilidad
FROM (
	SELECT idProducto, anio, SUM(cantidad * precio) ventas
	FROM [DATA4MIND].[BI_hechos_venta] hv
	JOIN [DATA4MIND].[BI_tiempo] t ON hv.fecha = t.fecha
	GROUP BY idProducto, anio
) v JOIN (
	SELECT idProducto, anio, SUM(cantidad * precio) compras
	FROM [DATA4MIND].[BI_hechos_compra] hc
	JOIN [DATA4MIND].[BI_tiempo] t ON t.fecha = hc.fecha
	GROUP BY idProducto, anio
) c ON v.idProducto = c.idProducto AND v.anio = c.anio
JOIN [DATA4MIND].[BI_producto] p ON p.idProducto = v.idProducto
GO

--Las 5 categorías de productos más vendidos por rango etario de clientes
--por mes.

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

--Total de Ingresos por cada medio de pago por mes, descontando los costos
--por medio de pago (en caso que aplique) y descuentos por medio de pago
--(en caso que aplique)

IF EXISTS(SELECT 1 FROM sys.views WHERE name='INGRESOS_MEDIO_PAGO' AND type='v')
	DROP VIEW [DATA4MIND].[INGRESOS_MEDIO_PAGO]
GO

CREATE VIEW [DATA4MIND].[INGRESOS_MEDIO_PAGO] AS
SELECT tipoMedioPago, fecha, SUM(ingresos) 'Total ingresos'
FROM (
	SELECT idMedioPago, fecha, SUM(cantidad * precio) - SUM(costoMedioPago) - SUM(importe) ingresos
	FROM [DATA4MIND].[BI_hechos_venta] hv
	JOIN [DATA4MIND].[BI_venta] v ON hv.idVenta = v.idVenta
	JOIN [DATA4MIND].[BI_descuento_venta] d ON d.idVenta = v.idVenta
	GROUP BY idMedioPago, fecha
) vv
JOIN [DATA4MIND].[BI_medio_pago] m ON m.idMedioPago = vv.idMedioPago
GROUP BY tipoMedioPago, fecha
GO

--Importe total en descuentos aplicados según su tipo de descuento, por
--canal de venta, por mes. Se entiende por tipo de descuento como los
--correspondientes a envío, medio de pago, cupones, etc)

IF EXISTS(SELECT 1 FROM sys.views WHERE name='IMPORTE_DESCUENTOS' AND type='v')
	DROP VIEW [DATA4MIND].[IMPORTE_DESCUENTOS]
GO

CREATE VIEW [DATA4MIND].[IMPORTE_DESCUENTOS] AS
SELECT tipoDescuento, tipoCupon, canal, fecha, SUM(cc.importe) + SUM(d.importe) importe
FROM [DATA4MIND].[BI_hechos_venta] h
JOIN [DATA4MIND].[BI_canal] c ON h.idCanal = c.idCanal
JOIN [DATA4MIND].[BI_tipo_descuento] t ON t.idTipoDescuento = h.idTipoDescuento
JOIN [DATA4MIND].[BI_venta] v ON h.idVenta = v.idVenta
JOIN [DATA4MIND].[BI_descuento_venta] d ON v.idVenta = d.idVenta
JOIN [DATA4MIND].[BI_cupon] cc ON cc.idVenta = v.idVenta
GROUP BY tipoDescuento, tipoCupon, canal, fecha
GO

--Porcentaje de envíos realizados a cada Provincia por mes. El porcentaje
--debe representar la cantidad de envíos realizados a cada provincia sobre
--total de envío mensuales.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='PORCENTAJE_ENVIOS' AND type='v')
	DROP VIEW [DATA4MIND].[PORCENTAJE_ENVIOS]
GO

CREATE VIEW [DATA4MIND].[PORCENTAJE_ENVIOS] AS
SELECT t.fecha Fecha, p.nombreProvincia Provincia, ROUND(100*(
	SELECT COUNT(vv.costoEnvio)/SUM(vv.costoEnvio)
	FROM [DATA4MIND].[BI_hechos_venta] v
	JOIN [DATA4MIND].[BI_venta] vv ON v.idVenta = vv.idVenta
	WHERE v.idProvincia=p.idProvincia AND vv.costoEnvio IS NOT NULL
), 3) Porcentaje 
FROM [DATA4MIND].[BI_hechos_venta] hv 
JOIN [DATA4MIND].[BI_provincia] p ON (hv.idProvincia=p.idProvincia)
JOIN [DATA4MIND].[BI_tiempo] t ON (hv.fecha=t.fecha)
GROUP BY p.idProvincia, t.fecha, p.nombreProvincia
GO

--Valor promedio de envío por Provincia por Medio De Envío anual.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='PROMEDIO_ENVIOS' AND type='v')
	DROP VIEW [DATA4MIND].[PROMEDIO_ENVIOS]
GO

CREATE VIEW [DATA4MIND].[PROMEDIO_ENVIOS] AS
SELECT prom.fecha Mes, p.nombreProvincia Provincia, me.medioEnvio Medio_de_Envio, prom.Suma_Costos_Envios Promedio 
FROM (
	SELECT v.fecha, v.idProvincia Nro_Provincia, AVG(vv.costoEnvio) Suma_Costos_Envios 
	FROM [DATA4MIND].[BI_hechos_venta] v
	JOIN [DATA4MIND].[BI_venta] vv ON v.idVenta = vv.idVenta
	GROUP BY v.idProvincia, v.fecha
) prom 
JOIN [DATA4MIND].[BI_provincia] p ON (prom.Nro_Provincia=p.idProvincia)
JOIN [DATA4MIND].[BI_hechos_venta] hv ON (prom.Nro_Provincia=hv.idProvincia)
JOIN [DATA4MIND].[BI_medio_envio] me ON (hv.idTipoEnvio=me.idTipoEnvio)
GO

--Aumento promedio de precios de cada proveedor anual. Para calcular este
--indicador se debe tomar como referencia el máximo precio por año menos
--el mínimo todo esto divido el mínimo precio del año. Teniendo en cuenta
--que los precios siempre van en aumento.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='AUMENTO_PROMEDIO' AND type='v')
	DROP VIEW [DATA4MIND].[AUMENTO_PROMEDIO]
GO

CREATE VIEW [DATA4MIND].[AUMENTO_PROMEDIO] AS
SELECT razonSocial, anio, (MAX(precio) - MIN(precio)) / MIN(precio) aumentoPromedio
FROM [DATA4MIND].[BI_hechos_compra] h
JOIN [DATA4MIND].[BI_tiempo] t ON h.fecha = t.fecha
JOIN [DATA4MIND].[BI_proveedor] p ON h.idProveedor = p.cuit
GROUP BY razonSocial, anio
GO

--Los 3 productos con mayor cantidad de reposición por mes.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='MAYOR_REPOSICION' AND type='v')
	DROP VIEW [DATA4MIND].[MAYOR_REPOSICION]
GO

CREATE VIEW [DATA4MIND].[MAYOR_REPOSICION] AS
SELECT fecha, idProducto, reposicion
FROM (
	SELECT idProducto, fecha, SUM(cantidad) reposicion, ROW_NUMBER() OVER (PARTITION BY fecha ORDER BY SUM(cantidad) DESC) pos
	FROM [DATA4MIND].[BI_hechos_compra]
	GROUP BY idProducto, fecha
) subq
WHERE pos < 4
GO