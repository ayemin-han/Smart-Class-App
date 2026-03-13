import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {

  static Database? _database;

  Future<Database> get database async {

    if (_database != null) return _database!;

    _database = await initDB();
    return _database!;
  }

  initDB() async {

    String path = join(await getDatabasesPath(), 'class_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        await db.execute('''
        CREATE TABLE records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT,
          latitude TEXT,
          longitude TEXT,
          qr TEXT,
          note TEXT
        )
        ''');

      },
    );
  }

  insertRecord(Map<String, dynamic> data) async {

    final db = await database;

    return db.insert('records', data);
  }
}