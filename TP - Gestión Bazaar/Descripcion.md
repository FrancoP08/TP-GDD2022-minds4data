# **Pre-Requisitos**
## **Descripcion**
&nbsp;&nbsp;&nbsp;Para la realizacion de este trabajo practico se conto con un script que permite crear un esquema sobre una base de datos en el motor SQL Server, que incluye una única tabla, llamada maestra, que contiene datos provistos por la cátedra correspondientes al dominio del negocio del TP. Cabe aclarar que los datos no se encuentran normalizados y estan desorganizados.

## **Instalacion y preparacion del ambiente:**
#### 1. Instalar el motor de base de datos Microsoft SQL Server 2012 Express
  Proporcinamos el siguiente [link](https://www.microsoft.com/es-es/download/details.aspx?id=56042) para la descarga, eligiendo el paquete en "ingles" y la version de x64.

#### 2. Crear una instancia del motor de base de datos

- El nombre de la instancia del motor de base de datos a instalar debe llamarse “SQLSERVER2012”. 
  No utilizar el nombre “Default” para la instancia. Instalar como instancia con nombre (“Named Instance”)
- La autenticación debe ser por “Modo Mixto”
       
#### 3. El usuario administrador de la base de datos deberá tener la siguiente configuración:

- Username: "sa"
- Password: "gestionDeDatos" (o alguna contraseña de preferencia para su usuario)
    
#### 4. Crear un nuevo “Inicio de Sesión”, desde el item “Seguridad” perteneciente al servidor de Base de Datos general. El inicio de sesión debe poseer las siguientes características:
- Solapa “General”:
- Nombre de inicio de sesión: “gd”
- Autenticación de SQL Server
- Contraseña: “gd2022”
- Base de Datos Predeterminada: GD2C2022.
- El resto de los parámetros respetar sus valores default.
- Solapa “Funciones del Servidor”:
- Seleccionar “sysadmin”
- Solapa “Asignación de Usuarios”:
- Seleccionar asignar a “GD2C2022”
- Para el resto de los parámetros respetar sus valores default.   
    
#### 5. Salir del “Management Studio” como usuario “sa” y volver a ingresar con el nuevo usuario “gd” creado. Es probable que informe que la contraseña ha caducado. Cambiar la contraseña ingresando exactamente la misma que antes: “gd2017”

#### 6. Correr el [script_creacion_inicial.sql](http:github.com/../TP%20de%20GDD%20-%20V1.2.zip) que se encuentra dentro del archivo .zip en el SQL Server. 

#### 7. Correr el [EjecutarScriptTablaMaestra.bat](http:github.com/../TP%20de%20GDD%20-%20V1.2.zip) que se encuentra dentro del archivo .zip en el SQL Server. 

    El Script se requiere (generalmente) aproximadamente alrededor de 40 minutos para finalizar su ejecución, aunque puede durar menos.

#### Para mas informacion acerca de como instalar el ambiente puede acceder al siguiente [video tutorial](https://youtu.be/HD5NryLhM14).