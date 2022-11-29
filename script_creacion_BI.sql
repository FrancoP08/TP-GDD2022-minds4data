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

	DECLARE @tableName NVARCHAR(255)

	DECLARE cursorTablas CURSOR FOR
	SELECT DISTINCT 'ALTER TABLE [' + tc.TABLE_SCHEMA + '].[' + tc.TABLE_NAME + '] DROP [' + rc.CONSTRAINT_NAME + '];'
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
	LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
	ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
	WHERE tc.TABLE_SCHEMA = 'DATA4MIND' AND tc.TABLE_NAME LIKE 'BI_%'

	OPEN cursorTablas
	FETCH NEXT FROM cursorTablas INTO @sql

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		EXEC sp_executesql @sql
		FETCH NEXT FROM cursorTablas INTO @Sql
	END

	CLOSE cursorTablas
	DEALLOCATE cursorTablas
	
	--HAY QUR BORRAR LAS TABLAS DE BI PERO ES UN DOLOR DE HUEVOS COMO HACERLO, ESO ES EL ERROR QUE TIRA, SI NO PUEDO ARREGLAR ESO NO PUEDO SABER SI HAY MAS ERRORES

	/**
	DECLARE cursorTablasAEliminar CURSOR FOR 
	(SELECT st.name FROM sys.tables st WHERE st.name LIKE 'BI_%')

	OPEN cursorTablasAEliminar 
	FETCH NEXT FROM cursorTablasAEliminar INTO @tableName

	WHILE(@@FETCH_STATUS = 0)
	BEGIN 
	  DROP TABLE [DATA4MIND].[@tableName] 
	  FETCH NEXT FROM cursorTablasAEliminar INTO @tableName
	END
	
	CLOSE cursorTablasAEliminar
	DEALLOCATE cursorTablasAEliminar
	
	**/

	--EXEC sp_MSforeachtable 'DROP TABLE ?', @whereand='AND schema_name(schema_id) = ''DATA4MIND'''  -- LO DEJO POR LAS DUDAS PERO BORRA LAS TABLAS DEL MODELO DE TRANSACCION

	EXEC [DATA4MIND].[DROP_TABLES]
	EXEC [DATA4MIND].[CREATE_TABLES]
	EXEC [DATA4MIND].[MIGRAR]
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
  CREATE TABLE [DATA4MIND].[BI_canal_venta](
  idCanal INTEGER IDENTITY(1,1) PRIMARY KEY, 
  detalle NVARCHAR(2255)
  )

  CREATE TABLE [DATA4MIND].[BI_tipo_envio](
  idTipoEnvio INTEGER IDENTITY(1,1) PRIMARY KEY,
  medioEnvio NVARCHAR(255)
  )

  CREATE TABLE [DATA4MIND].[BI_provincia](
  idProvincia INTEGER IDENTITY(1,1) PRIMARY KEY,
  nombreProvincia NVARCHAR(255),
  codigoPostal DECIMAL(18,0),
  nombreLocalidad NVARCHAR(255)
  );

  CREATE TABLE [DATA4MIND].[BI_tiempo](
  fecha DATETIME PRIMARY KEY,
  anio INT, 
  mes INT, 
  dia INT
  );

  CREATE TABLE [DATA4MIND].[BI_producto](
  idProducto NVARCHAR(50) PRIMARY KEY,
  descripcion NVARCHAR(50),
  idVariante INTEGER REFERENCES [DATA4MIND].[variante]
  );

  CREATE TABLE [DATA4MIND].[BI_categoria_producto](
  idCategoriaProducto INTEGER IDENTITY(1,1) PRIMARY KEY,
  categoria NVARCHAR(50)
  );

  CREATE TABLE [DATA4MIND].[BI_marca_producto](
  idMarcaProducto INTEGER IDENTITY(1,1) PRIMARY KEY,
  marca NVARCHAR(50)
  );

  CREATE TABLE [DATA4MIND].[BI_material_producto](
  idMaterialProducto INTEGER IDENTITY(1,1) PRIMARY KEY, 
  material NVARCHAR(50)
  );

  CREATE TABLE [DATA4MIND].[BI_tipo_descuento](
  idTipoDescuento INTEGER IDENTITY(1,1) PRIMARY KEY,
  tipoDescuento NVARCHAR(255)
  );

  CREATE TABLE [DATA4MIND].[BI_medio_pago](
  idMedioPago INTEGER IDENTITY(1,1) PRIMARY KEY,
  tipoMedioPago NVARCHAR(255)
  );

  CREATE TABLE [DATA4MIND].[BI_rango_etario](
  idRango INTEGER IDENTITY(1,1) PRIMARY KEY,
  clasificacion NVARCHAR(255)
  );

  CREATE TABLE [DATA4MIND].[BI_Hechos_venta](
  codigo_venta INTEGER IDENTITY(1,1) PRIMARY KEY,
  idProvincia INTEGER REFERENCES [DATA4MIND].[BI_provincia],
  idTipoEnvio INTEGER REFERENCES [DATA4MIND].[BI_tipo_envio],
  idCanal INTEGER REFERENCES [DATA4MIND].[BI_canal_venta],
  idMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
  idRango INTEGER REFERENCES [DATA4MIND].[BI_rango_etario],
  fecha DATETIME REFERENCES [DATA4MIND].[BI_tiempo],
  idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
  idCategoriaProducto INTEGER REFERENCES [DATA4MIND].[BI_categoria_producto],
  idMarcaProducto INTEGER REFERENCES [DATA4MIND].[BI_marca_producto],
  idMaterialProducto INTEGER REFERENCES [DATA4MIND].[BI_material_producto],
  idTipoDescuento INTEGER REFERENCES [DATA4MIND].[BI_tipo_descuento],
  ventaProductoTotal DECIMAL(18,2),
  precioEnvio DECIMAL(18,2),
  costoCanal DECIMAL(18,2),
  descuentoAplicable DECIMAL(18,2)
  );

  CREATE TABLE [DATA4MIND].[BI_Hechos_compra](
  idCompra INTEGER IDENTITY(1,1) PRIMARY KEY,
  fecha DATETIME REFERENCES [DATA4MIND].[BI_tiempo],
  idProducto NVARCHAR(50) REFERENCES [DATA4MIND].[BI_producto],
  idCategoriaProducto INTEGER REFERENCES [DATA4MIND].[BI_categoria_producto],
  idMarcaProducto INTEGER REFERENCES [DATA4MIND].[BI_marca_producto],
  idMaterialProducto INTEGER REFERENCES [DATA4MIND].[BI_material_producto],
  idTipoDescuento INTEGER REFERENCES [DATA4MIND].[BI_tipo_descuento],
  idMedioPago INTEGER REFERENCES [DATA4MIND].[BI_medio_pago],
  compraProductoTotal DECIMAL(18,2),
  descuentoAplicable DECIMAL(18,2)
  );
 
END
GO

EXEC [DATA4MIND].[CREATE_TABLES_BI] 

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='MIGRAR_BI')
	EXEC('CREATE PROCEDURE [DATA4MIND].[MIGRAR_BI] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[MIGRAR_BI]
AS
BEGIN
  INSERT INTO [DATA4MIND].[BI_canal_venta] (detalle)
  (SELECT DISTINCT v.venta_canal FROM [DATA4MIND].[venta_canal] v)

  INSERT INTO [DATA4MIND].[BI_tipo_envio] (medioEnvio)
  (SELECT DISTINCT m.medio_envio FROM [DATA4MIND].[medio_envio] m)

  INSERT INTO [DATA4MIND].[BI_provincia] (nombreProvincia, codigoPostal, nombreLocalidad)
  (SELECT p.nombre_provincia, codigo_postal, nombre_localidad FROM [DATA4MIND].[localidad] l 
  LEFT JOIN [DATA4MIND].[provincia] p ON (l.provincia_codigo=p.provincia_codigo))

  INSERT INTO [DATA4MIND].[BI_tiempo] (fecha, anio, mes, dia)
  (SELECT DISTINCT v.venta_fecha, YEAR(v.venta_fecha), MONTH(v.venta_fecha), DAY(v.venta_fecha) FROM [DATA4MIND].[venta] v)

  INSERT INTO [DATA4MIND].[BI_producto] (idProducto, descripcion, idVariante)
  (SELECT DISTINCT pv.producto_codigo, p.producto_descripcion, v.variante_codigo FROM [DATA4MIND].[producto] p 
  JOIN [DATA4MIND].[producto_variante] pv ON (p.producto_codigo=pv.producto_codigo) 
  JOIN [DATA4MIND].[variante] v ON (pv.variante_codigo=v.variante_codigo))

  INSERT INTO [DATA4MIND].[BI_categoria_producto] (categoria)
  (SELECT DISTINCT c.categoria FROM [DATA4MIND].[categoria] c)

  INSERT INTO [DATA4MIND].[BI_marca_producto] (marca)
  (SELECT m.marca FROM [DATA4MIND].[marca] m)

  INSERT INTO [DATA4MIND].[BI_material_producto] (material)
  (SELECT m.material FROM [DATA4MIND].[material] m)

  INSERT INTO [DATA4MIND].[BI_tipo_descuento] (tipoDescuento)
  (SELECT DISTINCT dv.venta_descuento_concepto FROM [DATA4MIND].[tipo_descuento_venta] dv)

  INSERT INTO [DATA4MIND].[BI_medio_pago] (tipoMedioPago)
  (SELECT mp.tipo_medio_pago FROM [DATA4MIND].[medio_pago] mp)

  INSERT INTO [DATA4MIND].[BI_rango_etario] (clasificacion)
  VALUES('Menores a 25'),
        ('Entre 25 a 35'), 
        ('Entre 35 a 55'),
        ('Mayores a 55')
  
  INSERT INTO [DATA4MIND].[BI_Hechos_compra] (fecha, idProducto, idCategoriaProducto, idMarcaProducto, idMaterialProducto, idTipoDescuento, idMedioPago, compraProductoTotal, descuentoAplicable)
  (SELECT c.compra_fecha, p.producto_codigo, p.categoria_codigo, p.marca_codigo, p.material_codigo, NULL, mp.tipo_medio_pago, (pc.compra_prod_cantidad*pc.compra_prod_precio), 
  (SELECT DESCUENTO_COMPRA_VALOR FROM [gd_esquema].Maestra WHERE COMPRA_NUMERO=c.compra_codigo) FROM [DATA4MIND].[compra] c 
  JOIN [DATA4MIND].[producto_comprado] pc ON (C.compra_codigo=PC.compra_codigo)
  JOIN [DATA4MIND].[producto_variante] pv ON (pc.producto_variante_codigo=pv.producto_variante_codigo)
  JOIN [DATA4MIND].[producto] P ON (pv.producto_codigo=p.producto_codigo)
  JOIN [DATA4MIND].[medio_pago] mp ON (mp.medio_pago_codigo=c.medio_pago_codigo)
  )
  

END
GO 

/**
EXEC [DATA4MIND].[MIGRAR_BI]

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='CREATE_VIEWS')
	EXEC('CREATE PROCEDURE [DATA4MIND].[CREATE_VIEWS] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[CREATE_VIEWS]
AS
BEGIN
END 
GO 

EXEC [DATA4MIND].[CREATE_VIEWS]
**/