// ─────────────────────────────────────────────────────────────────────────────
// marriage_repository.dart — Business-Logic Repository for Marriages
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_repository.dart';
import '../../../../core/sync/sync_status.dart';
import '../dao/marriage_dao.dart';
import '../models/marriage_model.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final marriageRepositoryProvider = Provider<MarriageRepository>((ref) {
  return MarriageRepository(ref.watch(syncRepositoryProvider));
});

final marriagesStreamProvider = StreamProvider.family<List<MarriageModel>,
    MarriageFilter>((ref, filter) {
  return ref.watch(marriageRepositoryProvider).watchAll(filter: filter);
});

// ── Filter Model ──────────────────────────────────────────────────────────────

class MarriageFilter {
  final ProcessingStatus? status;
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;

  const MarriageFilter({
    this.status,
    this.searchQuery,
    this.fromDate,
    this.toDate,
  });

  @override
  bool operator ==(Object other) =>
      other is MarriageFilter &&
      other.status == status &&
      other.searchQuery == searchQuery &&
      other.fromDate == fromDate &&
      other.toDate == toDate;

  @override
  int get hashCode =>
      Object.hash(status, searchQuery, fromDate, toDate);
}

// ── Repository ────────────────────────────────────────────────────────────────

class MarriageRepository {
  MarriageRepository(this._syncRepo);

  final SyncRepository _syncRepo;
  final _dao = MarriageDao.instance;
  final _uuid = const Uuid();

  // ── Reactive stream via periodic polling ─────────────────────────────────
  // (SQLite doesn't natively stream — poll every 500ms for local-first feel)
  Stream<List<MarriageModel>> watchAll({MarriageFilter? filter}) async* {
    while (true) {
      yield await _dao.getAll(
        status: filter?.status,
        searchQuery: filter?.searchQuery,
        fromDate: filter?.fromDate,
        toDate: filter?.toDate,
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // ── CREATE ────────────────────────────────────────────────────────────────
  Future<MarriageModel> create(MarriageModel draft) async {
    final now = DateTime.now();
    final marriage = draft.copyWith(
      id: draft.id.isEmpty ? _uuid.v4() : draft.id,
      syncStatus: SyncStatus.pendingUpload,
      lastStatusUpdate: now,
      createdAt: now,
    );
    await _dao.insert(marriage);
    unawaited(_syncRepo.onMarriageCreated(marriage).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    ).catchError((_) {}));
    return marriage;
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────
  Future<MarriageModel> update(MarriageModel marriage) async {
    final now = DateTime.now();

    ProcessingStatus newStatus = marriage.processingStatus;
    DeliveryInfo newHusbandDelivery = marriage.husbandDelivery;
    DeliveryInfo newWifeDelivery = marriage.wifeDelivery;

    // Rule 1: If both copies are delivered, status automatically becomes completed
    if (newHusbandDelivery.isDelivered && newWifeDelivery.isDelivered) {
      newStatus = ProcessingStatus.completed;
    }
    // Rule 2: If status is set to completed, both copies automatically become delivered
    else if (newStatus == ProcessingStatus.completed) {
      if (!newHusbandDelivery.isDelivered) {
        newHusbandDelivery = newHusbandDelivery.copyWith(
          isDelivered: true,
          deliveredAt: newHusbandDelivery.deliveredAt ?? now,
        );
      }
      if (!newWifeDelivery.isDelivered) {
        newWifeDelivery = newWifeDelivery.copyWith(
          isDelivered: true,
          deliveredAt: newWifeDelivery.deliveredAt ?? now,
        );
      }
    }
    // Rule 3: If status was completed, but at least one copy was undelivered, revert status
    else if (newStatus == ProcessingStatus.completed &&
        (!newHusbandDelivery.isDelivered || !newWifeDelivery.isDelivered)) {
      newStatus = marriage.pendingFiles.isNotEmpty
          ? ProcessingStatus.missingFiles
          : ProcessingStatus.inProgress;
    }

    final finalModel = marriage.copyWith(
      processingStatus: newStatus,
      husbandDelivery: newHusbandDelivery,
      wifeDelivery: newWifeDelivery,
      syncStatus: SyncStatus.pendingUpdate,
      lastStatusUpdate: now,
    );

    await _dao.update(finalModel);
    unawaited(_syncRepo.onMarriageUpdated(finalModel).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    ).catchError((_) {}));
    return finalModel;
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _dao.markAsDeleted(id);
    unawaited(_syncRepo.onMarriageDeleted(id).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    ).catchError((_) {}));
  }

  // ── UPDATE DELIVERY ───────────────────────────────────────────────────────
  Future<void> updateHusbandDelivery(
      String id, DeliveryInfo delivery) async {
    final marriage = await _dao.getById(id);
    if (marriage == null) return;
    await update(marriage.copyWith(husbandDelivery: delivery));
  }

  Future<void> updateWifeDelivery(
      String id, DeliveryInfo delivery) async {
    final marriage = await _dao.getById(id);
    if (marriage == null) return;
    await update(marriage.copyWith(wifeDelivery: delivery));
  }

  // ── UPDATE STATUS ─────────────────────────────────────────────────────────
  Future<void> updateStatus(String id, ProcessingStatus status) async {
    final marriage = await _dao.getById(id);
    if (marriage == null) return;
    await update(marriage.copyWith(processingStatus: status));
  }

  // ── GET SINGLE ────────────────────────────────────────────────────────────
  Future<MarriageModel?> getById(String id) => _dao.getById(id);

  // ── STATISTICS ────────────────────────────────────────────────────────────
  Future<Map<ProcessingStatus, int>> getStatusCounts() async {
    final counts = <ProcessingStatus, int>{};
    for (final status in ProcessingStatus.values) {
      counts[status] = await _dao.count(status: status);
    }
    return counts;
  }
}
