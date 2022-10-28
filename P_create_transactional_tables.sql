USE [DATA4MIND]
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
        codigo_postal DECIMAL(18,0) UNIQUE,
        provincia_codigo DECIMAL(19,0) REFERENCES provincia(provincia_codigo),
        nombre_localidad NVARCHAR(255)
		);


	-- ORDEN: Cliente, Proveedor, Producto, Variante, Producto_variante, (Venta, envio, canal, medio_pago_venta) ALTER, (compra, medio_pago_compra) ALTER, producto_comprado, producto_vendido, descuento_venta, descuento_compra--
	/** ALTER TABLE [nombre]
	    ADD CONSTRAINT FK_[tablaOrigen]_[tablaDestino]
		FOREIGN KEY [nombreColumna] REFERENCES [tablaDestino]([PKDestino])
	  **/


END 

EXEC CREATE_TRANSACTIONAL_TABLES;