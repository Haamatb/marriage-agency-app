// ─────────────────────────────────────────────────────────────────────────────
// archive_folder_service.dart — Desktop archive folder management
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ArchiveFolderService {
  ArchiveFolderService._();
  static final ArchiveFolderService instance = ArchiveFolderService._();

  String _basePath = Platform.isWindows ? r'D:\Archive_Marriage_Office' : '';

  void setBasePath(String path) => _basePath = path;

  Future<String> getBasePath() async {
    if (_basePath.isNotEmpty) return _basePath;
    final docs = await getApplicationDocumentsDirectory();
    _basePath = p.join(docs.path, 'Archive_Marriage_Office');
    return _basePath;
  }

  String get basePath => _basePath;

  // ── Marriage Folder ───────────────────────────────────────────────────────
  Future<String> getMarriageFolder(String recordNumber, String husbandName) async {
    final base = await getBasePath();
    final safeName = _sanitize('${recordNumber}_$husbandName');
    final path = p.join(base, 'Marriages', safeName);
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<void> openMarriageFolder(String recordNumber, String husbandName) async {
    final path = await getMarriageFolder(recordNumber, husbandName);
    await _openInExplorer(path);
  }

  // ── Agency Folder ─────────────────────────────────────────────────────────
  Future<String> getAgencyFolder(String agencyNumber, String title) async {
    final base = await getBasePath();
    final safeName = _sanitize('${agencyNumber}_$title');
    final path = p.join(base, 'Agencies', safeName);
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<void> openAgencyFolder(String agencyNumber, String title) async {
    final path = await getAgencyFolder(agencyNumber, title);
    await _openInExplorer(path);
  }

  // ── Platform File Explorer Launch ─────────────────────────────────────────
  Future<void> _openInExplorer(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  // ── Safe filename sanitization ─────────────────────────────────────────────
  String _sanitize(String input) {
    // Remove or replace characters not valid in Windows paths
    return input
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, input.length > 80 ? 80 : input.length);
  }

  // ── Settings persistence (simple file-based) ─────────────────────────────
  Future<void> loadSavedBasePath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final settingsFile = File(p.join(dir.path, 'marriage_app_settings.txt'));
      if (await settingsFile.exists()) {
        final saved = await settingsFile.readAsString();
        if (saved.trim().isNotEmpty) _basePath = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> saveBasePath(String newPath) async {
    try {
      _basePath = newPath;
      final dir = await getApplicationDocumentsDirectory();
      final settingsFile = File(p.join(dir.path, 'marriage_app_settings.txt'));
      await settingsFile.writeAsString(newPath);
    } catch (_) {}
  }
}
