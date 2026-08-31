// ─────────────────────────────────────────────────────────────────────────────
// marriage_dao.dart — SQLite Data Access Object for Marriages
// ─────────────────────────────────────────────────────────────────────────────
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/sync_status.dart';
import '../models/marriage_model.dart';

class MarriageDao {
  MarriageDao._();
  static final MarriageDao instance = MarriageDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  // ── INSERT ───────────────────────────────────────────────────────────────
  Future<void> insert(MarriageModel marriage) async {
    final db = await _db;
    await db.insert(
      'marriages',
      marriage.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── UPDATE ───────────────────────────────────────────────────────────────
  Future<void> update(MarriageModel marriage) async {
    final db = await _db;
    await db.update(
      'marriages',
      marriage.toSqliteMap(),
      where: 'id = ?',
      whereArgs: [marriage.id],
    );
  }

  // ── UPSERT (used by sync engine) ─────────────────────────────────────────
  Future<void> upsert(MarriageModel marriage) async {
    final existing = await getById(marriage.id);
    if (existing == null) {
      await insert(marriage);
    } else {
      // Conflict resolution: remote wins if remote is newer
      final remoteTs = marriage.firestoreUpdatedAt ?? marriage.lastStatusUpdate;
      final localTs = existing.lastStatusUpdate;
      if (remoteTs.isAfter(localTs)) {
        await update(marriage);
      }
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('marriages', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsDeleted(String id) async {
    final db = await _db;
    await db.update(
      'marriages',
      {
        'sync_status': SyncStatus.pendingDelete.value,
        'last_status_update': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── UPDATE SYNC STATUS ────────────────────────────────────────────────────
  Future<void> updateSyncStatus(String id, SyncStatus status) async {
    final db = await _db;
    await db.update(
      'marriages',
      {
        'sync_status': status.value,
        'synced_at': status == SyncStatus.synced
            ? DateTime.now().millisecondsSinceEpoch
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── GET BY ID ─────────────────────────────────────────────────────────────
  Future<MarriageModel?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('marriages', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MarriageModel.fromSqliteMap(rows.first);
  }

  // ── GET ALL (with optional filters) ──────────────────────────────────────
  Future<List<MarriageModel>> getAll({
    ProcessingStatus? status,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int offset = 0,
  }) async {
    final db = await _db;

    final List<String> conditions = ["m.sync_status != '${SyncStatus.pendingDelete.value}'"];
    final List<dynamic> args = [];

    if (status != null) {
      conditions.add('m.processing_status = ?');
      args.add(status.value);
    }

    if (fromDate != null) {
      final startOfDay = DateTime(fromDate.year, fromDate.month, fromDate.day).millisecondsSinceEpoch;
      conditions.add('(m.gregorian_date >= ? OR (m.gregorian_date IS NULL AND m.created_at >= ?))');
      args.add(startOfDay);
      args.add(startOfDay);
    }

    if (toDate != null) {
      final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;
      conditions.add('(m.gregorian_date <= ? OR (m.gregorian_date IS NULL AND m.created_at <= ?))');
      args.add(endOfDay);
      args.add(endOfDay);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      conditions.add('''(
        m.record_number LIKE ?
        OR m.hijri_date LIKE ?
        OR m.husband_name LIKE ?
        OR m.wife_name LIKE ?
        OR m.guardian_name LIKE ?
        OR m.husband_id_number LIKE ?
        OR m.wife_id_number LIKE ?
        OR m.husband_birth_date LIKE ?
        OR m.wife_birth_date LIKE ?
      )''');
      args.addAll([
        '%$q%',
        '%$q%',
        '%$q%',
        '%$q%',
        '%$q%',
        '%$q%',
        '%$q%',
        '%$q%',
        '%$q%',
      ]);
    }

    final whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final limitClause = limit != null ? 'LIMIT $limit OFFSET $offset' : '';

    final rows = await db.rawQuery('''
      SELECT m.* FROM marriages m
      $whereClause
      ORDER BY m.last_status_update DESC
      $limitClause
    ''', args);

    return rows.map(MarriageModel.fromSqliteMap).toList();
  }

  // ── GET PENDING SYNC ──────────────────────────────────────────────────────
  Future<List<MarriageModel>> getPendingSync() async {
    final db = await _db;
    final rows = await db.query(
      'marriages',
      where: "sync_status IN ('pending_upload', 'pending_update', 'pending_delete')",
    );
    return rows.map(MarriageModel.fromSqliteMap).toList();
  }

  // ── GET STALE RECORDS (for notifications) ─────────────────────────────────
  Future<List<MarriageModel>> getStaleRecords({int daysThreshold = 3}) async {
    final db = await _db;
    final threshold = DateTime.now()
        .subtract(Duration(days: daysThreshold))
        .millisecondsSinceEpoch;
    final rows = await db.query(
      'marriages',
      where: "processing_status IN ('missing_files', 'in_progress') AND last_status_update < ?",
      whereArgs: [threshold],
    );
    return rows.map(MarriageModel.fromSqliteMap).toList();
  }

  // ── STREAM (reactive) ─────────────────────────────────────────────────────
  // Implemented in the repository via polling/change events
  Future<int> count({ProcessingStatus? status}) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM marriages${status != null ? " WHERE processing_status = '${status.value}'" : ""}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
