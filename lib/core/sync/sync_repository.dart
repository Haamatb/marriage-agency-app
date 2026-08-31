// ─────────────────────────────────────────────────────────────────────────────
// sync_repository.dart — Bidirectional Firestore ↔ SQLite Sync Engine
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/agencies/data/dao/agency_dao.dart';
import '../../../features/agencies/data/models/agency_model.dart';
import '../../../features/marriages/data/dao/marriage_dao.dart';
import '../../../features/marriages/data/models/marriage_model.dart';
import 'sync_status.dart';

// ── Sync State Provider ───────────────────────────────────────────────────────

final syncStateProvider =
    StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  return SyncStateNotifier(ref.watch(syncRepositoryProvider));
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

class SyncStateNotifier extends StateNotifier<SyncState> {
  SyncStateNotifier(this._repo) : super(SyncState.offline) {
    _repo.syncStateStream.listen((s) => state = s);
    _repo.init();
  }

  final SyncRepository _repo;

  Future<void> forcePush() => _repo.pushPendingChanges();
}

// ── Sync Repository ───────────────────────────────────────────────────────────

class SyncRepository {
  SyncRepository()
      : _firestore = FirebaseFirestore.instance,
        _marriageDao = MarriageDao.instance,
        _agencyDao = AgencyDao.instance;

  final FirebaseFirestore _firestore;
  final MarriageDao _marriageDao;
  final AgencyDao _agencyDao;

  final _syncStateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<QuerySnapshot>? _marriagesSub;
  StreamSubscription<QuerySnapshot>? _agenciesSub;
  Timer? _heartbeatTimer;

  bool _isOnline = false;
  bool _isSyncing = false;

  // ── Initialization ────────────────────────────────────────────────────────
  Future<void> init() async {
    // Check initial connectivity
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = _isConnected(results);
    } catch (_) {
      _isOnline = false;
    }
    _emitState();

    // Listen for connectivity changes
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final connected = _isConnected(results);
      if (connected) {
        _isOnline = true;
        _emitState();
        await pushPendingChanges();
        _startFirestoreListeners();
      } else {
        _isOnline = false;
        _emitState();
        _stopFirestoreListeners();
      }
    });

    // Periodic Heartbeat Sync (every 10 seconds, retries pending changes if online)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await pushPendingChanges();
    });

    // Initial sync push
    await pushPendingChanges();
    if (_isOnline) {
      _startFirestoreListeners();
    }
  }

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  // ── Push Pending Local Changes → Firestore ────────────────────────────────
  Future<void> pushPendingChanges() async {
    if (_isSyncing) return;

    // Check if there are any pending items
    final pendingMarriages = await _marriageDao.getPendingSync();
    final pendingAgencies = await _agencyDao.getPendingSync();

    if (pendingMarriages.isEmpty && pendingAgencies.isEmpty) {
      if (_isOnline) {
        _syncStateController.add(SyncState.synced);
      }
      return;
    }

    _isSyncing = true;
    _syncStateController.add(SyncState.syncing);

    try {
      if (pendingMarriages.isNotEmpty) {
        await _pushMarriages(pendingMarriages).timeout(const Duration(seconds: 5));
      }
      if (pendingAgencies.isNotEmpty) {
        await _pushAgencies(pendingAgencies).timeout(const Duration(seconds: 5));
      }
      _isOnline = true;
      _syncStateController.add(SyncState.synced);
      _startFirestoreListeners();
    } catch (e) {
      // Offline or network timeout
      _isOnline = false;
      _syncStateController.add(SyncState.offline);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushMarriages(List<MarriageModel> pending) async {
    final batch = _firestore.batch();

    for (final marriage in pending) {
      final ref = _firestore.collection('marriages').doc(marriage.id);

      if (marriage.syncStatus == SyncStatus.pendingDelete) {
        batch.delete(ref);
      } else {
        batch.set(ref, marriage.toFirestore(), SetOptions(merge: true));
      }
    }

    await batch.commit();

    // Mark all as synced locally
    for (final marriage in pending) {
      if (marriage.syncStatus == SyncStatus.pendingDelete) {
        await _marriageDao.delete(marriage.id);
      } else {
        await _marriageDao.updateSyncStatus(marriage.id, SyncStatus.synced);
      }
    }
  }

  Future<void> _pushAgencies(List<AgencyModel> pending) async {
    final batch = _firestore.batch();

    for (final agency in pending) {
      final ref = _firestore.collection('agencies').doc(agency.id);

      if (agency.syncStatus == SyncStatus.pendingDelete) {
        batch.delete(ref);
      } else {
        batch.set(ref, agency.toFirestore(), SetOptions(merge: true));
      }
    }

    await batch.commit();

    // Mark all as synced locally
    for (final agency in pending) {
      if (agency.syncStatus == SyncStatus.pendingDelete) {
        await _agencyDao.delete(agency.id);
      } else {
        await _agencyDao.updateSyncStatus(agency.id, SyncStatus.synced);
      }
    }
  }

  // ── Pull Firestore Changes → Local DB ─────────────────────────────────────
  void _startFirestoreListeners() {
    _marriagesSub ??= _firestore
        .collection('marriages')
        .snapshots()
        .listen(_onMarriagesSnapshot, onError: (_) {});

    _agenciesSub ??= _firestore
        .collection('agencies')
        .snapshots()
        .listen(_onAgenciesSnapshot, onError: (_) {});
  }

  void _stopFirestoreListeners() {
    _marriagesSub?.cancel();
    _marriagesSub = null;
    _agenciesSub?.cancel();
    _agenciesSub = null;
  }

  Future<void> _onMarriagesSnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      try {
        final docId = change.doc.id;
        final local = await _marriageDao.getById(docId);

        // Protect local pending edits from remote overwrites
        if (local != null &&
            (local.syncStatus == SyncStatus.pendingUpload ||
             local.syncStatus == SyncStatus.pendingUpdate ||
             local.syncStatus == SyncStatus.pendingDelete)) {
          continue;
        }

        if (change.type == DocumentChangeType.removed) {
          await _marriageDao.delete(docId);
        } else {
          final marriage = MarriageModel.fromFirestore(change.doc);
          await _marriageDao.upsert(marriage.copyWith(syncStatus: SyncStatus.synced));
        }
      } catch (_) {}
    }
  }

  Future<void> _onAgenciesSnapshot(QuerySnapshot snapshot) async {
    for (final change in snapshot.docChanges) {
      try {
        final docId = change.doc.id;
        final local = await _agencyDao.getById(docId);

        // Protect local pending edits from remote overwrites
        if (local != null &&
            (local.syncStatus == SyncStatus.pendingUpload ||
             local.syncStatus == SyncStatus.pendingUpdate ||
             local.syncStatus == SyncStatus.pendingDelete)) {
          continue;
        }

        if (change.type == DocumentChangeType.removed) {
          await _agencyDao.delete(docId);
        } else {
          final agency = AgencyModel.fromFirestore(change.doc);
          await _agencyDao.upsert(agency.copyWith(syncStatus: SyncStatus.synced));
        }
      } catch (_) {}
    }
  }

  // ── Public Mutation Helpers ───────────────────────────────────────────────
  Future<void> onMarriageCreated(MarriageModel marriage) async {
    await pushPendingChanges();
  }

  Future<void> onMarriageUpdated(MarriageModel marriage) async {
    await pushPendingChanges();
  }

  Future<void> onMarriageDeleted(String id) async {
    await pushPendingChanges();
  }

  Future<void> onAgencyCreated(AgencyModel agency) async {
    await pushPendingChanges();
  }

  Future<void> onAgencyUpdated(AgencyModel agency) async {
    await pushPendingChanges();
  }

  Future<void> onAgencyDeleted(String id) async {
    await pushPendingChanges();
  }

  void _emitState() {
    if (!_isOnline) {
      _syncStateController.add(SyncState.offline);
    } else if (_isSyncing) {
      _syncStateController.add(SyncState.syncing);
    } else {
      _syncStateController.add(SyncState.synced);
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _connectivitySub?.cancel();
    _stopFirestoreListeners();
    _syncStateController.close();
  }
}
