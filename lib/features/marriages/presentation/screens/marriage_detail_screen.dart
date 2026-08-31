// ─────────────────────────────────────────────────────────────────────────────
// marriage_detail_screen.dart — Full record view with delivery & desktop tools
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'dart:ui' as ui show TextDirection;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/marriage_model.dart';
import '../../data/repositories/marriage_repository.dart';
import '../widgets/delivery_card.dart';
import 'marriage_form_screen.dart';
import '../../../../services/word_engine/docx_template_engine.dart';
import '../../../../services/folder_service/archive_folder_service.dart';

class MarriageDetailScreen extends ConsumerStatefulWidget {
  const MarriageDetailScreen({super.key, required this.marriage});
  final MarriageModel marriage;

  @override
  ConsumerState<MarriageDetailScreen> createState() =>
      _MarriageDetailScreenState();
}

class _MarriageDetailScreenState extends ConsumerState<MarriageDetailScreen> {
  late MarriageModel _marriage;

  @override
  void initState() {
    super.initState();
    _marriage = widget.marriage;
  }

  Future<void> _updateHusbandDelivery(DeliveryInfo d) async {
    final updated = await ref
        .read(marriageRepositoryProvider)
        .update(_marriage.copyWith(husbandDelivery: d));
    setState(() => _marriage = updated);
  }

  Future<void> _updateWifeDelivery(DeliveryInfo d) async {
    final updated = await ref
        .read(marriageRepositoryProvider)
        .update(_marriage.copyWith(wifeDelivery: d));
    setState(() => _marriage = updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('عقد رقم ${_marriage.recordNumber}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarriageFormScreen(existing: _marriage),
                  ),
                );
                // Refresh data
                final fresh = await ref
                    .read(marriageRepositoryProvider)
                    .getById(_marriage.id);
                if (fresh != null && mounted) setState(() => _marriage = fresh);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDeliverySection(),
              const SizedBox(height: 16),
              _buildPersonSection('الزوج', _marriage.husband),

              _buildPersonSection('الزوجة', _marriage.wife),

              _buildGuardianSection(),

              _buildMahrSection(),

              _buildWitnessesSection(),             


              if (_marriage.pendingFiles.isNotEmpty) _buildPendingFilesSection(),
              if (isDesktop) ...[
                const SizedBox(height: 16),
                _buildDesktopActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_marriage.husband.name}  ⟷  ${_marriage.wife.name}',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<ProcessingStatus>(
                  initialValue: _marriage.processingStatus,
                  tooltip: 'تغيير حالة العقد',
                  onSelected: (status) async {
                    final updated = await ref
                        .read(marriageRepositoryProvider)
                        .update(_marriage.copyWith(processingStatus: status));
                    if (mounted) setState(() => _marriage = updated);
                  },
                  itemBuilder: (context) => ProcessingStatus.values
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                ProcessingStatusBadge(s),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProcessingStatusBadge(_marriage.processingStatus),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.numbers, label: 'رقم العقد',
                value: _marriage.recordNumber),
            if (_marriage.hijriDate.isNotEmpty)
              _InfoRow(icon: Icons.calendar_today_outlined,
                  label: 'التاريخ الهجري', value: _marriage.hijriDate),
            if (_marriage.gregorianDate != null)
              _InfoRow(
                icon: Icons.today_outlined,
                label: 'التاريخ الميلادي',
                value: DateFormat('yyyy/MM/dd').format(_marriage.gregorianDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailTwoCol(Widget first, Widget second) {
    final isMobile = Platform.isAndroid || Platform.isIOS || MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          first,
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildDeliverySection() {
    final isMobile = Platform.isAndroid || Platform.isIOS || MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('التسليم'),
        if (isMobile) ...[
          DeliveryCard(
            title: 'نسخة الزوج',
            delivery: _marriage.husbandDelivery,
            icon: Icons.man_outlined,
            onUpdate: _updateHusbandDelivery,
          ),
          const SizedBox(height: 8),
          DeliveryCard(
            title: 'نسخة الزوجة',
            delivery: _marriage.wifeDelivery,
            icon: Icons.woman_outlined,
            onUpdate: _updateWifeDelivery,
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DeliveryCard(
                  title: 'نسخة الزوج',
                  delivery: _marriage.husbandDelivery,
                  icon: Icons.man_outlined,
                  onUpdate: _updateHusbandDelivery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DeliveryCard(
                  title: 'نسخة الزوجة',
                  delivery: _marriage.wifeDelivery,
                  icon: Icons.woman_outlined,
                  onUpdate: _updateWifeDelivery,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPersonSection(String title, PersonInfo person) {
    return _CollapsibleSection(
      title: title,
      icon: Icons.person_outline,
      initiallyExpanded: true,
      children: [
        const _DetailGroupHeader(icon: Icons.badge_outlined, title: 'البيانات الشخصية'),
        _InfoRow(icon: Icons.person_outline, label: 'الاسم الرباعي', value: person.name),
        _detailTwoCol(
          _InfoRow(icon: Icons.flag_outlined, label: 'الجنسية', value: person.nationality),
          _InfoRow(icon: Icons.family_restroom_outlined, label: 'الحالة الاجتماعية', value: person.previousMaritalStatus),
        ),
        _InfoRow(icon: Icons.person_2_outlined, label: 'اسم الأم', value: person.motherName),

        const SizedBox(height: 6),
        const _DetailGroupHeader(icon: Icons.credit_card_outlined, title: 'بيانات الهوية والميلاد والإقامة'),
        _detailTwoCol(
          _InfoRow(icon: Icons.credit_card_outlined, label: 'نوع الهوية', value: person.idType),
          _InfoRow(icon: Icons.numbers, label: 'رقم الهوية', value: person.idNumber),
        ),
        _detailTwoCol(
          _InfoRow(icon: Icons.location_on_outlined, label: 'جهة الإصدار', value: person.idIssuePlace),
          _InfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الإصدار', value: person.idIssueDate),
        ),
        _detailTwoCol(
          _InfoRow(icon: Icons.place_outlined, label: 'محل الميلاد', value: person.birthPlace),
          _InfoRow(icon: Icons.cake_outlined, label: 'تاريخ الميلاد', value: person.birthDate),
        ),
        _InfoRow(icon: Icons.home_outlined, label: 'محل الإقامة', value: person.residence),

        const SizedBox(height: 6),
        const _DetailGroupHeader(icon: Icons.work_outline, title: 'التعليم والمهنة'),
        _detailTwoCol(
          _InfoRow(icon: Icons.school_outlined, label: 'التعليم', value: person.educationLevel),
          _InfoRow(icon: Icons.work_outline, label: 'المهنة', value: person.profession),
        ),
      ],
    );
  }

  Widget _buildGuardianSection() {
    return _CollapsibleSection(
      title: 'بيانات الولي',
      icon: Icons.supervisor_account_outlined,
      children: [
        const _DetailGroupHeader(icon: Icons.person_outline, title: 'البيانات الشخصية والصلة'),
        _detailTwoCol(
          _InfoRow(icon: Icons.badge_outlined, label: 'اسم الولي', value: _marriage.guardian.name),
          _InfoRow(icon: Icons.people_outline, label: 'صلة القرابة', value: _marriage.guardian.relationship),
        ),
        const SizedBox(height: 6),
        const _DetailGroupHeader(icon: Icons.credit_card_outlined, title: 'بيانات الهوية والإصدار'),
        _detailTwoCol(
          _InfoRow(icon: Icons.credit_card_outlined, label: 'نوع الهوية', value: _marriage.guardian.idType),
          _InfoRow(icon: Icons.numbers, label: 'رقم الهوية', value: _marriage.guardian.idNumber),
        ),
        _detailTwoCol(
          _InfoRow(icon: Icons.location_on_outlined, label: 'جهة الإصدار', value: _marriage.guardian.idIssuePlace),
          _InfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الإصدار', value: _marriage.guardian.idIssueDate),
        ),
      ],
    );
  }

  Widget _buildMahrSection() {
    return _CollapsibleSection(
      title: 'بيانات المهر',
      icon: Icons.paid_outlined,
      children: [
        _InfoRow(icon: Icons.monetization_on_outlined, label: 'مقدار المهر', value: _marriage.mahr.amount),
        _InfoRow(icon: Icons.notes, label: 'تفاصيل وقبض المهر', value: _marriage.mahr.details),
      ],
    );
  }

  Widget _buildWitnessesSection() {
    if (_marriage.witnesses.isEmpty) return const SizedBox();
    return _CollapsibleSection(
      title: 'الشهود',
      icon: Icons.group_outlined,
      children: [
        for (int i = 0; i < _marriage.witnesses.length; i++) ...[
          _DetailGroupHeader(icon: Icons.person_outline, title: 'الشاهد ${i + 1}'),
          if (_marriage.witnesses[i].phone.isNotEmpty)
            _detailTwoCol(
              _InfoRow(icon: Icons.badge_outlined, label: 'الاسم', value: _marriage.witnesses[i].name),
              _InfoRow(icon: Icons.phone_outlined, label: 'الجوال', value: _marriage.witnesses[i].phone),
            )
          else
            _InfoRow(icon: Icons.badge_outlined, label: 'الاسم', value: _marriage.witnesses[i].name),
          _detailTwoCol(
            _InfoRow(icon: Icons.credit_card_outlined, label: 'نوع الهوية', value: _marriage.witnesses[i].idType),
            _InfoRow(icon: Icons.numbers, label: 'رقم الهوية', value: _marriage.witnesses[i].idNumber),
          ),
          _detailTwoCol(
            _InfoRow(icon: Icons.location_on_outlined, label: 'جهة الإصدار', value: _marriage.witnesses[i].idIssuePlace),
            _InfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الإصدار', value: _marriage.witnesses[i].idIssueDate),
          ),
          if (i < _marriage.witnesses.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildPendingFilesSection() {
    return Card(
      color: const Color(0xFFFFF8F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.statusMissingFiles.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.statusMissingFiles, size: 18),
              const SizedBox(width: 6),
              Text('النواقص والمستندات المطلوبة (${_marriage.pendingFiles.length})',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.statusMissingFiles,
                  )),
            ]),
            const SizedBox(height: 8),
            ..._marriage.pendingFiles.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    const Icon(Icons.radio_button_unchecked,
                        size: 14, color: AppTheme.statusMissingFiles),
                    const SizedBox(width: 8),
                    Text(f, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1C1A))),
                  ]),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopActions() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أدوات سطح المكتب',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => ArchiveFolderService.instance.openMarriageFolder(
                    _marriage.recordNumber,
                    _marriage.husband.name,
                  ),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text('فتح مجلد الأرشيف', style: GoogleFonts.cairo()),
                ),
                OutlinedButton.icon(
                  onPressed: () => DocxTemplateEngine.instance.generateMarriageContract(_marriage),
                  icon: const Icon(Icons.description_outlined),
                  label: Text('إنشاء وثيقة العقد', style: GoogleFonts.cairo()),
                ),
                OutlinedButton.icon(
                  onPressed: () => DocxTemplateEngine.instance.generateMarriageStatement(_marriage),
                  icon: const Icon(Icons.article_outlined),
                  label: Text('إفادة زواج', style: GoogleFonts.cairo()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text('حذف العقد', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Text('هل أنت متأكد من حذف هذا السجل؟',
              style: GoogleFonts.cairo()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(marriageRepositoryProvider).delete(_marriage.id);
      Navigator.pop(context);
    }
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _DetailGroupHeader extends StatelessWidget {
  const _DetailGroupHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: const Color(0xFF2E3D34)),
          ),
          const SizedBox(width: 5),
          Text('$label: ',
              style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF4A554E), fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF1A1C1A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: children,
      ),
    );
  }
}
