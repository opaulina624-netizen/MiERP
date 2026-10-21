-- ==========================================================
-- MINI ERP - Script de Base de Datos (MySQL)
-- Práctica de Laboratorio: Mini ERP mediante API REST
-- ==========================================================

CREATE DATABASE IF NOT EXISTS mini_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mini_erp;

-- 1. Tabla de Usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    rol VARCHAR(30) DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Clientes
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    rfc VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100),
    direccion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de Proveedores
CREATE TABLE IF NOT EXISTS proveedores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    rfc VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(100),
    contacto VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de Productos
CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    categoria VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tabla de Ventas
CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    fecha DATE NOT NULL,
    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(30) DEFAULT 'COMPLETADA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE RESTRICT
);

-- 6. Detalle de Ventas
CREATE TABLE IF NOT EXISTS ventas_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    venta_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
);

-- 7. Tabla de Compras
CREATE TABLE IF NOT EXISTS compras (
    id INT AUTO_INCREMENT PRIMARY KEY,
    proveedor_id INT NOT NULL,
    fecha DATE NOT NULL,
    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(30) DEFAULT 'RECIBIDA',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE RESTRICT
);

-- 8. Detalle de Compras
CREATE TABLE IF NOT EXISTS compras_detalle (
    id INT AUTO_INCREMENT PRIMARY KEY,
    compra_id INT NOT NULL,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (compra_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
);

-- ==========================================================
-- Datos Semilla (Seed Data)
-- ==========================================================

-- Usuarios (password: 123456)
INSERT INTO usuarios (usuario, password, nombre, rol) VALUES
('admin', '123456', 'Administrador General', 'admin'),
('ventas', '123456', 'Ejecutivo de Ventas', 'operador');

-- Clientes
INSERT INTO clientes (nombre, rfc, telefono, correo, direccion) VALUES
('Empresa ABC SA de CV', 'ABC010101XXX', '5555555555', 'contacto@empresa.com', 'Av. Reforma 100, CDMX'),
('Soluciones Digitales del Norte', 'SDN120315AB1', '8181234567', 'ventas@sdnorte.com', 'Parque Tecnológico 202, Monterrey'),
('Consultores Fiscales S.C.', 'CFS080910KL2', '3338901234', 'info@consultores.mx', 'Av. Américas 550, Guadalajara');

-- Proveedores
INSERT INTO proveedores (nombre, rfc, telefono, correo, contacto) VALUES
('Mayorista de Tecnología S.A.', 'MTE100520AA1', '5511223344', 'ventas@mayortec.com', 'Ing. Carlos Mendoza'),
('Componentes y Redes Globales', 'CRG150612BC3', '8122334455', 'contacto@redesglobales.com', 'Lic. Laura Treviño');

-- Productos
INSERT INTO productos (codigo, nombre, precio, stock, categoria) VALUES
('PROD001', 'Laptop Lenovo', 12500.00, 10, 'Computación'),
('PROD002', 'Mouse Inalámbrico Logitech', 350.00, 5, 'Accesorios'),
('PROD003', 'Teclado Mecánico RGB', 890.00, 15, 'Accesorios'),
('PROD004', 'Monitor Dell 27 4K', 6200.00, 4, 'Monitores'),
('PROD005', 'Impresora Multifuncional Epson', 4500.00, 2, 'Impresión');

-- Ventas iniciales
INSERT INTO ventas (cliente_id, fecha, total, estado) VALUES
(1, '2026-10-07', 37500.00, 'COMPLETADA'),
(2, '2026-10-15', 12500.00, 'COMPLETADA');

INSERT INTO ventas_detalle (venta_id, producto_id, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 3, 12500.00, 37500.00),
(2, 1, 1, 12500.00, 12500.00);

-- Compras iniciales
INSERT INTO compras (proveedor_id, fecha, total, estado) VALUES
(1, '2026-10-01', 60000.00, 'RECIBIDA');

INSERT INTO compras_detalle (compra_id, producto_id, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 5, 12000.00, 60000.00);
