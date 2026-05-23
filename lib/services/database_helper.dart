import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/favorite_route.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();

    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'routes.db');

    return await openDatabase(
      path,

      version: 1,

      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE routes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startAddress TEXT,
            endAddress TEXT,
            transportMode TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertRoute(FavoriteRoute route) async {
    final db = await database;

    await db.insert('routes', route.toMap());
  }

  Future<List<FavoriteRoute>> getRoutes() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query('routes');

    return List.generate(maps.length, (i) {
      return FavoriteRoute(
        id: maps[i]['id'],
        startAddress: maps[i]['startAddress'],
        endAddress: maps[i]['endAddress'],
        transportMode: maps[i]['transportMode'],
      );
    });
  }
}
