USE [GD2C2022]
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DATA4MIND')
	EXEC('CREATE SCHEMA DATA4MIND')
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name = 'DROP_TABLES')
	EXEC('CREATE PROCEDURE [DATA4MIND].[DROP_TABLES] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[DROP_TABLES]
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
	
	EXEC sp_MSforeachtable 'DROP TABLE ?', @whereand='AND schema_name(schema_id) = ''DATA4MIND'' AND o.name NOT LIKE ''BI_%'''
END
GO

EXEC [DATA4MIND].[DROP_TABLES]
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='CREATE_TABLES')
   EXEC('CREATE PROCEDURE [DATA4MIND].[CREATE_TABLES] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[CREATE_TABLES]
AS
BEGIN
	-- PROVINCIA

	CREATE TABLE [DATA4MIND].[provincia] (
		provincia_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		provincia NVARCHAR(255) NOT NULL
	);

	-- LOCALIDAD

	CREATE TABLE [DATA4MIND].[localidad] (
		localidad_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		provincia_codigo INTEGER REFERENCES [DATA4MIND].[provincia] NOT NULL,
		localidad NVARCHAR(255) NOT NULL,
		codigo_postal DECIMAL(18,0) NOT NULL
	);

	-- MEDIO DE PAGO

	CREATE TABLE [DATA4MIND].[medio_pago] (
		medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		medio_pago NVARCHAR(255) NOT NULL
	);

	-- COMPRA

	CREATE TABLE [DATA4MIND].[proveedor] (
		proveedor_cuit NVARCHAR(50) PRIMARY KEY,
		localidad_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[localidad],
		razon_social NVARCHAR(50) NOT NULL,
		mail NVARCHAR(50) NOT NULL,
		domicilio NVARCHAR(50) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[compra] (
		compra_codigo DECIMAL(19,0) PRIMARY KEY,
		proveedor_cuit NVARCHAR(50) NOT NULL REFERENCES [DATA4MIND].[proveedor],
		medio_pago_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[medio_pago],
		fecha DATE NOT NULL,
		descuento DECIMAL(18,2) NULL,
		importe DECIMAL(18,2),
		total DECIMAL(18,2) NOT NULL
	);
	
	-- VENTA

	CREATE TABLE [DATA4MIND].[cliente] (
		cliente_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		localidad_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[localidad],
		nombre NVARCHAR(255) NOT NULL,
		apellido NVARCHAR(255) NOT NULL,
		dni DECIMAL(18,0) NOT NULL,
		fecha_de_nacimiento DATE NOT NULL,
		direccion NVARCHAR(255) NOT NULL,
		telefono DECIMAL(18,2) NOT NULL,
		mail NVARCHAR(255) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[canal] (
		canal_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		canal NVARCHAR(2255) NOT NULL,
		costo DECIMAL(18,2) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[venta] (
		venta_codigo DECIMAL(19,0) PRIMARY KEY,
		cliente_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[cliente],
		fecha DATE NOT NULL,
		canal_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[canal],
		canal_costo DECIMAL(18,2) NOT NULL,
		medio_pago_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[medio_pago],
		medio_pago_costo DECIMAL(18,2) NOT NULL, 
		costo_envio DECIMAL(18,2),
		total_costos DECIMAL(18,2),
		total_descuentos DECIMAL(18,2) NULL,
		importe DECIMAL(18,2),
		total DECIMAL(18,2) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[medio_envio] (
		medio_envio_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		medio_envio NVARCHAR(255) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[envio] (
		envio_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		venta_codigo DECIMAL(19,0) NOT NULL REFERENCES [DATA4MIND].[venta],
		localidad_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[localidad],
		medio_envio_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[medio_envio],
		costo DECIMAL(18,2)
	);

	CREATE TABLE [DATA4MIND].[cupon] (
		cupon_codigo NVARCHAR(255) PRIMARY KEY,
		fecha_desde DATE NOT NULL,
		fecha_hasta DATE NOT NULL,
		valor DECIMAL(18,2) NOT NULL,
		tipo NVARCHAR(50) NOT NULL
	);
	
	CREATE TABLE [DATA4MIND].[cupon_canjeado] (
		cupon_codigo NVARCHAR(255) REFERENCES [DATA4MIND].[cupon],
		venta_codigo DECIMAL(19,0) REFERENCES [DATA4MIND].[venta],
		importe DECIMAL(18,2) NOT NULL,
		PRIMARY KEY(cupon_codigo, venta_codigo)
	);

	-- DESCUENTO

	CREATE TABLE [DATA4MIND].[tipo_descuento] (
		tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		concepto NVARCHAR(255) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[descuento_venta] (
		descuento_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		venta_codigo DECIMAL(19,0) NOT NULL REFERENCES [DATA4MIND].[venta],
		tipo_descuento_codigo NUMERIC(10) NOT NULL REFERENCES [DATA4MIND].[tipo_descuento],
		importe DECIMAL(18,2) NOT NULL,
		porcentaje DECIMAL(10,2)
	);

	CREATE TABLE [DATA4MIND].[descuento_compra] (
		descuento_compra_codigo DECIMAL(19,0) PRIMARY KEY,
		compra_codigo DECIMAL(19,0) NOT NULL REFERENCES [DATA4MIND].[compra],
		valor DECIMAL(18,2) NOT NULL,
	);

	-- PRODUCTO

	CREATE TABLE [DATA4MIND].[tipo_variante] (
		tipo_variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
		descripcion NVARCHAR(255) NOT NULL
	);
	
	CREATE TABLE [DATA4MIND].[variante] (
		variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY, 
		tipo_variante_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[tipo_variante],
		descripcion NVARCHAR(255) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[categoria] (
		categoria_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		categoria NVARCHAR(50) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[marca] (
		marca_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		marca NVARCHAR(50) NOT NULL
	);
	
	CREATE TABLE [DATA4MIND].[material] (
		material_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
		material NVARCHAR(50) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[producto] (
		producto_codigo NVARCHAR(50) PRIMARY KEY,
		material_codigo NUMERIC(10) NOT NULL REFERENCES [DATA4MIND].[material],
		marca_codigo NUMERIC(10) NOT NULL REFERENCES [DATA4MIND].[marca],
		categoria_codigo NUMERIC(10) NOT NULL REFERENCES [DATA4MIND].[categoria],
		descripcion NVARCHAR(50) NOT NULL
	);

	CREATE TABLE [DATA4MIND].[producto_variante] (
		producto_variante_codigo NVARCHAR(50) PRIMARY KEY,
		producto_codigo NVARCHAR(50) NOT NULL REFERENCES [DATA4MIND].[producto],
		variante_codigo INTEGER NOT NULL REFERENCES [DATA4MIND].[variante],
		precio_actual DECIMAL(18,2),
		stock_disponible DECIMAL(18,0)
	);

	CREATE TABLE [DATA4MIND].[producto_comprado] (
		compra_codigo DECIMAL(19,0) REFERENCES [DATA4MIND].[compra],
		producto_variante_codigo NVARCHAR(50) REFERENCES [DATA4MIND].[producto_variante],
		cantidad DECIMAL(18,0) NOT NULL,
		precio DECIMAL(18,2) NOT NULL,
		PRIMARY KEY (compra_codigo, producto_variante_codigo)
	);

	CREATE TABLE [DATA4MIND].[producto_vendido] (
		venta_codigo DECIMAL(19,0) REFERENCES [DATA4MIND].[venta],
		producto_variante_codigo NVARCHAR(50) REFERENCES [DATA4MIND].[producto_variante],
		cantidad DECIMAL(18,0) NOT NULL,
		precio DECIMAL(18,2) NOT NULL, 
		PRIMARY KEY (venta_codigo, producto_variante_codigo)
	);
END
GO

EXEC [DATA4MIND].[CREATE_TABLES]
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='CREATE_INDEXES')
	EXEC('CREATE PROCEDURE [DATA4MIND].[CREATE_INDEXES] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[CREATE_INDEXES]
AS
BEGIN
	CREATE UNIQUE INDEX index_provincia ON [DATA4MIND].[provincia](provincia);
	CREATE INDEX index_localidad ON [DATA4MIND].[localidad](codigo_postal, localidad);

	CREATE UNIQUE INDEX index_categoria ON [DATA4MIND].[categoria](categoria);
	CREATE UNIQUE INDEX index_marca ON [DATA4MIND].[marca](marca);
	CREATE UNIQUE INDEX index_material ON [DATA4MIND].[material](material);

	CREATE INDEX index_cliente ON [DATA4MIND].[cliente](apellido, dni);
	CREATE UNIQUE INDEX index_medio_envio ON [DATA4MIND].[medio_envio](medio_envio);

	CREATE UNIQUE INDEX index_descuento_venta ON [DATA4MIND].[tipo_descuento](concepto); 
END
GO

EXEC [DATA4MIND].[CREATE_INDEXES]
GO

IF NOT EXISTS(SELECT name FROM sys.procedures WHERE name='MIGRAR')
	EXEC('CREATE PROCEDURE [DATA4MIND].[MIGRAR] AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE [DATA4MIND].[MIGRAR]
AS
BEGIN
	-- PROVINCIA

	INSERT INTO [DATA4MIND].[provincia] (provincia)
	SELECT DISTINCT CLIENTE_PROVINCIA
	FROM [gd_esquema].[Maestra]
	WHERE CLIENTE_PROVINCIA IS NOT NULL
	UNION
	SELECT DISTINCT PROVEEDOR_PROVINCIA
	FROM [gd_esquema].[Maestra]
	WHERE PROVEEDOR_PROVINCIA IS NOT NULL

	-- LOCALIDAD

	INSERT INTO [DATA4MIND].[localidad] (localidad, provincia_codigo, codigo_postal)
	SELECT DISTINCT CLIENTE_LOCALIDAD, provincia_codigo, CLIENTE_CODIGO_POSTAL
	FROM [gd_esquema].[Maestra] JOIN [DATA4MIND].[provincia]
	ON CLIENTE_PROVINCIA = provincia
	WHERE CLIENTE_LOCALIDAD IS NOT NULL
	UNION
	SELECT DISTINCT PROVEEDOR_LOCALIDAD, provincia_codigo, PROVEEDOR_CODIGO_POSTAL
	FROM [gd_esquema].[Maestra] JOIN [DATA4MIND].[provincia]
	ON PROVEEDOR_PROVINCIA = provincia
	WHERE PROVEEDOR_LOCALIDAD IS NOT NULL
		
	-- MEDIO DE PAGO

	INSERT INTO [DATA4MIND].[medio_pago] (medio_pago)
	SELECT DISTINCT VENTA_MEDIO_PAGO
	FROM [gd_esquema].[Maestra]
	WHERE VENTA_MEDIO_PAGO IS NOT NULL
	UNION
	SELECT DISTINCT COMPRA_MEDIO_PAGO
	FROM [gd_esquema].[Maestra]
	WHERE COMPRA_MEDIO_PAGO IS NOT NULL

	-- COMPRA

	INSERT INTO [DATA4MIND].[proveedor] (proveedor_cuit, localidad_codigo, razon_social, mail, domicilio)
	SELECT DISTINCT PROVEEDOR_CUIT, localidad_codigo, PROVEEDOR_RAZON_SOCIAL, PROVEEDOR_MAIL, PROVEEDOR_DOMICILIO
	FROM [gd_esquema].[Maestra] JOIN [DATA4MIND].[localidad]
	ON PROVEEDOR_LOCALIDAD = localidad AND PROVEEDOR_CODIGO_POSTAL = codigo_postal
	WHERE PROVEEDOR_CUIT IS NOT NULL

	INSERT INTO [DATA4MIND].[compra] (compra_codigo, proveedor_cuit, medio_pago_codigo, fecha, total)
	SELECT DISTINCT COMPRA_NUMERO, PROVEEDOR_CUIT, p.medio_pago_codigo, COMPRA_FECHA, COMPRA_TOTAL
	FROM [gd_esquema].[Maestra]
	JOIN [DATA4MIND].[medio_pago] p ON p.medio_pago = COMPRA_MEDIO_PAGO
	WHERE COMPRA_NUMERO IS NOT NULL
	
	-- VENTA

	INSERT INTO [DATA4MIND].[cliente] (localidad_codigo, nombre, apellido, dni, fecha_de_nacimiento, direccion, telefono, mail)
	SELECT DISTINCT localidad_codigo, CLIENTE_NOMBRE, CLIENTE_APELLIDO, CLIENTE_DNI, CLIENTE_FECHA_NAC, CLIENTE_DIRECCION, CLIENTE_TELEFONO, CLIENTE_MAIL
	FROM [gd_esquema].[Maestra] JOIN [DATA4MIND].[localidad]
	ON CLIENTE_LOCALIDAD = localidad AND CLIENTE_CODIGO_POSTAL = codigo_postal
	WHERE CLIENTE_DNI IS NOT NULL

	INSERT INTO [DATA4MIND].[canal] (canal, costo)
	SELECT DISTINCT VENTA_CANAL, VENTA_CANAL_COSTO
	FROM [gd_esquema].[Maestra]
	WHERE VENTA_CANAL IS NOT NULL
	
	INSERT INTO [DATA4MIND].[venta] (venta_codigo, cliente_codigo, fecha, canal_codigo, canal_costo, medio_pago_codigo, medio_pago_costo, total, costo_envio, total_costos)
	SELECT DISTINCT m.VENTA_CODIGO, c.cliente_codigo, m.VENTA_FECHA, v.canal_codigo, v.costo, mp.medio_pago_codigo, m.VENTA_MEDIO_PAGO_COSTO, m.VENTA_TOTAL, m.VENTA_ENVIO_PRECIO, m.VENTA_CANAL_COSTO + m.VENTA_MEDIO_PAGO_COSTO + m.VENTA_ENVIO_PRECIO
	FROM [gd_esquema].[Maestra] m
	JOIN [DATA4MIND].[cliente] c ON m.CLIENTE_NOMBRE = c.nombre AND m.CLIENTE_APELLIDO = c.apellido AND m.CLIENTE_DNI = c.dni
	JOIN [DATA4MIND].[canal] v ON m.VENTA_CANAL = v.canal
	JOIN [DATA4MIND].[medio_pago] mp ON mp.medio_pago = m.VENTA_MEDIO_PAGO

	INSERT INTO [DATA4MIND].[medio_envio] (medio_envio)
	SELECT DISTINCT VENTA_MEDIO_ENVIO
	FROM [gd_esquema].[Maestra]
	WHERE VENTA_MEDIO_ENVIO IS NOT NULL

	INSERT INTO [DATA4MIND].[envio] (venta_codigo, localidad_codigo, medio_envio_codigo, costo)
	SELECT DISTINCT m.VENTA_CODIGO, localidad_codigo, medio_envio_codigo, VENTA_ENVIO_PRECIO
	FROM [gd_esquema].[Maestra] m
	JOIN [DATA4MIND].[localidad] ON CLIENTE_LOCALIDAD = localidad AND CLIENTE_CODIGO_POSTAL = codigo_postal
	JOIN [DATA4MIND].[medio_envio] ON VENTA_MEDIO_ENVIO = medio_envio
	WHERE VENTA_MEDIO_ENVIO IS NOT NULL

	INSERT INTO [DATA4MIND].[cupon]
	SELECT DISTINCT VENTA_CUPON_CODIGO, VENTA_CUPON_FECHA_DESDE, VENTA_CUPON_FECHA_HASTA, VENTA_CUPON_VALOR, VENTA_CUPON_TIPO
	FROM [gd_esquema].[Maestra]
	WHERE VENTA_CUPON_CODIGO IS NOT NULL

	INSERT INTO [DATA4MIND].[cupon_canjeado]
	SELECT DISTINCT VENTA_CUPON_CODIGO, VENTA_CODIGO, VENTA_CUPON_IMPORTE
	FROM [gd_esquema].[Maestra]
	WHERE VENTA_CUPON_CODIGO IS NOT NULL

	-- DESCUENTO

	INSERT INTO [DATA4MIND].[tipo_descuento] (concepto)
	SELECT DISTINCT VENTA_DESCUENTO_CONCEPTO
	FROM [gd_esquema].[Maestra]
	WHERE VENTA_DESCUENTO_CONCEPTO IS NOT NULL

	INSERT INTO [DATA4MIND].[descuento_venta] (venta_codigo, tipo_descuento_codigo, importe)
	SELECT DISTINCT m.VENTA_CODIGO, tipo_descuento_codigo, VENTA_DESCUENTO_IMPORTE
	FROM [gd_esquema].[Maestra] m
	JOIN [DATA4MIND].[tipo_descuento] d ON m.VENTA_DESCUENTO_CONCEPTO = d.concepto
	WHERE VENTA_DESCUENTO_IMPORTE IS NOT NULL

	INSERT INTO [DATA4MIND].[descuento_compra] (descuento_compra_codigo, compra_codigo, valor)
	SELECT DISTINCT DESCUENTO_COMPRA_CODIGO, COMPRA_NUMERO, DESCUENTO_COMPRA_VALOR
	FROM [gd_esquema].[Maestra]
	WHERE DESCUENTO_COMPRA_CODIGO IS NOT NULL

	-- PRODUCTO

	INSERT INTO [DATA4MIND].[tipo_variante] (descripcion)
	SELECT DISTINCT PRODUCTO_TIPO_VARIANTE
	FROM [gd_esquema].[Maestra]
	WHERE PRODUCTO_TIPO_VARIANTE IS NOT NULL

	INSERT INTO [DATA4MIND].[variante] (tipo_variante_codigo, descripcion)
	SELECT DISTINCT tipo_variante_codigo, PRODUCTO_VARIANTE
	FROM [gd_esquema].[Maestra] JOIN [DATA4MIND].[tipo_variante]
	ON PRODUCTO_TIPO_VARIANTE = descripcion
	WHERE PRODUCTO_TIPO_VARIANTE IS NOT NULL

	INSERT INTO [DATA4MIND].[categoria] (categoria)
	SELECT DISTINCT PRODUCTO_CATEGORIA
	FROM [gd_esquema].[Maestra]
	WHERE PRODUCTO_CATEGORIA IS NOT NULL

	INSERT INTO [DATA4MIND].[marca] (marca)
	SELECT DISTINCT PRODUCTO_MARCA
	FROM [gd_esquema].[Maestra]
	WHERE PRODUCTO_MARCA IS NOT NULL

	INSERT INTO [DATA4MIND].[material] (material)
	SELECT DISTINCT PRODUCTO_MATERIAL
	FROM [gd_esquema].[Maestra]
	WHERE PRODUCTO_MATERIAL IS NOT NULL

	INSERT INTO [DATA4MIND].[producto]
	SELECT DISTINCT PRODUCTO_CODIGO, material_codigo, marca_codigo, categoria_codigo, PRODUCTO_DESCRIPCION
	FROM [gd_esquema].[Maestra]
	JOIN [DATA4MIND].[material] ON PRODUCTO_MATERIAL = material
	JOIN [DATA4MIND].[marca] ON PRODUCTO_MARCA = marca
	JOIN [DATA4MIND].[categoria] ON PRODUCTO_CATEGORIA = categoria
	WHERE PRODUCTO_CODIGO IS NOT NULL

	INSERT INTO [DATA4MIND].[producto_variante] (producto_variante_codigo, producto_codigo, variante_codigo)
	SELECT DISTINCT PRODUCTO_VARIANTE_CODIGO, PRODUCTO_CODIGO, variante_codigo
	FROM [gd_esquema].[Maestra]
	JOIN [DATA4MIND].[variante] v ON PRODUCTO_VARIANTE = v.descripcion
	WHERE PRODUCTO_VARIANTE_CODIGO IS NOT NULL

	INSERT INTO [DATA4MIND].[producto_comprado] (compra_codigo, producto_variante_codigo, cantidad, precio)
	SELECT COMPRA_NUMERO, PRODUCTO_VARIANTE_CODIGO, SUM(COMPRA_PRODUCTO_CANTIDAD), COMPRA_PRODUCTO_PRECIO
	FROM [gd_esquema].[Maestra]
	WHERE COMPRA_NUMERO IS NOT NULL AND PRODUCTO_VARIANTE_CODIGO IS NOT NULL
	GROUP BY COMPRA_NUMERO, PRODUCTO_VARIANTE_CODIGO, COMPRA_PRODUCTO_PRECIO

	INSERT INTO [DATA4MIND].[producto_vendido]
	SELECT VENTA_CODIGO, PRODUCTO_VARIANTE_CODIGO, SUM(VENTA_PRODUCTO_CANTIDAD), VENTA_PRODUCTO_PRECIO
	FROM [gd_esquema].[Maestra]
	WHERE PRODUCTO_VARIANTE_CODIGO IS NOT NULL AND VENTA_CODIGO IS NOT NULL
	GROUP BY VENTA_CODIGO, PRODUCTO_VARIANTE_CODIGO, VENTA_PRODUCTO_PRECIO

	-- UPDATES

	UPDATE producto_variante
	SET
		stock_disponible = compras - ventas,
		precio_actual = (
			SELECT TOP 1 precio
			FROM [DATA4MIND].[producto_comprado] c
			WHERE c.producto_variante_codigo = p.producto_variante_codigo
			ORDER BY compra_codigo DESC
		)
	FROM [DATA4MIND].[producto_variante] p
	JOIN (
		SELECT producto_variante_codigo, SUM(cantidad) compras
		FROM [DATA4MIND].[producto_comprado]
		GROUP BY producto_variante_codigo
	) pc ON pc.producto_variante_codigo = p.producto_variante_codigo
	JOIN (
		SELECT producto_variante_codigo, SUM(cantidad) ventas
		FROM [DATA4MIND].[producto_vendido]
		GROUP BY producto_variante_codigo
	) pv ON pv.producto_variante_codigo = p.producto_variante_codigo

	UPDATE c
	SET importe = compras, descuento = compras * valor
	FROM [DATA4MIND].[compra] c JOIN (
		SELECT compra_codigo, SUM(cantidad * precio) compras
		FROM [DATA4MIND].[producto_comprado]
		GROUP BY compra_codigo
	) p ON c.compra_codigo = p.compra_codigo
	JOIN [DATA4MIND].[descuento_compra] d ON d.compra_codigo = c.compra_codigo

	UPDATE v
	SET importe = ventas, total_descuentos = COALESCE(d.importe + c.importe, d.importe, c.importe, 0)
	FROM [DATA4MIND].[venta] v 
	JOIN (
		SELECT venta_codigo, SUM(cantidad * precio) ventas
		FROM [DATA4MIND].[producto_vendido]
		GROUP BY venta_codigo
	) p ON v.venta_codigo = p.venta_codigo
	LEFT JOIN [DATA4MIND].[descuento_venta] d ON v.venta_codigo = d.venta_codigo
	LEFT JOIN [DATA4MIND].[cupon_canjeado] c ON c.venta_codigo = v.venta_codigo

	UPDATE d
	SET porcentaje = CONVERT(DECIMAL(10,2), d.importe/v.importe)
	FROM [DATA4MIND].[descuento_venta] d JOIN [DATA4MIND].[venta] v
	ON d.venta_codigo = v.venta_codigo
END
GO

EXEC [DATA4MIND].[MIGRAR]
GO