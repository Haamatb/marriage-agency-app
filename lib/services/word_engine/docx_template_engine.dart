import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../../features/agencies/data/models/agency_model.dart';
import '../../features/marriages/data/models/marriage_model.dart';
import '../folder_service/archive_folder_service.dart';

class DocxTemplateEngine {
  DocxTemplateEngine._();
  static final DocxTemplateEngine instance = DocxTemplateEngine._();

  // ── XML Entity Escaping ───────────────────────────────────────────────────
  String _escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ── Core Template Processing ──────────────────────────────────────────────
  Future<Uint8List> _processTemplate(
    String assetPath,
    Map<String, String> placeholders,
  ) async {
    // Load template from assets
    final ByteData data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    // Decode .docx zip
    final archive = ZipDecoder().decodeBytes(bytes);

    // Build new archive with replaced XML
    final outputArchive = Archive();

    for (final file in archive) {
      if (file.isFile) {
        if (file.name.endsWith('.xml')) {
          // Properly decode UTF-8 bytes to Dart Unicode string
          String xmlContent = utf8.decode(file.content as List<int>);

          // Clean up any internal XML tags that Word might have inserted inside {{...}}
          xmlContent = xmlContent.replaceAllMapped(
            RegExp(r'(\{\{[^}]*?<[^>]+>[^}]*?\}\})'),
            (m) => m.group(0)!.replaceAll(RegExp(r'<[^>]+>'), ''),
          );

          // Replace placeholders in XML
          for (final entry in placeholders.entries) {
            final key = entry.key;
            final val = _escape(entry.value);
            xmlContent = xmlContent.replaceAll('{{$key}}', val);
          }

          // Properly encode back to UTF-8 bytes
          final newBytes = Uint8List.fromList(utf8.encode(xmlContent));
          outputArchive.addFile(ArchiveFile(
            file.name,
            newBytes.length,
            newBytes,
          ));
        } else {
          outputArchive.addFile(file);
        }
      }
    }

    return Uint8List.fromList(ZipEncoder().encode(outputArchive)!);
  }

  // ── Save & Launch ─────────────────────────────────────────────────────────
  Future<void> _saveAndLaunch(Uint8List docxBytes, String filePath) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(docxBytes);

    // Launch with default program (Word)
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', filePath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    }
  }

  // ── Marriage Contract ─────────────────────────────────────────────────────
  Future<void> generateMarriageContract(MarriageModel marriage) async {
    final folder = await ArchiveFolderService.instance.getMarriageFolder(
      marriage.recordNumber,
      marriage.husband.name,
    );

    final placeholders = {
      'RECORD_NUMBER': marriage.recordNumber,
      'HIJRI_DATE': marriage.hijriDate,
      'GREGORIAN_DATE': marriage.gregorianDate != null
          ? '${marriage.gregorianDate!.year}/${marriage.gregorianDate!.month.toString().padLeft(2, '0')}/${marriage.gregorianDate!.day.toString().padLeft(2, '0')}'
          : '',
      // Husband
      'HUSBAND_NAME': marriage.husband.name,
      'HUSBAND_ID_TYPE': marriage.husband.idType,
      'HUSBAND_ID_NUMBER': marriage.husband.idNumber,
      'HUSBAND_ID_ISSUE_PLACE': marriage.husband.idIssuePlace,
      'HUSBAND_ID_ISSUE_DATE': marriage.husband.idIssueDate,
      'HUSBAND_BIRTH_PLACE': marriage.husband.birthPlace,
      'HUSBAND_BIRTH_DATE': marriage.husband.birthDate,
      'HUSBAND_RESIDENCE': marriage.husband.residence,
      'HUSBAND_NATIONALITY': marriage.husband.nationality,
      'HUSBAND_PREV_MARITAL': marriage.husband.previousMaritalStatus,
      'HUSBAND_EDUCATION': marriage.husband.educationLevel,
      'HUSBAND_PROFESSION': marriage.husband.profession,
      'HUSBAND_MOTHER_NAME': marriage.husband.motherName,
      // Wife
      'WIFE_NAME': marriage.wife.name,
      'WIFE_ID_TYPE': marriage.wife.idType,
      'WIFE_ID_NUMBER': marriage.wife.idNumber,
      'WIFE_ID_ISSUE_PLACE': marriage.wife.idIssuePlace,
      'WIFE_ID_ISSUE_DATE': marriage.wife.idIssueDate,
      'WIFE_BIRTH_PLACE': marriage.wife.birthPlace,
      'WIFE_BIRTH_DATE': marriage.wife.birthDate,
      'WIFE_RESIDENCE': marriage.wife.residence,
      'WIFE_NATIONALITY': marriage.wife.nationality,
      'WIFE_PREV_MARITAL': marriage.wife.previousMaritalStatus,
      'WIFE_EDUCATION': marriage.wife.educationLevel,
      'WIFE_PROFESSION': marriage.wife.profession,
      'WIFE_MOTHER_NAME': marriage.wife.motherName,
      // Guardian
      'GUARDIAN_NAME': marriage.guardian.name,
      'GUARDIAN_RELATIONSHIP': marriage.guardian.relationship,
      'GUARDIAN_ID_TYPE': marriage.guardian.idType,
      'GUARDIAN_ID_NUMBER': marriage.guardian.idNumber,
      'GUARDIAN_ID_ISSUE_PLACE': marriage.guardian.idIssuePlace,
      'GUARDIAN_ID_ISSUE_DATE': marriage.guardian.idIssueDate,
      // Mahr
      'MAHR_AMOUNT': marriage.mahr.amount,
      'MAHR_DETAILS': marriage.mahr.details,
      // Witnesses
      'WITNESS1_NAME': marriage.witnesses.isNotEmpty ? marriage.witnesses[0].name : '',
      'WITNESS1_ID_TYPE': marriage.witnesses.isNotEmpty ? marriage.witnesses[0].idType : '',
      'WITNESS1_ID': marriage.witnesses.isNotEmpty ? marriage.witnesses[0].idNumber : '',
      'WITNESS1_ID_NUMBER': marriage.witnesses.isNotEmpty ? marriage.witnesses[0].idNumber : '',
      'WITNESS1_ISSUE_DATE': marriage.witnesses.isNotEmpty ? marriage.witnesses[0].idIssueDate : '',
      'WITNESS1_ISSUE_PLACE': marriage.witnesses.isNotEmpty ? marriage.witnesses[0].idIssuePlace : '',
      'WITNESS2_NAME': marriage.witnesses.length > 1 ? marriage.witnesses[1].name : '',
      'WITNESS2_ID_TYPE': marriage.witnesses.length > 1 ? marriage.witnesses[1].idType : '',
      'WITNESS2_ID': marriage.witnesses.length > 1 ? marriage.witnesses[1].idNumber : '',
      'WITNESS2_ID_NUMBER': marriage.witnesses.length > 1 ? marriage.witnesses[1].idNumber : '',
      'WITNESS2_ISSUE_DATE': marriage.witnesses.length > 1 ? marriage.witnesses[1].idIssueDate : '',
      'WITNESS2_ISSUE_PLACE': marriage.witnesses.length > 1 ? marriage.witnesses[1].idIssuePlace : '',
    };

    final docxBytes = await _processTemplate(
      'assets/templates/marriage_contract_template.docx',
      placeholders,
    );

    final outputPath = p.join(
      folder,
      'عقد_زواج_${marriage.recordNumber}.docx',
    );

    await _saveAndLaunch(docxBytes, outputPath);
  }

  // ── Marriage Statement (إفادة زواج) ─────────────────────────────────────
  Future<void> generateMarriageStatement(MarriageModel marriage) async {
    final folder = await ArchiveFolderService.instance.getMarriageFolder(
      marriage.recordNumber,
      marriage.husband.name,
    );

    final gregorianStr = marriage.gregorianDate != null
        ? '${marriage.gregorianDate!.year}/${marriage.gregorianDate!.month.toString().padLeft(2, '0')}/${marriage.gregorianDate!.day.toString().padLeft(2, '0')}'
        : '';

    final placeholders = {
      'RECORD_NUMBER': marriage.recordNumber,
      'HIJRI_DATE': marriage.hijriDate,
      'GREGORIAN_DATE': gregorianStr,
      'HUSBAND_NAME': marriage.husband.name,
      'HUSBAND_ID_NUMBER': marriage.husband.idNumber,
      'WIFE_NAME': marriage.wife.name,
      'WIFE_ID_NUMBER': marriage.wife.idNumber,
      'GUARDIAN_NAME': marriage.guardian.name,
      'MAHR_AMOUNT': marriage.mahr.amount,
    };

    final docxBytes = await _processTemplate(
      'assets/templates/marriage_statement_template.docx',
      placeholders,
    );

    final outputPath = p.join(
      folder,
      'إفادة_زواج_${marriage.recordNumber}.docx',
    );

    await _saveAndLaunch(docxBytes, outputPath);
  }

  // ── Agency Document ───────────────────────────────────────────────────────
  Future<void> generateAgencyDocument(AgencyModel agency) async {
    final folder = await ArchiveFolderService.instance.getAgencyFolder(
      agency.agencyNumber,
      agency.title,
    );

    final gregorianStr = agency.gregorianDate != null
        ? '${agency.gregorianDate!.year}/${agency.gregorianDate!.month.toString().padLeft(2, '0')}/${agency.gregorianDate!.day.toString().padLeft(2, '0')}'
        : '';

    final placeholders = {
      'AGENCY_NUMBER': agency.agencyNumber,
      'AGENCY_TYPE': agency.agencyType,
      'AGENCY_TITLE': agency.title,
      'DAY_NAME': agency.dayName,
      'HIJRI_DATE': agency.hijriDate,
      'GREGORIAN_DATE': gregorianStr,
      // Principal
      'PRINCIPAL_NAME': agency.principal.name,
      'PRINCIPAL_ID_TYPE': agency.principal.idType,
      'PRINCIPAL_ID_NUMBER': agency.principal.idNumber,
      'PRINCIPAL_ID_ISSUE': agency.principal.idIssuePlaceAndDate,
      'PRINCIPAL_PHONE': agency.principal.phone,
      // Agent
      'AGENT_NAME': agency.agent.name,
      'AGENT_ID_TYPE': agency.agent.idType,
      'AGENT_ID_NUMBER': agency.agent.idNumber,
      'AGENT_ID_ISSUE': agency.agent.idIssuePlaceAndDate,
      'AGENT_PHONE': agency.agent.phone,
      // Witnesses
      'WITNESS1_NAME': agency.witnesses.isNotEmpty ? agency.witnesses[0].name : '',
      'WITNESS1_ID_TYPE': agency.witnesses.isNotEmpty ? agency.witnesses[0].idType : '',
      'WITNESS1_ID': agency.witnesses.isNotEmpty ? agency.witnesses[0].idNumber : '',
      'WITNESS1_ISSUE_DATE': agency.witnesses.isNotEmpty ? agency.witnesses[0].idIssueDate : '',
      'WITNESS1_ISSUE_PLACE': agency.witnesses.isNotEmpty ? agency.witnesses[0].idIssuePlace : '',
      'WITNESS2_NAME': agency.witnesses.length > 1 ? agency.witnesses[1].name : '',
      'WITNESS2_ID_TYPE': agency.witnesses.length > 1 ? agency.witnesses[1].idType : '',
      'WITNESS2_ID': agency.witnesses.length > 1 ? agency.witnesses[1].idNumber : '',
      'WITNESS2_ISSUE_DATE': agency.witnesses.length > 1 ? agency.witnesses[1].idIssueDate : '',
      'WITNESS2_ISSUE_PLACE': agency.witnesses.length > 1 ? agency.witnesses[1].idIssuePlace : '',
    };

    final docxBytes = await _processTemplate(
      'assets/templates/agency_template.docx',
      placeholders,
    );

    final outputPath = p.join(
      folder,
      'وكالة_${agency.agencyNumber}.docx',
    );

    await _saveAndLaunch(docxBytes, outputPath);
  }
}
