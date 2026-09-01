import 'dart:io';
import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/sync_status.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../data/models/agency_model.dart';
import '../../data/repositories/agency_repository.dart';
import '../../../marriages/data/models/marriage_model.dart' show DeliveryInfo;

class AgencyFormScreen extends ConsumerStatefulWidget {
  const AgencyFormScreen({super.key, this.existing});
  final AgencyModel? existing;

  @override
  ConsumerState<AgencyFormScreen> createState() => _AgencyFormScreenState();
}

class _AgencyFormScreenState extends ConsumerState<AgencyFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Tab 0: بيانات وتاريخ الوكالة
  final _agencyNumCtrl = TextEditingController();
  final _agencyTypeCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _dayNameCtrl = TextEditingController();
  final _hijriDateCtrl = TextEditingController();
  DateTime? _gregorianDate;
  AgencyStatus _status = AgencyStatus.draft;

  // Tab 1 — موكل
  final _principalNameCtrl = TextEditingController();
  String _principalIdType = 'بطاقة شخصية';
  final _principalIdNumCtrl = TextEditingController();
  String _principalIdIssuePlace = 'سيئون';
  String _principalIdIssueDate = '';
  final _principalPhoneCtrl = TextEditingController();

  // Tab 2 — الوكيل
  final _agentNameCtrl = TextEditingController();
  String _agentIdType = 'بطاقة شخصية';
  final _agentIdNumCtrl = TextEditingController();
  String _agentIdIssuePlace = 'سيئون';
  String _agentIdIssueDate = '';
  final _agentPhoneCtrl = TextEditingController();

  // Tab 3 — شهود
  final _w1NameCtrl = TextEditingController();
  String _w1IdType = 'بطاقة شخصية';
  final _w1IdCtrl = TextEditingController();
  String _w1IdIssueDate = '';
  String _w1IdIssuePlace = 'سيئون';

  final _w2NameCtrl = TextEditingController();
  String _w2IdType = 'بطاقة شخصية';
  final _w2IdCtrl = TextEditingController();
  String _w2IdIssueDate = '';
  String _w2IdIssuePlace = 'سيئون';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.existing != null) _populate(widget.existing!);
  }

  void _populate(AgencyModel a) {
    _agencyNumCtrl.text = a.agencyNumber;
    _agencyTypeCtrl.text = a.agencyType;
    _titleCtrl.text = a.title;
    _dayNameCtrl.text = a.dayName;
    _hijriDateCtrl.text = a.hijriDate;
    _gregorianDate = a.gregorianDate;
    _status = a.status;

    _principalNameCtrl.text = a.principal.name;
    _principalIdType = a.principal.idType.isNotEmpty ? a.principal.idType : 'بطاقة شخصية';
    _principalIdNumCtrl.text = a.principal.idNumber;
    _principalIdIssuePlace = a.principal.idIssuePlaceAndDate.isNotEmpty ? a.principal.idIssuePlaceAndDate : 'سيئون';
    _principalPhoneCtrl.text = a.principal.phone;

    _agentNameCtrl.text = a.agent.name;
    _agentIdType = a.agent.idType.isNotEmpty ? a.agent.idType : 'بطاقة شخصية';
    _agentIdNumCtrl.text = a.agent.idNumber;
    _agentIdIssuePlace = a.agent.idIssuePlaceAndDate.isNotEmpty ? a.agent.idIssuePlaceAndDate : 'سيئون';
    _agentPhoneCtrl.text = a.agent.phone;

    if (a.witnesses.isNotEmpty) {
      _w1NameCtrl.text = a.witnesses[0].name;
      _w1IdType = a.witnesses[0].idType.isNotEmpty ? a.witnesses[0].idType : 'بطاقة شخصية';
      _w1IdCtrl.text = a.witnesses[0].idNumber;
      _w1IdIssueDate = a.witnesses[0].idIssueDate;
      _w1IdIssuePlace = a.witnesses[0].idIssuePlace.isNotEmpty ? a.witnesses[0].idIssuePlace : 'سيئون';
    }
    if (a.witnesses.length > 1) {
      _w2NameCtrl.text = a.witnesses[1].name;
      _w2IdType = a.witnesses[1].idType.isNotEmpty ? a.witnesses[1].idType : 'بطاقة شخصية';
      _w2IdCtrl.text = a.witnesses[1].idNumber;
      _w2IdIssueDate = a.witnesses[1].idIssueDate;
      _w2IdIssuePlace = a.witnesses[1].idIssuePlace.isNotEmpty ? a.witnesses[1].idIssuePlace : 'سيئون';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _agencyNumCtrl, _agencyTypeCtrl, _titleCtrl, _dayNameCtrl,
      _hijriDateCtrl, _principalNameCtrl,
      _principalIdNumCtrl, _principalPhoneCtrl,
      _agentNameCtrl, _agentIdNumCtrl,
      _agentPhoneCtrl, _w1NameCtrl, _w1IdCtrl, _w2NameCtrl, _w2IdCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  AgencyModel _buildModel() {
    final now = DateTime.now();
    return AgencyModel(
      id: widget.existing?.id ?? const Uuid().v4(),
      agencyNumber: _agencyNumCtrl.text.trim(),
      agencyType: _agencyTypeCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      dayName: _dayNameCtrl.text.trim(),
      hijriDate: _hijriDateCtrl.text.trim(),
      gregorianDate: _gregorianDate,
      principal: PartyInfo(
        name: _principalNameCtrl.text.trim(),
        idType: _principalIdType,
        idNumber: _principalIdNumCtrl.text.trim(),
        idIssuePlaceAndDate: _principalIdIssueDate.isNotEmpty
            ? '$_principalIdIssuePlace - $_principalIdIssueDate'
            : _principalIdIssuePlace,
        phone: _principalPhoneCtrl.text.trim(),
      ),
      agent: PartyInfo(
        name: _agentNameCtrl.text.trim(),
        idType: _agentIdType,
        idNumber: _agentIdNumCtrl.text.trim(),
        idIssuePlaceAndDate: _agentIdIssueDate.isNotEmpty
            ? '$_agentIdIssuePlace - $_agentIdIssueDate'
            : _agentIdIssuePlace,
        phone: _agentPhoneCtrl.text.trim(),
      ),
      witnesses: [
        AgencyWitnessInfo(
          name: _w1NameCtrl.text.trim(),
          idType: _w1IdType,
          idNumber: _w1IdCtrl.text.trim(),
          idIssueDate: _w1IdIssueDate,
          idIssuePlace: _w1IdIssuePlace,
        ),
        AgencyWitnessInfo(
          name: _w2NameCtrl.text.trim(),
          idType: _w2IdType,
          idNumber: _w2IdCtrl.text.trim(),
          idIssueDate: _w2IdIssueDate,
          idIssuePlace: _w2IdIssuePlace,
        ),
      ].where((w) => w.name.isNotEmpty).toList(),
      status: _status,
      deliveryInfo: widget.existing?.deliveryInfo ?? const DeliveryInfo(),
      extraFields: widget.existing?.extraFields ?? {},
      syncStatus: SyncStatus.pendingUpload,
      lastStatusUpdate: now,
      createdAt: widget.existing?.createdAt ?? now,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(agencyRepositoryProvider);
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
          title: Text(widget.existing == null ? 'وكالة جديدة' : 'تعديل الوكالة'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'بيانات وتاريخ الوكالة'),
              Tab(text: 'الموكل'),
              Tab(text: 'الوكيل'),
              Tab(text: 'الشهود'),
            ],
          ),
          actions: [
            _saving
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)))
                : IconButton(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                  ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(),
              _buildPartyTab(
                'الموكل',
                _principalNameCtrl,
                _principalIdType,
                (v) => setState(() => _principalIdType = v),
                _principalIdNumCtrl,
                _principalIdIssuePlace,
                (v) => setState(() => _principalIdIssuePlace = v),
                _principalIdIssueDate,
                (v) => setState(() => _principalIdIssueDate = v),
                _principalPhoneCtrl,
              ),
              _buildPartyTab(
                'الوكيل',
                _agentNameCtrl,
                _agentIdType,
                (v) => setState(() => _agentIdType = v),
                _agentIdNumCtrl,
                _agentIdIssuePlace,
                (v) => setState(() => _agentIdIssuePlace = v),
                _agentIdIssueDate,
                (v) => setState(() => _agentIdIssueDate = v),
                _agentPhoneCtrl,
              ),
              _buildWitnessesTab(),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedBuilder(
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
                        icon: const Icon(Icons.save),
                        label: Text('حفظ الوكالة',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
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

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _SectionHeader(icon: Icons.description_outlined, title: 'بيانات الوكالة'),
          _twoCol(
            _Field(label: 'رقم الوكالة', ctrl: _agencyNumCtrl, required: true),
            _Field(label: 'نوع الوكالة (عامة / خاصة)', ctrl: _agencyTypeCtrl),
            flex1: 4,
            flex2: 6,
          ),
          _Field(label: 'موضوع الوكالة', ctrl: _titleCtrl, required: true),
          const SizedBox(height: 12),
          const _SectionHeader(icon: Icons.calendar_today_outlined, title: 'التاريخ'),
          _threeCol(
            _Field(label: 'اليوم', ctrl: _dayNameCtrl),
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
          const SizedBox(height: 12),
          const _SectionHeader(icon: Icons.assignment_outlined, title: 'الحالة'),
          DropdownButtonFormField<AgencyStatus>(
            isExpanded: true,
            value: _status,
            decoration: InputDecoration(
              labelText: 'حالة الوكالة',
              labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            style: GoogleFonts.cairo(fontWeight: FontWeight.w500),
            items: AgencyStatus.values.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s.label, style: GoogleFonts.cairo(), overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (v) => setState(() => _status = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyTab(
    String title,
    TextEditingController name,
    String idType,
    ValueChanged<String> onIdTypeChanged,
    TextEditingController idNum,
    String issuePlace,
    ValueChanged<String> onIssuePlaceChanged,
    String issueDate,
    ValueChanged<String> onIssueDateChanged,
    TextEditingController phone,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionHeader(icon: Icons.person_outline, title: 'بيانات $title'),
          _twoCol(
            _Field(label: 'الاسم الرباعي واللقب', ctrl: name, required: true),
            _Field(label: 'رقم الجوال', ctrl: phone, keyboardType: TextInputType.phone, onSubmitted: (_) => _nextTab()),
            flex1: 6,
            flex2: 4,
          ),
          _twoCol(
            IdTypeDropdownField(
              value: idType,
              onChanged: onIdTypeChanged,
            ),
            _Field(label: 'رقم الهوية', ctrl: idNum),
            flex1: 4,
            flex2: 6,
          ),
          _twoCol(
            CustomizableDropdownField(
              label: 'جهة إصدار الهوية',
              value: issuePlace,
              options: kCommonCities,
              onChanged: onIssuePlaceChanged,
              prefixIcon: Icons.location_on_outlined,
            ),
            AppDatePickerField(
              label: 'تاريخ إصدار الهوية',
              value: issueDate,
              onChanged: onIssueDateChanged,
            ),
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
          _Field(label: 'اسم الشاهد الأول الرباعي', ctrl: _w1NameCtrl),
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
          _Field(label: 'اسم الشاهد الثاني الرباعي', ctrl: _w2NameCtrl),
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

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ملاحظة: صيغة ونص الوكالة يُكتب في برنامج Word عند التوليد.',
                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared form helpers ───────────────────────────────────────────────────────

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
          Expanded(child: Divider(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))),
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
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });
  final String label;
  final TextEditingController ctrl;
  final bool required;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textInputAction: textInputAction ?? TextInputAction.next,
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
