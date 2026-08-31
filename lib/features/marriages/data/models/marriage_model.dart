// ─────────────────────────────────────────────────────────────────────────────
// marriage_model.dart — Strongly-typed Marriage model with full serialization
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/sync/sync_status.dart';

// ── Sub-models ───────────────────────────────────────────────────────────────

class PersonInfo {
  final String name;
  final String idType;
  final String idNumber;
  final String idIssuePlace;
  final String idIssueDate;
  final String birthPlace;
  final String birthDate;
  final String residence;
  final String nationality;
  final String previousMaritalStatus;
  final String educationLevel;
  final String profession;
  final String motherName;

  const PersonInfo({
    this.name = '',
    this.idType = '',
    this.idNumber = '',
    this.idIssuePlace = '',
    this.idIssueDate = '',
    this.birthPlace = '',
    this.birthDate = '',
    this.residence = '',
    this.nationality = '',
    this.previousMaritalStatus = '',
    this.educationLevel = '',
    this.profession = '',
    this.motherName = '',
  });

  PersonInfo copyWith({
    String? name, String? idType, String? idNumber, String? idIssuePlace,
    String? idIssueDate, String? birthPlace, String? birthDate, String? residence,
    String? nationality, String? previousMaritalStatus, String? educationLevel,
    String? profession, String? motherName,
  }) => PersonInfo(
    name: name ?? this.name,
    idType: idType ?? this.idType,
    idNumber: idNumber ?? this.idNumber,
    idIssuePlace: idIssuePlace ?? this.idIssuePlace,
    idIssueDate: idIssueDate ?? this.idIssueDate,
    birthPlace: birthPlace ?? this.birthPlace,
    birthDate: birthDate ?? this.birthDate,
    residence: residence ?? this.residence,
    nationality: nationality ?? this.nationality,
    previousMaritalStatus: previousMaritalStatus ?? this.previousMaritalStatus,
    educationLevel: educationLevel ?? this.educationLevel,
    profession: profession ?? this.profession,
    motherName: motherName ?? this.motherName,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'idType': idType, 'idNumber': idNumber,
    'idIssuePlace': idIssuePlace, 'idIssueDate': idIssueDate,
    'birthPlace': birthPlace, 'birthDate': birthDate, 'residence': residence,
    'nationality': nationality, 'previousMaritalStatus': previousMaritalStatus,
    'educationLevel': educationLevel, 'profession': profession,
    'motherName': motherName,
  };

  factory PersonInfo.fromMap(Map<String, dynamic> m) => PersonInfo(
    name: m['name'] ?? '', idType: m['idType'] ?? '',
    idNumber: m['idNumber'] ?? '', idIssuePlace: m['idIssuePlace'] ?? '',
    idIssueDate: m['idIssueDate'] ?? '', birthPlace: m['birthPlace'] ?? '',
    birthDate: m['birthDate'] ?? '',
    residence: m['residence'] ?? '', nationality: m['nationality'] ?? '',
    previousMaritalStatus: m['previousMaritalStatus'] ?? '',
    educationLevel: m['educationLevel'] ?? '',
    profession: m['profession'] ?? '', motherName: m['motherName'] ?? '',
  );
}

class GuardianInfo {
  final String name;
  final String relationship;
  final String idType;
  final String idNumber;
  final String idIssuePlace;
  final String idIssueDate;

  const GuardianInfo({
    this.name = '', this.relationship = '', this.idType = '',
    this.idNumber = '', this.idIssuePlace = '', this.idIssueDate = '',
  });

  GuardianInfo copyWith({
    String? name, String? relationship, String? idType,
    String? idNumber, String? idIssuePlace, String? idIssueDate,
  }) => GuardianInfo(
    name: name ?? this.name, relationship: relationship ?? this.relationship,
    idType: idType ?? this.idType, idNumber: idNumber ?? this.idNumber,
    idIssuePlace: idIssuePlace ?? this.idIssuePlace,
    idIssueDate: idIssueDate ?? this.idIssueDate,
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'relationship': relationship, 'idType': idType,
    'idNumber': idNumber, 'idIssuePlace': idIssuePlace, 'idIssueDate': idIssueDate,
  };

  factory GuardianInfo.fromMap(Map<String, dynamic> m) => GuardianInfo(
    name: m['name'] ?? '', relationship: m['relationship'] ?? '',
    idType: m['idType'] ?? '', idNumber: m['idNumber'] ?? '',
    idIssuePlace: m['idIssuePlace'] ?? '', idIssueDate: m['idIssueDate'] ?? '',
  );
}

class MahrInfo {
  final String amount;
  final String details;

  const MahrInfo({this.amount = '', this.details = ''});

  MahrInfo copyWith({String? amount, String? details}) =>
      MahrInfo(amount: amount ?? this.amount, details: details ?? this.details);

  Map<String, dynamic> toMap() => {'amount': amount, 'details': details};

  factory MahrInfo.fromMap(Map<String, dynamic> m) =>
      MahrInfo(amount: m['amount'] ?? '', details: m['details'] ?? '');
}

class WitnessInfo {
  final String name;
  final String idType;
  final String idNumber;
  final String idIssueDate;
  final String idIssuePlace;
  final String phone;

  const WitnessInfo({
    this.name = '',
    this.idType = '',
    this.idNumber = '',
    this.idIssueDate = '',
    this.idIssuePlace = '',
    this.phone = '',
  });

  WitnessInfo copyWith({
    String? name,
    String? idType,
    String? idNumber,
    String? idIssueDate,
    String? idIssuePlace,
    String? phone,
  }) =>
      WitnessInfo(
        name: name ?? this.name,
        idType: idType ?? this.idType,
        idNumber: idNumber ?? this.idNumber,
        idIssueDate: idIssueDate ?? this.idIssueDate,
        idIssuePlace: idIssuePlace ?? this.idIssuePlace,
        phone: phone ?? this.phone,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'idType': idType,
        'idNumber': idNumber,
        'idIssueDate': idIssueDate,
        'idIssuePlace': idIssuePlace,
        'phone': phone,
      };

  factory WitnessInfo.fromMap(Map<String, dynamic> m) => WitnessInfo(
        name: m['name'] ?? '',
        idType: m['idType'] ?? '',
        idNumber: m['idNumber'] ?? '',
        idIssueDate: m['idIssueDate'] ?? '',
        idIssuePlace: m['idIssuePlace'] ?? '',
        phone: m['phone'] ?? '',
      );
}

class DeliveryInfo {
  final bool isDelivered;
  final DateTime? deliveredAt;
  final String? receiverName;

  const DeliveryInfo({
    this.isDelivered = false,
    this.deliveredAt,
    this.receiverName,
  });

  DeliveryInfo copyWith({bool? isDelivered, DateTime? deliveredAt, String? receiverName}) =>
      DeliveryInfo(
        isDelivered: isDelivered ?? this.isDelivered,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        receiverName: receiverName ?? this.receiverName,
      );

  Map<String, dynamic> toMap() => {
    'isDelivered': isDelivered,
    'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
    'receiverName': receiverName,
  };

  factory DeliveryInfo.fromMap(Map<String, dynamic> m) => DeliveryInfo(
    isDelivered: m['isDelivered'] ?? false,
    deliveredAt: m['deliveredAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['deliveredAt'])
        : null,
    receiverName: m['receiverName'],
  );

  Map<String, dynamic> toFirestore() => {
    'isDelivered': isDelivered,
    'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
    'receiverName': receiverName,
  };

  factory DeliveryInfo.fromFirestore(Map<String, dynamic> m) => DeliveryInfo(
    isDelivered: m['isDelivered'] ?? false,
    deliveredAt: (m['deliveredAt'] as Timestamp?)?.toDate(),
    receiverName: m['receiverName'],
  );
}

// ── Main Marriage Model ───────────────────────────────────────────────────────

class MarriageModel {
  final String id;
  final String recordNumber;
  final String hijriDate;
  final DateTime? gregorianDate;

  final PersonInfo husband;
  final PersonInfo wife;
  final GuardianInfo guardian;
  final MahrInfo mahr;
  final List<WitnessInfo> witnesses;

  final ProcessingStatus processingStatus;
  final List<String> pendingFiles;

  final DeliveryInfo husbandDelivery;
  final DeliveryInfo wifeDelivery;

  final Map<String, dynamic> extraFields;
  final SyncStatus syncStatus;
  final DateTime? syncedAt;
  final DateTime lastStatusUpdate;
  final DateTime createdAt;
  final DateTime? firestoreUpdatedAt;

  const MarriageModel({
    required this.id,
    required this.recordNumber,
    this.hijriDate = '',
    this.gregorianDate,
    this.husband = const PersonInfo(),
    this.wife = const PersonInfo(),
    this.guardian = const GuardianInfo(),
    this.mahr = const MahrInfo(),
    this.witnesses = const [],
    this.processingStatus = ProcessingStatus.missingFiles,
    this.pendingFiles = const [],
    this.husbandDelivery = const DeliveryInfo(),
    this.wifeDelivery = const DeliveryInfo(),
    this.extraFields = const {},
    this.syncStatus = SyncStatus.pendingUpload,
    this.syncedAt,
    required this.lastStatusUpdate,
    required this.createdAt,
    this.firestoreUpdatedAt,
  });

  // Auto-complete detection
  bool get isFullyDelivered =>
      husbandDelivery.isDelivered && wifeDelivery.isDelivered;

  MarriageModel copyWith({
    String? id, String? recordNumber, String? hijriDate,
    DateTime? gregorianDate, PersonInfo? husband, PersonInfo? wife,
    GuardianInfo? guardian, MahrInfo? mahr, List<WitnessInfo>? witnesses,
    ProcessingStatus? processingStatus, List<String>? pendingFiles,
    DeliveryInfo? husbandDelivery, DeliveryInfo? wifeDelivery,
    Map<String, dynamic>? extraFields, SyncStatus? syncStatus,
    DateTime? syncedAt, DateTime? lastStatusUpdate, DateTime? createdAt,
    DateTime? firestoreUpdatedAt,
  }) => MarriageModel(
    id: id ?? this.id,
    recordNumber: recordNumber ?? this.recordNumber,
    hijriDate: hijriDate ?? this.hijriDate,
    gregorianDate: gregorianDate ?? this.gregorianDate,
    husband: husband ?? this.husband,
    wife: wife ?? this.wife,
    guardian: guardian ?? this.guardian,
    mahr: mahr ?? this.mahr,
    witnesses: witnesses ?? this.witnesses,
    processingStatus: processingStatus ?? this.processingStatus,
    pendingFiles: pendingFiles ?? this.pendingFiles,
    husbandDelivery: husbandDelivery ?? this.husbandDelivery,
    wifeDelivery: wifeDelivery ?? this.wifeDelivery,
    extraFields: extraFields ?? this.extraFields,
    syncStatus: syncStatus ?? this.syncStatus,
    syncedAt: syncedAt ?? this.syncedAt,
    lastStatusUpdate: lastStatusUpdate ?? this.lastStatusUpdate,
    createdAt: createdAt ?? this.createdAt,
    firestoreUpdatedAt: firestoreUpdatedAt ?? this.firestoreUpdatedAt,
  );

  // ── SQLite Serialization ─────────────────────────────────────────────────
  Map<String, dynamic> toSqliteMap() => {
    'id': id,
    'record_number': recordNumber,
    'hijri_date': hijriDate,
    'gregorian_date': gregorianDate?.millisecondsSinceEpoch,
    'husband_name': husband.name,
    'husband_id_type': husband.idType,
    'husband_id_number': husband.idNumber,
    'husband_id_issue_place': husband.idIssuePlace,
    'husband_id_issue_date': husband.idIssueDate,
    'husband_birth_place': husband.birthPlace,
    'husband_birth_date': husband.birthDate,
    'husband_residence': husband.residence,
    'husband_nationality': husband.nationality,
    'husband_prev_marital': husband.previousMaritalStatus,
    'husband_education': husband.educationLevel,
    'husband_profession': husband.profession,
    'husband_mother_name': husband.motherName,
    'wife_name': wife.name,
    'wife_id_type': wife.idType,
    'wife_id_number': wife.idNumber,
    'wife_id_issue_place': wife.idIssuePlace,
    'wife_id_issue_date': wife.idIssueDate,
    'wife_birth_place': wife.birthPlace,
    'wife_birth_date': wife.birthDate,
    'wife_residence': wife.residence,
    'wife_nationality': wife.nationality,
    'wife_prev_marital': wife.previousMaritalStatus,
    'wife_education': wife.educationLevel,
    'wife_profession': wife.profession,
    'wife_mother_name': wife.motherName,
    'guardian_name': guardian.name,
    'guardian_relationship': guardian.relationship,
    'guardian_id_type': guardian.idType,
    'guardian_id_number': guardian.idNumber,
    'guardian_id_issue_place': guardian.idIssuePlace,
    'guardian_id_issue_date': guardian.idIssueDate,
    'mahr_amount': mahr.amount,
    'mahr_details': mahr.details,
    'witnesses_json': jsonEncode(witnesses.map((w) => w.toMap()).toList()),
    'processing_status': processingStatus.value,
    'pending_files_json': jsonEncode(pendingFiles),
    'husband_delivery_json': jsonEncode(husbandDelivery.toMap()),
    'wife_delivery_json': jsonEncode(wifeDelivery.toMap()),
    'extra_fields_json': jsonEncode(extraFields),
    'sync_status': syncStatus.value,
    'synced_at': syncedAt?.millisecondsSinceEpoch,
    'last_status_update': lastStatusUpdate.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
    'firestore_updated_at': firestoreUpdatedAt?.millisecondsSinceEpoch,
  };

  factory MarriageModel.fromSqliteMap(Map<String, dynamic> m) {
    List<dynamic> witnessesRaw = [];
    try { witnessesRaw = jsonDecode(m['witnesses_json'] ?? '[]'); } catch (_) {}
    List<dynamic> pendingFilesRaw = [];
    try { pendingFilesRaw = jsonDecode(m['pending_files_json'] ?? '[]'); } catch (_) {}
    Map<String, dynamic> husbandDeliveryRaw = {};
    try { husbandDeliveryRaw = Map<String, dynamic>.from(jsonDecode(m['husband_delivery_json'] ?? '{}')); } catch (_) {}
    Map<String, dynamic> wifeDeliveryRaw = {};
    try { wifeDeliveryRaw = Map<String, dynamic>.from(jsonDecode(m['wife_delivery_json'] ?? '{}')); } catch (_) {}
    Map<String, dynamic> extraFieldsRaw = {};
    try { extraFieldsRaw = Map<String, dynamic>.from(jsonDecode(m['extra_fields_json'] ?? '{}')); } catch (_) {}

    return MarriageModel(
      id: m['id'],
      recordNumber: m['record_number'] ?? '',
      hijriDate: m['hijri_date'] ?? '',
      gregorianDate: m['gregorian_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['gregorian_date'])
          : null,
      husband: PersonInfo(
        name: m['husband_name'] ?? '', idType: m['husband_id_type'] ?? '',
        idNumber: m['husband_id_number'] ?? '',
        idIssuePlace: m['husband_id_issue_place'] ?? '',
        idIssueDate: m['husband_id_issue_date'] ?? '',
        birthPlace: m['husband_birth_place'] ?? '',
        birthDate: m['husband_birth_date'] ?? '',
        residence: m['husband_residence'] ?? '',
        nationality: m['husband_nationality'] ?? '',
        previousMaritalStatus: m['husband_prev_marital'] ?? '',
        educationLevel: m['husband_education'] ?? '',
        profession: m['husband_profession'] ?? '',
        motherName: m['husband_mother_name'] ?? '',
      ),
      wife: PersonInfo(
        name: m['wife_name'] ?? '', idType: m['wife_id_type'] ?? '',
        idNumber: m['wife_id_number'] ?? '',
        idIssuePlace: m['wife_id_issue_place'] ?? '',
        idIssueDate: m['wife_id_issue_date'] ?? '',
        birthPlace: m['wife_birth_place'] ?? '',
        birthDate: m['wife_birth_date'] ?? '',
        residence: m['wife_residence'] ?? '',
        nationality: m['wife_nationality'] ?? '',
        previousMaritalStatus: m['wife_prev_marital'] ?? '',
        educationLevel: m['wife_education'] ?? '',
        profession: m['wife_profession'] ?? '',
        motherName: m['wife_mother_name'] ?? '',
      ),
      guardian: GuardianInfo(
        name: m['guardian_name'] ?? '',
        relationship: m['guardian_relationship'] ?? '',
        idType: m['guardian_id_type'] ?? '',
        idNumber: m['guardian_id_number'] ?? '',
        idIssuePlace: m['guardian_id_issue_place'] ?? '',
        idIssueDate: m['guardian_id_issue_date'] ?? '',
      ),
      mahr: MahrInfo(amount: m['mahr_amount'] ?? '', details: m['mahr_details'] ?? ''),
      witnesses: witnessesRaw
          .map((w) => WitnessInfo.fromMap(Map<String, dynamic>.from(w)))
          .toList(),
      processingStatus: ProcessingStatus.fromValue(m['processing_status'] ?? 'missing_files'),
      pendingFiles: pendingFilesRaw.map((e) => e.toString()).toList(),
      husbandDelivery: DeliveryInfo.fromMap(husbandDeliveryRaw),
      wifeDelivery: DeliveryInfo.fromMap(wifeDeliveryRaw),
      extraFields: extraFieldsRaw,
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

  // ── Firestore Serialization ──────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'recordNumber': recordNumber,
    'hijriDate': hijriDate,
    'gregorianDate': gregorianDate != null ? Timestamp.fromDate(gregorianDate!) : null,
    'husband': husband.toMap(),
    'wife': wife.toMap(),
    'guardian': guardian.toMap(),
    'mahr': mahr.toMap(),
    'witnesses': witnesses.map((w) => w.toMap()).toList(),
    'processingStatus': processingStatus.value,
    'pendingFiles': pendingFiles,
    'husbandDelivery': husbandDelivery.toFirestore(),
    'wifeDelivery': wifeDelivery.toFirestore(),
    'extraFields': extraFields,
    'syncStatus': 'synced',
    'lastStatusUpdate': Timestamp.fromDate(lastStatusUpdate),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory MarriageModel.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MarriageModel(
      id: doc.id,
      recordNumber: m['recordNumber'] ?? '',
      hijriDate: m['hijriDate'] ?? '',
      gregorianDate: (m['gregorianDate'] as Timestamp?)?.toDate(),
      husband: PersonInfo.fromMap(Map<String, dynamic>.from(m['husband'] ?? {})),
      wife: PersonInfo.fromMap(Map<String, dynamic>.from(m['wife'] ?? {})),
      guardian: GuardianInfo.fromMap(Map<String, dynamic>.from(m['guardian'] ?? {})),
      mahr: MahrInfo.fromMap(Map<String, dynamic>.from(m['mahr'] ?? {})),
      witnesses: ((m['witnesses'] as List?) ?? [])
          .map((w) => WitnessInfo.fromMap(Map<String, dynamic>.from(w)))
          .toList(),
      processingStatus: ProcessingStatus.fromValue(m['processingStatus'] ?? 'missing_files'),
      pendingFiles: List<String>.from(m['pendingFiles'] ?? []),
      husbandDelivery: DeliveryInfo.fromFirestore(Map<String, dynamic>.from(m['husbandDelivery'] ?? {})),
      wifeDelivery: DeliveryInfo.fromFirestore(Map<String, dynamic>.from(m['wifeDelivery'] ?? {})),
      extraFields: Map<String, dynamic>.from(m['extraFields'] ?? {}),
      syncStatus: SyncStatus.synced,
      syncedAt: DateTime.now(),
      lastStatusUpdate: (m['lastStatusUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      firestoreUpdatedAt: (m['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
