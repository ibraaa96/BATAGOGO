import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance =
      DatabaseHelper._privateConstructor();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'batagogo.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user'",
      );
    }
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    await db.execute('''
      CREATE TABLE users (
        id_user INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        no_hp TEXT NOT NULL,
        alamat TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user'
      )
    ''');

    await db.execute('''
      CREATE TABLE produk (
        id_produk INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_produk TEXT NOT NULL,
        jenis TEXT NOT NULL,
        harga REAL NOT NULL,
        stok INTEGER NOT NULL,
        deskripsi TEXT NOT NULL,
        gambar TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pesanan (
        id_pesanan INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        tanggal_pesanan TEXT NOT NULL,
        total_harga REAL NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (id_user) REFERENCES users(id_user)
      )
    ''');

    await db.execute('''
      CREATE TABLE detail_pesanan (
        id_detail INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pesanan INTEGER NOT NULL,
        id_produk INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        harga REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (id_pesanan) REFERENCES pesanan(id_pesanan),
        FOREIGN KEY (id_produk) REFERENCES produk(id_produk)
      )
    ''');

    await db.execute('''
      CREATE TABLE pembayaran (
        id_pembayaran INTEGER PRIMARY KEY AUTOINCREMENT,
        id_pesanan INTEGER NOT NULL,
        metode TEXT NOT NULL,
        jumlah_bayar REAL NOT NULL,
        tanggal_bayar TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (id_pesanan) REFERENCES pesanan(id_pesanan)
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_support (
        id_support INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        pesan TEXT NOT NULL,
        tanggal TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (id_user) REFERENCES users(id_user)
      )
    ''');

    await _insertProducts(db);
  }

  Future<void> _insertProducts(Database db) async {
    final products = [
      {
        'nama_produk': 'Batagor Biasa',
        'jenis': 'Biasa',
        'harga': 10000.0,
        'stok': 50,
        'deskripsi':
            'Batagor dengan rasa gurih dan lezat, cocok untuk camilan.',
        'gambar': '',
      },
      {
        'nama_produk': 'Batagor Ikan',
        'jenis': 'Ikan',
        'harga': 15000.0,
        'stok': 40,
        'deskripsi':
            'Batagor dengan campuran ikan yang gurih dan nikmat.',
        'gambar': '',
      },
      {
        'nama_produk': 'Batagor Kuah',
        'jenis': 'Kuah',
        'harga': 15000.0,
        'stok': 35,
        'deskripsi':
            'Batagor dengan kuah gurih yang cocok dinikmati hangat.',
        'gambar': '',
      },
      {
        'nama_produk': 'Batagor Kering',
        'jenis': 'Kering',
        'harga': 12000.0,
        'stok': 30,
        'deskripsi':
            'Batagor kering renyah tanpa kuah.',
        'gambar': '',
      },
    ];

    for (final product in products) {
      await db.insert(
        'produk',
        product,
      );
    }
  }
  Future<String> getDatabasePath() async {
  return join(await getDatabasesPath(), 'batagogo.db');
}
}
