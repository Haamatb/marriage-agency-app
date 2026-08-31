// ─────────────────────────────────────────────────────────────────────────────
// marriage_list_screen.dart — Dashboard with search, filters & stat cards
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/sync_indicator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/marriage_model.dart';
import '../../data/repositories/marriage_repository.dart';
import 'marriage_form_screen.dart';
import 'marriage_detail_screen.dart';
import '../../../../services/excel_service/excel_service.dart';

class MarriageListScreen extends ConsumerStatefulWidget {
  const MarriageListScreen({super.key});

  @override
  ConsumerState<MarriageListScreen> createState() => _MarriageListScreenState();
}

class _MarriageListScreenState extends ConsumerState<MarriageListScreen> {
  ProcessingStatus? _filterStatus;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MarriageFilter get _filter => MarriageFilter(
        status: _filterStatus,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        fromDate: _selectedDateRange?.start,
        toDate: _selectedDateRange?.end,
      );

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime(2050),
      initialDateRange: _selectedDateRange,
      locale: const Locale('ar'),
      helpText: 'اختر نطاق تاريخ العقد',
      cancelText: 'إلغاء',
      confirmText: 'تطبيق',
      saveText: 'تطبيق',
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marriagesAsync = ref.watch(marriagesStreamProvider(_filter));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'سجلات الزواج',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'تبديل المظهر (فاتح / داكن)',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          const SyncIndicator(),
          const SizedBox(width: 4),
          _buildMenuButton(context),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً بك',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'إدارة وتوثيق عقود الأنكحة والوكالات',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSearchBar(),
                  if (_selectedDateRange != null) _buildDateRangeBadge(),
                  const SizedBox(height: 12),
                  _buildFilterChips(),
                  const SizedBox(height: 14),
                  _buildStatsSummary(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'قائمة العقود المسجلة',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        marriagesAsync.maybeWhen(
                          data: (list) => Text(
                            '${list.length} سجل',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
          _buildSliverList(marriagesAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarriageFormScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text('عقد جديد', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return FutureBuilder<Map<ProcessingStatus, int>>(
      future: ref.read(marriageRepositoryProvider).getStatusCounts(),
      builder: (_, snap) {
        final counts = snap.data ?? {};
        return SizedBox(
          height: 76,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _StatCard(
                label: 'متطلبات',
                count: counts[ProcessingStatus.missingFiles] ?? 0,
                color: AppTheme.statusMissingFiles,
                icon: Icons.warning_amber_rounded,
                selected: _filterStatus == ProcessingStatus.missingFiles,
                onTap: () => setState(() => _filterStatus =
                    _filterStatus == ProcessingStatus.missingFiles
                        ? null
                        : ProcessingStatus.missingFiles),
              ),
              _StatCard(
                label: 'قيد الإنجاز',
                count: counts[ProcessingStatus.inProgress] ?? 0,
                color: AppTheme.statusInProgress,
                icon: Icons.hourglass_top_rounded,
                selected: _filterStatus == ProcessingStatus.inProgress,
                onTap: () => setState(() => _filterStatus =
                    _filterStatus == ProcessingStatus.inProgress
                        ? null
                        : ProcessingStatus.inProgress),
              ),
              _StatCard(
                label: 'جاهز',
                count: counts[ProcessingStatus.ready] ?? 0,
                color: AppTheme.statusReady,
                icon: Icons.check_circle_outline_rounded,
                selected: _filterStatus == ProcessingStatus.ready,
                onTap: () => setState(() => _filterStatus =
                    _filterStatus == ProcessingStatus.ready
                        ? null
                        : ProcessingStatus.ready),
              ),
              _StatCard(
                label: 'مكتمل',
                count: counts[ProcessingStatus.completed] ?? 0,
                color: AppTheme.statusCompleted,
                icon: Icons.verified_rounded,
                selected: _filterStatus == ProcessingStatus.completed,
                onTap: () => setState(() => _filterStatus =
                    _filterStatus == ProcessingStatus.completed
                        ? null
                        : ProcessingStatus.completed),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeBadge() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E26) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range_rounded, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'النطاق: ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.start)} ⟵ ${DateFormat('yyyy/MM/dd').format(_selectedDateRange!.end)}',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _selectedDateRange = null),
              borderRadius: BorderRadius.circular(12),
              child: const Icon(Icons.cancel, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterBtnBg = isDark ? Colors.white : const Color(0xFF111111);
    final filterBtnIcon = isDark ? const Color(0xFF111111) : Colors.white;

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم، الرقم، أو التاريخ...',
                hintStyle: GoogleFonts.cairo(fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: _selectedDateRange != null ? AppTheme.accentBlue : filterBtnBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (_selectedDateRange != null ? AppTheme.accentBlue : (isDark ? Colors.white : Colors.black)).withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: _selectedDateRange != null ? Colors.white : filterBtnIcon,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _FilterChip(
            label: 'الكل',
            selected: _filterStatus == null,
            onSelected: (_) => setState(() => _filterStatus = null),
          ),
          ...ProcessingStatus.values.map((s) => _FilterChip(
                label: s.label,
                selected: _filterStatus == s,
                onSelected: (_) => setState(() =>
                    _filterStatus = _filterStatus == s ? null : s),
              )),
        ],
      ),
    );
  }

  Widget _buildSliverList(AsyncValue<List<MarriageModel>> marriagesAsync) {
    return marriagesAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('خطأ: $e', style: GoogleFonts.cairo())),
      ),
      data: (marriages) {
        if (marriages.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد سجلات بعد',
                    style: GoogleFonts.cairo(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _MarriageCard(
                marriage: marriages[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarriageDetailScreen(marriage: marriages[i]),
                  ),
                ),
              ),
              childCount: marriages.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) async {
        if (v == 'export') {
          await ExcelService.instance.exportMarriages(
            await ref.read(marriageRepositoryProvider).getStatusCounts().then((_) =>
                ref.read(marriageRepositoryProvider).getStatusCounts()),
          );
        } else if (v == 'import') {
          await ExcelService.instance.importMarriagesFromPicker(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'export',
          child: Row(children: [
            const Icon(Icons.download_rounded, size: 20),
            const SizedBox(width: 10),
            Text('تصدير Excel', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ]),
        ),
        PopupMenuItem(
          value: 'import',
          child: Row(children: [
            const Icon(Icons.upload_rounded, size: 20),
            const SizedBox(width: 10),
            Text('استيراد Excel', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }
}

// ── Stat Card (Bento Style) ───────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? (selected ? const Color(0xFF262630) : const Color(0xFF16161A))
        : (selected ? const Color(0xFFE5E7EB) : Colors.white);
    final borderColor = selected
        ? (isDark ? Colors.white : const Color(0xFF111111))
        : (isDark ? const Color(0xFF26262B) : const Color(0xFFE5E7EB));
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final mutedColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 116,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                Text(
                  '$count',
                  style: GoogleFonts.cairo(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: mutedColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pill Filter Chip with Dot ─────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? Colors.white : const Color(0xFF111111);
    final activeText = isDark ? const Color(0xFF0F0F12) : Colors.white;
    final inactiveBg = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final inactiveText = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    final borderColor = isDark ? const Color(0xFF2C2C34) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => onSelected(!selected),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? activeBg : borderColor,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: activeText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? activeText : inactiveText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Marriage List Card ────────────────────────────────────────────────────────

class _MarriageCard extends StatelessWidget {
  const _MarriageCard({required this.marriage, required this.onTap});
  final MarriageModel marriage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF26262B) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with names and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF22222A) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.diamond_rounded, size: 20, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${marriage.husband.name}  ⟷  ${marriage.wife.name}',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'عقد رقم: ${marriage.recordNumber}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                              if (marriage.hijriDate.isNotEmpty) ...[
                                Text(
                                  '• ${marriage.hijriDate}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ProcessingStatusBadge(marriage.processingStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: isDark ? const Color(0xFF222228) : const Color(0xFFF3F4F6),
                ),
                const SizedBox(height: 10),
                // Delivery and indicator footer
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _DeliveryPill(
                            label: 'نسخة الزوج',
                            delivered: marriage.husbandDelivery.isDelivered,
                          ),
                          _DeliveryPill(
                            label: 'نسخة الزوجة',
                            delivered: marriage.wifeDelivery.isDelivered,
                          ),
                          if (marriage.pendingFiles.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.statusMissingFiles.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${marriage.pendingFiles.length} نواقص',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusMissingFiles,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryPill extends StatelessWidget {
  const _DeliveryPill({required this.label, required this.delivered});
  final String label;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = delivered ? AppTheme.statusCompleted : (isDark ? Colors.white38 : Colors.black38);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: delivered ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
