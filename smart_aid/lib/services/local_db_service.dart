import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../models/dose_log_model.dart';
import '../offline/models/sync_queue_item.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'smart_aid_internal.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dose_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        medicationId TEXT NOT NULL,
        medicationName TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        operationType TEXT NOT NULL,
        userId TEXT NOT NULL,
        payload TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
    developer.log('Internal database and dose_logs/sync_queue tables created successfully.');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE sync_queue (
          id TEXT PRIMARY KEY,
          operationType TEXT NOT NULL,
          userId TEXT NOT NULL,
          payload TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
  }

  // Insert a medication intake log into the local database
  Future<void> insertLog({
    required String userId,
    required DoseLogModel log,
  }) async {
    final db = await database;
    try {
      final id = await db.insert(
        'dose_logs',
        {
          'userId': userId,
          'medicationId': log.medicationId,
          'medicationName': log.medicationName,
          'dateKey': log.date,
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('Successfully saved to internal database! Local row id: $id for ${log.medicationName}');
    } catch (e) {
      developer.log('Error saving to internal database: $e', error: e);
    }
  }

  // Retrieve local logs (for future history features if the user wants them)
  Future<List<Map<String, dynamic>>> getLogs(String userId) async {
    final db = await database;
    return await db.query(
      'dose_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC QUEUE
  // ---------------------------------------------------------------------------

  Future<void> enqueueSyncItem(SyncQueueItem item) async {
    final db = await database;
    try {
      await db.insert(
        'sync_queue',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log('Successfully enqueued sync item: ${item.operationType.name}');
    } catch (e) {
      developer.log('Error enqueueing sync item: $e', error: e);
    }
  }

  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_queue',
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
  }

  Future<void> removeSyncItem(String id) async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
