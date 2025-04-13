-- Creacion de la base de datos -- 
CREATE DATABASE SharedRetailDB1
GO

-- Usar la base de datos --
USE SharedRetailDB1 
GO

-- Crear tabla Productos --
CREATE TABLE Productos (
    id_producto INT IDENTITY (1,1) PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    precio DECIMAL(10,2)
);


-- Crear tabla Inventario --
CREATE TABLE Inventario (
    id_producto_inv INT,
    cantidad_disponible INT,
    ubicacion_tienda VARCHAR(100),
    estado_stock VARCHAR(50),
    FOREIGN KEY (id_producto_inv) REFERENCES Productos(id_producto)
);


-- Crer tabla Ventas -- 
CREATE TABLE Ventas (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    id_producto INT,
    cantidad_vendida INT,
    fecha_venta DATETIME,  -- <-- cambio aquí
    tienda_origen VARCHAR(100),
    FOREIGN KEY (id_producto) REFERENCES Productos(id_producto)
);



--  -- 
-- Crear tabla AuditoriaEstadoStock 
CREATE TABLE AuditoriaEstadoStock (
    id_auditoria INT IDENTITY(1,1) PRIMARY KEY,
    id_producto INT,
    estado_anterior VARCHAR(50),
    nuevo_estado VARCHAR(50),
    fecha_cambio DATETIME DEFAULT GETDATE()
);


-- Trigger Update Estado Stock --
CREATE TRIGGER trg_UpdateEstadoStock
ON Inventario
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE inv
    SET estado_stock = 
        CASE 
            WHEN inv.cantidad_disponible <= 0 THEN 'No hay stock'
            ELSE 'Disponible'
        END
    FROM Inventario inv
    INNER JOIN inserted i ON inv.id_producto_inv = i.id_producto_inv;

    -- Auditoría del cambio de estado
    INSERT INTO AuditoriaEstadoStock (id_producto, estado_anterior, nuevo_estado)
    SELECT 
        d.id_producto_inv,
        d.estado_stock,
        CASE 
            WHEN i.cantidad_disponible <= 0 THEN 'No hay stock'
            ELSE 'Disponible'
        END
    FROM inserted i
    JOIN deleted d ON i.id_producto_inv = d.id_producto_inv
    WHERE 
        d.estado_stock <> 
        CASE 
            WHEN i.cantidad_disponible <= 0 THEN 'No hay stock'
            ELSE 'Disponible'
        END;
END;

-- 3 -- 
-- Trigger RegistrarVentas -- 
-- Trigger RegistrarVentas 
CREATE TRIGGER trg_RegistrarVenta
ON Ventas
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_producto INT, @cantidad_vendida INT, @tienda_origen VARCHAR(100);
    DECLARE @cantidad_disponible INT;

    DECLARE venta_cursor CURSOR FOR 
        SELECT id_producto, cantidad_vendida, tienda_origen FROM inserted;

    OPEN venta_cursor;

    FETCH NEXT FROM venta_cursor INTO @id_producto, @cantidad_vendida, @tienda_origen;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @cantidad_disponible = cantidad_disponible
        FROM Inventario
        WHERE id_producto_inv = @id_producto;

        IF @cantidad_disponible IS NULL
        BEGIN
            PRINT 'Producto no encontrado en inventario.';
        END
        ELSE
        BEGIN
            -- Ensure cantidad_disponible never goes below 0
            DECLARE @cantidad_a_vender INT = 
                CASE 
                    WHEN @cantidad_disponible >= @cantidad_vendida THEN @cantidad_vendida
                    ELSE @cantidad_disponible
                END;

            -- Insertar la venta ajustada con fecha actual
            INSERT INTO Ventas (id_producto, cantidad_vendida, fecha_venta, tienda_origen)
            VALUES (@id_producto, @cantidad_a_vender, GETDATE(), @tienda_origen);

            -- Actualizar inventario y evitar valores negativos
            UPDATE Inventario
            SET cantidad_disponible = 
                CASE 
                    WHEN cantidad_disponible - @cantidad_a_vender < 0 THEN 0
                    ELSE cantidad_disponible - @cantidad_a_vender
                END
            WHERE id_producto_inv = @id_producto;
        END

        FETCH NEXT FROM venta_cursor INTO @id_producto, @cantidad_vendida, @tienda_origen;
    END;

    CLOSE venta_cursor;
    DEALLOCATE venta_cursor;
END;



-- 4 --
-- Vista InvenatarioAlmacen -- 
CREATE VIEW VistaInventarioAlmacen AS
SELECT 
    p.id_producto,
    p.nombre,
    i.cantidad_disponible,
    i.ubicacion_tienda,
    i.estado_stock
FROM Productos p
JOIN Inventario i ON p.id_producto = i.id_producto_inv;


-- Vista sistema POS --
CREATE VIEW VistaPOSProductosVentas AS
SELECT 
    p.id_producto,
    p.nombre,
    p.precio,
    v.id_venta,
    v.cantidad_vendida,
    v.fecha_venta,
    v.tienda_origen
FROM Productos p
JOIN Ventas v ON p.id_producto = v.id_producto;


-- Inserts ejemplo iniciales -- 
INSERT INTO Productos (nombre, descripcion, precio)
VALUES 
('Laptop Dell', 'Intel i7', 1200.00),
('Samsung Galaxy S22', 'Teléfono de gama alta', 950.00),
('Mouse Logitech G502', 'Mouse inalámbrico', 99.99)


INSERT INTO Inventario (id_producto_inv, cantidad_disponible, ubicacion_tienda, estado_stock)
VALUES 
(1, 10, 'Quito', 'Disponible'),
(2, 0, 'Guayaquil', 'No hay stock'),
(3, 25, 'Cuenca', 'Disponible')


SELECT * FROM Productos
SELECT * FROM Inventario
SELECT * FROM Ventas
SELECT * FROM AuditoriaEstadoStock

SELECT * FROM VistaInventarioAlmacen;
SELECT * FROM VistaPOSProductosVentas;

-- Crear Usuario para base --
CREATE USER emeri FOR LOGIN emeri;
EXEC sp_addrolemember 'db_datareader', emeri;  -- Read permissions
EXEC sp_addrolemember 'db_datawriter', emeri;  -- Write permissions


-- Test tabla inventario y auditoria de estados --
UPDATE Inventario
SET cantidad_disponible = 3
WHERE id_producto_inv = 1;


-- Constraint tabla Inventario para que cantidad no sea menor a 0 --
ALTER TABLE Inventario
ADD CONSTRAINT chk_cantidad_disponible CHECK (cantidad_disponible >= 0);


