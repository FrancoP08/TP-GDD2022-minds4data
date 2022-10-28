------------------- CREACION DE TABLAS --------------------
CREATE TABLE GESTION_BAZAAR.cliente (
cliente_codigo DECIMAL(19,0) PRIMARY KEY,
cliente_nombre NVARCHAR(255),
cliente_apellido NVARCHAR(255),
cliente_dni DECIMAL(18,0) UNIQUE,
cliente_fecha_nac DATE,
cliente_direccion NVARCHAR(255),
cliente_localidad INTEGER REFERENCES localidad,
cliente_telefono DECIMAL(18,2),
cliente_email NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.localidad (
localidad_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
codigo_postal DECIMAL(18,0) UNIQUE,
provincia_codigo DECIMAL(19,0) REFERENCES provincia,
nombre_localidad NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.provincia (
provincia_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
nombre_provincia NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.envio (
envio_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
localidad_codigo DECIMAL(19,0) REFERENCES venta,
precio_envio DECIMAL(18,2),
medio_envio NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.venta (
venta_codigo DECIMAL(19,0),
venta_fecha DATE,
cliente_codigo DECIMAL(19,0) REFERENCES cliente,
venta_total DECIMAL(18,2),
importe DECIMAL(18,2),
medio_pago_codigo DECIMAL(19,0) REFERENCES medio_de_pago,
venta_canal_codigo DECIMAL(19,0) REFERENCES canal,
descuento_codigo DECIMAL(19,0) REFERENCES descuento_venta,
envio_codigo DECIMAL(19,0) REFERENCES envio
);

CREATE TABLE GESTION_BAZAAR.descuento_venta(
descuento_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
medio_pago_codigo INTEGER REFERENCES medio_pago,
venta_descuento_importe DECIMAL(18,2), 
tipo_descuento_codigo NUMERIC(10) REFERENCES tipo_descuento_venta
);

CREATE TABLE GESTION_BAZAAR.tipo_descuento_venta (
tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
venta_descuento_concepto NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.canal (
venta_canal_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
venta_canal NVARCHAR(2255),
venta_canal_costo DECIMAL(18,2)
);

CREATE TABLE cupon_canjeado (
venta_cupon_codigo DECIMAL(19,0) REFERENCES cupon,
venta_codigo DECIMAL(19,0) REFERENCES venta,
venta_cupon_importe DECIMAL(18,2),
PRIMARY KEY(venta_cupon_codigo, venta_codigo)
);

CREATE TABLE GESTION_BAZAAR.cupon (
venta_cupon_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
venta_cupon_fecha_desde DATE,
venta_cupon_fecha_hasta DATE,
venta_cupon_valor DECIMAL(18,2),
venta_cupon_tipo NVARCHAR(50)
);

-- TODO: Revisar si no debe de tener un codigo que no sea las referencias a otras tablas para PK --
CREATE TABLE GESTION_BAZAAR.producto_vendido (
venta_codigo DECIMAL(19,0) REFERENCES venta,
producto_variante_codigo NVARCHAR(50) REFERENCES producto_variante,
venta_prod_cantidad DECIMAL(18,0),
venta_prod_precio DECIMAL(18,2), 
PRIMARY KEY(venta_codigo, producto_variante_codigo)
);

CREATE TABLE GESTION_BAZAAR.producto (
producto_codigo NVARCHAR(50) PRIMARY KEY,
material_codigo NUMERIC(50),
marca_codigo NUMERIC(50),
categoria_codigo NUMERIC(50),
producto_descripcion NVARCHAR(50)
);

CREATE TABLE GESTION_BAZAAR.material (
material_codigo NUMERIC(50) IDENTITY(1,1) PRIMARY KEY,
material NVARCHAR(50)
);

CREATE TABLE GESTION_BAZAAR.marca (
marca_codigo NUMERIC(50) IDENTITY(1,1) PRIMARY KEY,
marca NVARCHAR(50)
);

CREATE TABLE GESTION_BAZAAR.categoria (
categoria_codigo NUMERIC(50) IDENTITY(1,1) PRIMARY KEY,
categoria NVARCHAR(50)
);

CREATE TABLE GESTION_BAZAAR.producto_variante (
producto_variante_codigo NVARCHAR(50) PRIMARY KEY,
producto_codigo NVARCHAR(50) REFERENCES producto,
variante_codigo INTEGER IDENTITY(1,1) REFERENCES variante,
precio_actual DECIMAL(18,2),
stock_disponible DECIMAL(18,0)
);

CREATE TABLE GESTION_BAZAAR.variante (
variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY, 
tipo_variante_codigo NVARCHAR(50) REFERENCES tipo_variante,
variante_descripcion NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.tipo_variante (
tipo_variante_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
tipo_variante_descripcion NVARCHAR(255)
);

CREATE TABLE GESTION_BAZAAR.compra (
compra_codigo DECIMAL(19,0) IDENTITY PRIMARY KEY,
proovedor_codigo INTEGER REFERENCES proveedor,
medio_de_pago_codigo NUMERIC(10) REFERENCES medio_pago,
compra_fecha DATE NOT NULL,
importe DECIMAL(18,2),
compra_total DECIMAL(18,2)
);

CREATE TABLE GESTION_BAZAAR.descuento_de_compra (
descuento_compra_codigo DECIMAL(19,0) IDENTITY(1,1) PRIMARY KEY,
compra_codigo DECIMAL(19,0) REFERENCES compra,
descuento_compra_valor DECIMAL(18,2),
tipo_descuento_concepto NUMERIC(10) REFERENCES tipo_descuento_compra
);


CREATE TABLE GESTION_BAZAAR.tipo_descuento_compra (
tipo_descuento_codigo NUMERIC(10) IDENTITY(1,1) PRIMARY KEY,
compra_descuento_concepto NVARCHAR(255) -- El concepto del descuento es el mismo que en la columna de "VENTA_DESCUENTO_CONCEPTO" --
);

CREATE TABLE GESTION_BAZAAR.proveedor (
proveedor_codigo INTEGER IDENTITY(1,1),
proveedor_razon_social NVARCHAR(50),
proveedor_cuit NVARCHAR(50) PRIMARY KEY,
proveedor_mail NVARCHAR(50),
proveedor_domicilio NVARCHAR(50),
proveedor_localidad INTEGER REFERENCES localidad
);

CREATE TABLE GESTION_BAZAAR.medio_pago (
medio_pago_codigo INTEGER IDENTITY(1,1) PRIMARY KEY,
importe DECIMAL(18,2),
medio_pago_costo DECIMAL(18,2),
tipo_medio_pago NVARCHAR(255)
);

GO 