// ─────────────────────────────────────────────────────────────────────────────
// agency_repository.dart — Business-Logic Repository for Agencies
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_repository.dart';
import '../../../../core/sync/sync_status.dart';
import '../dao/agency_dao.dart';
import '../models/agency_model.dart';
import '../../../marriages/data/models/marriage_model.dart' show DeliveryInfo;

// ── Providers ─────────────────────────────────────────────────────────────────

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return AgencyRepository(ref.watch(syncRepositoryProvider));
});

class AgencyFilter {
  final AgencyStatus? status;
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;

  const AgencyFilter({this.status, this.searchQuery, this.fromDate, this.toDate});

  @override
  bool operator ==(Object other) =>
      other is AgencyFilter &&
      other.status == status &&
      other.searchQuery == searchQuery &&
      other.fromDate == fromDate &&
      other.toDate == toDate;

  @override
  int get hashCode => Object.hash(status, searchQuery, fromDate, toDate);
}

final agenciesStreamProvider =
    StreamProvider.family<List<AgencyModel>, AgencyFilter>((ref, filter) {
  return ref.watch(agencyRepositoryProvider).watchAll(filter: filter);
});

// ── Repository ────────────────────────────────────────────────────────────────

class AgencyRepository {
  AgencyRepository(this._syncRepo);

  final SyncRepository _syncRepo;
  final _dao = AgencyDao.instance;
  final _uuid = const Uuid();

  Stream<List<AgencyModel>> watchAll({AgencyFilter? filter}) async* {
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

  Future<AgencyModel> create(AgencyModel draft) async {
    final now = DateTime.now();
    final agency = draft.copyWith(
      id: draft.id.isEmpty ? _uuid.v4() : draft.id,
      syncStatus: SyncStatus.pendingUpload,
      lastStatusUpdate: now,
      createdAt: now,
    );
    await _dao.insert(agency);
    unawaited(_syncRepo.onAgencyCreated(agency).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    ).catchError((_) {}));
    return agency;
  }

  Future<AgencyModel> update(AgencyModel agency) async {
    final now = DateTime.now();
    AgencyStatus newStatus = agency.status;
    DeliveryInfo newDelivery = agency.deliveryInfo;

    // Rule 1: If delivery is marked true, status becomes completed
    if (newDelivery.isDelivered) {
      newStatus = AgencyStatus.completed;
    }
    // Rule 2: If status is set to completed, delivery becomes true
    else if (newStatus == AgencyStatus.completed) {
      newDelivery = newDelivery.copyWith(
        isDelivered: true,
        deliveredAt: newDelivery.deliveredAt ?? now,
      );
    }
    // Rule 3: If status was completed, but delivery was untoggled, revert status
    else if (newStatus == AgencyStatus.completed && !newDelivery.isDelivered) {
      newStatus = AgencyStatus.ready;
    }

    final updated = agency.copyWith(
      status: newStatus,
      deliveryInfo: newDelivery,
      syncStatus: SyncStatus.pendingUpdate,
      lastStatusUpdate: now,
    );
    await _dao.update(updated);
    unawaited(_syncRepo.onAgencyUpdated(updated).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    ).catchError((_) {}));
    return updated;
  }

  Future<void> delete(String id) async {
    await _dao.markAsDeleted(id);
    unawaited(_syncRepo.onAgencyDeleted(id).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    ).catchError((_) {}));
  }

  Future<void> updateDelivery(String id, DeliveryInfo delivery) async {
    final agency = await _dao.getById(id);
    if (agency == null) return;
    await update(agency.copyWith(deliveryInfo: delivery));
  }

  Future<void> updateStatus(String id, AgencyStatus status) async {
    final agency = await _dao.getById(id);
    if (agency == null) return;
    await update(agency.copyWith(status: status));
  }

  Future<AgencyModel?> getById(String id) => _dao.getById(id);

  Future<Map<AgencyStatus, int>> getStatusCounts() async {
    final counts = <AgencyStatus, int>{};
    for (final s in AgencyStatus.values) {
      counts[s] = await _dao.count(status: s);
    }
    return counts;
  }
}
