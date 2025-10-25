SET SERVEROUTPUT ON;
SET LINESIZE 220;
SET PAGESIZE 1000;
SET DEFINE OFF;

-------------------------------------------------------------------------------
-- TABLAS (idempotentes)
-------------------------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE hr.stuffies_productos (
      producto_id   NUMBER         PRIMARY KEY,
      nombre        VARCHAR2(200)  NOT NULL,
      precio        NUMBER(10,2)   NOT NULL,
      categoria     VARCHAR2(50),
      imagen        VARCHAR2(1000),
      imagen_hover  VARCHAR2(1000),
      descripcion   VARCHAR2(1000),
      destacado     NUMBER(1)      DEFAULT 0,
      stock         NUMBER         DEFAULT 0
    )
  ]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/

BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE hr.stuffies_stock_talla (
      producto_id NUMBER       NOT NULL,
      talla       VARCHAR2(10) NOT NULL,
      stock       NUMBER       DEFAULT 0,
      CONSTRAINT pk_sst PRIMARY KEY (producto_id, talla),
      CONSTRAINT fk_sst_prod FOREIGN KEY (producto_id)
        REFERENCES hr.stuffies_productos(producto_id)
    )
  ]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/

-- Espejo simple para reportes
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE hr.producto (
      id_producto NUMBER         PRIMARY KEY,
      nombre      VARCHAR2(200)  NOT NULL,
      precio      NUMBER(10,2)   NOT NULL,
      stock       NUMBER         DEFAULT 0
    )
  ]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/

-- Opcional: notificaciones (si existe, el trigger insertará alertas)
BEGIN
  EXECUTE IMMEDIATE q'[
    CREATE TABLE hr.stuffies_notificaciones (
      notificacion_id    NUMBER       PRIMARY KEY,
      cliente_id         NUMBER       NULL,
      mensaje            VARCHAR2(400),
      tipo               VARCHAR2(50),
      fecha_notificacion DATE         DEFAULT SYSDATE,
      leida              CHAR(1)      DEFAULT 'N'
    )
  ]';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/

-------------------------------------------------------------------------------
-- COMPATIBILIDAD: columna STOCK_ID autonumérica en STUFFIES_STOCK_TALLA (solo si existe o se crea)
-------------------------------------------------------------------------------
DECLARE
  v_col NUMBER := 0;
BEGIN
  SELECT COUNT(*) INTO v_col
  FROM user_tab_cols
  WHERE table_name = 'STUFFIES_STOCK_TALLA' AND column_name = 'STOCK_ID';

  IF v_col = 0 THEN
    -- Si tu tabla tenía esa columna en otra versión y la necesitas, la agregamos.
    EXECUTE IMMEDIATE 'ALTER TABLE hr.stuffies_stock_talla ADD (stock_id NUMBER)';
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE hr.seq_sst_stock_id START WITH 1';
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF; -- ya existe
  END;

  -- Trigger que rellena stock_id si la columna existe
  EXECUTE IMMEDIATE q'[
    CREATE OR REPLACE TRIGGER hr.trg_sst_stock_id
    BEFORE INSERT ON hr.stuffies_stock_talla
    FOR EACH ROW
    WHEN (NEW.stock_id IS NULL)
    BEGIN
      :NEW.stock_id := hr.seq_sst_stock_id.NEXTVAL;
    END;
  ]';
END;
/

-------------------------------------------------------------------------------
-- VISTAS
-------------------------------------------------------------------------------
CREATE OR REPLACE VIEW hr.vw_productos_con_stock AS
SELECT
  p.producto_id,
  p.nombre,
  p.precio,
  NVL((SELECT SUM(s.stock)
       FROM hr.stuffies_stock_talla s
       WHERE s.producto_id = p.producto_id),0) AS stock_total,
  LISTAGG(t.talla, ',') WITHIN GROUP (
    ORDER BY CASE
      WHEN REGEXP_LIKE(t.talla,'^\d+$') THEN TO_NUMBER(t.talla)
      WHEN t.talla='XS'  THEN 1
      WHEN t.talla='S'   THEN 2
      WHEN t.talla='M'   THEN 3
      WHEN t.talla='L'   THEN 4
      WHEN t.talla='XL'  THEN 5
      WHEN t.talla='XXL' THEN 6
      ELSE 99
    END
  ) AS tallas
FROM hr.stuffies_productos p
LEFT JOIN hr.stuffies_stock_talla t ON t.producto_id=p.producto_id
GROUP BY p.producto_id, p.nombre, p.precio;

CREATE OR REPLACE VIEW hr.vw_producto_tallas_csv AS
SELECT pr.id_producto,
       pr.nombre,
       pr.precio,
       pr.stock,
       LISTAGG(st.talla, ',') WITHIN GROUP (
         ORDER BY CASE
           WHEN REGEXP_LIKE(st.talla,'^\d+$') THEN TO_NUMBER(st.talla)
           WHEN st.talla='XS'  THEN 1
           WHEN st.talla='S'   THEN 2
           WHEN st.talla='M'   THEN 3
           WHEN st.talla='L'   THEN 4
           WHEN st.talla='XL'  THEN 5
           WHEN st.talla='XXL' THEN 6
           ELSE 99
         END
       ) AS tallas_csv
FROM hr.producto pr
LEFT JOIN hr.stuffies_stock_talla st
       ON st.producto_id = pr.id_producto
GROUP BY pr.id_producto, pr.nombre, pr.precio, pr.stock;

CREATE OR REPLACE VIEW hr.vw_reporte_stock_tabla AS
SELECT p.producto_id AS id,
       p.nombre,
       SUM(NVL(s.stock,0)) AS stock_total
FROM hr.stuffies_productos p
LEFT JOIN hr.stuffies_stock_talla s
  ON s.producto_id = p.producto_id
GROUP BY p.producto_id, p.nombre;

CREATE OR REPLACE VIEW hr.vw_reporte_stock_texto AS
WITH data AS (
  SELECT p.producto_id, p.nombre, SUM(NVL(s.stock,0)) AS stock_total
  FROM hr.stuffies_productos p
  LEFT JOIN hr.stuffies_stock_talla s
    ON s.producto_id = p.producto_id
  GROUP BY p.producto_id, p.nombre
)
SELECT '✅ Productos (stock total):' AS linea, 0 AS ord FROM dual
UNION ALL
SELECT ' - #'||producto_id||' '||RPAD(nombre,35)||' → stock='||stock_total, 1
FROM data;

-------------------------------------------------------------------------------
-- PACKAGE (sin COMMITs internos)
-------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE hr.pkg_gestion_stock AS
  PROCEDURE refrescar_producto(p_producto_id NUMBER);
  PROCEDURE refrescar_todo;
END pkg_gestion_stock;
/

CREATE OR REPLACE PACKAGE BODY hr.pkg_gestion_stock AS
  PROCEDURE sync_row_producto(p_id NUMBER) IS
  BEGIN
    MERGE INTO hr.producto pr
    USING (
      SELECT p.producto_id AS id_producto,
             p.nombre,
             p.precio,
             NVL((SELECT SUM(s.stock)
                  FROM hr.stuffies_stock_talla s
                  WHERE s.producto_id = p.producto_id),0) AS stock
      FROM hr.stuffies_productos p
      WHERE p.producto_id = p_id
    ) s
    ON (pr.id_producto = s.id_producto)
    WHEN MATCHED THEN UPDATE SET
      pr.nombre = s.nombre,
      pr.precio = s.precio,
      pr.stock  = s.stock
    WHEN NOT MATCHED THEN INSERT (id_producto, nombre, precio, stock)
    VALUES (s.id_producto, s.nombre, s.precio, s.stock);
  END;

  PROCEDURE refrescar_producto(p_producto_id NUMBER) IS
    v_stock NUMBER;
  BEGIN
    SELECT NVL(SUM(stock),0)
      INTO v_stock
      FROM hr.stuffies_stock_talla
     WHERE producto_id = p_producto_id;

    UPDATE hr.stuffies_productos
       SET stock = v_stock
     WHERE producto_id = p_producto_id;

    sync_row_producto(p_producto_id);
  END;

  PROCEDURE refrescar_todo IS
  BEGIN
    FOR r IN (SELECT producto_id FROM hr.stuffies_productos) LOOP
      refrescar_producto(r.producto_id);
    END LOOP;
  END;
END pkg_gestion_stock;
/

-------------------------------------------------------------------------------
-- TRIGGER COMPUESTO (no hace COMMIT, evita "tabla mutando")
-------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER hr.trg_sst_aiud
FOR INSERT OR UPDATE OR DELETE ON hr.stuffies_stock_talla
COMPOUND TRIGGER
  g_ids SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST();

  PROCEDURE add_id(p_id NUMBER) IS
  BEGIN
    IF p_id IS NOT NULL THEN
      g_ids.EXTEND; g_ids(g_ids.COUNT) := p_id;
    END IF;
  END;

  AFTER EACH ROW IS
  BEGIN
    add_id(NVL(:NEW.producto_id, :OLD.producto_id));
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_total_stock NUMBER;
  BEGIN
    FOR r IN (SELECT DISTINCT COLUMN_VALUE AS producto_id FROM TABLE(g_ids)) LOOP
      hr.pkg_gestion_stock.refrescar_producto(r.producto_id);

      -- Notificación opcional (ignorar errores si no existe tabla)
      BEGIN
        SELECT NVL(SUM(stock),0) INTO v_total_stock
        FROM hr.stuffies_stock_talla
        WHERE producto_id = r.producto_id;

        IF v_total_stock <= 2 THEN
          INSERT INTO hr.stuffies_notificaciones
            (notificacion_id, cliente_id, mensaje, tipo, fecha_notificacion, leida)
          VALUES (
            (SELECT NVL(MAX(notificacion_id),0)+1 FROM hr.stuffies_notificaciones),
            NULL,
            'Alerta: Stock bajo para producto ID '||r.producto_id,
            'ALERTA_STOCK',
            SYSDATE,
            'N'
          );
        END IF;
      EXCEPTION WHEN OTHERS THEN NULL; END;
    END LOOP;
  END AFTER STATEMENT;
END;
/

-------------------------------------------------------------------------------
-- CARGA DE DATOS **SIN** DELETE: UPSERT con MERGE (evita ORA-02292 / ORA-00001)
-- Deshabilitamos trigger durante la carga para que no dispare por cada fila
-------------------------------------------------------------------------------
ALTER TRIGGER hr.trg_sst_aiud DISABLE;

-- === MERGE único de PRODUCTOS ===
MERGE INTO hr.stuffies_productos p
USING (
  SELECT 1 AS producto_id, 'Hoodie Boxy Fit White Dice V2'        AS nombre, 39990 AS precio, 'polerones' AS categoria,
         'https://stuffiesconcept.com/cdn/shop/files/WhiteDice1.png?v=1753404231&width=600'    AS imagen,
         'https://stuffiesconcept.com/cdn/shop/files/WhiteDice2.png?v=1753404231&width=1426'   AS imagen_hover,
         'Poleron Boxy Fit White Dice V2.'                 AS descripcion, 0 AS destacado, 0 AS stock FROM dual
  UNION ALL SELECT 2, 'Star Player ''Blue Team'' T-Shirt', 10990, 'poleras',
         'https://stuffiesconcept.com/cdn/shop/files/1_594f01e1-55e5-4516-b0af-d2befc1aa113.png?v=1748653006&width=600',
         'https://stuffiesconcept.com/cdn/shop/files/2_221c9cfc-6049-4eb1-b7ec-3b19bd755c48.png?v=1748653006&width=600',
         'La Star Player T-Shirt nace de la unión entre la nostalgia del fútbol clásico y la energía del streetwear actual.', 0, 0 FROM dual
  UNION ALL SELECT 3, 'Stella Chroma Zip Hoodie', 55990, 'polerones',
         'https://stuffiesconcept.com/cdn/shop/files/1_8ee3f1b2-2f8a-45ba-bb78-a2f4ba49c4d5.png?v=1756936574&width=600',
         'https://stuffiesconcept.com/cdn/shop/files/2_1c0d6df0-c713-49a3-b2bd-b07d19c392ee.png?v=1756936574&width=600',
         'Hoodie con cierre frontal y bolsillos.', 1, 0 FROM dual
  UNION ALL SELECT 4, 'Stella Boxy-Slim White Tee', 22990, 'poleras',
         'https://stuffiesconcept.com/cdn/shop/files/3_0f38dc89-f9f8-4998-be22-b2e0122e8816.png?v=1756936601&width=600',
         'https://stuffiesconcept.com/cdn/shop/files/4_8a500939-3d78-4b9c-aaab-fc34db0d117d.png?v=1756936601&width=600',
         'Camiseta blanca corte boxy-slim.', 0, 0 FROM dual
  UNION ALL SELECT 5, 'Stella Boxy-Slim Black Tee', 15990, 'poleras',
         'https://stuffiesconcept.com/cdn/shop/files/5.png?v=1756936590&width=493',
         'https://stuffiesconcept.com/cdn/shop/files/6.png?v=1756936591&width=493',
         'Polera boxy-slim fit negra', 1, 0 FROM dual
  UNION ALL SELECT 6, 'Hoodie Boxy Fit Black Dice V2', 32990, 'polerones',
         'https://stuffiesconcept.com/cdn/shop/files/RedDice1.png?v=1753404319&width=600',
         'https://stuffiesconcept.com/cdn/shop/files/RedDice2.png?v=1753404319&width=600',
         'Poleron Boxy Fit White Dice V2.', 1, 0 FROM dual
  UNION ALL SELECT 7, 'Star Player ''Black Team'' t-shirt', 37990, 'poleras',
         'https://stuffiesconcept.com/cdn/shop/files/3_f5bf3ad8-c122-436f-8eee-1483a3f383da.png?v=1748652948&width=600',
         'https://stuffiesconcept.com/cdn/shop/files/4_b9bc3afc-97e9-4636-94f4-1a863738d755.png?v=1748652948&width=600',
         'La Star Player T-Shirt nace de la unión entre la nostalgia del fútbol clásico y la energía del streetwear actual..', 1, 0 FROM dual
  UNION ALL SELECT 8, 'Hoodie Boxy Fit Brown Dice V2.', 35990, 'polerones',
         'https://stuffiesconcept.com/cdn/shop/files/PinkDice1.png?v=1753404299&width=600',
         'https://stuffiesconcept.com/cdn/shop/files/PinkDice2.png?v=1753404299&width=600',
         ' Poleron Boxy Fit Brown Dice V2.', 0, 0 FROM dual
  UNION ALL SELECT 9, 'Pantalón Jeans Negro', 22990, 'pantalones',
         'https://i.postimg.cc/85CnPzS6/920c48b5-ab8b-486d-8681-74fd494c0b6e.avif',
         'https://i.postimg.cc/WjzNN7HP/b0435e27-d353-47fa-ade0-7ce8e83fc9b7.avif',
         'Jeans negro con calce relaxed.', 0, 0 FROM dual
  UNION ALL SELECT 10, 'Pantalón Jogger Gris', 19990, 'pantalones',
         'https://img.kwcdn.com/product/fancy/50c868f6-9264-465b-8e4f-01332ba99b8d.jpg?imageView2/2/w/800/q/70/format/avif',
         'https://img.kwcdn.com/product/fancy/642a3b78-e9e3-4b0a-b5f3-e897878511cc.jpg?imageView2/2/w/800/q/70/format/avif',
         'Jogger gris, cintura elasticada y puño.', 0, 0 FROM dual
  UNION ALL SELECT 11, 'Gorro Beanie Clásico', 9990, 'gorros',
         'https://img.kwcdn.com/product/fancy/109264d1-93cb-4d8a-af2f-a2e0056f21dc.jpg?imageView2/2/w/800/q/70/format/avif',
         'https://img.kwcdn.com/product/fancy/9b424f95-c691-49cf-9e1b-f2e97355cc98.jpg?imageView2/2/w/800/q/70/format/avif',
         'Beanie de punto, unisex, ideal para invierno.', 0, 0 FROM dual
) s
ON (p.producto_id = s.producto_id)
WHEN MATCHED THEN UPDATE SET
  p.nombre = s.nombre,
  p.precio = s.precio,
  p.categoria = s.categoria,
  p.imagen = s.imagen,
  p.imagen_hover = s.imagen_hover,
  p.descripcion = s.descripcion,
  p.destacado = s.destacado
WHEN NOT MATCHED THEN INSERT (producto_id,nombre,precio,categoria,imagen,imagen_hover,descripcion,destacado,stock)
VALUES (s.producto_id,s.nombre,s.precio,s.categoria,s.imagen,s.imagen_hover,s.descripcion,s.destacado,s.stock);

-- === MERGE único de STOCK POR TALLA ===
MERGE INTO hr.stuffies_stock_talla t
USING (
  SELECT 1 AS producto_id, 'S'  AS talla, '3' AS stock FROM dual
  UNION ALL SELECT 1, 'M', '5' FROM dual
  UNION ALL SELECT 1, 'L', '2' FROM dual
  UNION ALL SELECT 1, 'XL','0' FROM dual

  UNION ALL SELECT 2, 'M', '8' FROM dual
  UNION ALL SELECT 2, 'L', '4' FROM dual
  UNION ALL SELECT 2, 'XL','1' FROM dual

  UNION ALL SELECT 3, 'S', '2' FROM dual
  UNION ALL SELECT 3, 'M', '3' FROM dual
  UNION ALL SELECT 3, 'L', '3' FROM dual
  UNION ALL SELECT 3, 'XL','2' FROM dual

  UNION ALL SELECT 4, 'S', '0' FROM dual
  UNION ALL SELECT 4, 'M', '6' FROM dual
  UNION ALL SELECT 4, 'L', '6' FROM dual
  UNION ALL SELECT 4, 'XL','2' FROM dual

  UNION ALL SELECT 5, 'S', '5' FROM dual
  UNION ALL SELECT 5, 'M', '5' FROM dual
  UNION ALL SELECT 5, 'L', '5' FROM dual
  UNION ALL SELECT 5, 'XL','5' FROM dual

  UNION ALL SELECT 6, 'S', '0' FROM dual
  UNION ALL SELECT 6, 'M', '1' FROM dual
  UNION ALL SELECT 6, 'L', '0' FROM dual
  UNION ALL SELECT 6, 'XL','0' FROM dual

  UNION ALL SELECT 7, 'S', '2' FROM dual
  UNION ALL SELECT 7, 'M', '2' FROM dual
  UNION ALL SELECT 7, 'L', '2' FROM dual
  UNION ALL SELECT 7, 'XL','2' FROM dual

  UNION ALL SELECT 8, 'S', '4' FROM dual
  UNION ALL SELECT 8, 'M', '4' FROM dual
  UNION ALL SELECT 8, 'L', '0' FROM dual
  UNION ALL SELECT 8, 'XL','0' FROM dual

  UNION ALL SELECT 9,  '38','3' FROM dual
  UNION ALL SELECT 9,  '40','3' FROM dual
  UNION ALL SELECT 9,  '42','2' FROM dual
  UNION ALL SELECT 9,  '44','1' FROM dual
  UNION ALL SELECT 9,  '46','0' FROM dual
  UNION ALL SELECT 9,  '48','0' FROM dual
  UNION ALL SELECT 9,  '50','2' FROM dual
  UNION ALL SELECT 9,  '52','2' FROM dual
  UNION ALL SELECT 9,  '54','1' FROM dual

  UNION ALL SELECT 10, '38','0' FROM dual
  UNION ALL SELECT 10, '40','1' FROM dual
  UNION ALL SELECT 10, '42','1' FROM dual
  UNION ALL SELECT 10, '44','2' FROM dual
  UNION ALL SELECT 10, '46','2' FROM dual
  UNION ALL SELECT 10, '48','2' FROM dual
  UNION ALL SELECT 10, '50','0' FROM dual
  UNION ALL SELECT 10, '52','0' FROM dual
  UNION ALL SELECT 10, '54','0' FROM dual

  UNION ALL SELECT 11, '54','5' FROM dual
  UNION ALL SELECT 11, '56','5' FROM dual
  UNION ALL SELECT 11, '58','0' FROM dual
  UNION ALL SELECT 11, '60','1' FROM dual
) s
ON (t.producto_id = s.producto_id AND t.talla = s.talla)
WHEN MATCHED THEN UPDATE SET t.stock = TO_NUMBER(s.stock)
WHEN NOT MATCHED THEN INSERT (producto_id,talla,stock)
VALUES (s.producto_id, s.talla, TO_NUMBER(s.stock));

COMMIT;

ALTER TRIGGER hr.trg_sst_aiud ENABLE;

-- Refrescar espejo (producto) con los totales actualizados
BEGIN
  hr.pkg_gestion_stock.refrescar_todo;
END;
/
COMMIT;

-------------------------------------------------------------------------------
-- REPORTES (igual que los tuyos)
-------------------------------------------------------------------------------
PROMPT === REPORTE TABLA (ID, NOMBRE, STOCK TOTAL) ===
SELECT id, RPAD(nombre,35) AS nombre, stock_total
FROM hr.vw_reporte_stock_tabla
WHERE id BETWEEN 1 AND 11
ORDER BY id;

PROMPT === REPORTE TEXTO (igual a DBMS_OUTPUT) ===
SELECT linea FROM hr.vw_reporte_stock_texto
ORDER BY ord, linea;

PROMPT === VISTA CATALOGO (con tallas CSV) ===
SELECT * FROM hr.vw_producto_tallas_csv
WHERE id_producto BETWEEN 1 AND 11
ORDER BY id_producto;

SET DEFINE ON;
