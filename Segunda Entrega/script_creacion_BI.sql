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

    ------ TABLAS DIMENSIONES -------

	CREATE TABLE [DATA4MIND].[BI_tiempo] (
	fecha NVARCHAR(7) PRIMARY KEY,
	anio NVARCHAR(4),
	mes NVARCHAR(3)
	)

	CREATE TABLE [DATA4MIND].[BI_medio_pago](
		idMedioPago INTEGER IDENTITY(1,1) PRIMARY KEY,
		tipoMedioPago NVARCHAR(255)
	)

    --- PRODUCTO ---

	CREATE TABLE [DATA4MIND].[BI_producto](
		idProducto INT IDENTITY(1,1) PRIMARY KEY,
		descripcion NVARCHAR(50)
	)

	CREATE TABLE [DATA4MIND].[BI_categoria] (
	idCategoria INTEGER IDENTITY(1,1) PRIMARY KEY,
	categoria NVARCHAR(50) 
	)

	--- RANGO ETARIO ---

	CREATE TABLE [DATA4MIND].[BI_rango_etario](
	idRangoEtario INTEGER PRIMARY KEY,
	rango NVARCHAR(20)
	)

	--- PROVEEDOR ---

	CREATE TABLE [DATA4MIND].[BI_proveedor](
	    idProveedor INTEGER IDENTITY(1,1) PRIMARY KEY,
	    cuit NVARCHAR(50) UNIQUE,
		razonSocial NVARCHAR(50),
		mail NVARCHAR(50), 
		domicilio NVARCHAR(50)
	)

	--- DESCUENTOS ---

	CREATE TABLE [DATA4MIND].[BI_tipo_descuento](
		idTipoDescuento INTEGER IDENTITY(1,1) PRIMARY KEY,
		tipoDescuento NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_canal](
		idCanal INTEGER IDENTITY(1,1) PRIMARY KEY, 
		canal NVARCHAR(2255),
		costo DECIMAL(18,2)
	)

	--- ENVIOS ---

	CREATE TABLE [DATA4MIND].[BI_medio_envio](
		idTipoEnvio INTEGER IDENTITY(1,1) PRIMARY KEY,
		medioEnvio NVARCHAR(255)
	)

	CREATE TABLE [DATA4MIND].[BI_provincia](
	idProvincia INTEGER IDENTITY(1,1) PRIMARY KEY,
	provincia NVARCHAR(255)
	)

	------ TABLAS HECHOS -------

	CREATE TABLE [DATA4MIND].[BI_hecho_descuento_venta](
	idHechoDescuentoVenta INTEGER IDENTITY(1,1),
	fecha NVARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
	idTipoDescuento INTEGER REFERENCES [DATA4MIND].[BI_tipo_descuento],
	idCanal INTEGER REFERENCES [DATA4MIND].[BI_canal],
	idTipoMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
	costoMedioPago DECIMAL(18,2),
	importeTotal DECIMAL(18,2)
	PRIMARY KEY(idHechoDescuentoVenta, fecha, idTipoDescuento, idCanal, idTipoMedioPago)
	)

	CREATE TABLE [DATA4MIND].[BI_hecho_envio](
	idHechoEnvio INTEGER IDENTITY(1,1),
	fecha NVARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
	idProvincia INTEGER REFERENCES [DATA4MIND].[BI_provincia],
	idMedioEnvio INTEGER REFERENCES [DATA4MIND].[BI_medio_envio],
	costo DECIMAL(18,2)
	PRIMARY KEY(idHechoEnvio, fecha, idProvincia, idMedioEnvio)
	)

	CREATE TABLE [DATA4MIND].[BI_hecho_venta] (
	idHechoVenta INTEGER IDENTITY(1,1),
    fecha NVARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
	idCanal INTEGER REFERENCES [DATA4MIND].[BI_canal],
	idTipoMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
	idCategoria INTEGER REFERENCES [DATA4MIND].[BI_categoria], 
	idRangoEtario INTEGER REFERENCES [DATA4MIND].[BI_rango_etario],
	idProducto INT REFERENCES [DATA4MIND].[BI_producto],
	cantidad INT,
	precio DECIMAL(18,2)
	PRIMARY KEY(idHechoVenta, fecha, idCanal, idTipoMedioPago, idCategoria, idProducto, idRangoEtario)
	)

	CREATE TABLE [DATA4MIND].[BI_hecho_compra] (
	idHechoCompra INTEGER IDENTITY(1,1),
    fecha NVARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
	idProveedor INTEGER REFERENCES [DATA4MIND].[BI_proveedor],
	idProducto INT REFERENCES [DATA4MIND].[BI_producto],
	cantidad INT,
	precio DECIMAL(18,2)
	PRIMARY KEY(idHechoCompra, fecha, idProveedor, idProducto)
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

    ------- TABLAS DIMENSIONES --------

	--- COMPARTIDAS ---

	INSERT INTO [DATA4MIND].[BI_tiempo] (fecha, anio, mes)
	(SELECT DISTINCT FORMAT(fecha, 'yyyy-MM'), YEAR(fecha), MONTH(fecha)
	FROM [DATA4MIND].[venta]
	UNION
	SELECT DISTINCT FORMAT(fecha, 'yyyy-MM'), YEAR(fecha), MONTH(fecha)
	FROM [DATA4MIND].[compra])
	
	INSERT INTO [DATA4MIND].[BI_medio_pago] (tipoMedioPago)
	(SELECT medio_pago FROM [DATA4MIND].[medio_pago])

	--- PRODUCTO ---

	INSERT INTO [DATA4MIND].[BI_producto] (descripcion)
	(SELECT p.descripcion FROM [DATA4MIND].[producto] p)

	INSERT INTO [DATA4MIND].[BI_categoria] (categoria)
	(SELECT c.categoria FROM [DATA4MIND].[categoria] c)

	--- RANGO ETARIO ---

	INSERT INTO [DATA4MIND].[BI_rango_etario] (idRangoEtario, rango)
	VALUES (1, 'Menores a 25'), (2, 'Entre 25 a 35'), (3, 'Entre 35 a 55'), (4, 'Mayores a 55')
	
	--- PROVEEDOR ---

	INSERT INTO [DATA4MIND].[BI_proveedor] (cuit, razonSocial, mail, domicilio)
	(SELECT proveedor_cuit, razon_social, mail, domicilio FROM [DATA4MIND].[proveedor])
	
	--- DESCUENTOS ---

	INSERT INTO [DATA4MIND].[BI_tipo_descuento] (tipoDescuento)
	(SELECT td.concepto FROM [DATA4MIND].[tipo_descuento] td
	UNION
	SELECT DISTINCT tipo FROM [DATA4MIND].[cupon])

	--- CANAL ---

	INSERT INTO [DATA4MIND].[BI_canal] (canal, costo)
	(SELECT c.canal, c.costo FROM [DATA4MIND].[canal] c)

	--- ENVIOS ---

	INSERT INTO [DATA4MIND].[BI_medio_envio] (medioEnvio)
	(SELECT mv.medio_envio FROM [DATA4MIND].[medio_envio] mv)

	INSERT INTO [DATA4MIND].[BI_provincia] (provincia)
	(SELECT p.provincia FROM [DATA4MIND].[provincia] p)
	
	------- TABLAS HECHOS --------

	INSERT INTO [DATA4MIND].[BI_hecho_descuento_venta] (fecha, idTipoDescuento, idCanal, idTipoMedioPago, costoMedioPago, importeTotal)
	(SELECT FORMAT(v.fecha, 'yyyy-MM'), idTipoDescuento, idCanal, idMedioPago, SUM(v.medio_pago_costo), SUM(COALESCE(dv.importe, c.valor))
	FROM [DATA4MIND].[venta] v
	JOIN [DATA4MIND].[descuento_venta] dv ON (dv.venta_codigo=v.venta_codigo)
	JOIN [DATA4MIND].[tipo_descuento] td ON (td.tipo_descuento_codigo=dv.tipo_descuento_codigo)
	JOIN [DATA4MIND].[cupon_canjeado] cc ON (cc.venta_codigo=v.venta_codigo)
	JOIN [DATA4MIND].[cupon] c ON (c.cupon_codigo=cc.cupon_codigo)
	JOIN [DATA4MIND].[BI_tipo_descuento] d ON (d.tipoDescuento = td.concepto OR d.tipoDescuento = c.tipo)
	JOIN [DATA4MIND].[canal] ca ON ca.canal_codigo = v.canal_codigo
	JOIN [DATA4MIND].[BI_canal] bc ON (bc.canal=ca.canal)
	JOIN [DATA4MIND].[medio_pago] m ON v.medio_pago_codigo = m.medio_pago_codigo
	JOIN [DATA4MIND].[BI_medio_pago] bmp ON (bmp.tipoMedioPago=m.medio_pago)
	GROUP BY FORMAT(v.fecha, 'yyyy-MM'), idTipoDescuento, idCanal, idMedioPago
	)

	INSERT INTO [DATA4MIND].[BI_hecho_envio] (fecha, idProvincia, idMedioEnvio, costo)
	(SELECT DISTINCT FORMAT(fecha, 'yyyy-MM'), idProvincia, idTipoEnvio, SUM(e.costo) 
	FROM [DATA4MIND].[venta] v 
	JOIN [DATA4MIND].[envio] e ON (e.venta_codigo=v.venta_codigo)
	JOIN [DATA4MIND].[medio_envio] m ON m.medio_envio_codigo = e.envio_codigo
	JOIN [DATA4MIND].[localidad] l ON (l.localidad_codigo=e.localidad_codigo)
	JOIN [DATA4MIND].[provincia] p ON l.provincia_codigo = p.provincia_codigo
	JOIN [DATA4MIND].[BI_provincia] bp ON (bp.provincia=p.provincia)
	JOIN [DATA4MIND].[BI_medio_envio] bme ON (bme.medioEnvio=m.medio_envio)
	GROUP BY FORMAT(v.fecha, 'yyyy-MM'), bp.idProvincia, bme.idTipoEnvio
	)

	INSERT INTO [DATA4MIND].[BI_hecho_venta] (
		fecha, idProducto, idCategoria, idTipoMedioPago, idRangoEtario, idCanal, cantidad, precio
	)
	SELECT FORMAT(fecha, 'yyyy-MM') fecha, idProducto, idCategoria, idMedioPago, idRangoEtario, idCanal, SUM(cantidad), precio
	FROM [DATA4MIND].[venta] v
	JOIN [DATA4MIND].[medio_pago] m ON v.medio_pago_codigo = m.medio_pago_codigo
	JOIN (
		SELECT cliente_codigo, DATEDIFF(YEAR, fecha_de_nacimiento, GETDATE()) edad
		FROM [DATA4MIND].[cliente] cc
		JOIN [DATA4MIND].[localidad] ll ON cc.localidad_codigo = ll.localidad_codigo
	) cl ON v.cliente_codigo = cl.cliente_codigo
	JOIN [DATA4MIND].[BI_rango_etario] r ON
		CASE
			WHEN edad < 25 THEN 1
			WHEN edad >= 25 AND edad <= 35 THEN 2
			WHEN edad > 35 AND edad <= 55 THEN 3
			ELSE 4
		END = r.idRangoEtario
	JOIN [DATA4MIND].[producto_vendido] p ON v.venta_codigo = p.venta_codigo
	JOIN [DATA4MIND].[producto_variante] pv ON pv.producto_variante_codigo = p.producto_variante_codigo
	JOIN [DATA4MIND].[producto] producto ON producto.producto_codigo = pv.producto_codigo
	JOIN [DATA4MIND].[BI_producto] pp ON pp.descripcion = producto.descripcion
	JOIN [DATA4MIND].[categoria] categoria ON categoria.categoria_codigo = producto.categoria_codigo
	JOIN [DATA4MIND].[BI_categoria] c ON categoria.categoria = c.categoria
	JOIN [DATA4MIND].[BI_medio_pago] mp ON mp.tipoMedioPago = medio_pago
	JOIN [DATA4MIND].[canal] canal ON canal.canal_codigo = v.canal_codigo
	JOIN [DATA4MIND].[BI_canal] cc ON canal.canal = cc.canal
	GROUP BY FORMAT(fecha, 'yyyy-MM'), idProducto, idCategoria, idMedioPago, idRangoEtario, idCanal, precio

	INSERT INTO [DATA4MIND].[BI_hecho_compra] (
		fecha, idProducto, idProveedor, cantidad, precio
	) 
	SELECT FORMAT(fecha, 'yyyy-MM') fecha, idProducto, idProveedor, SUM(cantidad), precio
	FROM [DATA4MIND].[compra] c
	JOIN [DATA4MIND].[proveedor] p ON c.proveedor_cuit = p.proveedor_cuit
	JOIN [DATA4MIND].[producto_comprado] pc ON c.compra_codigo = pc.compra_codigo
	JOIN [DATA4MIND].[producto_variante] pv ON pv.producto_variante_codigo = pc.producto_variante_codigo
	JOIN [DATA4MIND].[producto] producto ON producto.producto_codigo = pv.producto_codigo
	JOIN [DATA4MIND].[BI_producto] pp ON pp.descripcion = producto.descripcion
	JOIN [DATA4MIND].[BI_proveedor] pro ON pro.cuit = p.proveedor_cuit
	GROUP BY FORMAT(fecha, 'yyyy-MM'), idProveedor, idProducto, precio
END
GO

EXEC [DATA4MIND].[MIGRAR_BI]
GO

-- 1

--Las ganancias mensuales de cada canal de venta.
--Se entiende por ganancias al total de las ventas, menos el total de las
--compras, menos los costos de transacci�n totales aplicados asociados los
--medios de pagos utilizados en las mismas.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='GANANCIAS_CANAL' AND type='v')
	DROP VIEW [DATA4MIND].[GANANCIAS_CANAL]
GO

CREATE VIEW [DATA4MIND].[GANANCIAS_CANAL] AS 
SELECT venta.fecha, canal, SUM(ingresos) - SUM(egresos) - SUM(costoMedioPago) ganancia
FROM (
	SELECT fecha, idProducto, idCanal, SUM(cantidad * precio) ingresos
	FROM [DATA4MIND].[BI_hecho_venta] v
	GROUP BY fecha, idCanal, idProducto
) venta JOIN (
	SELECT fecha, idProducto, SUM(cantidad * precio) egresos
	FROM [DATA4MIND].[BI_hecho_compra]
	GROUP BY fecha, idProducto
) compra ON compra.fecha = venta.fecha AND compra.idProducto = venta.idProducto
JOIN [DATA4MIND].[BI_hecho_descuento_venta] d ON venta.fecha = d.fecha AND venta.idCanal = d.idCanal
JOIN [DATA4MIND].[BI_canal] c ON venta.idCanal = c.idCanal
GROUP BY venta.fecha, canal
GO

-- 2

--Los 5 productos con mayor rentabilidad anual, con sus respectivos %
--Se entiende por rentabilidad a los ingresos generados por el producto
--(ventas) durante el periodo menos la inversi�n realizada en el producto
--(compras) durante el periodo, todo esto sobre dichos ingresos.
--Valor expresado en porcentaje.
--Para simplificar, no es necesario tener en cuenta los descuentos aplicados.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='RENTABILIDAD' AND type='v')
	DROP VIEW [DATA4MIND].[RENTABILIDAD]
GO

CREATE VIEW [DATA4MIND].[RENTABILIDAD] AS 
SELECT anio, descripcion, rentabilidad
FROM (
	SELECT ROW_NUMBER() OVER (PARTITION BY venta.anio ORDER BY (ingresos - egresos)/ingresos * 100 DESC) fila,
		venta.anio anio, venta.idProducto idProducto, (ingresos - egresos)/ingresos * 100 rentabilidad
	FROM (
		SELECT anio, idProducto, SUM(cantidad * precio) ingresos
		FROM [DATA4MIND].[BI_hecho_venta] v
		JOIN [DATA4MIND].[BI_tiempo] t ON v.fecha = t.fecha
		GROUP BY anio, idProducto
	) venta JOIN (
		SELECT anio, idProducto, SUM(cantidad * precio) egresos
		FROM [DATA4MIND].[BI_hecho_compra] c
		JOIN [DATA4MIND].[BI_tiempo] t ON c.fecha = t.fecha
		GROUP BY anio, idProducto
	) compra ON compra.anio = venta.anio AND compra.idProducto = venta.idProducto
) subq
JOIN [DATA4MIND].[BI_producto] p ON p.idProducto = subq.idProducto
WHERE fila <= 5
GO

-- 3

--Las 5 categor�as de productos m�s vendidos por rango etario de clientes
--por mes.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='MAS_VENDIDOS' AND type='v')
	DROP VIEW [DATA4MIND].[MAS_VENDIDOS]
GO

CREATE VIEW [DATA4MIND].[MAS_VENDIDOS] AS
SELECT rango, fecha, categoria, SUM(cantidad) ventas
FROM [DATA4MIND].[BI_hecho_venta] v
JOIN [DATA4MIND].[BI_categoria] c ON v.idCategoria = c.idCategoria
JOIN [DATA4MIND].[BI_rango_etario] r ON v.idRangoEtario = r.idRangoEtario
WHERE v.idCategoria IN (
	SELECT TOP 5 idCategoria
	FROM [DATA4MIND].[BI_hecho_venta]
	WHERE idRangoEtario = v.idRangoEtario AND fecha = v.fecha
	GROUP BY idCategoria
	ORDER BY SUM(cantidad) DESC
)
GROUP BY rango, fecha, categoria
GO

-- 4

--Total de Ingresos por cada medio de pago por mes, descontando los costos
--por medio de pago (en caso que aplique) y descuentos por medio de pago
--(en caso que aplique)

IF EXISTS(SELECT 1 FROM sys.views WHERE name='INGRESOS_MEDIO_PAGO' AND type='v')
	DROP VIEW [DATA4MIND].[INGRESOS_MEDIO_PAGO]
GO

CREATE VIEW [DATA4MIND].[INGRESOS_MEDIO_PAGO] AS
SELECT vv.fecha, tipoMedioPago, ingresos - descuentos 'Total ingresos'
FROM (
	SELECT fecha, idTipoMedioPago, SUM(cantidad * precio) ingresos
	FROM [DATA4MIND].[BI_hecho_venta]
	GROUP BY fecha, idTipoMedioPago
) vv JOIN (
	SELECT d.fecha, idTipoMedioPago, SUM(costoMedioPago) - descuentos descuentos
	FROM [DATA4MIND].[BI_hecho_descuento_venta] d
	JOIN (
		SELECT fecha, SUM(importeTotal) descuentos
		FROM [DATA4MIND].[BI_hecho_descuento_venta] d
		JOIN [DATA4MIND].[BI_tipo_descuento] t ON t.idTipoDescuento = d.idTipoDescuento
		WHERE tipoDescuento IN (SELECT tipoMedioPago FROM [DATA4MIND].[BI_medio_pago])
		GROUP BY fecha
	) subq ON subq.fecha = d.fecha
	GROUP BY d.fecha, idTipoMedioPago, descuentos
) dd ON dd.fecha = vv.fecha AND dd.idTipoMedioPago = vv.idTipoMedioPago
JOIN [DATA4MIND].[BI_medio_pago] m ON m.idMedioPago = vv.idTipoMedioPago
GO

-- 5

--Importe total en descuentos aplicados seg�n su tipo de descuento, por
--canal de venta, por mes. Se entiende por tipo de descuento como los
--correspondientes a env�o, medio de pago, cupones, etc)

IF EXISTS(SELECT 1 FROM sys.views WHERE name='IMPORTE_DESCUENTOS' AND type='v')
	DROP VIEW [DATA4MIND].[IMPORTE_DESCUENTOS]
GO

CREATE VIEW [DATA4MIND].[IMPORTE_DESCUENTOS] AS
SELECT tipoDescuento, canal, fecha, SUM(importeTotal) importe
FROM [DATA4MIND].[BI_hecho_descuento_venta] h
JOIN [DATA4MIND].[BI_tipo_descuento] d ON h.idTipoDescuento = d.idTipoDescuento
JOIN [DATA4MIND].[BI_canal] c ON h.idCanal = c.idCanal
GROUP BY tipoDescuento, canal, fecha
GO

-- 6

--Porcentaje de env�os realizados a cada Provincia por mes. El porcentaje
--debe representar la cantidad de env�os realizados a cada provincia sobre
--total de env�o mensuales.


IF EXISTS(SELECT 1 FROM sys.views WHERE name='PORCENTAJE_ENVIOS' AND type='v')
	DROP VIEW [DATA4MIND].[PORCENTAJE_ENVIOS]
GO

CREATE VIEW [DATA4MIND].[PORCENTAJE_ENVIOS] AS 
(SELECT DISTINCT be.fecha, pr.provincia, SUM(be.idHechoEnvio)/(SELECT COUNT(be2.idHechoEnvio) FROM [DATA4MIND].[BI_hecho_envio] be2 WHERE be2.fecha=be.fecha) porcentaje FROM [DATA4MIND].[BI_hecho_envio] be
JOIN [DATA4MIND].[BI_provincia] pr ON (pr.idProvincia=be.idProvincia)
GROUP BY be.fecha, pr.provincia)
GO

-- 7

--Valor promedio de env�o por Provincia por Medio De Env�o anual.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='PROMEDIO_ENVIOS' AND type='v')
	DROP VIEW [DATA4MIND].[PROMEDIO_ENVIOS]
GO


CREATE VIEW [DATA4MIND].[PROMEDIO_ENVIOS] AS
(SELECT bt.anio, pr.provincia, bme.medioEnvio, SUM(be.idHechoEnvio*be.costo)/(SELECT COUNT(pr2.idProvincia) FROM [DATA4MIND].[BI_provincia] pr2) promedio FROM [DATA4MIND].[BI_hecho_envio] be 
JOIN [DATA4MIND].[BI_provincia] pr ON (pr.idProvincia=be.idProvincia)
JOIN [DATA4MIND].[BI_medio_envio] bme ON (bme.idTipoEnvio=be.idMedioEnvio)
JOIN [DATA4MIND].[BI_tiempo] bt ON (bt.anio=SUBSTRING(be.fecha, 1, 4))
GROUP BY bt.anio, pr.provincia, bme.medioEnvio
)
GO

-- 8

--Aumento promedio de precios de cada proveedor anual. Para calcular este
--indicador se debe tomar como referencia el m�ximo precio por a�o menos
--el m�nimo todo esto divido el m�nimo precio del a�o. Teniendo en cuenta
--que los precios siempre van en aumento.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='AUMENTO_PROMEDIO' AND type='v')
	DROP VIEW [DATA4MIND].[AUMENTO_PROMEDIO]
GO

CREATE VIEW [DATA4MIND].[AUMENTO_PROMEDIO] AS
SELECT razonSocial, anio, (MAX(precio) - MIN(precio)) / MIN(precio) aumentoPromedio
FROM [DATA4MIND].[BI_hecho_compra] h
JOIN [DATA4MIND].[BI_tiempo] t ON h.fecha = t.fecha
JOIN [DATA4MIND].[BI_proveedor] p ON h.idProveedor = p.idProveedor
GROUP BY razonSocial, anio
GO

-- 9

--Los 3 productos con mayor cantidad de reposici�n por mes.

IF EXISTS(SELECT 1 FROM sys.views WHERE name='MAYOR_REPOSICION' AND type='v')
	DROP VIEW [DATA4MIND].[MAYOR_REPOSICION]
GO

CREATE VIEW [DATA4MIND].[MAYOR_REPOSICION] AS
SELECT fecha, idProducto, reposicion
FROM (
	SELECT idProducto, fecha, SUM(cantidad) reposicion, ROW_NUMBER() OVER (PARTITION BY fecha ORDER BY SUM(cantidad) DESC) pos
	FROM [DATA4MIND].[BI_hecho_compra]
	GROUP BY idProducto, fecha
) subq
WHERE pos < 4
GO
