// ─────────────────────────────────────────────────────────────────────────────
// form_fields.dart — Reusable specialized form inputs with dropdowns & pickers
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Predefined ID document types
const kIdTypes = [
  'جواز سفر',
  'بطاقة شخصية',
  'شهادة ميلاد',
];

/// Predefined masculine nationalities (للزوج)
const kNationalities = [
  'يمني',
  'سعودي',
  'إماراتي',
  'كويتي',
  'عماني',
  'بحريني',
  'قطري',
  'مصري',
  'سوري',
  'أردني',
  'سوداني',
];

/// Predefined feminine nationalities (للزوجة)
const kWifeNationalities = [
  'يمنية',
  'سعودية',
  'إماراتية',
  'كويتية',
  'عمانية',
  'بحرينية',
  'قطرية',
  'مصرية',
  'سورية',
  'أردنية',
  'سودانية',
];

/// Predefined common cities for birth place / issue place
const kCommonCities = [
  'سيئون',
  'المكلا',
  'تعز',
  'عدن',
];

/// Predefined guardian relationships
const kGuardianRelationships = [
  'أب',
  'أخ',
  'عم',
  'جد',
  'ابن',
  'وكيل شرعي',
  'القاضي (الحاكم الشرعي)',
];

/// Predefined marital statuses for husband (including marrying another)
const kHusbandMaritalStatuses = [
  'أعزب',
  'متزوج (على ثانية / تعدد)',
  'مطلق',
  'أرمل',
];

/// Predefined marital statuses for wife
const kWifeMaritalStatuses = [
  'بكر',
  'مطلقة',
  'أرملة',
  'ثيب',
];

/// Predefined education levels
const kEducationLevels = [
  'أساسي',
  'ثانوي',
  'جامعي',
  'غير متعلم',
];

/// Predefined professions for husband
const kHusbandProfessions = [
  'عمل خاص',
  'موظف حكومي',
];

/// Predefined professions for wife
const kWifeProfessions = [
  'ربة بيت',
  'موظفة حكومية',
  'عمل خاص',
];

/// Dropdown field for ID Types (جواز سفر، بطاقة شخصية، شهادة ميلاد)
class IdTypeDropdownField extends StatelessWidget {
  const IdTypeDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'نوع الهوية',
    this.required = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = kIdTypes.contains(value) ? value : (value.isEmpty ? null : null);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: effectiveValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
        ),
        style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
        dropdownColor: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        items: kIdTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(
              type,
              style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) onChanged(val);
        },
        validator: required
            ? (v) => (v == null || v.isEmpty) && value.isEmpty ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }
}

/// Date Picker field formatted strictly as DD/MM/YYYY
class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.prefixIcon = Icons.calendar_today_outlined,
  });

  final String label;
  final String value; // Expected in DD/MM/YYYY format or empty
  final ValueChanged<String> onChanged;
  final bool required;
  final IconData prefixIcon;

  DateTime? _parseDate(String val) {
    if (val.trim().isEmpty) return null;
    try {
      if (val.contains('/')) {
        final parts = val.split('/');
        if (parts.length == 3) {
          // DD/MM/YYYY
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
      return DateTime.tryParse(val);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseDate(value);
    final displayString = parsed != null ? _formatDate(parsed) : (value.isNotEmpty ? value : '');
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: parsed ?? now,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
            builder: (ctx, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
          );
          if (picked != null) {
            onChanged(_formatDate(picked));
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(prefixIcon, size: 20),
            suffixIcon: value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => onChanged(''),
                  )
                : null,
            errorText: required && value.isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
          child: Text(
            displayString.isNotEmpty ? displayString : 'اختر التاريخ (يوم/شهر/سنة)',
            style: GoogleFonts.cairo(
              color: displayString.isNotEmpty ? theme.textTheme.bodyLarge?.color : theme.hintColor,
              fontWeight: displayString.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown with predefined list + custom "أخرى" text input
class CustomizableDropdownField extends StatefulWidget {
  const CustomizableDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.required = false,
    this.prefixIcon,
    this.customLabel = 'حدد (أخرى)...',
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool required;
  final IconData? prefixIcon;
  final String customLabel;

  @override
  State<CustomizableDropdownField> createState() => _CustomizableDropdownFieldState();
}

class _CustomizableDropdownFieldState extends State<CustomizableDropdownField> {
  static const _otherKey = '__OTHER__';
  late TextEditingController _customController;
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    _isOther = widget.value.isNotEmpty && !widget.options.contains(widget.value);
    _customController = TextEditingController(text: _isOther ? widget.value : '');
  }

  @override
  void didUpdateWidget(covariant CustomizableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final isNowOther = widget.value.isNotEmpty && !widget.options.contains(widget.value);
      if (isNowOther != _isOther) {
        _isOther = isNowOther;
      }
      if (_isOther && _customController.text != widget.value) {
        _customController.text = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDropdownValue = _isOther
        ? _otherKey
        : (widget.options.contains(widget.value) ? widget.value : null);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: selectedDropdownValue,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, size: 20) : null,
            ),
            style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
            dropdownColor: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            items: [
              ...widget.options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(
                    opt,
                    style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              DropdownMenuItem(
                value: _otherKey,
                child: Text(
                  'أخرى (تحديد يدوي)...',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: theme.colorScheme.secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (val) {
              if (val == _otherKey) {
                setState(() {
                  _isOther = true;
                });
                widget.onChanged(_customController.text.trim());
              } else if (val != null) {
                setState(() {
                  _isOther = false;
                });
                widget.onChanged(val);
              }
            },
            validator: widget.required
                ? (v) => (v == null || v.isEmpty) && widget.value.isEmpty ? 'هذا الحقل مطلوب' : null
                : null,
          ),
          if (_isOther) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customController,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: widget.customLabel,
                prefixIcon: const Icon(Icons.edit_note_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _customController.clear();
                    widget.onChanged('');
                  },
                ),
              ),
              onChanged: (text) => widget.onChanged(text.trim()),
              validator: widget.required
                  ? (v) => v == null || v.trim().isEmpty ? 'يرجى كتابة القيمة' : null
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
