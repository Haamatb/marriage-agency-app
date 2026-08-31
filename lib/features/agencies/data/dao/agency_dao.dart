// ─────────────────────────────────────────────────────────────────────────────
// agency_dao.dart — SQLite Data Access Object for Agencies
// ─────────────────────────────────────────────────────────────────────────────
import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/sync/sync_status.dart';
import '../models/agency_model.dart';

class AgencyDao {
  AgencyDao._();
  static final AgencyDao instance = AgencyDao._();

  Future<Database> get _db => DatabaseHelper.instance.database;

  Future<void> insert(AgencyModel agency) async {
    final db = await _db;
    await db.insert('agencies', agency.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> update(AgencyModel agency) async {
    final db = await _db;
    await db.update('agencies', agency.toSqliteMap(),
        where: 'id = ?', whereArgs: [agency.id]);
  }

  Future<void> upsert(AgencyModel agency) async {
    final existing = await getById(agency.id);
    if (existing == null) {
      await insert(agency);
    } else {
      final remoteTs = agency.firestoreUpdatedAt ?? agency.lastStatusUpdate;
      final localTs = existing.lastStatusUpdate;
      if (remoteTs.isAfter(localTs)) {
        await update(agency);
      }
    }
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('agencies', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markAsDeleted(String id) async {
    final db = await _db;
    await db.update(
      'agencies',
      {
        'sync_status': SyncStatus.pendingDelete.value,
        'last_status_update': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSyncStatus(String id, SyncStatus status) async {
    final db = await _db;
    await db.update(
      'agencies',
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

  Future<AgencyModel?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('agencies', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AgencyModel.fromSqliteMap(rows.first);
  }

  Future<List<AgencyModel>> getAll({
    AgencyStatus? status,
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int offset = 0,
  }) async {
    final db = await _db;

    final List<String> conditions = ["a.sync_status != '${SyncStatus.pendingDelete.value}'"];
    final List<dynamic> args = [];

    if (status != null) {
      conditions.add('a.status = ?');
      args.add(status.value);
    }

    if (fromDate != null) {
      final startOfDay = DateTime(fromDate.year, fromDate.month, fromDate.day).millisecondsSinceEpoch;
      conditions.add('(a.gregorian_date >= ? OR (a.gregorian_date IS NULL AND a.created_at >= ?))');
      args.add(startOfDay);
      args.add(startOfDay);
    }

    if (toDate != null) {
      final endOfDay = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59, 999).millisecondsSinceEpoch;
      conditions.add('(a.gregorian_date <= ? OR (a.gregorian_date IS NULL AND a.created_at <= ?))');
      args.add(endOfDay);
      args.add(endOfDay);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      conditions.add('''(
        a.agency_number LIKE ?
        OR a.title LIKE ?
        OR a.hijri_date LIKE ?
        OR a.principal_name LIKE ?
        OR a.agent_name LIKE ?
        OR a.principal_id_number LIKE ?
        OR a.agent_id_number LIKE ?
      )''');
      args.addAll([
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
      SELECT a.* FROM agencies a
      $whereClause
      ORDER BY a.last_status_update DESC
      $limitClause
    ''', args);

    return rows.map(AgencyModel.fromSqliteMap).toList();
  }

  Future<List<AgencyModel>> getPendingSync() async {
    final db = await _db;
    final rows = await db.query(
      'agencies',
      where: "sync_status IN ('pending_upload', 'pending_update', 'pending_delete')",
    );
    return rows.map(AgencyModel.fromSqliteMap).toList();
  }

  Future<List<AgencyModel>> getStaleRecords({int daysThreshold = 3}) async {
    final db = await _db;
    final threshold = DateTime.now()
        .subtract(Duration(days: daysThreshold))
        .millisecondsSinceEpoch;
    final rows = await db.query(
      'agencies',
      where: "status IN ('draft', 'in_progress') AND last_status_update < ?",
      whereArgs: [threshold],
    );
    return rows.map(AgencyModel.fromSqliteMap).toList();
  }

  Future<int> count({AgencyStatus? status}) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM agencies${status != null ? " WHERE status = '${status.value}'" : ""}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
