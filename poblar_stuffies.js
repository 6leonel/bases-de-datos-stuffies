// ============================================
// BDY1103 – STUFFIES – POBLAR BASE DE DATOS
// IE3.2.2: Modelo NO RELACIONAL
// ============================================

// Drops de las colecciones
db.productos.drop();
db.clientes.drop();
db.pedidos.drop();

print("✓ Colecciones eliminadas\n");

// ============================================
// CREACIÓN E INSERCIÓN DE DATOS
// ============================================

// ==================== PRODUCTOS ====================
print("--- Insertando Productos ---");

db.productos.insertMany([
  {
    _id: 1,
    nombre: "Hoodie Boxy Fit White Dice V2",
    categoria: "polerones",
    precio: 39990,
    imagen: "https://stuffiesconcept.com/cdn/shop/files/WhiteDice1.png",
    imagen_hover: "https://stuffiesconcept.com/cdn/shop/files/WhiteDice2.png",
    descripcion: "Polerón boxy fit White Dice V2.",
    destacado: true,
    stock: {
      total: 10,
      tallas: [
        { talla: "S", cantidad: 3 },
        { talla: "M", cantidad: 5 },
        { talla: "L", cantidad: 2 },
        { talla: "XL", cantidad: 0 }
      ]
    },
    tags: ["new", "invierno"]
  },
  {
    _id: 2,
    nombre: "Star Player Blue Team T-Shirt",
    categoria: "poleras",
    precio: 10990,
    imagen: "https://stuffiesconcept.com/cdn/shop/files/1_594f01e1-55e5-4516-b0af-d2befc1aa113.png",
    imagen_hover: "https://stuffiesconcept.com/cdn/shop/files/2_221c9cfc-6049-4eb1-b7ec-3b19bd755c48.png",
    descripcion: "Polera Star Player Blue Team.",
    destacado: false,
    stock: {
      total: 13,
      tallas: [
        { talla: "M", cantidad: 8 },
        { talla: "L", cantidad: 4 },
        { talla: "XL", cantidad: 1 }
      ]
    },
    tags: ["futbol", "streetwear"]
  },
  {
    _id: 3,
    nombre: "Stella Boxy-Slim Black Tee",
    categoria: "poleras",
    precio: 15990,
    imagen: "https://stuffiesconcept.com/cdn/shop/files/5.png",
    imagen_hover: "https://stuffiesconcept.com/cdn/shop/files/6.png",
    descripcion: "Polera boxy-slim fit negra.",
    destacado: true,
    stock: {
      total: 20,
      tallas: [
        { talla: "S", cantidad: 5 },
        { talla: "M", cantidad: 5 },
        { talla: "L", cantidad: 5 },
        { talla: "XL", cantidad: 5 }
      ]
    },
    tags: ["básico", "negro"]
  },
  {
    _id: 4,
    nombre: "Gorro Beanie Clásico",
    categoria: "gorros",
    precio: 9990,
    imagen: "https://example.com/beanie1.png",
    imagen_hover: "https://example.com/beanie2.png",
    descripcion: "Beanie de punto, unisex, ideal para invierno.",
    destacado: false,
    stock: {
      total: 6,
      tallas: [
        { talla: "Única", cantidad: 6 }
      ]
    },
    tags: ["invierno", "accesorios"]
  }
]);

print("✓ 4 productos insertados\n");

// ==================== CLIENTES ====================
print("--- Insertando Clientes ---");

db.clientes.insertMany([
  {
    _id: 100,
    nombre: "Juan Pérez",
    email: "juan.perez@example.com",
    telefono: "+56 9 1111 1111",
    direccion: {
      calle: "Av. Siempre Viva 123",
      ciudad: "Viña del Mar",
      region: "Valparaíso"
    }
  },
  {
    _id: 101,
    nombre: "María González",
    email: "maria.gonzalez@example.com",
    telefono: "+56 9 2222 2222",
    direccion: {
      calle: "Los Robles 456",
      ciudad: "Santiago",
      region: "RM"
    }
  },
  {
    _id: 102,
    nombre: "Carlos Ramírez",
    email: "carlos.ramirez@example.com",
    telefono: "+56 9 3333 3333",
    direccion: {
      calle: "Av. del Mar 789",
      ciudad: "La Serena",
      region: "Coquimbo"
    }
  }
]);

print("✓ 3 clientes insertados\n");

// ==================== PEDIDOS ====================
print("--- Insertando Pedidos ---");

db.pedidos.insertMany([
  {
    _id: 5000,
    clienteId: 100,
    fecha: new Date("2024-11-20"),
    estado: "CREADO",
    items: [
      {
        productoId: 1,
        nombreProducto: "Hoodie Boxy Fit White Dice V2",
        talla: "M",
        cantidad: 1,
        precioUnitario: 39990
      },
      {
        productoId: 3,
        nombreProducto: "Stella Boxy-Slim Black Tee",
        talla: "L",
        cantidad: 2,
        precioUnitario: 15990
      }
    ],
    total: 71970
  },
  {
    _id: 5001,
    clienteId: 101,
    fecha: new Date("2024-11-21"),
    estado: "PAGADO",
    items: [
      {
        productoId: 2,
        nombreProducto: "Star Player Blue Team T-Shirt",
        talla: "M",
        cantidad: 2,
        precioUnitario: 10990
      }
    ],
    total: 21980
  }
]);

print("✓ 2 pedidos insertados\n");

print("=== BASE DE DATOS STUFFIES CREADA Y POBLADA ===");
