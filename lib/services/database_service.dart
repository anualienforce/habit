import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';
import '../models/category.dart';

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
    try {
      String path = join(await getDatabasesPath(), 'habit_tracker.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here in future versions
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint TEXT NOT NULL,
        colorValue TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create habits table
    await db.execute('''
      CREATE TABLE habits(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        categoryId TEXT NOT NULL,
        frequency INTEGER NOT NULL,
        weekdays TEXT NOT NULL,
        targetPerWeek INTEGER NOT NULL,
        targetPerMonth INTEGER NOT NULL,
        reminderTime INTEGER,
        isReminderEnabled INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isActive INTEGER NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Create habit_logs table
    await db.execute('''
      CREATE TABLE habit_logs(
        id TEXT PRIMARY KEY,
        habitId TEXT NOT NULL,
        date INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habits (id)
      )
    ''');

    // Insert default categories
    final defaultCategories = Category.getDefaultCategories();
    for (final category in defaultCategories) {
      await db.insert('categories', category.toJson());
    }
  }

  // Categories CRUD
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name');
    return List.generate(maps.length, (i) => Category.fromJson(maps[i]));
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Category.fromJson(maps.first);
    }
    return null;
  }

  Future<String> insertCategory(Category category) async {
    final db = await database;
    await db.insert('categories', category.toJson());
    return category.id;
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Habits CRUD
  Future<List<Habit>> getHabits({bool? isActive}) async {
    final db = await database;
    final whereClause = isActive != null ? 'isActive = ?' : null;
    final whereArgs = isActive != null ? [isActive ? 1 : 0] : null;
    
    final maps = await db.query(
      'habits',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => Habit.fromJson(maps[i]));
  }

  Future<Habit?> getHabitById(String id) async {
    final db = await database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Habit.fromJson(maps.first);
    }
    return null;
  }

  Future<List<Habit>> getHabitsByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      'habits',
      where: 'categoryId = ? AND isActive = ?',
      whereArgs: [categoryId, 1],
      orderBy: 'name',
    );
    return List.generate(maps.length, (i) => Habit.fromJson(maps[i]));
  }

  Future<String> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toJson());
    return habit.id;
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update(
      'habits',
      habit.toJson(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    await db.delete('habit_logs', where: 'habitId = ?', whereArgs: [id]);
  }

  // Habit Logs CRUD
  Future<List<HabitLog>> getHabitLogs(String habitId, {DateTime? startDate, DateTime? endDate}) async {
    final db = await database;
    String whereClause = 'habitId = ?';
    List<dynamic> whereArgs = [habitId];

    if (startDate != null) {
      whereClause += ' AND date >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND date <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final maps = await db.query(
      'habit_logs',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => HabitLog.fromJson(maps[i]));
  }

  Future<HabitLog?> getHabitLogByDate(String habitId, DateTime date) async {
    final db = await database;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final nextDay = dateOnly.add(const Duration(days: 1));
    
    final maps = await db.query(
      'habit_logs',
      where: 'habitId = ? AND date >= ? AND date < ?',
      whereArgs: [
        habitId,
        dateOnly.millisecondsSinceEpoch,
        nextDay.millisecondsSinceEpoch,
      ],
    );
    
    if (maps.isNotEmpty) {
      return HabitLog.fromJson(maps.first);
    }
    return null;
  }

  Future<String> insertHabitLog(HabitLog habitLog) async {
    final db = await database;
    await db.insert('habit_logs', habitLog.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    return habitLog.id;
  }

  Future<void> updateHabitLog(HabitLog habitLog) async {
    final db = await database;
    await db.update(
      'habit_logs',
      habitLog.toJson(),
      where: 'id = ?',
      whereArgs: [habitLog.id],
    );
  }

  Future<void> deleteHabitLog(String id) async {
    final db = await database;
    await db.delete('habit_logs', where: 'id = ?', whereArgs: [id]);
  }

  // Analytics queries
  Future<int> getCurrentStreak(String habitId) async {
    final db = await database;
    final today = DateTime.now();
    final maps = await db.rawQuery('''
      SELECT date FROM habit_logs 
      WHERE habitId = ? AND isCompleted = 1 
      ORDER BY date DESC
    ''', [habitId]);

    if (maps.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime(today.year, today.month, today.day);
    
    for (final map in maps) {
      final logDate = DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
      final logDateOnly = DateTime(logDate.year, logDate.month, logDate.day);
      
      if (logDateOnly == currentDate || 
          (streak == 0 && logDateOnly == currentDate.subtract(const Duration(days: 1)))) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  Future<int> getTotalCompletions(String habitId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_logs 
      WHERE habitId = ? AND isCompleted = 1
    ''', [habitId]);
    return result.first['count'] as int;
  }

  Future<double> getCompletionRate(String habitId, {int days = 30}) async {
    final db = await database;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    
    final totalResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_logs 
      WHERE habitId = ? AND date >= ? AND date <= ?
    ''', [habitId, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]);
    
    final completedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM habit_logs 
      WHERE habitId = ? AND isCompleted = 1 AND date >= ? AND date <= ?
    ''', [habitId, startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch]);
    
    final total = totalResult.first['count'] as int;
    final completed = completedResult.first['count'] as int;
    
    return total > 0 ? completed / total : 0.0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
