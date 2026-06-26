import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/trip.dart';

class TripDatabase {
  static final TripDatabase instance = TripDatabase._init();
  static Database? _database;

  TripDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mileage_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        date INTEGER NOT NULL,
        from_location TEXT NOT NULL DEFAULT '',
        to_location TEXT NOT NULL DEFAULT '',
        miles REAL NOT NULL,
        purpose TEXT NOT NULL DEFAULT 'Personal',
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> insertTrip(Trip trip) async {
    final db = await database;
    await db.insert('trips', trip.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    await db.update('trips', trip.toMap(),
        where: 'id = ?', whereArgs: [trip.id]);
  }

  Future<void> deleteTrip(String id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'date DESC');
    return maps.map(Trip.fromMap).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
