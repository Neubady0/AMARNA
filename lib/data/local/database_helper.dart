import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'amarna.db');
    return await openDatabase(
      path,
      version: 4, // Aumentamos la versión de la base de datos
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          role TEXT NOT NULL,
          cv_path TEXT,
          cv_content TEXT,
          name TEXT,
          studies TEXT,
          experience TEXT
      )
      ''');
    // Tabla de ofertas de empleo
    await db.execute('''
      CREATE TABLE job_offers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          requirements TEXT,
          location TEXT
      )
      ''');
    // Tabla de aplicaciones de usuario a ofertas
    await db.execute('''
      CREATE TABLE applications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          job_offer_id INTEGER NOT NULL,
          application_date TEXT NOT NULL,
          status TEXT NOT NULL,
          UNIQUE(user_id, job_offer_id),
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (job_offer_id) REFERENCES job_offers(id) ON DELETE CASCADE
      )
      ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Si la versión antigua era menor que 2, añadimos las columnas de perfil
      await db.execute("ALTER TABLE users ADD COLUMN name TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN studies TEXT");
      await db.execute("ALTER TABLE users ADD COLUMN experience TEXT");
    }
    if (oldVersion < 3) {
      // Si la versión antigua era menor que 3, creamos las nuevas tablas
      await db.execute('''
        CREATE TABLE job_offers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            requirements TEXT,
            location TEXT
        )
        ''');
      await db.execute('''
        CREATE TABLE applications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            job_offer_id INTEGER NOT NULL,
            application_date TEXT NOT NULL,
            status TEXT NOT NULL,
            UNIQUE(user_id, job_offer_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (job_offer_id) REFERENCES job_offers(id) ON DELETE CASCADE
        )
        ''');
    } // MISSING BRACE FIXED HERE
    if (oldVersion < 4) {
      // Si la versión antigua era menor que 4, añadimos la columna del contenido del CV
      await db.execute("ALTER TABLE users ADD COLUMN cv_content TEXT");
    }
  }

  Future<int> saveUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> updateUserCv(int userId, String cvPath, String cvContent) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'cv_path': cvPath,
        'cv_content': cvContent,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateUserProfile(int userId, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Nuevos métodos para ofertas y aplicaciones
  Future<int> saveJobOffer(Map<String, dynamic> offer) async {
    final db = await database;
    return await db.insert('job_offers', offer);
  }

  Future<List<Map<String, dynamic>>> getAllJobOffers() async {
    final db = await database;
    return await db.query('job_offers');
  }

  Future<int> applyToJobOffer(Map<String, dynamic> application) async {
    final db = await database;
    return await db.insert('applications', application);
  }

  Future<bool> hasUserApplied(int userId, int jobOfferId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'applications',
      where: 'user_id = ? AND job_offer_id = ?',
      whereArgs: [userId, jobOfferId],
    );
    return result.isNotEmpty;
  }
}
