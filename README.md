# Práctica de Laboratorio: Mini ERP mediante API REST
**Gestión Administrativa y Fiscal**

**Temas abarcados:**
* **2.3 API-First Design** (Diseño y especificación antes de la codificación)
* **2.4 Comunicación Frontend–Backend** (React 18 + Vite + TypeScript & Express + MySQL)
* **2.5 Diseño Avanzado de APIs** (Filtros, búsqueda, ordenamiento, paginación y códigos HTTP)
* **2.6 Middlewares y Pipelines** (Logger, validaciones, JWT auth y arquitectura desacoplada)

---

## 1. Arquitectura General del Sistema

El sistema implementa una arquitectura desacoplada por capas:

```
┌────────────────────────────────────────────────────────┐
│                   CLIENTE / USUARIO                    │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             FRONTEND (React + TypeScript)              │
│  - Dashboard con KPIs en tiempo real                   │
│  - Catálogo de Productos con filtros y paginación      │
│  - Gestión de Clientes y Proveedores                   │
│  - Punto de Venta con validación visual de existencias │
│  - Órdenes de Compra y Auditoría de Almacén            │
└───────────────────────────┬────────────────────────────┘
                            │ HTTP / JSON
                            ▼
┌────────────────────────────────────────────────────────┐
│               API REST (Node.js + Express)             │
│                     Puerto: 3000                       │
├────────────────────────────────────────────────────────┤
│ Pipeline de Middlewares:                               │
│  1. CORS (Cross-Origin Resource Sharing)               │
│  2. JSON Parser                                        │
│  3. Logger: [HH:MM:SS] METHOD /path                    │
│  4. Auth Middleware (Bearer Token / JWT)               │
│  5. Validation Middlewares                             │
├────────────────────────────────────────────────────────┤
│ Capas de Software:                                     │
│  - Routers (/api/productos, /api/ventas, ...)          │
│  - Controllers (Manejo de HTTP req/res)                │
│  - Services (Reglas de negocio y lógica transaccional) │
│  - Models / DataStore (Persistencia y queries)         │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             BASE DE DATOS (MySQL / MariaDB)            │
│  - Esquema Relacional: tablas, claves foráneas y tipos │
│  - Modo Fallback en memoria automático para desarrollo │
└────────────────────────────────────────────────────────┘
```

---

## 2. Parte I — API-First Design

### 2.1 Tabla de Recursos y Endpoints

| Método | Endpoint | Acción | Código HTTP Éxito | Códigos Error |
| :--- | :--- | :--- | :---: | :---: |
| **POST** | `/api/auth/login` | Iniciar sesión y obtener token Bearer | `200 OK` | `400, 401` |
| **GET** | `/api/productos` | Listar catálogo (filtros, paginación, orden) | `200 OK` | `500` |
| **GET** | `/api/productos/:id` | Obtener detalle de un producto específico | `200 OK` | `404` |
| **POST** | `/api/productos` | Crear un producto (valida campos) | `201 Created` | `400, 401` |
| **PUT** | `/api/productos/:id` | Actualizar información de producto | `200 OK` | `400, 401, 404` |
| **DELETE**| `/api/productos/:id` | Eliminar un producto del inventario | `200 OK` | `401, 404` |
| **GET** | `/api/clientes` | Obtener todos los clientes | `200 OK` | `500` |
| **GET** | `/api/clientes/:id` | Obtener datos fiscales de un cliente | `200 OK` | `404` |
| **POST** | `/api/clientes` | Registrar nuevo cliente con RFC | `201 Created` | `400, 401` |
| **PUT** | `/api/clientes/:id` | Actualizar cliente | `200 OK` | `400, 401, 404` |
| **DELETE**| `/api/clientes/:id` | Eliminar cliente | `200 OK` | `401, 404` |
| **GET** | `/api/proveedores` | Obtener lista de proveedores | `200 OK` | `500` |
| **GET** | `/api/proveedores/:id`| Obtener proveedor por ID | `200 OK` | `404` |
| **POST** | `/api/proveedores` | Registrar nuevo proveedor mayorista | `201 Created` | `400, 401` |
| **PUT** | `/api/proveedores/:id`| Actualizar proveedor | `200 OK` | `400, 401, 404` |
| **DELETE**| `/api/proveedores/:id`| Eliminar proveedor | `200 OK` | `401, 404` |
| **GET** | `/api/ventas` | Historial de ventas realizadas | `200 OK` | `500` |
| **GET** | `/api/ventas/:id` | Obtener detalle de una venta con partidas | `200 OK` | `404` |
| **POST** | `/api/ventas` | Registrar venta (valida stock y descuenta) | `201 Created` | `400, 401, 404` |
| **GET** | `/api/compras` | Historial de órdenes de compra | `200 OK` | `500` |
| **POST** | `/api/compras` | Registrar compra y sumar stock al inventario | `201 Created` | `400, 401, 404` |
| **GET** | `/api/inventario` | Resumen de existencias y alertas de stock bajo | `200 OK` | `500` |
| **GET** | `/api/dashboard` | Indicadores y KPIs del Panel Principal | `200 OK` | `500` |

---

### 2.2 Estructura de Datos (JSON Schemas)

#### Producto
```json
{
  "id": 1,
  "codigo": "PROD001",
  "nombre": "Laptop Lenovo",
  "precio": 12500,
  "stock": 10,
  "categoria": "Computación"
}
```

#### Cliente
```json
{
  "id": 1,
  "nombre": "Empresa ABC SA de CV",
  "rfc": "ABC010101XXX",
  "telefono": "5555555555",
  "correo": "contacto@empresa.com",
  "direccion": "Av. Reforma 100, CDMX"
}
```

#### Venta
```json
{
  "clienteId": 1,
  "fecha": "2026-10-07",
  "productos": [
    {
      "productoId": 2,
      "cantidad": 3
    }
  ],
  "total": 37500
}
```

---

## 3. Parte II — Construcción del Backend

### Estructura de Archivos
```
backend/
├── src/
│   ├── config/
│   │   └── db.js            # Conexión MySQL Pool + Graceful Fallback
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── productosController.js
│   │   ├── clientesController.js
│   │   ├── proveedoresController.js
│   │   ├── ventasController.js
│   │   ├── comprasController.js
│   │   ├── inventarioController.js
│   │   └── dashboardController.js
│   ├── middlewares/
│   │   ├── logger.js         # Formato: [HH:MM:SS] METHOD /path
│   │   ├── auth.js           # Verificación JWT / Bearer
│   │   ├── validator.js      # Validación de inputs requeridos
│   │   └── errorHandler.js   # Manejo de rutas 404 y errores 500
│   ├── models/
│   │   └── dataStore.js      # Repositorios SQL y DataStore desacoplado
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── productosRoutes.js
│   │   ├── clientesRoutes.js
│   │   ├── proveedoresRoutes.js
│   │   ├── ventasRoutes.js
│   │   ├── comprasRoutes.js
│   │   ├── inventarioRoutes.js
│   │   └── dashboardRoutes.js
│   ├── services/
│   │   ├── authService.js
│   │   ├── productosService.js
│   │   ├── clientesService.js
│   │   ├── proveedoresService.js
│   │   ├── ventasService.js  # Lógica de cálculo y comprobación de stock
│   │   ├── comprasService.js
│   │   └── dashboardService.js
│   └── app.js                # Pipeline HTTP principal
├── .env
├── .env.example
└── package.json
```

---

## 4. Parte IV — Diseño Avanzado de APIs

La API soporta parámetros de consulta estandarizados en `GET /api/productos`:

1. **Parámetro por ID:**
   `GET /api/productos/1`
2. **Filtro por Categoría:**
   `GET /api/productos?categoria=computacion` (normalización insensible a mayúsculas y acentos)
3. **Búsqueda Flexible:**
   `GET /api/productos?buscar=laptop` (busca en nombre, código y categoría)
4. **Paginación:**
   `GET /api/productos?page=1&limit=10`
   *Responde con metadatos:*
   ```json
   {
     "success": true,
     "data": [...],
     "pagination": {
       "total": 5,
       "page": 1,
       "limit": 10,
       "totalPages": 1
     }
   }
   ```
5. **Ordenamiento:**
   `GET /api/productos?sort=precio&order=desc`

---

## 5. Parte V — Middlewares y Pipeline de una Petición

### 5.1 Logger
Middleware registrado en `src/middlewares/logger.js`.
Genera en consola exactamente el formato solicitado:
```
[18:20:01] GET /api/productos
[18:20:05] POST /api/clientes
[18:20:12] DELETE /api/productos/8
```

### 5.2 Middleware de Validación
Antes de persistir un producto en `POST /api/productos` o `PUT /api/productos/:id`, valida:
- **Nombre**: obligatorio, tipo string no vacío.
- **Código**: obligatorio, tipo string no vacío.
- **Precio**: mayor a 0.
- **Stock**: entero mayor o igual a 0.

Si falla, retorna `HTTP 400 Bad Request`:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Datos del producto incorrectos",
    "detalles": [
      "El campo \"precio\" es obligatorio y debe ser un número mayor a 0."
    ]
  }
}
```

### 5.3 Middleware de Autenticación
- Endpoint público: `POST /api/auth/login` con:
  ```json
  { "usuario": "admin", "password": "123456" }
  ```
- Retorna:
  ```json
  {
    "success": true,
    "token": "TOKEN_GENERADO..."
  }
  ```
- Las operaciones administrativas (`POST`, `PUT`, `DELETE`, `/api/ventas`, `/api/compras`) exigen la cabecera:
  `Authorization: Bearer <TOKEN>`

---

### 5.4 Explicación del Pipeline y Separación por Capas

```
CLIENTE (React / Postman)
   │
   ▼
Request HTTP
   │
   ▼
[1] CORS (Valida orígenes permitidos)
   │
   ▼
[2] Logger (Registra [HH:MM:SS] METHOD /path)
   │
   ▼
[3] Authentication (Valida JWT en cabecera Bearer)
   │
   ▼
[4] Validation (Comprueba tipos, campos obligatorios, rangos numéricos)
   │
   ▼
[5] Router (Dirige la petición al controlador adecuado)
   │
   ▼
[6] Controller (Extrae req.params, req.query, req.body y formatea la respuesta HTTP)
   │
   ▼
[7] Service (Aplica reglas del negocio: verificar cliente, validar existencias, calcular totales)
   │
   ▼
[8] Model / Database (Ejecuta sentencias SQL o manipulación de datos)
   │
   ▼
Response JSON (200 / 201 / 400 / 404 / 500)
   │
   ▼
FRONTEND
```

#### ¿Por qué no colocar toda la lógica dentro de las rutas?
1. **Separación de Responsabilidades (Single Responsibility Principle):**
   - La **Ruta** únicamente debe declarar qué URL y verbo HTTP responde.
   - El **Controlador** debe ocuparse del protocolo web (códigos de estado, cabeceras, extraer parámetros).
   - El **Servicio** encapsula la lógica empresarial pura (cálculos fiscales, algoritmos de stock, descuentos), la cual es independiente de HTTP.
   - El **Modelo** gestiona exclusivamente el almacenamiento y consultas a la base de datos.
2. **Reutilización de Código:**
   Si la lógica de calcular el total o verificar el stock reside en un Servicio (`VentasService`), esa misma función puede ser invocada por una API REST, una tarea programada (cron), una interfaz por consola CLI o un servicio de mensajería (WebSocket/gRPC) sin duplicar código.
3. **Mantenibilidad y Legibilidad:**
   Tener archivos de rutas con cientos de líneas que mezclan consultas SQL con validaciones y manejo de errores genera código espagueti difícil de leer y propenso a errores colaterales.
4. **Testabilidad (Unit Testing):**
   Al desacoplar los servicios, se pueden escribir pruebas unitarias automatizadas (Jest/Mocha) evaluando las reglas de negocio sin necesidad de levantar un servidor HTTP o simular peticiones web.

---

## 6. Práctica Específica con Postman y Regla de Stock (Sección 15)

Se incluye la colección lista para importar en:
`postman/Mini_ERP_API.postman_collection.json`

### Flujo de Registro de Venta
1. El usuario envía `POST /api/ventas` con el token de autenticación.
2. Pasa por Logger &rarr; Auth &rarr; Validation &rarr; Controller &rarr; Service.
3. El servicio verifica la existencia del cliente, la existencia de los productos y compara el **stock disponible** contra la **cantidad solicitada**.

#### Caso de Prueba Crítico (Sección 15)
- Producto seleccionado: **Mouse Inalámbrico Logitech** (`id: 2`, Stock actual = **5**)
- Cantidad solicitada: **8**
- **Resultado de la API (HTTP 400 Bad Request):**
```json
{
  "success": false,
  "message": "Stock insuficiente",
  "producto": "Mouse Inalámbrico Logitech",
  "stockDisponible": 5,
  "cantidadSolicitada": 8
}
```

#### Caso Exitoso
- Si la cantidad es menor o igual al stock, se crea la venta, se descuenta de forma atómica en el inventario y retorna `HTTP 201 Created`:
```json
{
  "success": true,
  "message": "Venta registrada con éxito",
  "data": {
    "id": 3,
    "clienteId": 1,
    "clienteNombre": "Empresa ABC SA de CV",
    "fecha": "2026-10-20",
    "total": 25000,
    "estado": "COMPLETADA",
    "productos": [
      {
        "productoId": 1,
        "nombre": "Laptop Lenovo",
        "cantidad": 2,
        "precioUnitario": 12500,
        "subtotal": 25000
      }
    ]
  }
}
```

---

## 7. Guía de Ejecución Rápida

### Requisitos Previos
- Node.js v18+ y npm
- MySQL / MariaDB (opcional; el backend cuenta con fallback automático en memoria para pruebas inmediatas si MySQL no está activo).

### Paso 1: Configurar Base de Datos MySQL (Opcional si usa MySQL local)
Abra phpMyAdmin o MySQL CLI y ejecute el script:
```sql
SOURCE database/schema.sql;
```

### Paso 2: Iniciar el Backend
```bash
cd backend
npm install
npm run dev
```
*El servidor correrá en `http://localhost:3000`*.

### Paso 3: Iniciar el Frontend (React + Vite)
En una nueva terminal:
```bash
cd frontend
npm install
npm run dev
```
*Abra en su navegador `http://localhost:5173`*.

### Paso 4: Pruebas con Postman
1. Abra Postman.
2. Haga clic en **Import**.
3. Seleccione el archivo `postman/Mini_ERP_API.postman_collection.json`.
4. Ejecute la petición `0. Autenticación -> POST /api/auth/login` (guarda automáticamente el token en las variables).
5. Ejecute cualquier endpoint de Productos, Clientes, Ventas o Compras.
