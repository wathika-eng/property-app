import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'stayspace.db';

  static Database get database {
    if (_database != null) return _database!;
    _database = _initDatabase();
    return _database!;
  }

  static Database _initDatabase() {
    final dbPath = path.join(Directory.current.path, 'backend', 'data', _dbName);
    final dbDir = path.dirname(dbPath);
    
    // Create directory if it doesn't exist
    if (!Directory(dbDir).existsSync()) {
      Directory(dbDir).createSync(recursive: true);
    }

    final db = sqlite3.open(dbPath);
    _createTables(db);
    return db;
  }

  static void _createTables(Database db) {
    // Users table
    db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        profile_image TEXT,
        is_landlord INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Listings table
    db.execute('''
      CREATE TABLE IF NOT EXISTS listings (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        location TEXT NOT NULL,
        address TEXT NOT NULL,
        images TEXT NOT NULL,
        bedrooms INTEGER NOT NULL,
        bathrooms INTEGER NOT NULL,
        max_guests INTEGER NOT NULL,
        amenities TEXT NOT NULL,
        rating REAL DEFAULT 0.0,
        review_count INTEGER DEFAULT 0,
        landlord_id TEXT NOT NULL,
        landlord_name TEXT NOT NULL,
        is_available INTEGER DEFAULT 1,
        available_from TEXT,
        available_to TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (landlord_id) REFERENCES users (id)
      )
    ''');

    // Bookings table
    db.execute('''
      CREATE TABLE IF NOT EXISTS bookings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        listing_id TEXT NOT NULL,
        listing_title TEXT NOT NULL,
        check_in TEXT NOT NULL,
        check_out TEXT NOT NULL,
        guests INTEGER NOT NULL,
        total_price REAL NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (listing_id) REFERENCES listings (id)
      )
    ''');

    // Bookmarks table
    db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        listing_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (listing_id) REFERENCES listings (id),
        UNIQUE(user_id, listing_id)
      )
    ''');

    // Reviews table
    db.execute('''
      CREATE TABLE IF NOT EXISTS reviews (
        id TEXT PRIMARY KEY,
        listing_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_profile_image TEXT,
        rating REAL NOT NULL,
        comment TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (listing_id) REFERENCES listings (id),
        UNIQUE(user_id, listing_id)
      )
    ''');
  }

  static void close() {
    _database?.dispose();
    _database = null;
  }
}