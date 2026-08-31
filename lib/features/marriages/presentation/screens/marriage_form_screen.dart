import 'dart:io';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../data/models/marriage_model.dart';
import '../../data/repositories/marriage_repository.dart';
import '../widgets/pending_files_checklist.dart';

class MarriageFormScreen extends ConsumerStatefulWidget {
  const MarriageFormScreen({super.key, this.existing});
  final MarriageModel? existing;

  @override
  ConsumerState<MarriageFormScreen> createState() => _MarriageFormScreenState();
}

class _MarriageFormScreenState extends ConsumerState<MarriageFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // ── Tab 0: العقد والتاريخ ─────────────────────────────────────────────────
  final _recordNumberCtrl = TextEditingController();
  final _hijriDateCtrl = TextEditingController();
  DateTime? _gregorianDate;
  ProcessingStatus _processingStatus = ProcessingStatus.missingFiles;
  List<String> _pendingFiles = [];

  // ── Tab 1: الزوج ─────────────────────────────────────────────────────────
  final _hNameCtrl = TextEditingController();
  String _hIdType = 'بطاقة شخصية';
  final _hIdNumCtrl = TextEditingController();
  String _hIdIssuePlace = 'سيئون';
  String _hIdIssueDate = '';
  String _hBirthPlace = 'سيئون';
  String _hBirthDate = '';
  final _hResidenceCtrl = TextEditingController();
  String _hNationality = 'يمني';
  String _hMaritalStatus = 'أعزب';
  String _hEducation = 'ثانوي';
  String _hProfession = 'عمل خاص';
  final _hMotherNameCtrl = TextEditingController();

  // ── Tab 2: الزوجة ────────────────────────────────────────────────────────
  final _wNameCtrl = TextEditingController();
  String _wIdType = 'شهادة ميلاد';
  final _wIdNumCtrl = TextEditingController();
  String _wIdIssuePlace = 'سيئون';
  String _wIdIssueDate = '';
  String _wBirthPlace = 'سيئون';
  String _wBirthDate = '';
  final _wResidenceCtrl = TextEditingController();
  String _wNationality = 'يمنية';
  String _wMaritalStatus = 'بكر';
  String _wEducation = 'ثانوي';
  String _wProfession = 'ربة بيت';
  final _wMotherNameCtrl = TextEditingController();

  // ── Tab 3: الولي والمهر ──────────────────────────────────────────────────
  final _gNameCtrl = TextEditingController();
  String _gRelation = 'أب';
  String _gIdType = 'بطاقة شخصية';
  final _gIdNumCtrl = TextEditingController();
  String _gIdIssuePlace = 'سيئون';
  String _gIdIssueDate = '';
  final _mahrAmountCtrl = TextEditingController();
  final _mahrDetailsCtrl = TextEditingController();

  // ── Tab 4: الشهود والنواقص ───────────────────────────────────────────────
  final _w1NameCtrl = TextEditingController();
  String _w1IdType = 'بطاقة شخصية';
  final _w1IdCtrl = TextEditingController();
  String _w1IdIssueDate = '';
  String _w1IdIssuePlace = 'سيئون';
  final _w1PhoneCtrl = TextEditingController();

  final _w2NameCtrl = TextEditingController();
  String _w2IdType = 'بطاقة شخصية';
  final _w2IdCtrl = TextEditingController();
  String _w2IdIssueDate = '';
  String _w2IdIssuePlace = 'سيئون';
  final _w2PhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.existing != null) _populateForm(widget.existing!);
  }

  void _populateForm(MarriageModel m) {
    _recordNumberCtrl.text = m.recordNumber;
    _hijriDateCtrl.text = m.hijriDate;
    _gregorianDate = m.gregorianDate;
    _processingStatus = m.processingStatus;
    _pendingFiles = List.from(m.pendingFiles);

    // Husband
    _hNameCtrl.text = m.husband.name;
    _hIdType = m.husband.idType.isNotEmpty ? m.husband.idType : 'بطاقة شخصية';
    _hIdNumCtrl.text = m.husband.idNumber;
    _hIdIssuePlace = m.husband.idIssuePlace.isNotEmpty ? m.husband.idIssuePlace : 'سيئون';
    _hIdIssueDate = m.husband.idIssueDate;
    _hBirthPlace = m.husband.birthPlace.isNotEmpty ? m.husband.birthPlace : 'سيئون';
    _hBirthDate = m.husband.birthDate;
    _hResidenceCtrl.text = m.husband.residence;
    _hNationality = m.husband.nationality.isNotEmpty ? m.husband.nationality : 'يمني';
    _hMaritalStatus = m.husband.previousMaritalStatus.isNotEmpty ? m.husband.previousMaritalStatus : 'أعزب';
    _hEducation = m.husband.educationLevel.isNotEmpty ? m.husband.educationLevel : 'ثانوي';
    _hProfession = m.husband.profession.isNotEmpty ? m.husband.profession : 'عمل خاص';
    _hMotherNameCtrl.text = m.husband.motherName;

    // Wife
    _wNameCtrl.text = m.wife.name;
    _wIdType = m.wife.idType.isNotEmpty ? m.wife.idType : 'شهادة ميلاد';
    _wIdNumCtrl.text = m.wife.idNumber;
    _wIdIssuePlace = m.wife.idIssuePlace.isNotEmpty ? m.wife.idIssuePlace : 'سيئون';
    _wIdIssueDate = m.wife.idIssueDate;
    _wBirthPlace = m.wife.birthPlace.isNotEmpty ? m.wife.birthPlace : 'سيئون';
    _wBirthDate = m.wife.birthDate;
    _wResidenceCtrl.text = m.wife.residence;
    _wNationality = m.wife.nationality.isNotEmpty
        ? (m.wife.nationality == 'يمني' ? 'يمنية' : m.wife.nationality)
        : 'يمنية';
    _wMaritalStatus = m.wife.previousMaritalStatus.isNotEmpty ? m.wife.previousMaritalStatus : 'بكر';
    _wEducation = m.wife.educationLevel.isNotEmpty ? m.wife.educationLevel : 'ثانوي';
    _wProfession = m.wife.profession.isNotEmpty ? m.wife.profession : 'ربة بيت';
    _wMotherNameCtrl.text = m.wife.motherName;

    // Guardian
    _gNameCtrl.text = m.guardian.name;
    _gRelation = m.guardian.relationship.isNotEmpty ? m.guardian.relationship : 'أب';
    _gIdType = m.guardian.idType.isNotEmpty ? m.guardian.idType : 'بطاقة شخصية';
    _gIdNumCtrl.text = m.guardian.idNumber;
    _gIdIssuePlace = m.guardian.idIssuePlace.isNotEmpty ? m.guardian.idIssuePlace : 'سيئون';
    _gIdIssueDate = m.guardian.idIssueDate;

    // Mahr
    _mahrAmountCtrl.text = m.mahr.amount;
    _mahrDetailsCtrl.text = m.mahr.details;

    // Witnesses
    if (m.witnesses.isNotEmpty) {
      _w1NameCtrl.text = m.witnesses[0].name;
      _w1IdType = m.witnesses[0].idType.isNotEmpty ? m.witnesses[0].idType : 'بطاقة شخصية';
      _w1IdCtrl.text = m.witnesses[0].idNumber;
      _w1IdIssueDate = m.witnesses[0].idIssueDate;
      _w1IdIssuePlace = m.witnesses[0].idIssuePlace.isNotEmpty ? m.witnesses[0].idIssuePlace : 'سيئون';
      _w1PhoneCtrl.text = m.witnesses[0].phone;
    }
    if (m.witnesses.length > 1) {
      _w2NameCtrl.text = m.witnesses[1].name;
      _w2IdType = m.witnesses[1].idType.isNotEmpty ? m.witnesses[1].idType : 'بطاقة شخصية';
      _w2IdCtrl.text = m.witnesses[1].idNumber;
      _w2IdIssueDate = m.witnesses[1].idIssueDate;
      _w2IdIssuePlace = m.witnesses[1].idIssuePlace.isNotEmpty ? m.witnesses[1].idIssuePlace : 'سيئون';
      _w2PhoneCtrl.text = m.witnesses[1].phone;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final ctrl in [
      _recordNumberCtrl, _hijriDateCtrl, _hNameCtrl,
      _hIdNumCtrl, _hResidenceCtrl,
      _hMotherNameCtrl, _wNameCtrl, _wIdNumCtrl,
      _wResidenceCtrl,
      _wMotherNameCtrl, _gNameCtrl, _gIdNumCtrl, _mahrAmountCtrl, _mahrDetailsCtrl,
      _w1NameCtrl, _w1IdCtrl, _w1PhoneCtrl, _w2NameCtrl, _w2IdCtrl, _w2PhoneCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  MarriageModel _buildModel() {
    final now = DateTime.now();
    final existing = widget.existing;
    return MarriageModel(
      id: existing?.id ?? const Uuid().v4(),
      recordNumber: _recordNumberCtrl.text.trim(),
      hijriDate: _hijriDateCtrl.text.trim(),
      gregorianDate: _gregorianDate,
      husband: PersonInfo(
        name: _hNameCtrl.text.trim(),
        idType: _hIdType,
        idNumber: _hIdNumCtrl.text.trim(),
        idIssuePlace: _hIdIssuePlace,
        idIssueDate: _hIdIssueDate,
        birthPlace: _hBirthPlace,
        birthDate: _hBirthDate,
        residence: _hResidenceCtrl.text.trim(),
        nationality: _hNationality,
        previousMaritalStatus: _hMaritalStatus,
        educationLevel: _hEducation,
        profession: _hProfession,
        motherName: _hMotherNameCtrl.text.trim(),
      ),
      wife: PersonInfo(
        name: _wNameCtrl.text.trim(),
        idType: _wIdType,
        idNumber: _wIdNumCtrl.text.trim(),
        idIssuePlace: _wIdIssuePlace,
        idIssueDate: _wIdIssueDate,
        birthPlace: _wBirthPlace,
        birthDate: _wBirthDate,
        residence: _wResidenceCtrl.text.trim(),
        nationality: _wNationality,
        previousMaritalStatus: _wMaritalStatus,
        educationLevel: _wEducation,
        profession: _wProfession,
        motherName: _wMotherNameCtrl.text.trim(),
      ),
      guardian: GuardianInfo(
        name: _gNameCtrl.text.trim(),
        relationship: _gRelation,
        idType: _gIdType,
        idNumber: _gIdNumCtrl.text.trim(),
        idIssuePlace: _gIdIssuePlace,
        idIssueDate: _gIdIssueDate,
      ),
      mahr: MahrInfo(
        amount: _mahrAmountCtrl.text.trim(),
        details: _mahrDetailsCtrl.text.trim(),
      ),
      witnesses: [
        WitnessInfo(
          name: _w1NameCtrl.text.trim(),
          idType: _w1IdType,
          idNumber: _w1IdCtrl.text.trim(),
          idIssueDate: _w1IdIssueDate,
          idIssuePlace: _w1IdIssuePlace,
          phone: _w1PhoneCtrl.text.trim(),
        ),
        WitnessInfo(
          name: _w2NameCtrl.text.trim(),
          idType: _w2IdType,
          idNumber: _w2IdCtrl.text.trim(),
          idIssueDate: _w2IdIssueDate,
          idIssuePlace: _w2IdIssuePlace,
          phone: _w2PhoneCtrl.text.trim(),
        ),
      ].where((w) => w.name.isNotEmpty).toList(),
      processingStatus: _processingStatus,
      pendingFiles: _pendingFiles,
      husbandDelivery: existing?.husbandDelivery ?? const DeliveryInfo(),
      wifeDelivery: existing?.wifeDelivery ?? const DeliveryInfo(),
      extraFields: existing?.extraFields ?? {},
      syncStatus: SyncStatus.pendingUpload,
      lastStatusUpdate: now,
      createdAt: existing?.createdAt ?? now,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(marriageRepositoryProvider);
      final model = _buildModel();
      if (widget.existing == null) {
        await repo.create(model);
      } else {
        await repo.update(model);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e', style: GoogleFonts.cairo())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing == null ? 'عقد زواج جديد' : 'تعديل العقد',
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'العقد والتاريخ'),
              Tab(text: 'الزوج'),
              Tab(text: 'الزوجة'),
              Tab(text: 'الولي والمهر'),
              Tab(text: 'الشهود والمتطلبات'),
            ],
          ),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                tooltip: 'حفظ',
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildContractTab(),
              _buildHusbandTab(),
              _buildWifeTab(),
              _buildGuardianMahrTab(),
              _buildWitnessesTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildNavBar(),
      ),
    );
  }

  Widget _twoCol(Widget first, Widget second, {int flex1 = 1, int flex2 = 1}) {
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
        Expanded(flex: flex1, child: first),
        const SizedBox(width: 12),
        Expanded(flex: flex2, child: second),
      ],
    );
  }

  Widget _threeCol(Widget first, Widget second, Widget third, {int flex1 = 1, int flex2 = 1, int flex3 = 1}) {
    final isMobile = Platform.isAndroid || Platform.isIOS || MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          first,
          second,
          third,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: flex1, child: first),
        const SizedBox(width: 12),
        Expanded(flex: flex2, child: second),
        const SizedBox(width: 12),
        Expanded(flex: flex3, child: third),
      ],
    );
  }

  Widget _buildContractTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.numbers, title: 'بيانات العقد والتاريخ'),
          _threeCol(
            _Field(label: 'رقم العقد', ctrl: _recordNumberCtrl, required: true),
            _Field(label: 'التاريخ الهجري', ctrl: _hijriDateCtrl),
            AppDatePickerField(
              label: 'التاريخ الميلادي',
              value: _gregorianDate != null
                  ? '${_gregorianDate!.day.toString().padLeft(2, '0')}/${_gregorianDate!.month.toString().padLeft(2, '0')}/${_gregorianDate!.year}'
                  : '',
              onChanged: (dStr) {
                if (dStr.isEmpty) {
                  setState(() => _gregorianDate = null);
                } else {
                  final parts = dStr.split('/');
                  if (parts.length == 3) {
                    final d = int.tryParse(parts[0]);
                    final m = int.tryParse(parts[1]);
                    final y = int.tryParse(parts[2]);
                    if (d != null && m != null && y != null) {
                      setState(() => _gregorianDate = DateTime(y, m, d));
                    }
                  }
                }
              },
            ),
            flex1: 3,
            flex2: 3,
            flex3: 4,
          ),
          const SizedBox(height: 16),
          const _SectionHeader(icon: Icons.assignment_outlined, title: 'حالة الملف'),
          _StatusDropdown(
            value: _processingStatus,
            onChanged: (v) => setState(() => _processingStatus = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildHusbandTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.person_outline, title: 'بيانات الزوج'),
          _Field(label: 'الاسم الرباعي', ctrl: _hNameCtrl, required: true),
          _twoCol(
            IdTypeDropdownField(
              value: _hIdType,
              onChanged: (v) => setState(() => _hIdType = v),
            ),
            _Field(label: 'رقم الهوية', ctrl: _hIdNumCtrl),
            flex1: 4,
            flex2: 6,
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'جهة إصدار الهوية',
              value: _hIdIssuePlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _hIdIssuePlace = v),
              prefixIcon: Icons.location_on_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ إصدار الهوية',
              value: _hIdIssueDate,
              onChanged: (v) => setState(() => _hIdIssueDate = v),
            ),
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'محل الميلاد',
              value: _hBirthPlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _hBirthPlace = v),
              prefixIcon: Icons.place_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ الميلاد',
              value: _hBirthDate,
              onChanged: (v) => setState(() => _hBirthDate = v),
            ),
          ),
          _Field(label: 'محل الإقامة الحالية', ctrl: _hResidenceCtrl),
          _twoCol(
            CustomizableDropdownField(
              label: 'الجنسية',
              value: _hNationality,
              options: kNationalities,
              onChanged: (v) => setState(() => _hNationality = v),
              prefixIcon: Icons.flag_outlined,
            ),
            CustomizableDropdownField(
              label: 'الحالة الاجتماعية',
              value: _hMaritalStatus,
              options: kHusbandMaritalStatuses,
              onChanged: (v) => setState(() => _hMaritalStatus = v),
              prefixIcon: Icons.family_restroom_outlined,
            ),
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'المستوى التعليمي',
              value: _hEducation,
              options: kEducationLevels,
              onChanged: (v) => setState(() => _hEducation = v),
              prefixIcon: Icons.school_outlined,
            ),
            CustomizableDropdownField(
              label: 'العمل الوظيفي / المهنة',
              value: _hProfession,
              options: kHusbandProfessions,
              onChanged: (v) => setState(() => _hProfession = v),
              prefixIcon: Icons.work_outline,
            ),
          ),
          _Field(label: 'اسم الأم', ctrl: _hMotherNameCtrl, onSubmitted: (_) => _nextTab()),
        ],
      ),
    );
  }

  Widget _buildWifeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.person_outline, title: 'بيانات الزوجة'),
          _Field(label: 'الاسم الرباعي', ctrl: _wNameCtrl, required: true),
          _twoCol(
            IdTypeDropdownField(
              value: _wIdType,
              onChanged: (v) => setState(() => _wIdType = v),
            ),
            _Field(label: 'رقم الهوية', ctrl: _wIdNumCtrl),
            flex1: 4,
            flex2: 6,
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'جهة إصدار الهوية',
              value: _wIdIssuePlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _wIdIssuePlace = v),
              prefixIcon: Icons.location_on_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ إصدار الهوية',
              value: _wIdIssueDate,
              onChanged: (v) => setState(() => _wIdIssueDate = v),
            ),
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'محل الميلاد',
              value: _wBirthPlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _wBirthPlace = v),
              prefixIcon: Icons.place_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ الميلاد',
              value: _wBirthDate,
              onChanged: (v) => setState(() => _wBirthDate = v),
            ),
          ),
          _Field(label: 'محل الإقامة الحالية', ctrl: _wResidenceCtrl),
          _twoCol(
            CustomizableDropdownField(
              label: 'الجنسية',
              value: _wNationality,
              options: kWifeNationalities,
              onChanged: (v) => setState(() => _wNationality = v),
              prefixIcon: Icons.flag_outlined,
            ),
            CustomizableDropdownField(
              label: 'الحالة الاجتماعية',
              value: _wMaritalStatus,
              options: kWifeMaritalStatuses,
              onChanged: (v) => setState(() => _wMaritalStatus = v),
              prefixIcon: Icons.family_restroom_outlined,
            ),
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'المستوى التعليمي',
              value: _wEducation,
              options: kEducationLevels,
              onChanged: (v) => setState(() => _wEducation = v),
              prefixIcon: Icons.school_outlined,
            ),
            CustomizableDropdownField(
              label: 'العمل الوظيفي / المهنة',
              value: _wProfession,
              options: kWifeProfessions,
              onChanged: (v) => setState(() => _wProfession = v),
              prefixIcon: Icons.work_outline,
            ),
          ),
          _Field(label: 'اسم الأم', ctrl: _wMotherNameCtrl, onSubmitted: (_) => _nextTab()),
        ],
      ),
    );
  }

  Widget _buildGuardianMahrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.supervisor_account_outlined, title: 'بيانات الولي'),
          _twoCol(
            _Field(label: 'اسم الولي الرباعي', ctrl: _gNameCtrl, required: true),
            CustomizableDropdownField(
              label: 'صلة القرابة',
              value: _gRelation,
              options: kGuardianRelationships,
              onChanged: (v) => setState(() => _gRelation = v),
              prefixIcon: Icons.family_restroom_outlined,
            ),
            flex1: 6,
            flex2: 4,
          ),
          _twoCol(
            IdTypeDropdownField(
              value: _gIdType,
              onChanged: (v) => setState(() => _gIdType = v),
            ),
            _Field(label: 'رقم الهوية', ctrl: _gIdNumCtrl),
            flex1: 4,
            flex2: 6,
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'جهة الإصدار',
              value: _gIdIssuePlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _gIdIssuePlace = v),
              prefixIcon: Icons.location_on_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ الإصدار',
              value: _gIdIssueDate,
              onChanged: (v) => setState(() => _gIdIssueDate = v),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(icon: Icons.paid_outlined, title: 'المهر'),
          _Field(label: 'مقدار المهر', ctrl: _mahrAmountCtrl),
          _Field(
            label: 'تفاصيل وقبض المهر',
            ctrl: _mahrDetailsCtrl,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildWitnessesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.group_outlined, title: 'الشاهد الأول'),
          _twoCol(
            _Field(label: 'اسم الشاهد الأول', ctrl: _w1NameCtrl),
            _Field(label: 'رقم الجوال', ctrl: _w1PhoneCtrl, keyboardType: TextInputType.phone),
            flex1: 6,
            flex2: 4,
          ),
          _twoCol(
            IdTypeDropdownField(
              value: _w1IdType,
              onChanged: (v) => setState(() => _w1IdType = v),
            ),
            _Field(label: 'رقم الهوية', ctrl: _w1IdCtrl),
            flex1: 4,
            flex2: 6,
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'جهة إصدار الهوية',
              value: _w1IdIssuePlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _w1IdIssuePlace = v),
              prefixIcon: Icons.location_on_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ إصدار الهوية',
              value: _w1IdIssueDate,
              onChanged: (v) => setState(() => _w1IdIssueDate = v),
            ),
          ),

          const SizedBox(height: 16),
          const _SectionHeader(icon: Icons.group_outlined, title: 'الشاهد الثاني'),
          _twoCol(
            _Field(label: 'اسم الشاهد الثاني', ctrl: _w2NameCtrl),
            _Field(label: 'رقم الجوال', ctrl: _w2PhoneCtrl, keyboardType: TextInputType.phone),
            flex1: 6,
            flex2: 4,
          ),
          _twoCol(
            IdTypeDropdownField(
              value: _w2IdType,
              onChanged: (v) => setState(() => _w2IdType = v),
            ),
            _Field(label: 'رقم الهوية', ctrl: _w2IdCtrl),
            flex1: 4,
            flex2: 6,
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'جهة إصدار الهوية',
              value: _w2IdIssuePlace,
              options: kCommonCities,
              onChanged: (v) => setState(() => _w2IdIssuePlace = v),
              prefixIcon: Icons.location_on_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ إصدار الهوية',
              value: _w2IdIssueDate,
              onChanged: (v) => setState(() => _w2IdIssueDate = v),
            ),
          ),

          const SizedBox(height: 20),
          const _SectionHeader(icon: Icons.warning_amber_outlined, title: 'النواقص والمستندات المطلوبة'),
          PendingFilesChecklist(
            pendingFiles: _pendingFiles,
            onChanged: (v) => setState(() => _pendingFiles = v),
          ),
        ],
      ),
    );
  }

  void _nextTab() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo((_tabController.index + 1).clamp(0, _tabController.length - 1));
    }
  }

  void _prevTab() {
    if (_tabController.index > 0) {
      _tabController.animateTo((_tabController.index - 1).clamp(0, _tabController.length - 1));
    }
  }

  Widget _buildNavBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final currentIndex = _tabController.index;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              if (currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevTab,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text('السابق', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 12),
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
}

// ── Reusable Form Widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.ctrl,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });
  final String label;
  final TextEditingController ctrl;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final defaultAction = maxLines > 1 ? TextInputAction.newline : (textInputAction ?? TextInputAction.next);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: defaultAction,
        onFieldSubmitted: (val) {
          if (onSubmitted != null) {
            onSubmitted!(val);
          } else {
            FocusScope.of(context).nextFocus();
          }
        },
        style: GoogleFonts.cairo(color: const Color(0xFF1A1C1A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: const Color(0xFF2E3D34), fontWeight: FontWeight.w600),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});
  final ProcessingStatus value;
  final ValueChanged<ProcessingStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<ProcessingStatus>(
        isExpanded: true,
        value: value,
        decoration: InputDecoration(
          labelText: 'حالة الملف',
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
        items: ProcessingStatus.values.map((s) {
          return DropdownMenuItem(
            value: s,
            child: Text(s.label, style: GoogleFonts.cairo(), overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
