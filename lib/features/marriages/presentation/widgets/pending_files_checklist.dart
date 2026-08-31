// ─────────────────────────────────────────────────────────────────────────────
// pending_files_checklist.dart — Interactive missing documents checklist
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

/// Common predefined document types used in marriage documentation
const kPredefinedDocuments = [
  'هوية الزوج',
  'هوية الزوجة',
  'هوية الولي',
  'هوية الشهود',
  'تصريح الأمن',
];

class PendingFilesChecklist extends StatefulWidget {
  const PendingFilesChecklist({
    super.key,
    required this.pendingFiles,
    required this.onChanged,
  });

  final List<String> pendingFiles;
  final ValueChanged<List<String>> onChanged;

  @override
  State<PendingFilesChecklist> createState() => _PendingFilesChecklistState();
}

class _PendingFilesChecklistState extends State<PendingFilesChecklist> {
  late List<String> _items;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.pendingFiles);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String item, bool? selected) {
    setState(() {
      if (selected == true) {
        if (!_items.contains(item)) _items.add(item);
      } else {
        _items.remove(item);
      }
    });
    widget.onChanged(List.from(_items));
  }

  void _removeCustom(String item) {
    setState(() => _items.remove(item));
    widget.onChanged(List.from(_items));
  }

  void _addCustom() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    if (!_items.contains(text)) {
      setState(() => _items.add(text));
      widget.onChanged(List.from(_items));
    }
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Custom items = items not in predefined list
    final customItems = _items.where((i) => !kPredefinedDocuments.contains(i)).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Predefined checkboxes
          Text(
            'الوثائق المطلوبة',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF1A1C1A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: kPredefinedDocuments.map((doc) {
              final checked = _items.contains(doc);
              return FilterChip(
                label: Text(
                  doc,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: checked ? FontWeight.w800 : FontWeight.w600,
                    color: checked ? AppTheme.green: const Color(0xFF2E3D34),
                  ),
                ),
                selected: checked,
                onSelected: (v) => _toggle(doc, v),
                backgroundColor: const Color(0xFFF9FAF9),
                selectedColor: AppTheme.green.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.green,
                side: BorderSide(
                  color: checked
                      ? AppTheme.green
                      : Colors.grey.shade300,
                  width: checked ? 1.5 : 1.0,
                ),
              );
            }).toList(),
          ),

          // Custom items
          if (customItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'متطلبات أخرى',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: const Color(0xFF1A1C1A),
              ),
            ),
            const SizedBox(height: 6),
            ...customItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppTheme.statusMissingFiles),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.grey.shade700,
                        onPressed: () => _removeCustom(item),
                      ),
                    ],
                  ),
                )),
          ],

          // Add custom
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  style: GoogleFonts.cairo(fontSize: 13, color: const Color(0xFF1A1C1A)),
                  decoration: InputDecoration(
                    hintText: 'أضف مستنداً مخصصاً...',
                    hintStyle: GoogleFonts.cairo(fontSize: 13, color: Colors.grey.shade500),
                    isDense: true,
                    fillColor: const Color(0xFFF9FAF9),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                
                onPressed: _addCustom,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Summary count
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_items.length} وثائق مطلوبة محددة',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppTheme.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
