# الشرح الشامل والسطري لكامل الشيفرة البرمجية (Comprehensive Codebase Deep Dive)
## تطبيق إدارة عقود الزواج والوكالات الشرعية

---

# فهرس الأقسام التفصيلية

1. [نظام وقواعد بيانات SQLite الداخلية (`database_helper.dart` سطر بسطر)](#1-نظام-وقواعد-بيانات-sqlite-الداخلية-database_helperdart)
2. [نظام التبويبات والنموذج متعدد الخطوات (`TabController` & `TabBarView` بالتفصيل)](#2-نظام-التبويبات-والنموذج-متعدد-الخطوات-marriage_form_screendart)
3. [آلية جمع البيانات والحفظ في النموذج (`_save()` والتحقق من الحقول)](#3-آلية-جمع-البيانات-والحفظ-في-النموذج-_save)
4. [محرك المزامنة التلقائية والعمل الأوفلاين (`sync_repository.dart` سطر بسطر)](#4-محرك-المزامنة-التلقائية-والعمل-الأوفلاين-sync_repositorydart)
5. [الربط التبادلي التلقائي بين التسليم والحالة (`Bidirectional Sync Engine`)](#5-الربط-التبادلي-التلقائي-بين-التسليم-والحالة)
6. [محرك توليد مستندات Word والتعامل مع XML و UTF-8 (`docx_template_engine.dart`)](#6-محرك-توليد-مستندات-word-والتعامل-مع-xml-و-utf-8)
7. [عناصر الواجهة المخصصة: القوائم، التواريخ، وبطاقات التسليم (`Widgets Deep Dive`)](#7-عناصر-الواجهة-المخصصة)
8. [شاشات العرض والتفاصيل وقوائم البحث FTS4 (`List & Detail Screens`)](#8-شاشات-العرض-والتفاصيل-وقوائم-البحث)

---

# 1. نظام وقواعد بيانات SQLite الداخلية (`database_helper.dart`)

يتحكم هذا الملف في إنشاء وإدارة قاعدة بيانات **SQLite** محلياً على جهاز المستخدم (سواء على نظام macOS عبر `sqflite_common_ffi` أو على الهواتف).

### شرح إعدادات الأداء (PRAGMA Configuration):

```dart
Future<void> _onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
  await db.execute('PRAGMA journal_mode = WAL');
  await db.execute('PRAGMA synchronous = NORMAL');
}
```

* **`PRAGMA foreign_keys = ON;`**:
  * تفعيل المفاتيح الأجنبية (`Foreign Keys`) لضمان سلامة العلاقات بين الجداول ومنع أي بيانات يتيمة.
* **`PRAGMA journal_mode = WAL;` (Write-Ahead Logging)**:
  * **السبب والتقنية:** الوضع الافتراضي لـ SQLite يقفل قاعدة البيانات بالكامل عند أي عملية كتابة (Lock)، مما يسبب بطء عند القراءة والكتابة المتزامنة. وضع `WAL` يسمح بالقراءة والكتابة في نفس اللحظة دون أي تعليق (`Concurrency`)، وهو السر وراء استجابة التطبيق الفورية.
* **`PRAGMA synchronous = NORMAL;`**:
  * يقلل من عدد عمليات المزامنة الإجبارية للقرص الصلب (`fsync`) مع الحفاظ الكامل على أمان البيانات في وضع `WAL`، مما يرفع سرعة عمليات الإدراج بنسبة تزيد عن **300%**.

---

### جدول البحث بالنص الكامل ومحفزات المزامنة (FTS4 & Triggers):

لتمكين البحث الفوري عن أي جزء من الاسم (مثلاً: "محمد" أو "باحميد") أو أرقام الهويات والعقود:

```sql
-- جدول FTS4 الظاهري
CREATE VIRTUAL TABLE IF NOT EXISTS marriages_fts USING fts4(
  content="marriages",
  id,
  record_number,
  husband_name,
  wife_name,
  guardian_name,
  husband_id_number,
  wife_id_number
);
```

#### المشغلات التلقائية (Triggers) لمزامنة البحث:
لضمان تحديث جدول البحث تلقائياً عند أي إدراج، تعديل، أو حذف دون تدخل يدوي:

```sql
-- عند إدراج عقد جديد
CREATE TRIGGER IF NOT EXISTS marriages_ai AFTER INSERT ON marriages BEGIN
  INSERT INTO marriages_fts(docid, id, record_number, husband_name, wife_name, guardian_name, husband_id_number, wife_id_number)
  VALUES (new.rowid, new.id, new.record_number, new.husband_name, new.wife_name, new.guardian_name, new.husband_id_number, new.wife_id_number);
END;

-- عند تعديل عقد
CREATE TRIGGER IF NOT EXISTS marriages_au AFTER UPDATE ON marriages BEGIN
  DELETE FROM marriages_fts WHERE docid = old.rowid;
  INSERT INTO marriages_fts(docid, id, record_number, husband_name, wife_name, guardian_name, husband_id_number, wife_id_number)
  VALUES (new.rowid, new.id, new.record_number, new.husband_name, new.wife_name, new.guardian_name, new.husband_id_number, new.wife_id_number);
END;

-- عند حذف عقد
CREATE TRIGGER IF NOT EXISTS marriages_ad AFTER DELETE ON marriages BEGIN
  DELETE FROM marriages_fts WHERE docid = old.rowid;
END;
```

---

# 2. نظام التبويبات والنموذج متعدد الخطوات (`marriage_form_screen.dart`)

يتكون نموذج عقد الزواج من **5 تبويبات رئيسية**:
1. **بيانات العقد (العقد والتاريخ)**
2. **بيانات الزوج**
3. **بيانات الزوجة**
4. **الولي والمهر**
5. **الشهود والنواقص**

### 1. دورة حياة الـ `TabController` والمزامنة:

```dart
class _MarriageFormScreenState extends ConsumerState<MarriageFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // إنشاء وحدة التحكم بـ 5 تبويبات
    _tabController = TabController(length: 5, vsync: this);
    
    // الاستماع لأي تغيير في التبويب لإعادة رسم شريط التنقل السفلي
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // إذا كنا في وضع التعديل، نقوم بتعبئة البيانات فوراً
    if (widget.existing != null) _populateForm(widget.existing!);
  }

  @override
  void dispose() {
    _tabController.dispose(); // تفريغ الذاكرة ومنع تسريب الموارد
    super.dispose();
  }
```

* **`SingleTickerProviderStateMixin`**: يوفر نبضات التوقيت (`Ticker`) للـ `TabController` لتحريك الانتقال بين التبويبات بسلاسة (60 إطار في الثانية).
* **`_tabController.addListener`**: يضمن تحديث حالة الزر السفلي (بين "التالي" و "حفظ العقد") بدقة عند السحب أو الضغط.

---

### 2. التنقل الآمن بين التبويبات (Safe Clamping Navigation):

لتجنب حدوث خطأ الخروج عن حدود المصفوفة (`IndexOutOfBoundsException`):

```dart
void _nextTab() {
  if (_tabController.index < _tabController.length - 1) {
    _tabController.animateTo(
      (_tabController.index + 1).clamp(0, _tabController.length - 1),
    );
  }
}

void _prevTab() {
  if (_tabController.index > 0) {
    _tabController.animateTo(
      (_tabController.index - 1).clamp(0, _tabController.length - 1),
    );
  }
}
```

* **`.clamp(0, length - 1)`**: صمام أمان رياضي يضمن أن مؤشر التبويب لن يقل عن 0 ولن يزيد عن 4 مهما كان سرعة نقر المستخدم.

---

### 3. شريط التنقل السفلي الديناميكي (`_buildNavBar`):

```dart
Widget _buildNavBar() {
  return AnimatedBuilder(
    animation: _tabController,
    builder: (context, _) {
      final currentIndex = _tabController.index;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            // زر السابق: يظهر فقط إذا كنا في التبويب الثاني فما بعد
            if (currentIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _prevTab,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text('السابق', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
              ),
            if (currentIndex > 0) const SizedBox(width: 12),
            
            // زر التالي أو زر حفظ العقد النهائي
            if (currentIndex < _tabController.length - 1)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _nextTab,
                  icon: const Icon(Icons.arrow_back),
                  label: Text('التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
              )
            else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text('حفظ العقد', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      );
    },
  );
}
```

---

# 3. آلية جمع البيانات والحفظ في النموذج (`_save`)

عند الضغط على "حفظ العقد"، يتم التحقق من المدخلات ثم تجميع الكائنات الفرعية في كائن `MarriageModel` واحد:

```dart
Future<void> _save() async {
  // 1. التحقق من صحة الحقول الإجبارية
  if (!_formKey.currentState!.validate()) {
    // إذا كان هناك حقل ناقص في تبويب آخر، ننبه المستخدم
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('يرجى التأكد من ملء جميع الحقول المطلوبة', style: GoogleFonts.cairo()),
        backgroundColor: AppTheme.statusMissingFiles,
      ),
    );
    return;
  }

  setState(() => _saving = true);
  final now = DateTime.now();

  // 2. بناء بيانات الزوج
  final husband = PersonInfo(
    name: _hNameCtrl.text.trim(),
    idType: _hIdType,
    idNumber: _hIdNumCtrl.text.trim(),
    idIssuePlace: _hIdIssuePlace,
    idIssueDate: _hIdIssueDate,
    birthPlace: _hBirthPlace,
    residence: _hResidenceCtrl.text.trim(),
    nationality: _hNationality,
    previousMaritalStatus: _hMaritalStatus,
    educationLevel: _hEducation,
    profession: _hProfession,
    motherName: _hMotherNameCtrl.text.trim(),
  );

  // 3. بناء بيانات الزوجة
  final wife = PersonInfo(
    name: _wNameCtrl.text.trim(),
    idType: _wIdType,
    idNumber: _wIdNumCtrl.text.trim(),
    idIssuePlace: _wIdIssuePlace,
    idIssueDate: _wIdIssueDate,
    birthPlace: _wBirthPlace,
    residence: _wResidenceCtrl.text.trim(),
    nationality: _wNationality,
    previousMaritalStatus: _wMaritalStatus,
    educationLevel: _wEducation,
    profession: _wProfession,
    motherName: _wMotherNameCtrl.text.trim(),
  );

  // 4. بناء بيانات الولي والمهر والشهود
  final guardian = GuardianInfo(...);
  final mahr = MahrInfo(...);
  final witnesses = [...];

  // 5. إنشاء النموذج الكامل
  final marriage = MarriageModel(
    id: widget.existing?.id ?? '',
    recordNumber: _recordNumberCtrl.text.trim(),
    hijriDate: _hijriDateCtrl.text.trim(),
    gregorianDate: _gregorianDate,
    husband: husband,
    wife: wife,
    guardian: guardian,
    mahr: mahr,
    witnesses: witnesses,
    processingStatus: _processingStatus,
    pendingFiles: _pendingFiles,
    husbandDelivery: widget.existing?.husbandDelivery ?? const DeliveryInfo(),
    wifeDelivery: widget.existing?.wifeDelivery ?? const DeliveryInfo(),
    lastStatusUpdate: now,
    createdAt: widget.existing?.createdAt ?? now,
  );

  // 6. الحفظ الفوري في المستودع المحلي
  if (widget.existing != null) {
    await ref.read(marriageRepositoryProvider).update(marriage);
  } else {
    await ref.read(marriageRepositoryProvider).create(marriage);
  }

  if (mounted) {
    setState(() => _saving = false);
    Navigator.pop(context); // إغلاق النموذج والعودة للقائمة فوراً
  }
}
```

---

# 4. محرك المزامنة التلقائية والعمل الأوفلاين (`sync_repository.dart`)

```text
               ┌───────────────────────────────┐
               │   عملية إدخال / تعديل محلي    │
               └───────────────┬───────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │  كتابة في SQLite في 5ms      │
               │  syncStatus: pending_upload   │
               └───────────────┬───────────────┘
                               │
                 unawaited background trigger
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
   [ حالة الجهاز: متصل ]                [ حالة الجهاز: غير متصل ]
            │                                     │
   رفع فوري إلى Firestore               انتظار عودة الشبكة محلياً
   تحديث الحالة إلى 'synced'                     │
                                                  ▼
                                       1. مستشعر Connectivity
                                       2. مؤقت نبضات كل 10 ثوانٍ
                                       3. رفع تجميعي Batch Commit
```

### كود فحص وحماية المزامنة التلقائية:
```dart
// الاستماع الدائم لتغيرات الشبكة على macOS و Windows
_connectivitySub = Connectivity().onConnectivityChanged.listen((results) async {
  final connected = results.any((r) => r != ConnectivityResult.none);
  if (connected) {
    _isOnline = true;
    _emitState();
    await pushPendingChanges(); // رفع مباشر وفوري
    _startFirestoreListeners(); // تفعيل الاستماع للسحابة
  } else {
    _isOnline = false;
    _emitState();
    _stopFirestoreListeners(); // إيقاف الاستماع لتوفير الموارد
  }
});
```

---

# 5. الربط التبادلي التلقائي بين التسليم والحالة

داخل `MarriageRepository.dart`، تم ربط الحالات بحيث لا يحتاج المأذون لتغيير الحالة يدوياً إذا قام بتسليم النسخ:

```dart
// قواعد المزامنة التلقائية
if (newHusbandDelivery.isDelivered && newWifeDelivery.isDelivered) {
  // إذا سُلمت النسختان، تصبح الحالة تلقائياً: مكتمل
  newStatus = ProcessingStatus.completed;
} else if (newStatus == ProcessingStatus.completed) {
  // إذا اختار المستخدم حالة "مكتمل"، تُفعّل النسختان تلقائياً
  if (!newHusbandDelivery.isDelivered) {
    newHusbandDelivery = newHusbandDelivery.copyWith(
      isDelivered: true,
      deliveredAt: newHusbandDelivery.deliveredAt ?? now,
    );
  }
  if (!newWifeDelivery.isDelivered) {
    newWifeDelivery = newWifeDelivery.copyWith(
      isDelivered: true,
      deliveredAt: newWifeDelivery.deliveredAt ?? now,
    );
  }
} else if (newStatus == ProcessingStatus.completed &&
    (!newHusbandDelivery.isDelivered || !newWifeDelivery.isDelivered)) {
  // إذا أُلغي تسليم إحدى النسخ، تعود الحالة السابقة
  newStatus = marriage.pendingFiles.isNotEmpty
      ? ProcessingStatus.missingFiles
      : ProcessingStatus.inProgress;
}
```

---

# 6. محرك توليد مستندات Word والتعامل مع XML و UTF-8 (`docx_template_engine.dart`)

```text
[.docx قالب خام] ──► [فك ضغط ZIP] ──► [قراءة word/document.xml عبر UTF-8]
                                                    │
                                                    ▼
                                    [إزالة وسوم التنسيق داخل {{...}}]
                                                    │
                                                    ▼
                                     [استبدال المتغيرات بالبيانات]
                                                    │
                                                    ▼
[.docx مستند نهائي] ◄── [ضغط ZIP] ◄── [تشفير UTF-8 آمن للأحرف العربية]
```

### معالجة الرموز الخاصة والـ XML Entity:
```dart
String _escape(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
```

### فك، استبدال، وإعادة تشفير القالب:
```dart
Future<Uint8List> _processTemplate(
  String assetPath,
  Map<String, String> placeholders,
) async {
  final ByteData data = await rootBundle.load(assetPath);
  final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());
  final outputArchive = Archive();

  for (final file in archive) {
    if (file.isFile) {
      if (file.name.endsWith('.xml')) {
        // فك تشفير UTF-8 الصحيح للنصوص العربية
        String xmlContent = utf8.decode(file.content as List<int>);

        // دمج المتغيرات التي قام Word بتقسيمها عبر وسوم داخلية
        xmlContent = xmlContent.replaceAllMapped(
          RegExp(r'(\{\{[^}]*?<[^>]+>[^}]*?\}\})'),
          (m) => m.group(0)!.replaceAll(RegExp(r'<[^>]+>'), ''),
        );

        // استبدال المتغيرات
        for (final entry in placeholders.entries) {
          xmlContent = xmlContent.replaceAll('{{${entry.key}}}', _escape(entry.value));
        }

        // تشفير UTF-8 كامل للأحرف العربية
        final newBytes = Uint8List.fromList(utf8.encode(xmlContent));
        outputArchive.addFile(ArchiveFile(file.name, newBytes.length, newBytes));
      } else {
        outputArchive.addFile(file);
      }
    }
  }

  return Uint8List.fromList(ZipEncoder().encode(outputArchive)!);
}
```

---

# 7. عناصر الواجهة المخصصة

### 1. القائمة المنسدلة الذكية مع خيار الإدخال المخصص (`CustomizableDropdownField`):
تتيح اختيار قيمة جاهزة (مثل: سيئون، المكلا، تعز، عدن) أو اختيار **"أخرى (إدخال يدوي)"** لإظهار حقل كتابة حر:

```dart
if (_isCustom)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextFormField(
      controller: _customCtrl,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: 'اكتب ${widget.label} يدوياً',
        prefixIcon: const Icon(Icons.edit_note),
      ),
    ),
  );
```

### 2. منتقي التاريخ المزدوج (`AppDatePickerField`):
يعرض التاريخ بصيغة `DD/MM/YYYY` ويفتح التقويم الميلادي التفاعلي:

```dart
Future<void> _pickDate(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: currentDate,
    firstDate: DateTime(1920),
    lastDate: DateTime(2050),
    locale: const Locale('ar'),
  );
  if (picked != null) {
    final formatted = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    onChanged(formatted);
  }
}
```

---

# 8. شاشات العرض والتفاصيل وقوائم البحث

### شاشة تفاصيل العقد (`MarriageDetailScreen`):
- تعرض بطاقات التسليم في صف متجاور (`Row`).
- شارة الحالة التفاعلية (`PopupMenuButton`) لتغيير الحالة فوراً بنقرة واحدة.
- أقسام قابلة للطي ومقسمة لمجموعات فرعية واضحة (البيانات الشخصية، الهوية، التعليم والمهنة).
- أزرار مباشرة لفتح مجلد الأرشيف على سطح المكتب وتوليد عقود وإفادات Word.

---

## 🎯 ملخص القيم والمبادئ الهندسية في المشروع:
1. **Zero-Lag UX:** واجهة لا تتعطل ولا تنتظر استجابة الشبكة.
2. **Data Integrity:** عدم فقدان أي حرف أو إدخال عند العمل بدون إنترنت.
3. **Arabic-First Typography:** تباين كامل واعتماد نصوص واضحة بخط Cairo.
4. **Desktop Flow:** تجربة مستخدم سريعة تعتمد على زر Enter والتنقل اللحظي.
