// ─────────────────────────────────────────────────────────────────────────────
// excel_service.dart — Import/Export Excel for marriages & agencies
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/sync/sync_status.dart';
import '../../features/agencies/data/models/agency_model.dart';
import '../../features/agencies/data/repositories/agency_repository.dart';
import '../../features/marriages/data/models/marriage_model.dart';
import '../../features/marriages/data/repositories/marriage_repository.dart';

class ExcelService {
  ExcelService._();
  static final ExcelService instance = ExcelService._();

  final _uuid = const Uuid();

  // ── Column Headers — Arabic ───────────────────────────────────────────────
  static const _marriageHeaders = [
    'رقم العقد', 'التاريخ الهجري', 'التاريخ الميلادي',
    'اسم الزوج', 'هوية الزوج', 'رقم هوية الزوج', 'جنسية الزوج', 'مهنة الزوج',
    'اسم الزوجة', 'هوية الزوجة', 'رقم هوية الزوجة', 'جنسية الزوجة',
    'اسم الولي', 'صلة القرابة', 'رقم هوية الولي',
    'مقدار المهر', 'تفاصيل المهر',
    'اسم الشاهد الأول', 'رقم هوية الشاهد الأول',
    'اسم الشاهد الثاني', 'رقم هوية الشاهد الثاني',
    'حالة الملف', 'تسليم الزوج', 'تسليم الزوجة',
  ];

  static const _agencyHeaders = [
    'رقم الوكالة', 'نوع الوكالة', 'موضوع الوكالة',
    'اليوم', 'التاريخ الهجري', 'التاريخ الميلادي',
    'اسم الموكل', 'هوية الموكل', 'رقم هوية الموكل', 'جوال الموكل',
    'اسم الوكيل', 'هوية الوكيل', 'رقم هوية الوكيل', 'جوال الوكيل',
    'اسم الشاهد الأول', 'رقم هوية الشاهد الأول',
    'اسم الشاهد الثاني', 'رقم هوية الشاهد الثاني',
    'الحالة',
  ];

  // ── Export Marriages ───────────────────────────────────────────────────────
  Future<String?> exportMarriages(
    Map<ProcessingStatus, int> counts, {
    List<MarriageModel>? records,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['الزواجات'];

    // Style header row
    for (int col = 0; col < _marriageHeaders.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(_marriageHeaders[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B6B45'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Data rows
    final data = records ?? [];
    for (int row = 0; row < data.length; row++) {
      final m = data[row];
      final rowData = [
        m.recordNumber,
        m.hijriDate,
        m.gregorianDate?.toString().split(' ')[0] ?? '',
        m.husband.name, m.husband.idType, m.husband.idNumber,
        m.husband.nationality, m.husband.profession,
        m.wife.name, m.wife.idType, m.wife.idNumber, m.wife.nationality,
        m.guardian.name, m.guardian.relationship, m.guardian.idNumber,
        m.mahr.amount, m.mahr.details,
        m.witnesses.isNotEmpty ? m.witnesses[0].name : '',
        m.witnesses.isNotEmpty ? m.witnesses[0].idNumber : '',
        m.witnesses.length > 1 ? m.witnesses[1].name : '',
        m.witnesses.length > 1 ? m.witnesses[1].idNumber : '',
        m.processingStatus.label,
        m.husbandDelivery.isDelivered ? 'نعم' : 'لا',
        m.wifeDelivery.isDelivered ? 'نعم' : 'لا',
      ];

      for (int col = 0; col < rowData.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
            .value = TextCellValue(rowData[col]);
      }
    }

    return _saveExcel(excel, 'marriages_export');
  }

  // ── Export Agencies ───────────────────────────────────────────────────────
  Future<String?> exportAgencies(List<AgencyModel> agencies) async {
    final excel = Excel.createExcel();
    final sheet = excel['الوكالات'];

    for (int col = 0; col < _agencyHeaders.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(_agencyHeaders[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1B6B45'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    for (int row = 0; row < agencies.length; row++) {
      final a = agencies[row];
      final rowData = [
        a.agencyNumber, a.agencyType, a.title,
        a.dayName, a.hijriDate,
        a.gregorianDate?.toString().split(' ')[0] ?? '',
        a.principal.name, a.principal.idType, a.principal.idNumber, a.principal.phone,
        a.agent.name, a.agent.idType, a.agent.idNumber, a.agent.phone,
        a.witnesses.isNotEmpty ? a.witnesses[0].name : '',
        a.witnesses.isNotEmpty ? a.witnesses[0].idNumber : '',
        a.witnesses.length > 1 ? a.witnesses[1].name : '',
        a.witnesses.length > 1 ? a.witnesses[1].idNumber : '',
        a.status.label,
      ];

      for (int col = 0; col < rowData.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1))
            .value = TextCellValue(rowData[col]);
      }
    }

    return _saveExcel(excel, 'agencies_export');
  }

  // ── Import Marriages from File Picker ─────────────────────────────────────
  Future<int> importMarriagesFromPicker(
      BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.single.path == null) return 0;

    return importMarriagesFromFile(result.files.single.path!, ref);
  }

  Future<int> importMarriagesFromFile(String filePath, WidgetRef ref) async {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final repo = ref.read(marriageRepositoryProvider);

    int imported = 0;

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      // Skip header row (row 0)
      for (int row = 1; row < sheet.maxRows; row++) {
        try {
          final cells = sheet.row(row);
          String cellVal(int col) =>
              cells.length > col ? (cells[col]?.value?.toString() ?? '') : '';

          final marriage = MarriageModel(
            id: _uuid.v4(),
            recordNumber: cellVal(0),
            hijriDate: cellVal(1),
            gregorianDate: _parseDate(cellVal(2)),
            husband: PersonInfo(
              name: cellVal(3),
              idType: cellVal(4),
              idNumber: cellVal(5),
              nationality: cellVal(6),
              profession: cellVal(7),
            ),
            wife: PersonInfo(
              name: cellVal(8),
              idType: cellVal(9),
              idNumber: cellVal(10),
              nationality: cellVal(11),
            ),
            guardian: GuardianInfo(
              name: cellVal(12),
              relationship: cellVal(13),
              idNumber: cellVal(14),
            ),
            mahr: MahrInfo(amount: cellVal(15), details: cellVal(16)),
            witnesses: [
              if (cellVal(17).isNotEmpty)
                WitnessInfo(name: cellVal(17), idNumber: cellVal(18)),
              if (cellVal(19).isNotEmpty)
                WitnessInfo(name: cellVal(19), idNumber: cellVal(20)),
            ],
            processingStatus: _parseProcessingStatus(cellVal(21)),
            syncStatus: SyncStatus.pendingUpload,
            lastStatusUpdate: DateTime.now(),
            createdAt: DateTime.now(),
          );

          if (marriage.recordNumber.isNotEmpty) {
            await repo.create(marriage);
            imported++;
          }
        } catch (e) {
          // Skip malformed rows
          debugPrint('Import row $row error: $e');
        }
      }
    }

    return imported;
  }

  // ── Import Agencies ───────────────────────────────────────────────────────
  Future<int> importAgenciesFromPicker(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.single.path == null) return 0;

    final bytes = File(result.files.single.path!).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final repo = ref.read(agencyRepositoryProvider);

    int imported = 0;

    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      for (int row = 1; row < sheet.maxRows; row++) {
        try {
          final cells = sheet.row(row);
          String cellVal(int col) =>
              cells.length > col ? (cells[col]?.value?.toString() ?? '') : '';

          final agency = AgencyModel(
            id: _uuid.v4(),
            agencyNumber: cellVal(0),
            agencyType: cellVal(1),
            title: cellVal(2),
            dayName: cellVal(3),
            hijriDate: cellVal(4),
            gregorianDate: _parseDate(cellVal(5)),
            principal: PartyInfo(
              name: cellVal(6),
              idType: cellVal(7),
              idNumber: cellVal(8),
              phone: cellVal(9),
            ),
            agent: PartyInfo(
              name: cellVal(10),
              idType: cellVal(11),
              idNumber: cellVal(12),
              phone: cellVal(13),
            ),
            witnesses: [
              if (cellVal(14).isNotEmpty)
                AgencyWitnessInfo(name: cellVal(14), idNumber: cellVal(15)),
              if (cellVal(16).isNotEmpty)
                AgencyWitnessInfo(name: cellVal(16), idNumber: cellVal(17)),
            ],
            status: _parseAgencyStatus(cellVal(18)),
            syncStatus: SyncStatus.pendingUpload,
            lastStatusUpdate: DateTime.now(),
            createdAt: DateTime.now(),
          );

          if (agency.agencyNumber.isNotEmpty) {
            await repo.create(agency);
            imported++;
          }
        } catch (e) {
          debugPrint('Import row $row error: $e');
        }
      }
    }

    return imported;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<String?> _saveExcel(Excel excel, String prefix) async {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(dir.path, '${prefix}_$timestamp.xlsx');
    final fileBytes = excel.save();
    if (fileBytes == null) return null;
    await File(path).writeAsBytes(fileBytes);
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    }
    return path;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    try {
      return DateTime.parse(value.replaceAll('/', '-'));
    } catch (_) {
      return null;
    }
  }

  ProcessingStatus _parseProcessingStatus(String value) {
    return ProcessingStatus.values.firstWhere(
      (s) => s.label == value || s.value == value,
      orElse: () => ProcessingStatus.inProgress,
    );
  }

  AgencyStatus _parseAgencyStatus(String value) {
    return AgencyStatus.values.firstWhere(
      (s) => s.label == value || s.value == value,
      orElse: () => AgencyStatus.draft,
    );
  }
}
