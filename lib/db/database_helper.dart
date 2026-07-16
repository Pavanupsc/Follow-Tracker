import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';
import '../models/followup.dart';

/// Single persistence layer for the app.
///
/// On mobile/desktop this uses sqflite. On web (Chrome preview) it uses an
/// in-memory store so the UI is fully usable without a WASM SQLite worker.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  // Web / fallback in-memory store
  final List<Customer> _customers = [];
  final List<FollowUp> _followUps = [];

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'followup_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            address TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE followups (
            id TEXT PRIMARY KEY,
            customer_id TEXT NOT NULL,
            scheduled_at TEXT NOT NULL,
            original_date TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            pending_amount REAL NOT NULL DEFAULT 0,
            paid_amount REAL NOT NULL DEFAULT 0,
            notes TEXT,
            last_modified_from TEXT,
            FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE reschedule_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            followup_id TEXT NOT NULL,
            from_date TEXT NOT NULL,
            to_date TEXT NOT NULL,
            changed_at TEXT NOT NULL,
            FOREIGN KEY (followup_id) REFERENCES followups (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_followups_customer ON followups (customer_id)');
        await db.execute(
            'CREATE INDEX idx_followups_scheduled ON followups (scheduled_at)');
      },
    );
  }

  // ---------- Customers ----------

  Future<void> insertCustomer(Customer c) async {
    if (kIsWeb) {
      _customers.removeWhere((e) => e.id == c.id);
      _customers.add(c);
      return;
    }
    final db = await database;
    await db.insert('customers', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomer(Customer c) async {
    if (kIsWeb) {
      final i = _customers.indexWhere((e) => e.id == c.id);
      if (i >= 0) _customers[i] = c;
      return;
    }
    final db = await database;
    await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCustomer(String id) async {
    if (kIsWeb) {
      _customers.removeWhere((e) => e.id == id);
      _followUps.removeWhere((e) => e.customerId == id);
      return;
    }
    final db = await database;
    await db.delete('followups', where: 'customer_id = ?', whereArgs: [id]);
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Customer>> getCustomers() async {
    if (kIsWeb) {
      final list = List<Customer>.from(_customers)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    }
    final db = await database;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  // ---------- Follow-ups ----------

  Future<void> insertFollowUp(FollowUp f) async {
    if (kIsWeb) {
      _followUps.removeWhere((e) => e.id == f.id);
      _followUps.add(FollowUp.fromMap(f.toMap())..history.addAll(f.history));
      return;
    }
    final db = await database;
    await db.insert('followups', f.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFollowUp(FollowUp f) async {
    if (kIsWeb) {
      final i = _followUps.indexWhere((e) => e.id == f.id);
      final copy = FollowUp.fromMap(f.toMap())..history.addAll(f.history);
      if (i >= 0) {
        _followUps[i] = copy;
      } else {
        _followUps.add(copy);
      }
      return;
    }
    final db = await database;
    await db.update('followups', f.toMap(), where: 'id = ?', whereArgs: [f.id]);
    await db.delete('reschedule_history',
        where: 'followup_id = ?', whereArgs: [f.id]);
    for (final h in f.history) {
      await db.insert('reschedule_history', {
        'followup_id': f.id,
        'from_date': h.from.toIso8601String(),
        'to_date': h.to.toIso8601String(),
        'changed_at': h.changedAt.toIso8601String(),
      });
    }
  }

  Future<void> deleteFollowUp(String id) async {
    if (kIsWeb) {
      _followUps.removeWhere((e) => e.id == id);
      return;
    }
    final db = await database;
    await db.delete('followups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<FollowUp>> getFollowUpsForCustomer(String customerId) async {
    if (kIsWeb) {
      final list = _followUps.where((f) => f.customerId == customerId).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return list.map(_cloneFollowUp).toList();
    }
    final db = await database;
    final rows = await db.query('followups',
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'scheduled_at');
    return _hydrate(db, rows);
  }

  Future<List<FollowUp>> getAllFollowUps() async {
    if (kIsWeb) {
      final list = List<FollowUp>.from(_followUps)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return list.map(_cloneFollowUp).toList();
    }
    final db = await database;
    final rows = await db.query('followups', orderBy: 'scheduled_at');
    return _hydrate(db, rows);
  }

  FollowUp _cloneFollowUp(FollowUp f) =>
      FollowUp.fromMap(f.toMap())..history.addAll(f.history);

  Future<List<FollowUp>> _hydrate(
      Database db, List<Map<String, Object?>> rows) async {
    final result = <FollowUp>[];
    for (final row in rows) {
      final f = FollowUp.fromMap(row);
      final historyRows = await db.query('reschedule_history',
          where: 'followup_id = ?', whereArgs: [f.id], orderBy: 'id');
      f.history.addAll(historyRows.map(RescheduleEntry.fromRow));
      result.add(f);
    }
    return result;
  }
}
