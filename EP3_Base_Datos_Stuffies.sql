------------------------------------------------------------
-- BDY1103 – Evaluación Parcial 3
-- STUFFIES – MODELO "NoSQL" TIPO DOCUMENTO (JSON EN ORACLE)
--
-- RÚBRICA EP3 (ENFOCADO EN NO RELACIONAL):
--  - IE3.2.2: Justifica la implementación de un modelo de datos
--             NO RELACIONAL (documentos JSON tipo MongoDB).
--  - IE3.3.1: Manipula bases de datos NO RELACIONALES con operaciones
--             CRUD (Create, Read, Update, Delete).
--
-- Este script muestra:
--  * Un modelo de documentos JSON (productos, clientes, pedidos)
--    almacenados en columnas CLOB con CHECK (IS JSON).
--  * Operaciones CRUD sobre esos documentos:
--    - CREATE: INSERT de documentos completos.
--    - READ: SELECT con JSON_VALUE y JSON_TABLE.
--    - UPDATE: JSON_MERGEPATCH para modificar campos del documento.
--    - DELETE: eliminación de documentos según condiciones.
------------------------------------------------------------

SET SERVEROUTPUT ON;
SET LINESIZE 220;
SET PAGESIZE 1000;

PROMPT ================== LIMPIEZA IDP (BORRADO SEGURO) ==================
-- IE3.3.1 (Preparación para CRUD): dejamos las "colecciones" listas
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE hr.stuffies_nosql_pedidos PURGE';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN NULL; ELSE RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE hr.stuffies_nosql_clientes PURGE';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN NULL; ELSE RAISE; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE hr.stuffies_nosql_productos PURGE';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE != -942 THEN NULL; ELSE RAISE; END IF;
END;
/

------------------------------------------------------------
-- 1) "COLECCIONES" TIPO DOCUMENTO (TABLAS + JSON)
--    IE3.2.2: Implementación de un MODELO NO RELACIONAL basado en
--    documentos JSON, similar a MongoDB:
--      - Cada fila = 1 documento completo.
--      - Se guarda en columna CLOB con CHECK (IS JSON).
------------------------------------------------------------
PROMPT ================== CREACIÓN TABLAS JSON ==================

-- Colección "productos"
CREATE TABLE hr.stuffies_nosql_productos (
  producto_id NUMBER PRIMARY KEY,
  data        CLOB CHECK (data IS JSON)
);

-- Colección "clientes"
CREATE TABLE hr.stuffies_nosql_clientes (
  cliente_id NUMBER PRIMARY KEY,
  data       CLOB CHECK (data IS JSON)
);

-- Colección "pedidos"
CREATE TABLE hr.stuffies_nosql_pedidos (
  pedido_id  NUMBER PRIMARY KEY,
  data       CLOB CHECK (data IS JSON)
);

------------------------------------------------------------
-- 2) CARGA INICIAL (CREATE) - DOCUMENTOS JSON
--    IE3.3.1 – Operación CREATE sobre BD no relacional
------------------------------------------------------------
PROMPT ================== INSERT (CREATE DOCUMENTOS) ==================

-- ================== PRODUCTOS (DOCUMENTOS JSON) ==================
INSERT INTO hr.stuffies_nosql_productos (producto_id, data) VALUES (
  1,
  q'!{
    "nombre": "Hoodie Boxy Fit White Dice V2",
    "categoria": "polerones",
    "precio": 39990,
    "imagen": "https://stuffiesconcept.com/cdn/shop/files/WhiteDice1.png",
    "imagen_hover": "https://stuffiesconcept.com/cdn/shop/files/WhiteDice2.png",
    "descripcion": "Polerón boxy fit White Dice V2.",
    "destacado": true,
    "stock": {
      "total": 10,
      "tallas": [
        { "talla": "S",  "cantidad": 3 },
        { "talla": "M",  "cantidad": 5 },
        { "talla": "L",  "cantidad": 2 },
        { "talla": "XL", "cantidad": 0 }
      ]
    },
    "tags": ["new", "invierno"]
  }!'
);

INSERT INTO hr.stuffies_nosql_productos (producto_id, data) VALUES (
  2,
  q'!{
    "nombre": "Star Player Blue Team T-Shirt",
    "categoria": "poleras",
    "precio": 10990,
    "imagen": "https://stuffiesconcept.com/cdn/shop/files/1_594f01e1-55e5-4516-b0af-d2befc1aa113.png",
    "imagen_hover": "https://stuffiesconcept.com/cdn/shop/files/2_221c9cfc-6049-4eb1-b7ec-3b19bd755c48.png",
    "descripcion": "Polera Star Player Blue Team.",
    "destacado": false,
    "stock": {
      "total": 13,
      "tallas": [
        { "talla": "M",  "cantidad": 8 },
        { "talla": "L",  "cantidad": 4 },
        { "talla": "XL", "cantidad": 1 }
      ]
    },
    "tags": ["futbol", "streetwear"]
  }!'
);

INSERT INTO hr.stuffies_nosql_productos (producto_id, data) VALUES (
  3,
  q'!{
    "nombre": "Stella Boxy-Slim Black Tee",
    "categoria": "poleras",
    "precio": 15990,
    "imagen": "https://stuffiesconcept.com/cdn/shop/files/5.png",
    "imagen_hover": "https://stuffiesconcept.com/cdn/shop/files/6.png",
    "descripcion": "Polera boxy-slim fit negra.",
    "destacado": true,
    "stock": {
      "total": 20,
      "tallas": [
        { "talla": "S",  "cantidad": 5 },
        { "talla": "M",  "cantidad": 5 },
        { "talla": "L",  "cantidad": 5 },
        { "talla": "XL", "cantidad": 5 }
      ]
    },
    "tags": ["básico", "negro"]
  }!'
);

-- Producto extra para mostrar más casos
INSERT INTO hr.stuffies_nosql_productos (producto_id, data) VALUES (
  4,
  q'!{
    "nombre": "Gorro Beanie Clásico",
    "categoria": "gorros",
    "precio": 9990,
    "imagen": "https://example.com/beanie1.png",
    "imagen_hover": "https://example.com/beanie2.png",
    "descripcion": "Beanie de punto, unisex, ideal para invierno.",
    "destacado": false,
    "stock": {
      "total": 6,
      "tallas": [
        { "talla": "Única", "cantidad": 6 }
      ]
    },
    "tags": ["invierno", "accesorios"]
  }!'
);

-- ================== CLIENTES (DOCUMENTOS JSON) ==================
INSERT INTO hr.stuffies_nosql_clientes (cliente_id, data) VALUES (
  100,
  q'!{
    "nombre": "Juan Pérez",
    "email": "juan.perez@example.com",
    "telefono": "+56 9 1111 1111",
    "direccion": {
      "calle": "Av. Siempre Viva 123",
      "ciudad": "Viña del Mar",
      "region": "Valparaíso"
    }
  }!'
);

INSERT INTO hr.stuffies_nosql_clientes (cliente_id, data) VALUES (
  101,
  q'!{
    "nombre": "María González",
    "email": "maria.gonzalez@example.com",
    "telefono": "+56 9 2222 2222",
    "direccion": {
      "calle": "Los Robles 456",
      "ciudad": "Santiago",
      "region": "RM"
    }
  }!'
);

INSERT INTO hr.stuffies_nosql_clientes (cliente_id, data) VALUES (
  102,
  q'!{
    "nombre": "Carlos Ramírez",
    "email": "carlos.ramirez@example.com",
    "telefono": "+56 9 3333 3333",
    "direccion": {
      "calle": "Av. del Mar 789",
      "ciudad": "La Serena",
      "region": "Coquimbo"
    }
  }!'
);

-- ================== PEDIDOS (DOCUMENTOS JSON) ==================
INSERT INTO hr.stuffies_nosql_pedidos (pedido_id, data) VALUES (
  5000,
  q'!{
    "clienteId": 100,
    "fecha": "2024-11-20",
    "estado": "CREADO",
    "items": [
      {
        "productoId": 1,
        "nombreProducto": "Hoodie Boxy Fit White Dice V2",
        "talla": "M",
        "cantidad": 1,
        "precioUnitario": 39990
      },
      {
        "productoId": 3,
        "nombreProducto": "Stella Boxy-Slim Black Tee",
        "talla": "L",
        "cantidad": 2,
        "precioUnitario": 15990
      }
    ],
    "total": 71970
  }!'
);

INSERT INTO hr.stuffies_nosql_pedidos (pedido_id, data) VALUES (
  5001,
  q'!{
    "clienteId": 101,
    "fecha": "2024-11-21",
    "estado": "PAGADO",
    "items": [
      {
        "productoId": 2,
        "nombreProducto": "Star Player Blue Team T-Shirt",
        "talla": "M",
        "cantidad": 2,
        "precioUnitario": 10990
      }
    ],
    "total": 21980
  }!'
);

COMMIT;

------------------------------------------------------------
-- 3) READ (CONSULTAS) - EQUIVALENTE A find() DE MONGO
--    IE3.3.1 – Operación READ sobre BD no relacional
------------------------------------------------------------
PROMPT ================== READ (CONSULTAS BÁSICAS) ==================

-- 1) Listar todos los productos (proyección básica tipo catálogo)
SELECT
  p.producto_id,
  JSON_VALUE(p.data, '$.nombre')      AS nombre,
  JSON_VALUE(p.data, '$.categoria')   AS categoria,
  JSON_VALUE(p.data, '$.precio')      AS precio,
  JSON_VALUE(p.data, '$.stock.total') AS stock_total
FROM hr.stuffies_nosql_productos p
ORDER BY p.producto_id;

-- 2) Productos por categoría = "poleras"
SELECT
  producto_id,
  JSON_VALUE(data, '$.nombre') AS nombre,
  JSON_VALUE(data, '$.precio') AS precio
FROM hr.stuffies_nosql_productos
WHERE JSON_VALUE(data, '$.categoria') = 'poleras';

-- 3) Productos destacados con stock.total > 5
SELECT
  producto_id,
  JSON_VALUE(data, '$.nombre')      AS nombre,
  JSON_VALUE(data, '$.stock.total') AS stock_total
FROM hr.stuffies_nosql_productos
WHERE JSON_VALUE(data, '$.destacado') = 'true'
  AND JSON_VALUE(data, '$.stock.total') > 5;

PROMPT ================== READ (CONSULTAS AVANZADAS JSON_TABLE) ==================

-- 4) Desnormalizar tallas y stock (JSON_TABLE) – similar a unwind en Mongo
SELECT
  p.producto_id,
  JSON_VALUE(p.data, '$.nombre') AS nombre,
  jt.talla,
  jt.cantidad
FROM hr.stuffies_nosql_productos p,
     JSON_TABLE(
       p.data,
       '$.stock.tallas[*]'
       COLUMNS (
         talla    VARCHAR2(10) PATH '$.talla',
         cantidad NUMBER       PATH '$.cantidad'
       )
     ) jt
ORDER BY p.producto_id, jt.talla;

-- 5) Historial de pedidos con nombre de cliente (join via JSON)
SELECT
  ped.pedido_id,
  JSON_VALUE(ped.data, '$.fecha')      AS fecha,
  JSON_VALUE(ped.data, '$.estado')     AS estado,
  JSON_VALUE(cli.data, '$.nombre')     AS nombre_cliente,
  JSON_VALUE(ped.data, '$.total')      AS total
FROM hr.stuffies_nosql_pedidos ped
JOIN hr.stuffies_nosql_clientes cli
  ON JSON_VALUE(ped.data, '$.clienteId') = cli.cliente_id;

------------------------------------------------------------
-- 4) UPDATE (ACTUALIZACIONES) - EQUIVALENTE A updateOne/Many
--    IE3.3.1 – Operación UPDATE sobre documentos JSON
------------------------------------------------------------
PROMPT ================== UPDATE (MODIFICACIÓN DE DOCUMENTOS) ==================

-- 1) Cambiar precio del producto 2 (similar a updateOne)
UPDATE hr.stuffies_nosql_productos
SET data = JSON_MERGEPATCH(
  data,
  '{ "precio": 11990 }'
)
WHERE producto_id = 2;

-- 2) Marcar como destacados los productos con stock.total >= 15 (updateMany)
UPDATE hr.stuffies_nosql_productos
SET data = JSON_MERGEPATCH(
  data,
  '{ "destacado": true }'
)
WHERE JSON_VALUE(data, '$.stock.total') >= 15;

-- 3) Cambiar estado de un pedido (CREADO -> PAGADO)
UPDATE hr.stuffies_nosql_pedidos
SET data = JSON_MERGEPATCH(
  data,
  '{ "estado": "PAGADO" }'
)
WHERE pedido_id = 5000;

COMMIT;

------------------------------------------------------------
-- 5) DELETE - EQUIVALENTE A deleteOne / deleteMany
--    IE3.3.1 – Operación DELETE sobre documentos JSON
------------------------------------------------------------
PROMPT ================== DELETE (ELIMINACIÓN DE DOCUMENTOS) ==================

-- 1) Eliminar producto 4 (ejemplo deleteOne)
DELETE FROM hr.stuffies_nosql_productos
WHERE producto_id = 4;

-- 2) Eliminar pedidos en estado "CANCELADO" (deleteMany)
DELETE FROM hr.stuffies_nosql_pedidos
WHERE JSON_VALUE(data, '$.estado') = 'CANCELADO';

COMMIT;

------------------------------------------------------------
-- 6) DEMO RESUMEN EN DBMS_OUTPUT PARA LA PRESENTACIÓN
--    IE3.2.2 + IE3.3.1: explicación resumida del modelo y del CRUD
------------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== EP3 – MODELO NoSQL (JSON EN ORACLE) ===');
  DBMS_OUTPUT.PUT_LINE('- Modelo de datos no relacional basado en documentos JSON:');
  DBMS_OUTPUT.PUT_LINE('  * Colecciones simuladas como tablas:');
  DBMS_OUTPUT.PUT_LINE('    - STUFFIES_NOSQL_PRODUCTOS');
  DBMS_OUTPUT.PUT_LINE('    - STUFFIES_NOSQL_CLIENTES');
  DBMS_OUTPUT.PUT_LINE('    - STUFFIES_NOSQL_PEDIDOS');
  DBMS_OUTPUT.PUT_LINE('- Cada fila almacena un documento JSON completo (similar a MongoDB).');
  DBMS_OUTPUT.PUT_LINE('- Operaciones CRUD realizadas sobre la BD no relacional:');
  DBMS_OUTPUT.PUT_LINE('  * CREATE: INSERT de documentos JSON en las tres colecciones.');
  DBMS_OUTPUT.PUT_LINE('  * READ  : SELECT con JSON_VALUE y JSON_TABLE (filtros, joins, tallas).');
  DBMS_OUTPUT.PUT_LINE('  * UPDATE: JSON_MERGEPATCH para actualizar precio, destacado y estado.');
  DBMS_OUTPUT.PUT_LINE('  * DELETE: eliminación de productos y pedidos según condiciones en el JSON.');
END;
/
