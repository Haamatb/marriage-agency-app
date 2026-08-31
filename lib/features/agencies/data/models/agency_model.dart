// ─────────────────────────────────────────────────────────────────────────────
// agency_model.dart — Strongly-typed Agency model
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../marriages/data/models/marriage_model.dart' show DeliveryInfo;

class AgencyWitnessInfo {
  final String name;
  final String idType;
  final String idNumber;
  final String idIssueDate;
  final String idIssuePlace;

  const AgencyWitnessInfo({
    this.name = '',
    this.idType = '',
    this.idNumber = '',
    this.idIssueDate = '',
    this.idIssuePlace = '',
  });

  AgencyWitnessInfo copyWith({
    String? name,
    String? idType,
    String? idNumber,
    String? idIssueDate,
    String? idIssuePlace,
  }) =>
      AgencyWitnessInfo(
        name: name ?? this.name,
        idType: idType ?? this.idType,
        idNumber: idNumber ?? this.idNumber,
        idIssueDate: idIssueDate ?? this.idIssueDate,
        idIssuePlace: idIssuePlace ?? this.idIssuePlace,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'idType': idType,
        'idNumber': idNumber,
        'idIssueDate': idIssueDate,
        'idIssuePlace': idIssuePlace,
      };

  factory AgencyWitnessInfo.fromMap(Map<String, dynamic> m) => AgencyWitnessInfo(
        name: m['name'] ?? '',
        idType: m['idType'] ?? '',
        idNumber: m['idNumber'] ?? '',
        idIssueDate: m['idIssueDate'] ?? '',
        idIssuePlace: m['idIssuePlace'] ?? '',
      );
}

class PartyInfo {
  final String name;
  final String idType;
  final String idNumber;
  final String idIssuePlaceAndDate;
  final String phone;

  const PartyInfo({
    this.name = '', this.idType = '', this.idNumber = '',
    this.idIssuePlaceAndDate = '', this.phone = '',
  });

  PartyInfo copyWith({
    String? name, String? idType, String? idNumber,
    String? idIssuePlaceAndDate, String? phone,
  }) => PartyInfo(
    name: name ?? this.name, idType: idType ?? this.idType,
    idNumber: idNumber ?? this.idNumber,
    idIssuePlaceAndDate: idIssuePlaceAndDate ?? this.idIssuePlaceAndDate,
    phone: phone ?? this.phone,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'idType': idType, 'idNumber': idNumber,
    'idIssuePlaceAndDate': idIssuePlaceAndDate, 'phone': phone,
  };

  factory PartyInfo.fromMap(Map<String, dynamic> m) => PartyInfo(
    name: m['name'] ?? '', idType: m['idType'] ?? '',
    idNumber: m['idNumber'] ?? '',
    idIssuePlaceAndDate: m['idIssuePlaceAndDate'] ?? '',
    phone: m['phone'] ?? '',
  );
}

// ── Main Agency Model ─────────────────────────────────────────────────────────

class AgencyModel {
  final String id;
  final String agencyNumber;
  final String agencyType;
  final String title;
  final String dayName;
  final String hijriDate;
  final DateTime? gregorianDate;

  final PartyInfo principal;
  final PartyInfo agent;
  final List<AgencyWitnessInfo> witnesses;

  final AgencyStatus status;
  final DeliveryInfo deliveryInfo;

  final Map<String, dynamic> extraFields;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;
  final DateTime lastStatusUpdate;
  final DateTime createdAt;
  final DateTime? firestoreUpdatedAt;

  const AgencyModel({
    required this.id,
    required this.agencyNumber,
    this.agencyType = '',
    this.title = '',
    this.dayName = '',
    this.hijriDate = '',
    this.gregorianDate,
    this.principal = const PartyInfo(),
    this.agent = const PartyInfo(),
    this.witnesses = const [],
    this.status = AgencyStatus.draft,
    this.deliveryInfo = const DeliveryInfo(),
    this.extraFields = const {},
    this.syncStatus = SyncStatus.pendingUpload,
    this.syncedAt,
    required this.lastStatusUpdate,
    required this.createdAt,
    this.firestoreUpdatedAt,
  });

  AgencyModel copyWith({
    String? id, String? agencyNumber, String? agencyType, String? title,
    String? dayName, String? hijriDate, DateTime? gregorianDate,
    PartyInfo? principal, PartyInfo? agent, List<AgencyWitnessInfo>? witnesses,
    AgencyStatus? status, DeliveryInfo? deliveryInfo,
    Map<String, dynamic>? extraFields, SyncStatus? syncStatus,
    DateTime? syncedAt, DateTime? lastStatusUpdate, DateTime? createdAt,
    DateTime? firestoreUpdatedAt,
  }) => AgencyModel(
    id: id ?? this.id,
    agencyNumber: agencyNumber ?? this.agencyNumber,
    agencyType: agencyType ?? this.agencyType,
    title: title ?? this.title,
    dayName: dayName ?? this.dayName,
    hijriDate: hijriDate ?? this.hijriDate,
    gregorianDate: gregorianDate ?? this.gregorianDate,
    principal: principal ?? this.principal,
    agent: agent ?? this.agent,
    witnesses: witnesses ?? this.witnesses,
    status: status ?? this.status,
    deliveryInfo: deliveryInfo ?? this.deliveryInfo,
    extraFields: extraFields ?? this.extraFields,
    syncStatus: syncStatus ?? this.syncStatus,
    syncedAt: syncedAt ?? this.syncedAt,
    lastStatusUpdate: lastStatusUpdate ?? this.lastStatusUpdate,
    createdAt: createdAt ?? this.createdAt,
    firestoreUpdatedAt: firestoreUpdatedAt ?? this.firestoreUpdatedAt,
  );

  // ── SQLite ───────────────────────────────────────────────────────────────
  Map<String, dynamic> toSqliteMap() => {
    'id': id, 'agency_number': agencyNumber, 'agency_type': agencyType,
    'title': title, 'day_name': dayName, 'hijri_date': hijriDate,
    'gregorian_date': gregorianDate?.millisecondsSinceEpoch,
    'principal_name': principal.name, 'principal_id_type': principal.idType,
    'principal_id_number': principal.idNumber,
    'principal_id_issue': principal.idIssuePlaceAndDate,
    'principal_phone': principal.phone,
    'agent_name': agent.name, 'agent_id_type': agent.idType,
    'agent_id_number': agent.idNumber,
    'agent_id_issue': agent.idIssuePlaceAndDate,
    'agent_phone': agent.phone,
    'witnesses_json': jsonEncode(witnesses.map((w) => w.toMap()).toList()),
    'status': status.value,
    'delivery_info_json': jsonEncode(deliveryInfo.toMap()),
    'extra_fields_json': jsonEncode(extraFields),
    'sync_status': syncStatus.value,
    'synced_at': syncedAt?.millisecondsSinceEpoch,
    'last_status_update': lastStatusUpdate.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
    'firestore_updated_at': firestoreUpdatedAt?.millisecondsSinceEpoch,
  };

  factory AgencyModel.fromSqliteMap(Map<String, dynamic> m) {
    List<dynamic> witnessesRaw = [];
    try { witnessesRaw = jsonDecode(m['witnesses_json'] ?? '[]'); } catch (_) {}
    Map<String, dynamic> deliveryRaw = {};
    try { deliveryRaw = Map<String, dynamic>.from(jsonDecode(m['delivery_info_json'] ?? '{}')); } catch (_) {}
    Map<String, dynamic> extraRaw = {};
    try { extraRaw = Map<String, dynamic>.from(jsonDecode(m['extra_fields_json'] ?? '{}')); } catch (_) {}

    return AgencyModel(
      id: m['id'],
      agencyNumber: m['agency_number'] ?? '',
      agencyType: m['agency_type'] ?? '',
      title: m['title'] ?? '',
      dayName: m['day_name'] ?? '',
      hijriDate: m['hijri_date'] ?? '',
      gregorianDate: m['gregorian_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['gregorian_date']) : null,
      principal: PartyInfo(
        name: m['principal_name'] ?? '', idType: m['principal_id_type'] ?? '',
        idNumber: m['principal_id_number'] ?? '',
        idIssuePlaceAndDate: m['principal_id_issue'] ?? '',
        phone: m['principal_phone'] ?? '',
      ),
      agent: PartyInfo(
        name: m['agent_name'] ?? '', idType: m['agent_id_type'] ?? '',
        idNumber: m['agent_id_number'] ?? '',
        idIssuePlaceAndDate: m['agent_id_issue'] ?? '',
        phone: m['agent_phone'] ?? '',
      ),
      witnesses: witnessesRaw
          .map((w) => AgencyWitnessInfo.fromMap(Map<String, dynamic>.from(w)))
          .toList(),
      status: AgencyStatus.fromValue(m['status'] ?? 'draft'),
      deliveryInfo: DeliveryInfo.fromMap(deliveryRaw),
      extraFields: extraRaw,
      syncStatus: SyncStatus.fromValue(m['sync_status'] ?? 'pending_upload'),
      syncedAt: m['synced_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['synced_at']) : null,
      lastStatusUpdate: m['last_status_update'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['last_status_update'])
          : DateTime.now(),
      createdAt: m['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['created_at'])
          : DateTime.now(),
      firestoreUpdatedAt: m['firestore_updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['firestore_updated_at']) : null,
    );
  }

  // ── Firestore ────────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'id': id, 'agencyNumber': agencyNumber, 'agencyType': agencyType,
    'title': title, 'dayName': dayName, 'hijriDate': hijriDate,
    'gregorianDate': gregorianDate != null ? Timestamp.fromDate(gregorianDate!) : null,
    'principal': principal.toMap(),
    'agent': agent.toMap(),
    'witnesses': witnesses.map((w) => w.toMap()).toList(),
    'status': status.value,
    'deliveryInfo': deliveryInfo.toFirestore(),
    'extraFields': extraFields,
    'syncStatus': 'synced',
    'lastStatusUpdate': Timestamp.fromDate(lastStatusUpdate),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory AgencyModel.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return AgencyModel(
      id: doc.id,
      agencyNumber: m['agencyNumber'] ?? '',
      agencyType: m['agencyType'] ?? '',
      title: m['title'] ?? '',
      dayName: m['dayName'] ?? '',
      hijriDate: m['hijriDate'] ?? '',
      gregorianDate: (m['gregorianDate'] as Timestamp?)?.toDate(),
      principal: PartyInfo.fromMap(Map<String, dynamic>.from(m['principal'] ?? {})),
      agent: PartyInfo.fromMap(Map<String, dynamic>.from(m['agent'] ?? {})),
      witnesses: ((m['witnesses'] as List?) ?? [])
          .map((w) => AgencyWitnessInfo.fromMap(Map<String, dynamic>.from(w)))
          .toList(),
      status: AgencyStatus.fromValue(m['status'] ?? 'draft'),
      deliveryInfo: DeliveryInfo.fromFirestore(Map<String, dynamic>.from(m['deliveryInfo'] ?? {})),
      extraFields: Map<String, dynamic>.from(m['extraFields'] ?? {}),
      syncStatus: SyncStatus.synced,
      syncedAt: DateTime.now(),
      lastStatusUpdate: (m['lastStatusUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      firestoreUpdatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
