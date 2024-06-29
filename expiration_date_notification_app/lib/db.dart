import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_items.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS food_items (
        id $idType,
        name $textType,
        expiration_date $textType,
        storage_method $textType,
        tips_for_saving $textType,
        is_used $integerType DEFAULT 0,
        created_at $textType
      );
    ''');
  }

  Future<void> insertFoodItem(Map<String, dynamic> foodItem) async {
    final db = await instance.database;
    // Add "created_at" with the current DateTime as a string
    final updatedFoodItem = {
      ...foodItem,
      'created_at': DateTime.now().toString(),
    };
    await db.insert('food_items', updatedFoodItem, conflictAlgorithm: ConflictAlgorithm.replace);
    print("食材の登録完了");
  }

  // データベースを閉じる
  Future close() async {
    final db = await instance.database;
    db.close();
  }

   Future<List<FoodItem>> fetchFoodItems() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('food_items');

    return List.generate(maps.length, (i) {
      return FoodItem(
        id: maps[i]['id'].toString(),
        name: maps[i]['name'],
        expirationDate: maps[i]['expiration_date'],
        storageMethod: maps[i]['storage_method'],
        tipsForSaving: maps[i]['tips_for_saving'],
      );
    });
  
  }
  Future<void> deleteFoodItem(String id) async {
    final db = await database;
    await db.delete(
      'food_items', 
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
class FoodItem {
  final String id;
  final String name;
  final String expirationDate;
  final String storageMethod;
  final String tipsForSaving;

  FoodItem({
    required this.id, 
    required this.name,
    required this.expirationDate,
    required this.storageMethod,
    required this.tipsForSaving,
  });
}