import 'package:flutter_test/flutter_test.dart';
import 'package:marriage_agency_app/core/sync/sync_status.dart';
import 'package:marriage_agency_app/core/utils/arabic_date_helper.dart';
import 'package:marriage_agency_app/features/marriages/data/models/marriage_model.dart';
import 'package:marriage_agency_app/features/agencies/data/models/agency_model.dart';

void main() {
  group('MarriageModel Tests', () {
    test('Serialization and Deserialization to/from SQLite Map', () {
      final now = DateTime.now();
      final model = MarriageModel(
        id: 'test-uuid-1',
        recordNumber: '1001',
        hijriDate: '1446/02/15',
        gregorianDate: DateTime(2024, 8, 20),
        husband: const PersonInfo(
          name: 'أحمد محمد',
          idNumber: '1234567890',
          nationality: 'سعودي',
          birthDate: '15/05/1995',
        ),
        wife: const PersonInfo(
          name: 'فاطمة علي',
          idNumber: '0987654321',
          nationality: 'سعودية',
          birthDate: '20/10/1998',
        ),
        guardian: const GuardianInfo(
          name: 'علي حسن',
          relationship: 'أب',
        ),
        mahr: const MahrInfo(amount: '50000', details: 'مقبوض بالكامل'),
        witnesses: const [
          WitnessInfo(name: 'سالم سعد', idNumber: '1111111111'),
          WitnessInfo(name: 'عمر خالد', idNumber: '2222222222'),
        ],
        processingStatus: ProcessingStatus.completed,
        pendingFiles: const ['صورة الهوية'],
        syncStatus: SyncStatus.pendingUpload,
        lastStatusUpdate: now,
        createdAt: now,
      );

      final map = model.toSqliteMap();
      expect(map['id'], 'test-uuid-1');
      expect(map['record_number'], '1001');
      expect(map['husband_name'], 'أحمد محمد');
      expect(map['husband_birth_date'], '15/05/1995');
      expect(map['wife_name'], 'فاطمة علي');
      expect(map['wife_birth_date'], '20/10/1998');
      expect(map['processing_status'], 'completed');

      final fromMap = MarriageModel.fromSqliteMap(map);
      expect(fromMap.id, model.id);
      expect(fromMap.husband.name, model.husband.name);
      expect(fromMap.husband.birthDate, '15/05/1995');
      expect(fromMap.wife.name, model.wife.name);
      expect(fromMap.wife.birthDate, '20/10/1998');
      expect(fromMap.guardian.name, model.guardian.name);
      expect(fromMap.witnesses.length, 2);
      expect(fromMap.pendingFiles, contains('صورة الهوية'));
    });
  });

  group('AgencyModel Tests', () {
    test('Serialization and Deserialization to/from SQLite Map', () {
      final now = DateTime.now();
      final agency = AgencyModel(
        id: 'agency-uuid-1',
        agencyNumber: '2001',
        agencyType: 'عامة',
        title: 'توكيل عام لإدارة العقارات',
        dayName: 'الثلاثاء',
        hijriDate: '1446/02/15',
        gregorianDate: DateTime(2024, 8, 20),
        principal: const PartyInfo(
          name: 'سعد فهد',
          idNumber: '3333333333',
          phone: '0500000000',
        ),
        agent: const PartyInfo(
          name: 'خالد ناصر',
          idNumber: '4444444444',
          phone: '0555555555',
        ),
        witnesses: const [
          AgencyWitnessInfo(name: 'ماجد صالح', idNumber: '5555555555'),
        ],
        status: AgencyStatus.ready,
        syncStatus: SyncStatus.synced,
        lastStatusUpdate: now,
        createdAt: now,
      );

      final map = agency.toSqliteMap();
      expect(map['id'], 'agency-uuid-1');
      expect(map['agency_number'], '2001');
      expect(map['principal_name'], 'سعد فهد');
      expect(map['agent_name'], 'خالد ناصر');
      expect(map['status'], 'ready');

      final fromMap = AgencyModel.fromSqliteMap(map);
      expect(fromMap.id, agency.id);
      expect(fromMap.principal.name, agency.principal.name);
      expect(fromMap.agent.name, agency.agent.name);
      expect(fromMap.witnesses.length, 1);
    });
  });

  group('Bidirectional Delivery and Status Logic', () {
    test('Marriage isFullyDelivered detection', () {
      final now = DateTime.now();
      final pending = MarriageModel(
        id: '1',
        recordNumber: '1',
        lastStatusUpdate: now,
        createdAt: now,
        husbandDelivery: const DeliveryInfo(isDelivered: true),
        wifeDelivery: const DeliveryInfo(isDelivered: false),
      );
      expect(pending.isFullyDelivered, isFalse);

      final completed = MarriageModel(
        id: '2',
        recordNumber: '2',
        lastStatusUpdate: now,
        createdAt: now,
        husbandDelivery: const DeliveryInfo(isDelivered: true),
        wifeDelivery: const DeliveryInfo(isDelivered: true),
      );
      expect(completed.isFullyDelivered, isTrue);
    });

    test('Agency isDelivered detection', () {
      final now = DateTime.now();
      final agency = AgencyModel(
        id: 'a-2',
        agencyNumber: '201',
        title: 'وكالة بيع',
        deliveryInfo: const DeliveryInfo(isDelivered: true),
        lastStatusUpdate: now,
        createdAt: now,
      );
      expect(agency.deliveryInfo.isDelivered, true);
    });
  });

  group('ArabicDateHelper Tests', () {
    test('Gregorian date numbers and words', () {
      final date = DateTime(2026, 9, 1);
      final numeric = ArabicDateHelper.formatGregorianNumeric(date);
      final words = ArabicDateHelper.formatGregorianInWords(date);
      final full = ArabicDateHelper.formatGregorianFull(date);

      expect(numeric, '01/09/2026م');
      expect(words, contains('الأول'));
      expect(words, contains('سبتمبر'));
      expect(words, contains('ألفين وست'));
      expect(full, '01/09/2026م ($words)');
    });

    test('Hijri date numbers and words', () {
      final hijriStr = '1447/09/12';
      final numeric = ArabicDateHelper.formatHijriNumeric(hijriStr);
      final words = ArabicDateHelper.formatHijriInWords(hijriStr);
      final full = ArabicDateHelper.formatHijriFull(hijriStr);

      expect(numeric, '12/09/1447هـ');
      expect(words, contains('الثاني عشر'));
      expect(words, contains('رمضان'));
      expect(words, contains('ألف وأربعمائة وسبع وأربعين'));
      expect(full, '12/09/1447هـ ($words)');
    });

    test('Hijri date with DD/MM/YYYY format input', () {
      final hijriStr = '25/08/1446';
      final numeric = ArabicDateHelper.formatHijriNumeric(hijriStr);
      final words = ArabicDateHelper.formatHijriInWords(hijriStr);

      expect(numeric, '25/08/1446هـ');
      expect(words, contains('الخامس والعشرين'));
      expect(words, contains('شعبان'));
      expect(words, contains('ألف وأربعمائة وست وأربعين'));
    });
  });
}
