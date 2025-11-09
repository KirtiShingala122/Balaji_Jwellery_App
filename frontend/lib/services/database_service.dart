import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/admin.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import 'package:flutter/foundation.dart'
 hide Category; // add this import on top
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // add this too
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // ✅ For Web: use IndexedDB-backed database
      final factory = databaseFactoryFfiWeb;
      final db = await factory.openDatabase('balaji_imitation_web.db');
      await _onCreate(db, 1);
      return db;
    } else {
      String path = join(await getDatabasesPath(), 'balaji_imitation.db');
      return await openDatabase(path, version: 1, onCreate: _onCreate);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Admin table
    await db.execute('''
      CREATE TABLE admins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        fullName TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastLogin TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uniqueCode TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        price REAL NOT NULL,
        stockQuantity INTEGER NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phoneNumber TEXT NOT NULL,
        address TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Bills table
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billNumber TEXT UNIQUE NOT NULL,
        customerId INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        taxAmount REAL NOT NULL,
        discountAmount REAL NOT NULL,
        totalAmount REAL NOT NULL,
        billDate TEXT NOT NULL,
        paymentStatus TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Bill items table
    await db.execute('''
      CREATE TABLE bill_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    //   // Insert default admin
    //   await db.insert('admins', {
    //     'username': 'admin',
    //     'password': 'admin123', // In production, this should be hashed
    //     'email': 'admin@balajiimitation.com',
    //     'fullName': 'Admin User',
    //     'createdAt': DateTime.now().toIso8601String(),
    //   });
  }

  // Admin operations
  Future<int> insertAdmin(Admin admin) async {
    final db = await database;
    return await db.insert('admins', admin.toMap());
  }

  Future<Admin?> getAdminByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'admins',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return Admin.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateAdminLastLogin(int adminId) async {
    final db = await database;
    await db.update(
      'admins',
      {'lastLogin': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [adminId],
    );
  }

  Future<int> updateAdmin(Admin admin) async {
    final db = await database;
    return await db.update(
      'admins',
      admin.toMap(),
      where: 'id = ?',
      whereArgs: [admin.id],
    );
  }

  // Category operations
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Product operations
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<Product?> getProductByCode(String uniqueCode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'uniqueCode = ?',
      whereArgs: [uniqueCode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'stockQuantity <= 5',
    );
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // Customer operations
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'name LIKE ? OR email LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Bill operations
  Future<int> insertBill(Bill bill) async {
    final db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<int> insertBillItem(BillItem billItem) async {
    final db = await database;
    return await db.insert('bill_items', billItem.toMap());
  }

  Future<List<Bill>> getAllBills() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bills');
    return List.generate(maps.length, (i) => Bill.fromMap(maps[i]));
  }

  Future<List<Bill>> getBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'billDate BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return List.generate(maps.length, (i) => Bill.fromMap(maps[i]));
  }

  Future<List<BillItem>> getBillItems(int billId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bill_items',
      where: 'billId = ?',
      whereArgs: [billId],
    );
    return List.generate(maps.length, (i) => BillItem.fromMap(maps[i]));
  }

  Future<double> getTotalSales() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM bills',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalSalesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(totalAmount) as total FROM bills WHERE billDate BETWEEN ? AND ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getTotalProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return result.first['count'] as int;
  }

  Future<int> getTotalCategories() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM categories',
    );
    return result.first['count'] as int;
  }

  Future<int> getTotalCustomers() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM customers');
    return result.first['count'] as int;
  }
}
