import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';

class CardFormScreen extends ConsumerStatefulWidget {
  final CardEntry? entry;
  CardFormScreen({super.key, this.entry});

  @override
  ConsumerState<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late CardType _cardType;
  late CardProvider _provider;
  CardScope? _scope;
  String? _selectedBank;
  late TextEditingController _customProviderController;
  late TextEditingController _customBankController;
  late TextEditingController _numberController;
  late TextEditingController _holderController;
  late TextEditingController _expiryController;
  late TextEditingController _cvvController;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _cardType = widget.entry?.cardType ?? CardType.debit;
    _provider = widget.entry?.provider ?? CardProvider.visa;
    _scope = widget.entry?.scope;
    _selectedBank = widget.entry?.issuingBank;
    _customProviderController = TextEditingController(text: widget.entry?.customProviderName ?? '');
    _customBankController = TextEditingController(text: widget.entry?.customBankName ?? '');
    _numberController = TextEditingController(text: widget.entry?.formattedNumber ?? '');
    _holderController = TextEditingController(text: widget.entry?.cardholderName ?? '');
    _expiryController = TextEditingController(text: widget.entry?.expiryDate ?? '');
    _cvvController = TextEditingController(text: widget.entry?.cvv ?? '');
  }

  @override
  void dispose() {
    _customProviderController.dispose();
    _customBankController.dispose();
    _numberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cleanNumber = _numberController.text.replaceAll(' ', '');
    final bankName = _selectedBank == 'Other' ? 'Other' : _selectedBank;

    if (_isEditing) {
      final updated = widget.entry!.copyWith(
        cardType: _cardType,
        provider: _provider,
        customProviderName: _provider == CardProvider.other ? _customProviderController.text.trim() : null,
        cardNumber: cleanNumber,
        cardholderName: _holderController.text.trim(),
        expiryDate: _expiryController.text.trim(),
        cvv: _cvvController.text.trim(),
        issuingBank: bankName,
        customBankName: _selectedBank == 'Other' ? _customBankController.text.trim() : null,
        scope: _scope,
      );
      await ref.read(vaultProvider.notifier).updateCard(updated);
    } else {
      final entry = CardEntry(
        cardType: _cardType,
        provider: _provider,
        customProviderName: _provider == CardProvider.other ? _customProviderController.text.trim() : null,
        cardNumber: cleanNumber,
        cardholderName: _holderController.text.trim(),
        expiryDate: _expiryController.text.trim(),
        cvv: _cvvController.text.trim(),
        issuingBank: bankName,
        customBankName: _selectedBank == 'Other' ? _customBankController.text.trim() : null,
        scope: _scope,
      );
      await ref.read(vaultProvider.notifier).addCard(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  String? _validateCardNumber(String? v) {
    if (v == null || v.isEmpty) return 'Card number is required';
    final clean = v.replaceAll(' ', '');
    if (clean.length < 13 || clean.length > 19) return 'Enter 13–19 digit card number';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name is required';
    if (RegExp(r'[0-9]').hasMatch(v)) return 'Name cannot contain numbers';
    return null;
  }

  String? _validateExpiry(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(v)) return 'Use MM/YY';
    final parts = v.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final expiry = DateTime(year, month + 1, 0);
    if (expiry.isBefore(DateTime.now())) return 'Expired';
    return null;
  }

  String? _validateCVV(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(v)) return '3-4 digits';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'Add Card'),
        actions: [TextButton(onPressed: _save, child: Text('Save', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card type
              const _SectionTitle('Card Type'),
              SizedBox(height: 10),
              Row(children: [
                _toggleChip('Debit', _cardType == CardType.debit, () => setState(() => _cardType = CardType.debit)),
                SizedBox(width: 12),
                _toggleChip('Credit', _cardType == CardType.credit, () => setState(() => _cardType = CardType.credit)),
              ]),
              SizedBox(height: 20),

              // Provider dropdown
              const _SectionTitle('Card Network'),
              SizedBox(height: 10),
              _dropdown<CardProvider>(
                value: _provider,
                items: CardProvider.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                onChanged: (v) => setState(() => _provider = v ?? CardProvider.visa),
              ),
              // Custom provider name when "Other"
              if (_provider == CardProvider.other) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _customProviderController,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  validator: (v) => (_provider == CardProvider.other && (v == null || v.trim().isEmpty)) ? 'Enter provider name' : null,
                  decoration: InputDecoration(labelText: 'Provider Name', hintText: 'e.g. JCB, UnionPay', prefixIcon: Icon(Icons.payment, color: AppColors.accentGold)),
                ),
              ],
              SizedBox(height: 20),

              // Card number
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                validator: _validateCardNumber,
                maxLength: 23,
                style: TextStyle(color: AppColors.of(context).textPrimary, letterSpacing: 2, fontFamily: 'monospace'),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()],
                onChanged: (v) {
                  final detected = CardEntry.detectProvider(v);
                  if (detected != CardProvider.other && detected != _provider) setState(() => _provider = detected);
                },
                decoration: InputDecoration(labelText: 'Card Number', hintText: '0000 0000 0000 0000', prefixIcon: Icon(Icons.credit_card, color: AppColors.accentGold), counterText: ''),
              ),
              SizedBox(height: 16),

              // Cardholder name — letters only
              TextFormField(
                controller: _holderController,
                validator: _validateName,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-]'))],
                decoration: InputDecoration(labelText: 'Cardholder Name', hintText: 'JOHN DOE', prefixIcon: Icon(Icons.person_outline, color: AppColors.accentGold)),
              ),
              SizedBox(height: 16),

              // Expiry + CVV
              Row(children: [
                Expanded(child: TextFormField(
                  controller: _expiryController,
                  validator: _validateExpiry,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  style: TextStyle(color: AppColors.of(context).textPrimary, letterSpacing: 2),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryDateFormatter()],
                  decoration: InputDecoration(labelText: 'Expiry', hintText: 'MM/YY', prefixIcon: Icon(Icons.calendar_today, color: AppColors.accentGold), counterText: ''),
                )),
                SizedBox(width: 16),
                Expanded(child: TextFormField(
                  controller: _cvvController,
                  obscureText: true,
                  validator: _validateCVV,
                  keyboardType: TextInputType.number,
                  maxLength: _provider == CardProvider.amex ? 4 : 3,
                  style: TextStyle(color: AppColors.of(context).textPrimary, letterSpacing: 4),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_provider == CardProvider.amex ? 4 : 3)],
                  decoration: InputDecoration(labelText: 'CVV', hintText: '•••', prefixIcon: Icon(Icons.lock_outline, color: AppColors.accentRed), counterText: ''),
                )),
              ]),
              SizedBox(height: 20),

              // Bank dropdown
              const _SectionTitle('Issuing Bank'),
              SizedBox(height: 10),
              _dropdown<String>(
                value: _selectedBank,
                hint: 'Select bank (optional)',
                items: KnownBanks.banks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
              ),
              // Custom bank name when "Other"
              if (_selectedBank == 'Other') ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _customBankController,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                  validator: (v) => (_selectedBank == 'Other' && (v == null || v.trim().isEmpty)) ? 'Enter bank name' : null,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s.\-()]'))],
                  decoration: InputDecoration(labelText: 'Bank Name', hintText: 'e.g. Karnataka Bank', prefixIcon: Icon(Icons.account_balance, color: AppColors.accentGold)),
                ),
              ],
              SizedBox(height: 20),

              // Domestic / International (optional)
              const _SectionTitle('Card Scope (optional)'),
              SizedBox(height: 10),
              Wrap(spacing: 10, children: [
                _toggleChip('Domestic', _scope == CardScope.domestic, () => setState(() => _scope = _scope == CardScope.domestic ? null : CardScope.domestic)),
                _toggleChip('International', _scope == CardScope.international, () => setState(() => _scope = _scope == CardScope.international ? null : CardScope.international)),
                _toggleChip('Both', _scope == CardScope.both, () => setState(() => _scope = _scope == CardScope.both ? null : CardScope.both)),
              ]),
              SizedBox(height: 32),

              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _save, child: Text(_isEditing ? 'Update Card' : 'Save Card'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentGold.withValues(alpha: 0.15) : AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.accentGold : AppColors.of(context).border),
        ),
        child: Text(label, style: TextStyle(color: selected ? AppColors.accentGold : AppColors.of(context).textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  Widget _dropdown<T>({required T? value, List<DropdownMenuItem<T>>? items, void Function(T?)? onChanged, String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.of(context).surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.of(context).border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.of(context).surfaceDark,
          hint: hint != null ? Text(hint, style: TextStyle(color: AppColors.of(context).textMuted)) : null,
          style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary));
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    if (text.length > 19) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 4) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
