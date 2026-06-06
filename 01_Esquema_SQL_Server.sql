-- ==============================================================================
-- PROYECTO: Arquitectura Híbrida de Analítica Predictiva
-- FASE 1: Modelo Relacional, Gobernanza y DRP (SQL Server)
-- ==============================================================================

-- 1. CREACIÓN DE LA BASE DE DATOS
-- ==============================================================================
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DB_Analitica_Predictiva')
BEGIN
    CREATE DATABASE DB_Analitica_Predictiva;
END
GO

USE DB_Analitica_Predictiva;
GO

-- ==============================================================================
-- 2. NORMALIZACIÓN: CREACIÓN DE TABLAS DE DIMENSIÓN (Esquema Estrella)
-- ==============================================================================

-- Dimensión Tiempo
CREATE TABLE Dim_Tiempo (
    IdTiempo INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL UNIQUE,
    Anio INT NOT NULL,
    Mes INT NOT NULL,
    Trimestre INT NOT NULL,
    DiaSemana VARCHAR(20) NOT NULL
);
GO

-- Dimensión Geografía (Provincias y Cantones)
CREATE TABLE Dim_Geografia (
    IdGeografia INT IDENTITY(1,1) PRIMARY KEY,
    Provincia VARCHAR(100) NOT NULL,
    Region VARCHAR(50) NOT NULL
);
GO

-- Dimensión Sector (Residencial, Industrial, Comercial, etc.)
CREATE TABLE Dim_Sector (
    IdSector INT IDENTITY(1,1) PRIMARY KEY,
    NombreSector VARCHAR(100) NOT NULL UNIQUE
);
GO

-- Dimensión Empresa Eléctrica (CNEL, EEQ, etc.)
CREATE TABLE Dim_EmpresaElectrica (
    IdEmpresa INT IDENTITY(1,1) PRIMARY KEY,
    NombreEmpresa VARCHAR(150) NOT NULL UNIQUE,
    Siglas VARCHAR(50)
);
GO

-- ==============================================================================
-- 3. NORMALIZACIÓN: CREACIÓN DE TABLAS DE HECHOS (FACT TABLES)
-- ==============================================================================

-- Hechos: Demanda y Pérdidas Eléctricas (Datos de ARCONEL)
CREATE TABLE Fact_Demanda (
    IdDemanda INT IDENTITY(1,1) PRIMARY KEY,
    IdTiempo INT NOT NULL,
    IdGeografia INT NOT NULL,
    IdSector INT NOT NULL,
    IdEmpresa INT NOT NULL,
    EnergiaFacturada_MWh DECIMAL(18,4) NOT NULL,
    DemandaMaxima_MW DECIMAL(18,4),
    PorcentajePerdidas DECIMAL(5,2),
    ClientesFacturados INT,
    
    -- Llaves Foráneas (FK)
    CONSTRAINT FK_Demanda_Tiempo FOREIGN KEY (IdTiempo) REFERENCES Dim_Tiempo(IdTiempo),
    CONSTRAINT FK_Demanda_Geografia FOREIGN KEY (IdGeografia) REFERENCES Dim_Geografia(IdGeografia),
    CONSTRAINT FK_Demanda_Sector FOREIGN KEY (IdSector) REFERENCES Dim_Sector(IdSector),
    CONSTRAINT FK_Demanda_Empresa FOREIGN KEY (IdEmpresa) REFERENCES Dim_EmpresaElectrica(IdEmpresa)
);
GO

-- Hechos: Clima e Hidrología (Datos de NASA POWER)
CREATE TABLE Fact_Clima (
    IdClima INT IDENTITY(1,1) PRIMARY KEY,
    IdTiempo INT NOT NULL,
    IdGeografia INT NOT NULL,
    Temperatura_C DECIMAL(5,2) NOT NULL,
    Precipitacion_mm DECIMAL(8,2) NOT NULL,
    
    -- Llaves Foráneas (FK)
    CONSTRAINT FK_Clima_Tiempo FOREIGN KEY (IdTiempo) REFERENCES Dim_Tiempo(IdTiempo),
    CONSTRAINT FK_Clima_Geografia FOREIGN KEY (IdGeografia) REFERENCES Dim_Geografia(IdGeografia)
);
GO

-- Hechos: Economía y Valor Agregado Bruto (Datos del BCE)
CREATE TABLE Fact_Economia (
    IdEconomia INT IDENTITY(1,1) PRIMARY KEY,
    IdTiempo INT NOT NULL,
    IdSector INT NOT NULL,
    VAB_MilesUSD DECIMAL(18,4) NOT NULL,
    
    -- Llaves Foráneas (FK)
    CONSTRAINT FK_Econo_Tiempo FOREIGN KEY (IdTiempo) REFERENCES Dim_Tiempo(IdTiempo),
    CONSTRAINT FK_Econo_Sector FOREIGN KEY (IdSector) REFERENCES Dim_Sector(IdSector)
);
GO

-- ==============================================================================
-- 4. GOBERNANZA: TABLA DE AUDITORÍA Y TRIGGERS
-- ==============================================================================

-- Tabla para guardar el log de cambios en la Demanda
CREATE TABLE Auditoria_Demanda (
    IdAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    IdDemanda_Afectada INT,
    Valor_Anterior DECIMAL(18,4),
    Valor_Nuevo DECIMAL(18,4),
    UsuarioModifica VARCHAR(100),
    FechaModificacion DATETIME DEFAULT GETDATE(),
    Accion VARCHAR(50)
);
GO

-- Trigger para auditar modificaciones (UPDATE) en la tabla Fact_Demanda
CREATE TRIGGER trg_Audit_Update_Demanda
ON Fact_Demanda
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO Auditoria_Demanda (IdDemanda_Afectada, Valor_Anterior, Valor_Nuevo, UsuarioModifica, Accion)
    SELECT 
        i.IdDemanda, 
        d.EnergiaFacturada_MWh, 
        i.EnergiaFacturada_MWh, 
        SYSTEM_USER, 
        'UPDATE - FACTURACION'
    FROM inserted i
    INNER JOIN deleted d ON i.IdDemanda = d.IdDemanda;
END
GO

-- ==============================================================================
-- 5. GOBERNANZA: SEGURIDAD (ROLES Y PERMISOS GRANT/REVOKE)
-- ==============================================================================

-- Creación de roles
IF DATABASE_PRINCIPAL_ID('Rol_Analitico') IS NULL
    CREATE ROLE Rol_Analitico;
GO

IF DATABASE_PRINCIPAL_ID('Rol_AdminDB') IS NULL
    CREATE ROLE Rol_AdminDB;
GO

-- Esquemas de permisos (Grant/Revoke)
-- Rol Analítico: Solo puede leer y seleccionar para Machine Learning
GRANT SELECT ON Fact_Demanda TO Rol_Analitico;
GRANT SELECT ON Fact_Clima TO Rol_Analitico;
GRANT SELECT ON Fact_Economia TO Rol_Analitico;
GRANT SELECT ON Dim_Tiempo TO Rol_Analitico;
GRANT SELECT ON Dim_Geografia TO Rol_Analitico;
REVOKE INSERT, UPDATE, DELETE ON Fact_Demanda FROM Rol_Analitico;

-- Rol Admin: Control total
GRANT CONTROL ON DATABASE::DB_Analitica_Predictiva TO Rol_AdminDB;
GO

-- ==============================================================================
-- 6. DISASTER RECOVERY PLAN (DRP): BACKUP Y RESTORE
-- ==============================================================================
/* 
    NOTA: Ejecutar estos comandos de DRP en un Job automático del Agente SQL o 
    de forma manual cuando se requiera respaldo. Se asume ruta C:\Backups\

-- Script de RESPALDO (Full Backup)
BACKUP DATABASE DB_Analitica_Predictiva
TO DISK = 'C:\Backups\DB_Analitica_Predictiva_FULL.bak'
WITH FORMAT, 
     MEDIANAME = 'SQLServerBackups', 
     NAME = 'Full Backup de DB_Analitica_Predictiva';
GO

-- Script de RESTAURACIÓN (Restore) en caso de caída del servidor
-- (Para usar esto, asegúrate de desconectar las conexiones activas)
RESTORE DATABASE DB_Analitica_Predictiva
FROM DISK = 'C:\Backups\DB_Analitica_Predictiva_FULL.bak'
WITH REPLACE, RECOVERY;
GO
*/

PRINT 'Fase 1: Modelo Relacional, Gobernanza y DRP creados con éxito.';
GO
