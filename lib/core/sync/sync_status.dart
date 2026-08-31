// ─────────────────────────────────────────────────────────────────────────────
// sync_status.dart — Sync State Enum
// ─────────────────────────────────────────────────────────────────────────────

enum SyncStatus {
  synced('synced'),
  pendingUpload('pending_upload'),
  pendingUpdate('pending_update'),
  pendingDelete('pending_delete');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromValue(String v) =>
      SyncStatus.values.firstWhere((e) => e.value == v,
          orElse: () => SyncStatus.pendingUpload);
}

enum SyncState { synced, syncing, offline, error }

enum ProcessingStatus {
  missingFiles('missing_files', 'نواقص'),
  inProgress('in_progress', 'قيد الإنجاز'),
  ready('ready', 'جاهز'),
  completed('completed', 'مكتمل');

  const ProcessingStatus(this.value, this.label);
  final String value;
  final String label;

  static ProcessingStatus fromValue(String v) =>
      ProcessingStatus.values.firstWhere((e) => e.value == v,
          orElse: () => ProcessingStatus.inProgress);
}

enum AgencyStatus {
  draft('draft', 'مسودة'),
  pendingSignatures('pending_signatures', 'بانتظار التوقيع'),
  inProgress('in_progress', 'قيد الإنجاز'),
  ready('ready', 'جاهز'),
  completed('completed', 'مكتمل');

  const AgencyStatus(this.value, this.label);
  final String value;
  final String label;

  static AgencyStatus fromValue(String v) =>
      AgencyStatus.values.firstWhere((e) => e.value == v,
          orElse: () => AgencyStatus.draft);
}
