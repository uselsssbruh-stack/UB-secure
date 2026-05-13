import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/identity_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';

class IdentityFormScreen extends ConsumerStatefulWidget {
  final IdentityEntry? entry;
  IdentityFormScreen({super.key, this.entry});

  @override
  ConsumerState<IdentityFormScreen> createState() => _IdentityFormScreenState();
}

class _IdentityFormScreenState extends ConsumerState<IdentityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late IdentityType _type;
  String? _gender;
  String? _dlScope;

  late TextEditingController _numberCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _customDocNameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _notesCtrl;
  // PAN
  late TextEditingController _fatherMotherNameCtrl;
  // Aadhaar
  late TextEditingController _sonDaughterOfCtrl;
  // Voter
  late TextEditingController _fatherMotherHusbandCtrl;
  // DL
  late TextEditingController _issueDateCtrl;
  late TextEditingController _validThroughCtrl;
  late TextEditingController _doiCtrl;
  late TextEditingController _bloodGroupCtrl;
  late TextEditingController _covCtrl;
  late TextEditingController _sonOfCtrl;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _type = e?.type ?? IdentityType.pan;
    _gender = e?.gender;
    _dlScope = e?.dlScope;

    _numberCtrl = TextEditingController(text: e?.number ?? '');
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _customDocNameCtrl = TextEditingController(text: e?.customDocName ?? '');
    _dobCtrl = TextEditingController(text: e?.dateOfBirth ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _fatherMotherNameCtrl = TextEditingController(text: e?.fatherMotherName ?? '');
    _sonDaughterOfCtrl = TextEditingController(text: e?.sonDaughterOf ?? '');
    _fatherMotherHusbandCtrl = TextEditingController(text: e?.fatherMotherHusbandName ?? '');
    _issueDateCtrl = TextEditingController(text: e?.issueDate ?? '');
    _validThroughCtrl = TextEditingController(text: e?.validThrough ?? '');
    _doiCtrl = TextEditingController(text: e?.doi ?? '');
    _bloodGroupCtrl = TextEditingController(text: e?.bloodGroup ?? '');
    _covCtrl = TextEditingController(text: e?.cov ?? '');
    _sonOfCtrl = TextEditingController(text: e?.sonOf ?? '');
  }

  @override
  void dispose() {
    for (final c in [_numberCtrl, _nameCtrl, _customDocNameCtrl, _dobCtrl, _addressCtrl, _notesCtrl,
        _fatherMotherNameCtrl, _sonDaughterOfCtrl, _fatherMotherHusbandCtrl,
        _issueDateCtrl, _validThroughCtrl, _doiCtrl, _bloodGroupCtrl, _covCtrl, _sonOfCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTypeChanged(IdentityType t) => setState(() { _type = t; _numberCtrl.clear(); });

  String? _validateNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Document number is required';
    final clean = v.replaceAll(' ', '').toUpperCase();
    switch (_type) {
      case IdentityType.pan:
        if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(clean)) return 'Format: 5 letters + 4 digits + 1 letter';
        break;
      case IdentityType.aadhaar:
        if (!RegExp(r'^[0-9]{12}$').hasMatch(clean)) return 'Must be exactly 12 digits';
        break;
      case IdentityType.voterId:
        if (!RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(clean)) return 'Format: 3 letters + 7 digits';
        break;
      case IdentityType.drivingLicense:
        if (clean.length < 10 || clean.length > 16) return '10–16 characters';
        if (!RegExp(r'^[A-Z]{2}[0-9]{2}').hasMatch(clean)) return 'Must start with state code';
        break;
      case IdentityType.other:
        if (clean.isEmpty) return 'Number is required';
        break;
    }
    return null;
  }

  String? _validateName(String? v) {
    if (_type == IdentityType.other) return null; // name optional for 'other'
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
    return null;
  }

  String? _validateDate(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^[0-9]{2}/[0-9]{2}/[0-9]{4}$').hasMatch(v)) return 'Use DD/MM/YYYY';
    try {
      final p = v.split('/');
      final d = int.parse(p[0]), m = int.parse(p[1]), y = int.parse(p[2]);
      final date = DateTime(y, m, d);
      if (date.day != d || date.month != m) return 'Invalid date';
      if (date.isAfter(DateTime.now())) return 'Cannot be in future';
    } catch (_) { return 'Invalid date'; }
    return null;
  }

  List<TextInputFormatter> _getNumberFormatters() {
    switch (_type) {
      case IdentityType.aadhaar:
        return [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12), _AadhaarFmt()];
      case IdentityType.pan:
      case IdentityType.voterId:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          LengthLimitingTextInputFormatter(_type.maxLength),
          _UpperCaseFmt(),
        ];
      case IdentityType.drivingLicense:
        return [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), LengthLimitingTextInputFormatter(16), _UpperCaseFmt()];
      case IdentityType.other:
        return [LengthLimitingTextInputFormatter(30)];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final number = _type == IdentityType.other ? _numberCtrl.text.trim() : _numberCtrl.text.replaceAll(' ', '').toUpperCase();
    final entry = IdentityEntry(
      id: _isEditing ? widget.entry!.id : null,
      type: _type,
      number: number,
      name: _nameCtrl.text.trim(),
      customDocName: _type == IdentityType.other ? _customDocNameCtrl.text.trim() : null,
      dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
      gender: _gender,
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      fatherMotherName: _fatherMotherNameCtrl.text.trim().isEmpty ? null : _fatherMotherNameCtrl.text.trim(),
      sonDaughterOf: _sonDaughterOfCtrl.text.trim().isEmpty ? null : _sonDaughterOfCtrl.text.trim(),
      fatherMotherHusbandName: _fatherMotherHusbandCtrl.text.trim().isEmpty ? null : _fatherMotherHusbandCtrl.text.trim(),
      issueDate: _issueDateCtrl.text.trim().isEmpty ? null : _issueDateCtrl.text.trim(),
      validThrough: _validThroughCtrl.text.trim().isEmpty ? null : _validThroughCtrl.text.trim(),
      doi: _doiCtrl.text.trim().isEmpty ? null : _doiCtrl.text.trim(),
      bloodGroup: _bloodGroupCtrl.text.trim().isEmpty ? null : _bloodGroupCtrl.text.trim(),
      cov: _covCtrl.text.trim().isEmpty ? null : _covCtrl.text.trim(),
      dlScope: _dlScope,
      sonOf: _sonOfCtrl.text.trim().isEmpty ? null : _sonOfCtrl.text.trim(),
      createdAt: _isEditing ? widget.entry!.createdAt : null,
    );

    if (_isEditing) {
      await ref.read(vaultProvider.notifier).updateIdentity(entry);
    } else {
      await ref.read(vaultProvider.notifier).addIdentity(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Identity' : 'Add Identity'),
        actions: [TextButton(onPressed: _save, child: Text('Save', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              _label('Document Type'),
              SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: IdentityType.values.map((t) => _typeChip(t)).toList()),
              SizedBox(height: 20),

              // Custom doc name for "Other"
              if (_type == IdentityType.other) ...[
                _textField(_customDocNameCtrl, 'Document Name', Icons.description, hint: 'e.g. Metro Card, Passport',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter document name' : null),
                SizedBox(height: 16),
              ],

              // Number
              TextFormField(
                controller: _numberCtrl,
                validator: _validateNumber,
                keyboardType: _type == IdentityType.aadhaar ? TextInputType.number : TextInputType.text,
                maxLength: _type.maxLength,
                style: TextStyle(color: AppColors.of(context).textPrimary, letterSpacing: 2, fontFamily: 'monospace'),
                inputFormatters: _getNumberFormatters(),
                decoration: InputDecoration(
                  labelText: '${_type == IdentityType.other ? 'Document' : _type.label} Number',
                  hintText: _type.numberHint,
                  helperText: _type.numberDescription,
                  helperStyle: TextStyle(color: AppColors.of(context).textMuted, fontSize: 11),
                  prefixIcon: Icon(Icons.numbers, color: AppColors.accentPurple),
                  counterText: '',
                ),
              ),
              SizedBox(height: 16),

              // Name
              _textField(_nameCtrl, _type == IdentityType.other ? 'Name (optional)' : 'Full Name (as on document)',
                Icons.person_outline, validator: _validateName,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-]'))],
                capitalization: TextCapitalization.words),
              SizedBox(height: 16),

              // DOB
              _dateField(_dobCtrl, 'Date of Birth (optional)'),

              // ─── PAN-specific ───
              if (_type == IdentityType.pan) ...[
                SizedBox(height: 16),
                _textField(_fatherMotherNameCtrl, "Father's / Mother's Name (optional)", Icons.family_restroom,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-]'))]),
              ],

              // ─── Aadhaar-specific ───
              if (_type == IdentityType.aadhaar) ...[
                SizedBox(height: 16),
                _textField(_sonDaughterOfCtrl, 'S/o, D/o, W/o (optional)', Icons.people_outline,
                  hint: 'Son/Daughter/Wife of',
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-]'))]),
                SizedBox(height: 16),
                _genderSelector(),
                SizedBox(height: 16),
                _textField(_addressCtrl, 'Address (optional)', Icons.home_outlined, maxLines: 2),
              ],

              // ─── Voter ID-specific ───
              if (_type == IdentityType.voterId) ...[
                SizedBox(height: 16),
                _textField(_fatherMotherHusbandCtrl, "Father's / Mother's / Husband's Name (optional)", Icons.family_restroom,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-]'))]),
                SizedBox(height: 16),
                _genderSelector(),
                SizedBox(height: 16),
                _textField(_addressCtrl, 'Address (optional)', Icons.home_outlined, maxLines: 2),
              ],

              // ─── DL-specific ───
              if (_type == IdentityType.drivingLicense) ...[
                SizedBox(height: 16),
                _textField(_sonOfCtrl, 'S/o, D/o, W/o (optional)', Icons.people_outline,
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-]'))]),
                SizedBox(height: 16),
                _dateField(_issueDateCtrl, 'Date of Issue (optional)'),
                SizedBox(height: 16),
                _dateField(_validThroughCtrl, 'Valid Through (optional)', allowFuture: true),
                SizedBox(height: 16),
                _dateField(_doiCtrl, 'DOI — Date of Initial Issue (optional)'),
                SizedBox(height: 16),
                _textField(_bloodGroupCtrl, 'Blood Group (optional)', Icons.bloodtype_outlined,
                  hint: 'e.g. O+, A-, B+, AB+',
                  formatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZO+\-]')), LengthLimitingTextInputFormatter(4)]),
                SizedBox(height: 16),
                _textField(_covCtrl, 'COV — Class of Vehicle (optional)', Icons.directions_car_outlined,
                  hint: 'e.g. LMV, MCWG, HMV'),
                SizedBox(height: 16),
                _textField(_addressCtrl, 'Address (optional)', Icons.home_outlined, maxLines: 2),
                SizedBox(height: 16),
                _label('Valid Through (optional)'),
                SizedBox(height: 8),
                Wrap(spacing: 10, children: ['India', 'International'].map((s) {
                  final selected = _dlScope == s;
                  return GestureDetector(
                    onTap: () => setState(() => _dlScope = _dlScope == s ? null : s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accentPurple.withValues(alpha: 0.15) : AppColors.of(context).cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppColors.accentPurple : AppColors.of(context).border),
                      ),
                      child: Text(s, style: TextStyle(color: selected ? AppColors.accentPurple : AppColors.of(context).textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  );
                }).toList()),
              ],

              // ─── Other type: generic fields ───
              if (_type == IdentityType.other) ...[
                SizedBox(height: 16),
                _textField(_addressCtrl, 'Address (optional)', Icons.home_outlined, maxLines: 2),
              ],

              // Notes (all types)
              SizedBox(height: 16),
              _textField(_notesCtrl, 'Notes (optional)', Icons.note_outlined, maxLines: 2),
              SizedBox(height: 32),

              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _save, child: Text(_isEditing ? 'Update' : 'Save Identity'))),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _typeChip(IdentityType t) {
    final selected = _type == t;
    return GestureDetector(
      onTap: () => _onTypeChanged(t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPurple.withValues(alpha: 0.15) : AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.accentPurple : AppColors.of(context).border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(t.icon, style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text(t.label, style: TextStyle(color: selected ? AppColors.accentPurple : AppColors.of(context).textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _genderSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Gender'),
      SizedBox(height: 8),
      Row(children: ['Male', 'Female', 'Other'].map((g) {
        final selected = _gender == g;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => setState(() => _gender = g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentPurple.withValues(alpha: 0.15) : AppColors.of(context).cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppColors.accentPurple : AppColors.of(context).border),
              ),
              child: Text(g, style: TextStyle(color: selected ? AppColors.accentPurple : AppColors.of(context).textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _textField(TextEditingController c, String label, IconData icon, {
    String? hint, String? Function(String?)? validator,
    List<TextInputFormatter>? formatters, int maxLines = 1,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: c, validator: validator, maxLines: maxLines,
      style: TextStyle(color: AppColors.of(context).textPrimary),
      textCapitalization: capitalization,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        prefixIcon: maxLines > 1 ? Padding(padding: const EdgeInsets.only(bottom: 30), child: Icon(icon, color: AppColors.accentPurple)) : Icon(icon, color: AppColors.accentPurple),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Widget _dateField(TextEditingController c, String label, {bool allowFuture = false}) {
    return TextFormField(
      controller: c,
      validator: allowFuture ? null : _validateDate,
      keyboardType: TextInputType.number,
      maxLength: 10,
      style: TextStyle(color: AppColors.of(context).textPrimary),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _DateFmt()],
      decoration: InputDecoration(labelText: label, hintText: 'DD/MM/YYYY', prefixIcon: Icon(Icons.calendar_today, color: AppColors.accentPurple), counterText: ''),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary));
}

class _AadhaarFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    final t = val.text.replaceAll(' ', '');
    if (t.length > 12) return old;
    final b = StringBuffer();
    for (int i = 0; i < t.length; i++) { if (i > 0 && i % 4 == 0) b.write(' '); b.write(t[i]); }
    final f = b.toString();
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class _UpperCaseFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) =>
    TextEditingValue(text: val.text.toUpperCase(), selection: val.selection);
}

class _DateFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue val) {
    final t = val.text.replaceAll('/', '');
    if (t.length > 8) return old;
    final b = StringBuffer();
    for (int i = 0; i < t.length; i++) { if (i == 2 || i == 4) b.write('/'); b.write(t[i]); }
    final f = b.toString();
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
