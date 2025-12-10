import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'easy_pill.db');

    debugPrint('Database path: $path');

    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosing TEXT,
        pill_count INTEGER,
        description TEXT,
        schedule_type INTEGER NOT NULL,
        interval INTEGER,
        fixed_times TEXT,
        start_time TEXT,
        created_at TEXT NOT NULL,
        notification_id INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE dose_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        taken_at TEXT NOT NULL,
        FOREIGN KEY(medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE skipped_doses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        skipped_at TEXT NOT NULL,
        FOREIGN KEY(medication_id) REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    debugPrint('Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      debugPrint('Upgrading database from $oldVersion to $newVersion');
      
      // Add skipped_doses table if upgrading from version 1
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS skipped_doses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            scheduled_time TEXT NOT NULL,
            skipped_at TEXT NOT NULL,
            FOREIGN KEY(medication_id) REFERENCES medications(id) ON DELETE CASCADE
          )
        ''');
      }
      
      // Add start_time column if upgrading to version 3
      if (oldVersion < 3) {
        await db.execute('ALTER TABLE medications ADD COLUMN start_time TEXT');
      }
    }
  }

  // CRUD Operations for Medications
  Future<int> insertMedication(Medication medication) async {
    try {
      final db = await database;
      final id = await db.insert(
        'medications',
        medication.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Medication inserted with ID: $id');
      return id;
    } catch (e) {
      debugPrint('Error inserting medication: $e');
      rethrow;
    }
  }

  Future<List<Medication>> getAllMedications() async {
    try {
      final db = await database;
      final maps = await db.query(
        'medications',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );

      final medications = [
        for (final map in maps) Medication.fromMap(map),
      ];
      
      debugPrint('Retrieved ${medications.length} medications from database');
      return medications;
    } catch (e) {
      debugPrint('Error getting medications: $e');
      rethrow;
    }
  }

  Future<Medication?> getMedicationById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'medications',
        where: 'id = ? AND is_active = ?',
        whereArgs: [id, 1],
      );

      if (maps.isNotEmpty) {
        return Medication.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting medication: $e');
      rethrow;
    }
  }

  Future<int> updateMedication(Medication medication) async {
    try {
      final db = await database;
      final count = await db.update(
        'medications',
        medication.toMap(),
        where: 'id = ?',
        whereArgs: [medication.id],
      );
      debugPrint('Updated medication with ID: ${medication.id}');
      return count;
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  Future<int> deleteMedication(int id) async {
    try {
      final db = await database;
      // Soft delete - mark as inactive
      final count = await db.update(
        'medications',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      
      // Also delete dose history
      await db.delete(
        'dose_history',
        where: 'medication_id = ?',
        whereArgs: [id],
      );
      
      debugPrint('Deleted medication with ID: $id');
      return count;
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  // Dose History Operations
  Future<void> recordDoseTaken(int medicationId) async {
    try {
      final db = await database;
      await db.insert(
        'dose_history',
        {
          'medication_id': medicationId,
          'taken_at': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Recorded dose for medication ID: $medicationId');
    } catch (e) {
      debugPrint('Error recording dose: $e');
      rethrow;
    }
  }

  Future<List<DateTime>> getDoseHistoryForMedication(int medicationId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'dose_history',
        where: 'medication_id = ?',
        whereArgs: [medicationId],
        orderBy: 'taken_at DESC',
      );

      return [
        for (final map in maps)
          DateTime.parse(map['taken_at'] as String),
      ];
    } catch (e) {
      debugPrint('Error getting dose history: $e');
      rethrow;
    }
  }

  Future<int> getTodaysDoseCount(int medicationId) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM dose_history WHERE medication_id = ? AND taken_at BETWEEN ? AND ?',
        [medicationId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );

      return result.isNotEmpty ? (result.first['count'] as int?) ?? 0 : 0;
    } catch (e) {
      debugPrint('Error getting today dose count: $e');
      rethrow;
    }
  }

  Future<Map<int, int>> getTodayDoseCounts() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay =
          DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      final result = await db.rawQuery(
        'SELECT medication_id, COUNT(*) as count FROM dose_history WHERE taken_at BETWEEN ? AND ? GROUP BY medication_id',
        [startOfDay, endOfDay],
      );

      final counts = <int, int>{};
      for (final row in result) {
        final id = row['medication_id'] as int?;
        final count = row['count'] as int?;
        if (id != null && count != null) {
          counts[id] = count;
        }
      }

      return counts;
    } catch (e) {
      debugPrint('Error getting today dose counts: $e');
      rethrow;
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      debugPrint('Database closed');
    }
  }

  // Skipped Doses Operations
  Future<void> skipDose(int medicationId, DateTime scheduledTime) async {
    try {
      final db = await database;
      await db.insert(
        'skipped_doses',
        {
          'medication_id': medicationId,
          'scheduled_time': scheduledTime.toIso8601String(),
          'skipped_at': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Skipped dose for medication ID: $medicationId at $scheduledTime');
    } catch (e) {
      debugPrint('Error skipping dose: $e');
      rethrow;
    }
  }

  Future<List<DateTime>> getSkippedDosesForMedication(int medicationId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'skipped_doses',
        where: 'medication_id = ?',
        whereArgs: [medicationId],
        orderBy: 'scheduled_time DESC',
      );

      return [
        for (final map in maps)
          DateTime.parse(map['scheduled_time'] as String),
      ];
    } catch (e) {
      debugPrint('Error getting skipped doses: $e');
      rethrow;
    }
  }

  Future<Set<String>> getAllSkippedDoseKeys() async {
    try {
      final db = await database;
      final maps = await db.query('skipped_doses');

      return {
        for (final map in maps)
          '${map['medication_id']}_${map['scheduled_time']}',
      };
    } catch (e) {
      debugPrint('Error getting all skipped dose keys: $e');
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    try {
      final db = await database;
      await db.delete('skipped_doses');
      await db.delete('dose_history');
      await db.delete('medications');
      debugPrint('All data deleted');
    } catch (e) {
      debugPrint('Error deleting all data: $e');
      rethrow;
    }
  }
}
