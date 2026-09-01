// ─────────────────────────────────────────────────────────────────────────────
// arabic_date_helper.dart — Date formatting in Arabic numbers (DD/MM/YYYY) and words
// ─────────────────────────────────────────────────────────────────────────────

class ArabicDateHelper {
  ArabicDateHelper._();

  static const List<String> _daysInWords = [
    '',
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرين',
    'الحادي والعشرين',
    'الثاني والعشرين',
    'الثالث والعشرين',
    'الرابع والعشرين',
    'الخامس والعشرين',
    'السادس والعشرين',
    'السابع والعشرين',
    'الثامن والعشرين',
    'التاسع والعشرين',
    'الثلاثين',
    'الحادي والثلاثين',
  ];

  static const List<String> _hijriMonths = [
    '',
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> _gregorianMonths = [
    '',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  /// Converts a year number into Arabic words for feminine noun (سنة ...)
  static String yearToWords(int year) {
    if (year <= 0) return '';
    final unitsF = ['', 'واحدة', 'اثنتين', 'ثلاث', 'أربع', 'خمس', 'ست', 'سبع', 'ثمان', 'تسع'];
    final tensGen = ['', 'عشرة', 'عشرين', 'ثلاثين', 'أربعين', 'خمسين', 'ستين', 'سبعين', 'ثمانين', 'تسعين'];

    final parts = <String>[];
    final thousands = year ~/ 1000;
    final hundreds = (year % 1000) ~/ 100;
    final rem = year % 100;

    if (thousands == 1) {
      parts.add('ألف');
    } else if (thousands == 2) {
      parts.add('ألفين');
    } else if (thousands > 2) {
      parts.add('${unitsF[thousands]} آلاف');
    }

    if (hundreds == 1) {
      parts.add('مائة');
    } else if (hundreds == 2) {
      parts.add('مائتين');
    } else if (hundreds >= 3 && hundreds <= 9) {
      parts.add('${unitsF[hundreds]}مائة');
    }

    if (rem > 0) {
      if (rem == 1) {
        parts.add('واحدة');
      } else if (rem == 2) {
        parts.add('اثنتين');
      } else if (rem <= 10) {
        parts.add(unitsF[rem]);
      } else if (rem == 11) {
        parts.add('إحدى عشرة');
      } else if (rem == 12) {
        parts.add('اثنتي عشرة');
      } else if (rem <= 19) {
        parts.add('${unitsF[rem % 10]} عشرة');
      } else {
        final u = rem % 10;
        final t = rem ~/ 10;
        if (u > 0) {
          parts.add('${unitsF[u]} و${tensGen[t]}');
        } else {
          parts.add(tensGen[t]);
        }
      }
    }

    return parts.join(' و');
  }

  // ── Gregorian Date Formatting ──────────────────────────────────────────────

  /// Returns Gregorian date in numeric format: DD/MM/YYYYم (e.g. 01/09/2026م)
  static String formatGregorianNumeric(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/${year}م';
  }

  /// Returns Gregorian date in Arabic words
  /// (e.g. الأول من شهر سبتمبر لسنة ألفين وست وعشرين ميلادية)
  static String formatGregorianInWords(DateTime? date) {
    if (date == null) return '';
    final dayWord = (date.day >= 1 && date.day <= 31)
        ? _daysInWords[date.day]
        : date.day.toString();
    final monthWord = (date.month >= 1 && date.month <= 12)
        ? _gregorianMonths[date.month]
        : date.month.toString();
    final yearWord = yearToWords(date.year);

    return '$dayWord من شهر $monthWord لسنة $yearWord ميلادية';
  }

  /// Combined Gregorian date: DD/MM/YYYYم (كتابةً: ...)
  static String formatGregorianFull(DateTime? date) {
    if (date == null) return '';
    final numeric = formatGregorianNumeric(date);
    final words = formatGregorianInWords(date);
    return '$numeric ($words)';
  }

  // ── Hijri Date Formatting ──────────────────────────────────────────────────

  /// Parses Hijri date string which may be "YYYY/MM/DD", "DD/MM/YYYY", "YYYY-MM-DD", etc.
  static ({int day, int month, int year})? parseHijri(String hijriStr) {
    final clean = hijriStr
        .replaceAll('هـ', '')
        .replaceAll('ه', '')
        .replaceAll('-', '/')
        .trim();
    if (clean.isEmpty) return null;

    final parts = clean.split('/').map((s) => int.tryParse(s.trim())).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) {
      return null;
    }

    int d = 0, m = 0, y = 0;
    if (parts[0]! > 1000) {
      // Format YYYY/MM/DD
      y = parts[0]!;
      m = parts[1]!;
      d = parts[2]!;
    } else if (parts[2]! > 1000) {
      // Format DD/MM/YYYY
      d = parts[0]!;
      m = parts[1]!;
      y = parts[2]!;
    } else {
      // Fallback
      d = parts[0]!;
      m = parts[1]!;
      y = parts[2]!;
    }

    return (day: d, month: m, year: y);
  }

  /// Returns Hijri date in numeric format: DD/MM/YYYYهـ (e.g. 12/09/1447هـ)
  static String formatHijriNumeric(String hijriStr) {
    final parsed = parseHijri(hijriStr);
    if (parsed == null) {
      final trimmed = hijriStr.trim();
      if (trimmed.isEmpty) return '';
      return trimmed.endsWith('هـ') ? trimmed : '$trimmedهـ';
    }
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/${year}هـ';
  }

  /// Returns Hijri date in Arabic words
  /// (e.g. الثاني عشر من شهر رمضان لسنة ألف وأربعمائة وسبع وأربعين هجرية)
  static String formatHijriInWords(String hijriStr) {
    final parsed = parseHijri(hijriStr);
    if (parsed == null) return '';

    final dayWord = (parsed.day >= 1 && parsed.day <= 31)
        ? _daysInWords[parsed.day]
        : parsed.day.toString();
    final monthWord = (parsed.month >= 1 && parsed.month <= 12)
        ? _hijriMonths[parsed.month]
        : parsed.month.toString();
    final yearWord = yearToWords(parsed.year);

    return '$dayWord من شهر $monthWord لسنة $yearWord هجرية';
  }

  /// Combined Hijri date: DD/MM/YYYYهـ (كتابةً: ...)
  static String formatHijriFull(String hijriStr) {
    if (hijriStr.trim().isEmpty) return '';
    final numeric = formatHijriNumeric(hijriStr);
    final words = formatHijriInWords(hijriStr);
    if (words.isEmpty) return numeric;
    return '$numeric ($words)';
  }
}
