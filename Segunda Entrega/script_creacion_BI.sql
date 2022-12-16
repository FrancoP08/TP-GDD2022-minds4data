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

	--- COMPARTIDAS ---
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
		idProducto NVARCHAR(50) PRIMARY KEY,
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

	--- DESCUENTOS DE VENTAS ---
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

	--- ENVIO ---
	CREATE TABLE [DATA4MIND].[BI_hecho_envio](
	idHechoEnvio INTEGER IDENTITY(1,1),
	fecha NVARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
	idProvincia INTEGER REFERENCES [DATA4MIND].[BI_provincia],
	idMedioEnvio INTEGER REFERENCES [DATA4MIND].[BI_medio_envio],
	costo DECIMAL(18,2)
	PRIMARY KEY(idHechoEnvio, fecha, idProvincia, idMedioEnvio)
	)

	--- GANANICA ---
	CREATE TABLE [DATA4MIND].[BI_hecho_ganancia] (
	idHechoGanancia INTEGER IDENTITY(1,1),
    fecha NVARCHAR(7) REFERENCES [DATA4MIND].[BI_tiempo],
	idProveedor INTEGER REFERENCES [DATA4MIND].[BI_proveedor],
	idCanal INTEGER REFERENCES [DATA4MIND].[BI_canal],
	idTipoMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
	idCategoria INTEGER REFERENCES [DATA4MIND].[BI_categoria], 
	idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
	idRangoEtario INTEGER REFERENCES [DATA4MIND].[BI_rango_etario],
	cantidadComprada INT,
	cantidadVendida INT,
	precio DECIMAL(18,2)
	PRIMARY KEY(idHechoGanancia, fecha, idProveedor, idCanal, idTipoMedioPago, idCategoria, idProducto, idRangoEtario)
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

	INSERT INTO [DATA4MIND].[BI_producto] (idProducto, descripcion)
	(SELECT p.producto_codigo, p.descripcion FROM [DATA4MIND].[producto] p)

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
	(SELECT td.concepto FROM [DATA4MIND].[tipo_descuento] td)

	INSERT INTO [DATA4MIND].[BI_canal] (canal, costo)
	(SELECT c.canal, c.costo FROM [DATA4MIND].[canal] c)

	--- ENVIOS ---
	INSERT INTO [DATA4MIND].[BI_medio_envio] (medioEnvio)
	(SELECT mv.medio_envio FROM [DATA4MIND].[medio_envio] mv)

	INSERT INTO [DATA4MIND].[BI_provincia] (provincia)
	(SELECT p.provincia FROM [DATA4MIND].[provincia] p)
	
	------- TABLAS HECHOS --------
	INSERT INTO [DATA4MIND].[BI_hecho_descuento_venta] (fecha, idTipoDescuento, idCanal, idTipoMedioPago, costoMedioPago, importeTotal)
	(SELECT DISTINCT bt.fecha, td.tipo_descuento_codigo, v.canal_codigo, v.medio_pago_codigo, SUM(v.medio_pago_costo), SUM(v.total_descuentos) FROM [DATA4MIND].[venta] v
	JOIN [DATA4MIND].[descuento_venta] dv ON (dv.venta_codigo=v.venta_codigo)
	JOIN [DATA4MIND].[tipo_descuento] td ON (td.tipo_descuento_codigo=dv.tipo_descuento_codigo)
	JOIN [DATA4MIND].[BI_canal] bc ON (bc.idCanal=v.canal_codigo)
	JOIN [DATA4MIND].[BI_medio_pago] bmp ON (bmp.idMedioPago=v.medio_pago_codigo)
	JOIN [DATA4MIND].[BI_tiempo] bt ON (bt.fecha= FORMAT(v.fecha, 'yyyy-MM'))
	GROUP BY bt.fecha, td.tipo_descuento_codigo, v.canal_codigo, v.medio_pago_codigo
	)

	INSERT INTO [DATA4MIND].[BI_hecho_envio] (fecha, idProvincia, idMedioEnvio, costo)
	(SELECT DISTINCT FORMAT(fecha, 'yyyy-MM'), bp.idProvincia, bme.idTipoEnvio, SUM(e.costo) 
	FROM [DATA4MIND].[venta] v 
	JOIN [DATA4MIND].[envio] e ON (e.venta_codigo=v.venta_codigo)
	JOIN [DATA4MIND].[localidad] l ON (l.localidad_codigo=e.localidad_codigo)
	JOIN [DATA4MIND].[BI_provincia] bp ON (bp.idProvincia=l.provincia_codigo)
	JOIN [DATA4MIND].[BI_medio_envio] bme ON (bme.idTipoEnvio=e.medio_envio_codigo)
	GROUP BY FORMAT(v.fecha, 'yyyy-MM'), bp.idProvincia, bme.idTipoEnvio
	)

	INSERT INTO [DATA4MIND].[BI_hecho_ganancia] (
		fecha, idProducto, idCategoria, idTipoMedioPago, idRangoEtario, idCanal, idProveedor, 
		cantidadVendida, cantidadComprada, precio
	) SELECT vv.fecha, vv.producto_codigo, idCategoria, idMedioPago, idRangoEtario, idCanal, idProveedor,
		cantidadVendida, cantidadComprada, vv.precio
	FROM (
		SELECT FORMAT(fecha, 'yyyy-MM') fecha, idRangoEtario, canal, medio_pago, producto_codigo, SUM(cantidad) cantidadVendida, precio
		FROM [DATA4MIND].[venta] v
		JOIN [DATA4MIND].[medio_pago] m ON v.medio_pago_codigo = m.medio_pago_codigo
		JOIN [DATA4MIND].[producto_vendido] p ON v.venta_codigo = p.venta_codigo
		JOIN [DATA4MIND].[producto_variante] pv ON pv.producto_variante_codigo = p.producto_variante_codigo
		JOIN [DATA4MIND].[canal] c ON c.canal_codigo = v.canal_codigo
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
		GROUP BY FORMAT(fecha, 'yyyy-MM'), idRangoEtario, canal, medio_pago, producto_codigo, precio
	) vv JOIN (
		SELECT FORMAT(fecha, 'yyyy-MM') fecha, p.proveedor_cuit, producto_codigo, SUM(cantidad) cantidadComprada, precio
		FROM [DATA4MIND].[compra] c
		JOIN [DATA4MIND].[proveedor] p ON c.proveedor_cuit = p.proveedor_cuit
		JOIN [DATA4MIND].[producto_comprado] pc ON c.compra_codigo = pc.compra_codigo
		JOIN [DATA4MIND].[producto_variante] pv ON pv.producto_variante_codigo = pc.producto_variante_codigo
		GROUP BY FORMAT(fecha, 'yyyy-MM'), p.proveedor_cuit, producto_codigo, precio
	) cc ON vv.fecha = cc.fecha AND vv.producto_codigo = cc.producto_codigo
	JOIN [DATA4MIND].[producto] producto ON producto.producto_codigo = vv.producto_codigo
	JOIN [DATA4MIND].[categoria] categoria ON categoria.categoria_codigo = producto.categoria_codigo
	JOIN [DATA4MIND].[BI_categoria] c ON categoria.categoria = c.categoria
	JOIN [DATA4MIND].[BI_medio_pago] mp ON mp.tipoMedioPago = medio_pago
	JOIN [DATA4MIND].[BI_canal] canal ON canal.canal = vv.canal
	JOIN [DATA4MIND].[BI_proveedor] pro ON pro.cuit = proveedor_cuit
END
GO

EXEC [DATA4MIND].[MIGRAR_BI]
GO


--Las ganancias mensuales de cada canal de venta.
--Se entiende por ganancias al total de las ventas, menos el total de las
--compras, menos los costos de transacción totales aplicados asociados los
--medios de pagos utilizados en las mismas.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='GANANCIAS_CANAL' AND type='v')
--	DROP VIEW [DATA4MIND].[GANANCIAS_CANAL]
--GO

--CREATE VIEW [DATA4MIND].[GANANCIAS_CANAL] AS 
--(SELECT v.fecha, bc.idCanal, (SUM(v.cant_total*v.precio) - SUM(c.cant_total*c.precio) - SUM(bdv.costoMedioPago)) Total FROM 
--	(SELECT DISTINCT bv.idCanal, bv.fecha, SUM(bv.cantidadVendida) cant_total, bv.precio
--	FROM [DATA4MIND].[BI_hecho_venta] bv
--	GROUP BY bv.idCanal, bv.fecha, bv.precio) v
--JOIN (SELECT DISTINCT bc.fecha, SUM(bc.cantidadComprada) cant_total, bc.precio 
--	FROM [DATA4MIND].[BI_hecho_compra] bc
--	GROUP BY bc.fecha, bc.precio) c ON v.fecha = c.fecha
--JOIN [DATA4MIND].[BI_hecho_descuento_venta] bdv ON (bdv.fecha=v.fecha)
--JOIN [DATA4MIND].[BI_canal] bc ON bc.idCanal = v.idCanal
--GROUP BY v.fecha, bc.idCanal
--)





--/**
--CREATE VIEW [DATA4MIND].[GANANCIAS_CANAL] AS
--SELECT canal, v.fecha, ventas - SUM(c.cantidad * c.precio) ganancias
--FROM (
--	SELECT idCanal, fecha, SUM(ingresos) ventas
--	FROM (
--		SELECT idCanal, fecha, SUM(cantidad * precio) - SUM(costoMedioPago) ingresos
--		FROM [DATA4MIND].[BI_hechos_venta] hv
--		JOIN [DATA4MIND].[BI_venta] v ON hv.idVenta = v.idVenta
--		GROUP BY idCanal, fecha, v.idVenta
--	) vv
--	GROUP BY idCanal, fecha
--) v
--JOIN [DATA4MIND].[BI_hechos_compra] c ON v.fecha = c.fecha
--JOIN [DATA4MIND].[BI_canal] cc ON cc.idCanal = v.idCanal
--GROUP BY canal, v.fecha, ventas
--GO
--**/








----Los 5 productos con mayor rentabilidad anual, con sus respectivos %
----Se entiende por rentabilidad a los ingresos generados por el producto
----(ventas) durante el periodo menos la inversión realizada en el producto
----(compras) durante el periodo, todo esto sobre dichos ingresos.
----Valor expresado en porcentaje.
----Para simplificar, no es necesario tener en cuenta los descuentos aplicados.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='RENTABILIDAD' AND type='v')
--	DROP VIEW [DATA4MIND].[RENTABILIDAD]
--GO

--CREATE VIEW [DATA4MIND].[RENTABILIDAD] AS
--SELECT TOP 5 descripcion, v.anio periodo, (ventas - compras) / ventas * 100 rentabilidad
--FROM (
--	SELECT idProducto, anio, SUM(cantidad * precio) ventas
--	FROM [DATA4MIND].[BI_hechos_venta] hv
--	JOIN [DATA4MIND].[BI_tiempo] t ON hv.fecha = t.fecha
--	GROUP BY idProducto, anio
--) v JOIN (
--	SELECT idProducto, anio, SUM(cantidad * precio) compras
--	FROM [DATA4MIND].[BI_hechos_compra] hc
--	JOIN [DATA4MIND].[BI_tiempo] t ON t.fecha = hc.fecha
--	GROUP BY idProducto, anio
--) c ON v.idProducto = c.idProducto AND v.anio = c.anio
--JOIN [DATA4MIND].[BI_producto] p ON p.idProducto = v.idProducto
--GO

----Las 5 categorías de productos más vendidos por rango etario de clientes
----por mes.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='MAS_VENDIDOS' AND type='v')
--	DROP VIEW [DATA4MIND].[MAS_VENDIDOS]
--GO

--CREATE VIEW [DATA4MIND].[MAS_VENDIDOS] AS
--SELECT rangoEtario, fecha, categoria, SUM(cantidad) ventas
--FROM [DATA4MIND].[BI_hechos_venta] v
--JOIN [DATA4MIND].[BI_categoria] c ON v.idCategoria = c.idCategoria
--JOIN [DATA4MIND].[BI_rango_etario] r ON v.idRangoEtario = r.idRangoEtario
--WHERE v.idCategoria IN (
--	SELECT TOP 5 idCategoria
--	FROM [DATA4MIND].[BI_hechos_venta]
--	WHERE idRangoEtario = v.idRangoEtario AND fecha = v.fecha
--	GROUP BY idCategoria
--	ORDER BY SUM(cantidad) DESC
--)
--GROUP BY rangoEtario, fecha, categoria
--GO

----Total de Ingresos por cada medio de pago por mes, descontando los costos
----por medio de pago (en caso que aplique) y descuentos por medio de pago
----(en caso que aplique)

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='INGRESOS_MEDIO_PAGO' AND type='v')
--	DROP VIEW [DATA4MIND].[INGRESOS_MEDIO_PAGO]
--GO

--CREATE VIEW [DATA4MIND].[INGRESOS_MEDIO_PAGO] AS
--SELECT tipoMedioPago, fecha, SUM(ingresos) 'Total ingresos'
--FROM (
--	SELECT idMedioPago, fecha, SUM(cantidad * precio) - SUM(costoMedioPago) - SUM(importe) ingresos
--	FROM [DATA4MIND].[BI_hechos_venta] hv
--	JOIN [DATA4MIND].[BI_venta] v ON hv.idVenta = v.idVenta
--	JOIN [DATA4MIND].[BI_descuento_venta] d ON d.idVenta = v.idVenta
--	GROUP BY idMedioPago, fecha
--) vv
--JOIN [DATA4MIND].[BI_medio_pago] m ON m.idMedioPago = vv.idMedioPago
--GROUP BY tipoMedioPago, fecha
--GO

----Importe total en descuentos aplicados según su tipo de descuento, por
----canal de venta, por mes. Se entiende por tipo de descuento como los
----correspondientes a envío, medio de pago, cupones, etc)

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='IMPORTE_DESCUENTOS' AND type='v')
--	DROP VIEW [DATA4MIND].[IMPORTE_DESCUENTOS]
--GO

--CREATE VIEW [DATA4MIND].[IMPORTE_DESCUENTOS] AS
--SELECT tipoDescuento, tipoCupon, canal, fecha, SUM(cc.importe) + SUM(d.importe) importe
--FROM [DATA4MIND].[BI_hechos_venta] h
--JOIN [DATA4MIND].[BI_canal] c ON h.idCanal = c.idCanal
--JOIN [DATA4MIND].[BI_tipo_descuento] t ON t.idTipoDescuento = h.idTipoDescuento
--JOIN [DATA4MIND].[BI_venta] v ON h.idVenta = v.idVenta
--JOIN [DATA4MIND].[BI_descuento_venta] d ON v.idVenta = d.idVenta
--JOIN [DATA4MIND].[BI_cupon] cc ON cc.idVenta = v.idVenta
--GROUP BY tipoDescuento, tipoCupon, canal, fecha
--GO

----Porcentaje de envíos realizados a cada Provincia por mes. El porcentaje
----debe representar la cantidad de envíos realizados a cada provincia sobre
----total de envío mensuales.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='PORCENTAJE_ENVIOS' AND type='v')
--	DROP VIEW [DATA4MIND].[PORCENTAJE_ENVIOS]
--GO


--CREATE VIEW [DATA4MIND].[PORCENTAJE_ENVIOS] AS














--/**
--CREATE VIEW [DATA4MIND].[PORCENTAJE_ENVIOS] AS
--SELECT t.fecha Fecha, p.nombreProvincia Provincia, ROUND(100*(
--	SELECT COUNT(vv.costoEnvio)/SUM(vv.costoEnvio)
--	FROM [DATA4MIND].[BI_hechos_venta] v
--	JOIN [DATA4MIND].[BI_venta] vv ON v.idVenta = vv.idVenta
--	WHERE v.idProvincia=p.idProvincia AND vv.costoEnvio IS NOT NULL
--), 3) Porcentaje 
--FROM [DATA4MIND].[BI_hechos_venta] hv 
--JOIN [DATA4MIND].[BI_provincia] p ON (hv.idProvincia=p.idProvincia)
--JOIN [DATA4MIND].[BI_tiempo] t ON (hv.fecha=t.fecha)
--GROUP BY p.idProvincia, t.fecha, p.nombreProvincia
--GO
--**/

----Valor promedio de envío por Provincia por Medio De Envío anual.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='PROMEDIO_ENVIOS' AND type='v')
--	DROP VIEW [DATA4MIND].[PROMEDIO_ENVIOS]
--GO

--CREATE VIEW [DATA4MIND].[PROMEDIO_ENVIOS] AS
--SELECT DISTINCT prom.fecha Mes, p.nombreProvincia Provincia, me.medioEnvio Medio_de_Envio, prom.Suma_Costos_Envios Promedio 
--FROM (
--	SELECT v.fecha, v.idProvincia Nro_Provincia, AVG(vv.costoEnvio) Suma_Costos_Envios 
--	FROM [DATA4MIND].[BI_hechos_venta] v
--	JOIN [DATA4MIND].[BI_venta] vv ON v.idVenta = vv.idVenta
--	GROUP BY v.idProvincia, v.fecha
--) prom 
--JOIN [DATA4MIND].[BI_provincia] p ON (prom.Nro_Provincia=p.idProvincia)
--JOIN [DATA4MIND].[BI_hechos_venta] hv ON (prom.Nro_Provincia=hv.idProvincia)
--JOIN [DATA4MIND].[BI_medio_envio] me ON (hv.idTipoEnvio=me.idTipoEnvio)
--GO

----Aumento promedio de precios de cada proveedor anual. Para calcular este
----indicador se debe tomar como referencia el máximo precio por año menos
----el mínimo todo esto divido el mínimo precio del año. Teniendo en cuenta
----que los precios siempre van en aumento.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='AUMENTO_PROMEDIO' AND type='v')
--	DROP VIEW [DATA4MIND].[AUMENTO_PROMEDIO]
--GO

--CREATE VIEW [DATA4MIND].[AUMENTO_PROMEDIO] AS
--SELECT razonSocial, anio, (MAX(precio) - MIN(precio)) / MIN(precio) aumentoPromedio
--FROM [DATA4MIND].[BI_hechos_compra] h
--JOIN [DATA4MIND].[BI_tiempo] t ON h.fecha = t.fecha
--JOIN [DATA4MIND].[BI_proveedor] p ON h.idProveedor = p.cuit
--GROUP BY razonSocial, anio
--GO

----Los 3 productos con mayor cantidad de reposición por mes.

--IF EXISTS(SELECT 1 FROM sys.views WHERE name='MAYOR_REPOSICION' AND type='v')
--	DROP VIEW [DATA4MIND].[MAYOR_REPOSICION]
--GO

--CREATE VIEW [DATA4MIND].[MAYOR_REPOSICION] AS
--SELECT fecha, idProducto, reposicion
--FROM (
--	SELECT idProducto, fecha, SUM(cantidad) reposicion, ROW_NUMBER() OVER (PARTITION BY fecha ORDER BY SUM(cantidad) DESC) pos
--	FROM [DATA4MIND].[BI_hechos_compra]
--	GROUP BY idProducto, fecha
--) subq
--WHERE pos < 4
--GO
