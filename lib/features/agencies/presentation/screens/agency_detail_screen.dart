// ─────────────────────────────────────────────────────────────────────────────
// agency_detail_screen.dart — Full agency record view
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/models/agency_model.dart';
import '../../data/repositories/agency_repository.dart';
import 'agency_form_screen.dart';
import '../../../../services/word_engine/docx_template_engine.dart';
import '../../../../services/folder_service/archive_folder_service.dart';
import '../../../marriages/presentation/widgets/delivery_card.dart';

class AgencyDetailScreen extends ConsumerStatefulWidget {
  const AgencyDetailScreen({super.key, required this.agency});
  final AgencyModel agency;

  @override
  ConsumerState<AgencyDetailScreen> createState() => _AgencyDetailScreenState();
}

class _AgencyDetailScreenState extends ConsumerState<AgencyDetailScreen> {
  late AgencyModel _agency;

  @override
  void initState() {
    super.initState();
    _agency = widget.agency;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('وكالة رقم ${_agency.agencyNumber}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AgencyFormScreen(existing: _agency)),
                );
                final fresh = await ref.read(agencyRepositoryProvider).getById(_agency.id);
                if (fresh != null && mounted) setState(() => _agency = fresh);
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
              _buildPartyCard('الموكل', _agency.principal),
              _buildPartyCard('الموكل إليه', _agency.agent),
              _buildWitnessesCard(),
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
                    _agency.title.isNotEmpty ? _agency.title : 'وكالة',
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                PopupMenuButton<AgencyStatus>(
                  initialValue: _agency.status,
                  tooltip: 'تغيير حالة الوكالة',
                  onSelected: (status) async {
                    final updated = await ref
                        .read(agencyRepositoryProvider)
                        .update(_agency.copyWith(status: status));
                    if (mounted) setState(() => _agency = updated);
                  },
                  itemBuilder: (context) => AgencyStatus.values
                      .map((s) => PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                AgencyStatusBadge(s),
                              ],
                            ),
                          ))
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AgencyStatusBadge(_agency.status),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.numbers, label: 'رقم الوكالة', value: _agency.agencyNumber),
            _InfoRow(icon: Icons.category_outlined, label: 'النوع', value: _agency.agencyType),
            if (_agency.dayName.isNotEmpty)
              _InfoRow(icon: Icons.today_outlined, label: 'اليوم', value: _agency.dayName),
            if (_agency.hijriDate.isNotEmpty)
              _InfoRow(icon: Icons.calendar_today_outlined, label: 'التاريخ الهجري', value: _agency.hijriDate),
            if (_agency.gregorianDate != null)
              _InfoRow(
                icon: Icons.event_outlined,
                label: 'التاريخ الميلادي',
                value: DateFormat('yyyy/MM/dd').format(_agency.gregorianDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return DeliveryCard(
      title: 'تسليم الوكالة',
      delivery: _agency.deliveryInfo,
      icon: Icons.description_outlined,
      onUpdate: (d) async {
        final updated = await ref.read(agencyRepositoryProvider).update(
          _agency.copyWith(
            deliveryInfo: d,
            status: d.isDelivered ? AgencyStatus.completed : _agency.status,
          ),
        );
        if (mounted) setState(() => _agency = updated);
      },
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

  Widget _buildPartyCard(String title, PartyInfo party) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.person_outline,
            color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          const _DetailGroupHeader(icon: Icons.badge_outlined, title: 'البيانات الشخصية'),
          if (party.phone.isNotEmpty)
            _detailTwoCol(
              _InfoRow(icon: Icons.person_outline, label: 'الاسم', value: party.name),
              _InfoRow(icon: Icons.phone_outlined, label: 'الجوال', value: party.phone),
            )
          else
            _InfoRow(icon: Icons.person_outline, label: 'الاسم', value: party.name),
          const SizedBox(height: 6),
          const _DetailGroupHeader(icon: Icons.credit_card_outlined, title: 'بيانات الهوية والإصدار'),
          _detailTwoCol(
            _InfoRow(icon: Icons.credit_card_outlined, label: 'نوع الهوية', value: party.idType),
            _InfoRow(icon: Icons.numbers, label: 'رقم الهوية', value: party.idNumber),
          ),
          _InfoRow(icon: Icons.location_on_outlined, label: 'جهة وتاريخ الإصدار', value: party.idIssuePlaceAndDate),
        ],
      ),
    );
  }

  Widget _buildWitnessesCard() {
    if (_agency.witnesses.isEmpty) return const SizedBox();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.group_outlined,
            color: Theme.of(context).colorScheme.primary),
        title: Text('الشهود', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (int i = 0; i < _agency.witnesses.length; i++) ...[
            _DetailGroupHeader(icon: Icons.person_outline, title: 'الشاهد ${i + 1}'),
            if (_agency.witnesses[i].idType.isNotEmpty)
              _detailTwoCol(
                _InfoRow(icon: Icons.badge_outlined, label: 'الاسم', value: _agency.witnesses[i].name),
                _InfoRow(icon: Icons.credit_card_outlined, label: 'نوع الهوية', value: _agency.witnesses[i].idType),
              )
            else
              _InfoRow(icon: Icons.badge_outlined, label: 'الاسم', value: _agency.witnesses[i].name),
            if (_agency.witnesses[i].idIssueDate.isNotEmpty)
              _detailTwoCol(
                _InfoRow(icon: Icons.numbers, label: 'رقم الهوية', value: _agency.witnesses[i].idNumber),
                _InfoRow(icon: Icons.calendar_month_outlined, label: 'تاريخ الإصدار', value: _agency.witnesses[i].idIssueDate),
              )
            else
              _InfoRow(icon: Icons.numbers, label: 'رقم الهوية', value: _agency.witnesses[i].idNumber),
            if (_agency.witnesses[i].idIssuePlace.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, label: 'جهة الإصدار', value: _agency.witnesses[i].idIssuePlace),
            if (i < _agency.witnesses.length - 1) const SizedBox(height: 10),
          ],
        ],
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
                  onPressed: () => ArchiveFolderService.instance.openAgencyFolder(
                    _agency.agencyNumber,
                    _agency.title,
                  ),
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text('فتح مجلد الأرشيف', style: GoogleFonts.cairo()),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      DocxTemplateEngine.instance.generateAgencyDocument(_agency),
                  icon: const Icon(Icons.description_outlined),
                  label: Text('إنشاء وثيقة الوكالة', style: GoogleFonts.cairo()),
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
          title: Text('حذف الوكالة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Text('هل أنت متأكد من حذف هذه الوكالة؟',
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
      await ref.read(agencyRepositoryProvider).delete(_agency.id);
      Navigator.pop(context);
    }
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
              style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade600)),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
