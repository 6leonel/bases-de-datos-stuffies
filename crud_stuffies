// ============================================
// BDY1103 – STUFFIES – OPERACIONES CRUD
// IE3.3.1: Manipula bases de datos NO RELACIONALES
// ============================================

// =====================================
// ============== CREATE ===============
// =====================================

print("\n=== CREATE (INSERTAR) ===\n");

// Insertar un nuevo producto
print("--- Insertando nuevo producto ---");
db.productos.insertOne({
  _id: 5,
  nombre: "Hoodie Oversize Black",
  categoria: "polerones",
  precio: 44990,
  imagen: "https://example.com/hoodie-black.png",
  imagen_hover: "https://example.com/hoodie-black-2.png",
  descripcion: "Hoodie oversize color negro.",
  destacado: false,
  stock: {
    total: 15,
    tallas: [
      { talla: "M", cantidad: 5 },
      { talla: "L", cantidad: 7 },
      { talla: "XL", cantidad: 3 }
    ]
  },
  tags: ["nuevo", "negro"]
});

db.productos.findOne({ _id: 5 });

// Insertar un nuevo pedido
print("\n--- Insertando nuevo pedido ---");
db.pedidos.insertOne({
  _id: 5002,
  clienteId: 102,
  fecha: new Date(),
  estado: "CREADO",
  items: [
    {
      productoId: 4,
      nombreProducto: "Gorro Beanie Clásico",
      talla: "Única",
      cantidad: 2,
      precioUnitario: 9990
    }
  ],
  total: 19980
});

db.pedidos.findOne({ _id: 5002 });

// =====================================
// =============== READ ================
// =====================================

print("\n=== READ (CONSULTAR) ===\n");

// Consultar todos los productos
print("--- Todos los productos ---");
db.productos.find({}, { nombre: 1, precio: 1, categoria: 1 }).pretty();

// Consultar productos con precio > 15000
print("\n--- Productos con precio > $15,000 ---");
db.productos.find({ precio: { $gt: 15000 } }, { nombre: 1, precio: 1 }).pretty();

// Buscar productos destacados
print("\n--- Productos destacados ---");
db.productos.find({ destacado: true }, { nombre: 1, destacado: 1 }).pretty();

// Buscar productos de categoría "poleras"
print("\n--- Productos categoría 'poleras' ---");
db.productos.find({ categoria: "poleras" }, { nombre: 1, precio: 1 }).pretty();

// Buscar clientes de Santiago
print("\n--- Clientes de Santiago ---");
db.clientes.find({ "direccion.ciudad": "Santiago" }, { nombre: 1, "direccion.ciudad": 1 }).pretty();

// Consulta con agregación: pedidos con nombre de cliente
print("\n--- Pedidos con información del cliente ---");
db.pedidos.aggregate([
  {
    $lookup: {
      from: "clientes",
      localField: "clienteId",
      foreignField: "_id",
      as: "cliente_info"
    }
  },
  {
    $unwind: "$cliente_info"
  },
  {
    $project: {
      pedido_id: "$_id",
      fecha: 1,
      estado: 1,
      nombre_cliente: "$cliente_info.nombre",
      total: 1
    }
  }
]).pretty();

// =====================================
// ============== UPDATE ===============
// =====================================

print("\n=== UPDATE (ACTUALIZAR) ===\n");

// Actualizar precio de un producto
print("--- Antes del cambio ---");
db.productos.findOne({ _id: 2 }, { nombre: 1, precio: 1 });

db.productos.updateOne(
  { _id: 2 },
  { $set: { precio: 11990 } }
);

print("\n--- Después del cambio ---");
db.productos.findOne({ _id: 2 }, { nombre: 1, precio: 1 });

// Reducir stock de una talla específica (venta)
print("\n--- Antes de la venta ---");
db.productos.findOne({ _id: 1 }, { nombre: 1, "stock.total": 1, "stock.tallas": 1 });

db.productos.updateOne(
  { _id: 1, "stock.tallas.talla": "M" },
  {
    $inc: {
      "stock.tallas.$.cantidad": -1,
      "stock.total": -1
    }
  }
);

print("\n--- Después de la venta ---");
db.productos.findOne({ _id: 1 }, { nombre: 1, "stock.total": 1, "stock.tallas": 1 });

// Cambiar estado de un pedido
print("\n--- Cambiar estado de pedido ---");
print("Antes:");
db.pedidos.findOne({ _id: 5000 }, { clienteId: 1, estado: 1 });

db.pedidos.updateOne(
  { _id: 5000 },
  { $set: { estado: "PAGADO" } }
);

print("\nDespués:");
db.pedidos.findOne({ _id: 5000 }, { clienteId: 1, estado: 1 });

// Marcar productos con stock alto como destacados
print("\n--- Marcar productos con stock >= 15 como destacados ---");
db.productos.updateMany(
  { "stock.total": { $gte: 15 } },
  { $set: { destacado: true } }
);

db.productos.find(
  { "stock.total": { $gte: 15 } },
  { nombre: 1, destacado: 1, "stock.total": 1 }
).pretty();

// Añadir tag a productos destacados
print("\n--- Añadir tag 'oferta' a productos destacados ---");
db.productos.updateMany(
  { destacado: true },
  { $addToSet: { tags: "oferta" } }
);

db.productos.find(
  { destacado: true },
  { nombre: 1, tags: 1 }
).pretty();

// =====================================
// ============== DELETE ===============
// =====================================

print("\n=== DELETE (ELIMINAR) ===\n");

// Crear producto temporal para eliminar
print("--- Creando producto temporal ---");
db.productos.insertOne({
  _id: 99,
  nombre: "Producto Temporal",
  categoria: "test",
  precio: 1000,
  destacado: false,
  stock: { total: 0, tallas: [] },
  tags: ["test"]
});

print("Verificando que existe:");
db.productos.findOne({ _id: 99 });

// Eliminar el producto temporal
print("\n--- Eliminando producto temporal ---");
db.productos.deleteOne({ _id: 99 });

print("Verificando que fue eliminado:");
db.productos.findOne({ _id: 99 }); // Devuelve null

// Eliminar pedidos con estado CANCELADO
print("\n--- Creando pedido a cancelar ---");
db.pedidos.insertOne({
  _id: 9999,
  clienteId: 100,
  fecha: new Date("2023-01-01"),
  estado: "CANCELADO",
  items: [],
  total: 0
});

print("Total de pedidos antes:");
print(db.pedidos.countDocuments());

print("\n--- Eliminando pedidos cancelados ---");
db.pedidos.deleteMany({ estado: "CANCELADO" });

print("Total de pedidos después:");
print(db.pedidos.countDocuments());

// =====================================
// ========== CONSULTAS AVANZADAS ======
// =====================================

print("\n=== CONSULTAS AVANZADAS ===\n");

// Unwind de tallas (desnormalizar)
print("--- Tallas disponibles por producto ---");
db.productos.aggregate([
  {
    $project: {
      nombre: 1,
      tallas: "$stock.tallas"
    }
  },
  {
    $unwind: "$tallas"
  },
  {
    $project: {
      nombre: 1,
      talla: "$tallas.talla",
      cantidad: "$tallas.cantidad"
    }
  }
]).pretty();

// Contar productos por categoría
print("\n--- Cantidad de productos por categoría ---");
db.productos.aggregate([
  {
    $group: {
      _id: "$categoria",
      cantidad: { $sum: 1 }
    }
  },
  {
    $sort: { cantidad: -1 }
  }
]).pretty();

// Total de ventas
print("\n--- Total de ventas ---");
db.pedidos.aggregate([
  {
    $group: {
      _id: null,
      totalVentas: { $sum: "$total" },
      cantidadPedidos: { $sum: 1 }
    }
  }
]).pretty();

// Productos más vendidos
print("\n--- Productos más vendidos ---");
db.pedidos.aggregate([
  { $unwind: "$items" },
  {
    $group: {
      _id: "$items.nombreProducto",
      cantidadVendida: { $sum: "$items.cantidad" },
      totalRecaudado: { $sum: { $multiply: ["$items.cantidad", "$items.precioUnitario"] } }
    }
  },
  { $sort: { cantidadVendida: -1 } }
]).pretty();

print("\n=== FIN DE OPERACIONES CRUD ===");
