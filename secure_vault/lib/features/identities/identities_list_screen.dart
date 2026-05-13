import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/clipboard_service.dart';
import '../../models/identity_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'identity_form_screen.dart';

class IdentitiesListScreen extends ConsumerWidget {
  IdentitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider).vault;
    final identities = vault?.identities ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Identity Documents'),
        actions: [IconButton(icon: Icon(Icons.add_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IdentityFormScreen())))],
      ),
      body: identities.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.identityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                child: Icon(Icons.badge_rounded, size: 40, color: AppColors.identityColor)),
              SizedBox(height: 20),
              Text('No Identities Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
              SizedBox(height: 8),
              Text('Add your identity documents', style: TextStyle(color: AppColors.of(context).textMuted)),
              SizedBox(height: 24),
              ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IdentityFormScreen())), icon: Icon(Icons.add_rounded), label: Text('Add Identity')),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: identities.length,
              itemBuilder: (context, index) => _buildEntry(context, ref, identities[index]),
            ),
      floatingActionButton: identities.isNotEmpty
          ? FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IdentityFormScreen())), child: Icon(Icons.add_rounded))
          : null,
    );
  }

  Widget _buildEntry(BuildContext context, WidgetRef ref, IdentityEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        GestureDetector(onTap: () => _showDetail(context, entry), child: _IdentityCardUI(entry: entry)),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _chip(context, 'Copy', Icons.copy_rounded, () {
            ClipboardService.copyWithAutoClear(entry.number);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied — auto-clears in 15s')));
          }),
          SizedBox(width: 8),
          _chip(context, 'Edit', Icons.edit_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => IdentityFormScreen(entry: entry)))),
          SizedBox(width: 8),
          _chip(context, 'Delete', Icons.delete_outline, () async {
            final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: Text('Delete Identity'), content: Text('This cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.accentRed), child: Text('Delete')),
              ],
            ));
            if (ok == true) ref.read(vaultProvider.notifier).deleteIdentity(entry.id);
          }, danger: true),
        ]),
      ]),
    );
  }

  void _showDetail(BuildContext context, IdentityEntry entry) {
    showModalBottomSheet(
      context: context, backgroundColor: AppColors.of(context).surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) => _DetailSheet(entry: entry),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    return Material(
      color: danger ? AppColors.accentRed.withValues(alpha: 0.1) : AppColors.of(context).cardDark,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(borderRadius: BorderRadius.circular(10), onTap: onTap,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: danger ? AppColors.accentRed : AppColors.of(context).textSecondary),
            SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: danger ? AppColors.accentRed : AppColors.of(context).textSecondary)),
          ]),
        ),
      ),
    );
  }
}

// ─── Card UI ───

class _IdentityCardUI extends StatelessWidget {
  final IdentityEntry entry;
  const _IdentityCardUI({required this.entry});

  @override
  Widget build(BuildContext context) {
    // Aadhaar gets its own flippable card widget
    if (entry.type == IdentityType.aadhaar) {
      return _AadhaarCardWidget(entry: entry);
    }
    // PAN gets its own realistic card widget
    if (entry.type == IdentityType.pan) {
      return _PanCardWidget(entry: entry);
    }
    // DL gets its own realistic card widget
    if (entry.type == IdentityType.drivingLicense) {
      return _DrivingLicenseCardWidget(entry: entry);
    }
    // Voter ID gets its own flippable card widget
    if (entry.type == IdentityType.voterId) {
      return _VoterIdCardWidget(entry: entry);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: _getGradient(),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(18),
          child: _buildContent(),
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (entry.type) {
      case IdentityType.pan: return LinearGradient(colors: [Color(0xFF1B3A4B), Color(0xFF2E5D7B), Color(0xFF1B3A4B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case IdentityType.aadhaar: return LinearGradient(colors: [Color(0xFF1C1C1C), Color(0xFF2D2D2D), Color(0xFF1C1C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case IdentityType.voterId: return LinearGradient(colors: [Color(0xFF2D1B4E), Color(0xFF4A2D7A), Color(0xFF2D1B4E)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case IdentityType.drivingLicense: return LinearGradient(colors: [Color(0xFF0D3B0D), Color(0xFF1B6B1B), Color(0xFF0D3B0D)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      case IdentityType.other: return LinearGradient(colors: [Color(0xFF333333), Color(0xFF555555), Color(0xFF333333)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }

  Widget _buildContent() {
    switch (entry.type) {
      case IdentityType.pan: return _panCard();
      case IdentityType.aadhaar: return _aadhaarCard();
      case IdentityType.voterId: return _voterCard();
      case IdentityType.drivingLicense: return _dlCard();
      case IdentityType.other: return _otherCard();
    }
  }

  Widget _panCard() {
    // Handled by _PanCardWidget — this shouldn't be called
    return SizedBox();
  }

  Widget _aadhaarCard() {
    // Handled by _AadhaarCardWidget — this shouldn't be called
    return SizedBox();
  }

  Widget _voterCard() {
    // Handled by _VoterIdCardWidget
    return SizedBox();
  }

  Widget _dlCard() {
    // Handled by _DrivingLicenseCardWidget
    return SizedBox();
  }

  Widget _otherCard() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(entry.displayDocName.toUpperCase(), style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1), overflow: TextOverflow.ellipsis)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
          child: Text('DOC', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1))),
      ]),
      Spacer(),
      if (entry.name.isNotEmpty) Text(entry.name.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      if (entry.dateOfBirth != null) Text('DOB: ${entry.dateOfBirth}', style: TextStyle(color: Colors.white60, fontSize: 10)),
      Spacer(),
      Text('Doc No.', style: TextStyle(color: Colors.white38, fontSize: 8)),
      Text(entry.number, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 2, fontFamily: 'monospace')),
    ]);
  }
}

// ─── Voter ID / EPIC (Realistic, Flippable) ───

class _VoterIdCardWidget extends StatefulWidget {
  final IdentityEntry entry;
  const _VoterIdCardWidget({required this.entry});

  @override
  State<_VoterIdCardWidget> createState() => _VoterIdCardWidgetState();
}

class _VoterIdCardWidgetState extends State<_VoterIdCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    if (_showBack) _ctrl.reverse(); else _ctrl.forward();
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1.586,
          child: AnimatedBuilder(
            listenable: _anim,
            builder: (context, _) {
              final angle = _anim.value * math.pi;
              final isBack = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                child: isBack
                    ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _buildBack())
                    : _buildFront(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// EPIC logo — three standing figures
  Widget _epicLogo() {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.person, size: 8, color: Color(0xFF333333)),
            Icon(Icons.person, size: 10, color: Color(0xFF333333)),
            Icon(Icons.person, size: 8, color: Color(0xFF333333)),
          ]),
          Text('EPIC', style: TextStyle(fontSize: 5, fontWeight: FontWeight.w900, color: Color(0xFF333333), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildFront() {
    final e = widget.entry;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Color(0xFFEDF7ED), Color(0xFFE5F3E5), Color(0xFFEFF8EF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFCCDDCC), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Stack(
        children: [
          // Red "EPIC" watermarks scattered
          Positioned(left: 20, top: 50, child: Transform.rotate(angle: -0.15, child: Text('EPIC', style: TextStyle(color: const Color(0xFFCC0000).withValues(alpha: 0.06), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)))),
          Positioned(right: 30, top: 80, child: Transform.rotate(angle: 0.1, child: Text('EPIC', style: TextStyle(color: const Color(0xFFCC0000).withValues(alpha: 0.05), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)))),
          Positioned(left: 60, bottom: 20, child: Text('EPIC', style: TextStyle(color: const Color(0xFFCC0000).withValues(alpha: 0.05), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3))),
          Positioned(right: 10, bottom: 30, child: Text('EPIC', style: TextStyle(color: const Color(0xFFCC0000).withValues(alpha: 0.04), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3))),
          // Green atom symbols
          Positioned(right: 15, bottom: 15, child: Icon(Icons.science_outlined, size: 20, color: const Color(0xFF228B22).withValues(alpha: 0.08))),
          Positioned(left: 10, bottom: 25, child: Icon(Icons.science_outlined, size: 16, color: const Color(0xFF228B22).withValues(alpha: 0.07))),
          Positioned(right: 60, top: 60, child: Icon(Icons.science_outlined, size: 14, color: const Color(0xFF228B22).withValues(alpha: 0.06))),
          // Content
          Column(
            children: [
              // Top red accent
              Container(height: 3, color: const Color(0xFFCC0000)),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ashoka emblem
                    Image.asset('assets/misc/emblem.png', height: 24, fit: BoxFit.contain),
                    SizedBox(width: 6),
                    // Title text
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('भारत निर्वाचन आयोग', style: TextStyle(color: Color(0xFF2E4A2E), fontSize: 7, fontWeight: FontWeight.w700)),
                        Text('ELECTION COMMISSION OF INDIA', style: TextStyle(color: Color(0xFF2E4A2E), fontSize: 6.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        SizedBox(height: 2),
                        Text('Electors Photo Identity Card', style: TextStyle(color: Color(0xFF4A6B4A), fontSize: 6, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic)),
                      ],
                    )),
                    SizedBox(width: 6),
                    Image.asset('assets/misc/Election_Commission_of_India_Logo.png', height: 28, fit: BoxFit.contain),
                  ],
                ),
              ),
              SizedBox(height: 2),
              // EPIC number bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.symmetric(vertical: 3),
                width: double.infinity,
                decoration: BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFAACCAA), width: 0.5), bottom: BorderSide(color: Color(0xFFAACCAA), width: 0.5))),
                child: Center(
                  child: Text(
                    e.number.toUpperCase(),
                    style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3, fontFamily: 'monospace'),
                  ),
                ),
              ),
              // Body: Name + Father's name
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _field('Name', e.name),
                      SizedBox(height: 6),
                      if (e.fatherMotherHusbandName != null && e.fatherMotherHusbandName!.isNotEmpty)
                        _field("Father's / Mother's / Husband's Name", e.fatherMotherHusbandName!),
                    ],
                  ),
                ),
              ),
              // Bottom hint
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
                color: const Color(0xFFDDEEDD),
                child: Row(children: [
                  Spacer(),
                  Text('Tap to flip', style: TextStyle(color: Color(0xFF88AA88), fontSize: 6, fontStyle: FontStyle.italic)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final e = widget.entry;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCDDCC), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Stack(
        children: [
          // Watermark
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Center(child: Text(
              'ELECTION COMMISSION\nOF INDIA',
              textAlign: TextAlign.center,
              style: TextStyle(color: const Color(0xFF2E4A2E).withValues(alpha: 0.04), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, height: 1.2),
            )),
          ),
          // Content
          Column(
            children: [
              Container(height: 3, color: const Color(0xFFCC0000)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // EPIC No
                      Row(children: [
                        Text('EPIC No. : ', style: TextStyle(color: Color(0xFF4A6B4A), fontSize: 7, fontWeight: FontWeight.w600)),
                        Text(e.number.toUpperCase(), style: TextStyle(color: Color(0xFF111111), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1, fontFamily: 'monospace')),
                      ]),
                      Divider(height: 8, thickness: 0.3, color: Color(0xFFBBCCBB)),
                      // Gender + DOB row
                      Row(children: [
                        Expanded(child: _backField('Gender', e.gender ?? '—')),
                        Container(width: 0.5, height: 20, color: const Color(0xFFBBCCBB)),
                        SizedBox(width: 8),
                        Expanded(child: _backField('Date of Birth', e.dateOfBirth ?? '—')),
                      ]),
                      Divider(height: 8, thickness: 0.3, color: Color(0xFFBBCCBB)),
                      // Address
                      Text('Address :', style: TextStyle(color: Color(0xFF4A6B4A), fontSize: 6.5, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text(
                        e.address ?? '—',
                        style: TextStyle(color: Color(0xFF222222), fontSize: 8, height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      // ERO signature line
                      Divider(height: 8, thickness: 0.3, color: Color(0xFFBBCCBB)),
                      Text('Electoral Registration Officer', style: TextStyle(color: Color(0xFF88AA88), fontSize: 5.5, fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      // Note
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBBCCBB), width: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(0xFFF5FAF5),
                        ),
                        child: Text(
                          'Note: This card is not a proof of age except for the purpose of election.',
                          style: TextStyle(color: Color(0xFF6B8B6B), fontSize: 5.5, fontStyle: FontStyle.italic, height: 1.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label :', style: TextStyle(color: Color(0xFF4A6B4A), fontSize: 7, fontWeight: FontWeight.w600)),
      SizedBox(height: 2),
      Text(value, style: TextStyle(color: Color(0xFF111111), fontSize: 11, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
    ]);
  }

  Widget _backField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Color(0xFF4A6B4A), fontSize: 6.5, fontWeight: FontWeight.w600)),
      SizedBox(height: 1),
      Text(value, style: TextStyle(color: Color(0xFF222222), fontSize: 9, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ─── Driving License (Realistic) ───

class _DrivingLicenseCardWidget extends StatelessWidget {
  final IdentityEntry entry;
  const _DrivingLicenseCardWidget({required this.entry});

  static const _lbl = TextStyle(color: Color(0xFF666666), fontSize: 6.5, fontWeight: FontWeight.w600);
  static const _val = TextStyle(color: Color(0xFF111111), fontSize: 9, fontWeight: FontWeight.w700);
  static const _div = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDDDDD), width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              // Top maroon accent bar
              Container(height: 3, color: const Color(0xFF8B0000)),
              // Header: Transport Department
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: const Color(0xFFF5F5F5),
                child: Row(children: [
                  Image.asset('assets/misc/emblem.png', height: 20, fit: BoxFit.contain),
                  SizedBox(width: 6),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('UNION OF INDIA — TRANSPORT DEPARTMENT', style: TextStyle(color: Color(0xFF333333), fontSize: 6.5, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      Text('भारत संघ — परिवहन विभाग', style: TextStyle(color: Color(0xFF555555), fontSize: 6, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF8B0000), width: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text('DRIVING LICENCE', style: TextStyle(color: Color(0xFF8B0000), fontSize: 5.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ]),
              ),
              Divider(height: 1, thickness: 0.5, color: _div),
              // Fields section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DL No
                      _fieldRow('DL No.', entry.number.toUpperCase(), mono: true),
                      Divider(height: 5, thickness: 0.3, color: _div),
                      // NAME + S/o row
                      Row(children: [
                        Expanded(flex: 3, child: _fieldRow('NAME', entry.name.toUpperCase())),
                        if (entry.sonOf != null && entry.sonOf!.isNotEmpty) ...[
                          Container(width: 0.5, height: 18, color: _div),
                          SizedBox(width: 6),
                          Expanded(flex: 2, child: _fieldRow('S/o', entry.sonOf!)),
                        ],
                      ]),
                      Divider(height: 5, thickness: 0.3, color: _div),
                      // D.O.B + VALID TILL
                      Row(children: [
                        Expanded(child: _fieldRow('D.O.B', entry.dateOfBirth ?? '—')),
                        Container(width: 0.5, height: 18, color: _div),
                        SizedBox(width: 6),
                        Expanded(child: _fieldRow('VALID TILL', entry.validThrough ?? '—')),
                      ]),
                      Divider(height: 5, thickness: 0.3, color: _div),
                      // DOI + B.G.
                      Row(children: [
                        Expanded(child: _fieldRow('DOI', entry.doi ?? entry.issueDate ?? '—')),
                        Container(width: 0.5, height: 18, color: _div),
                        SizedBox(width: 6),
                        Expanded(child: _fieldRow('B.G.', entry.bloodGroup ?? '—')),
                      ]),
                      Divider(height: 5, thickness: 0.3, color: _div),
                      // COV + VALID THROUGHOUT
                      Row(children: [
                        Expanded(child: _fieldRow('COV', entry.cov ?? '—')),
                        Container(width: 0.5, height: 18, color: _div),
                        SizedBox(width: 6),
                        Expanded(child: _fieldRow('VALID', entry.dlScope != null ? 'THROUGHOUT ${entry.dlScope!.toUpperCase()}' : 'THROUGHOUT INDIA')),
                      ]),
                      Spacer(),
                      // Bottom: FORM-7 + Sign
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 50, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _div, width: 0.5))), child: SizedBox(height: 8)),
                          Text('Sign. Of Holder', style: TextStyle(color: Color(0xFF888888), fontSize: 5)),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(width: 60, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _div, width: 0.5))), child: SizedBox(height: 8)),
                          Text('Licensing Authority', style: TextStyle(color: Color(0xFF888888), fontSize: 5)),
                        ]),
                        Text('FORM - 7', style: TextStyle(color: const Color(0xFF999999), fontSize: 5.5, fontWeight: FontWeight.w600, letterSpacing: 1)),
                      ]),
                    ],
                  ),
                ),
              ),
              // Address section — bigger, multi-line
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                color: const Color(0xFFF0F0F0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ADDRESS', style: TextStyle(color: Color(0xFF666666), fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  SizedBox(height: 2),
                  Text(
                    entry.address ?? '—',
                    style: TextStyle(color: Color(0xFF222222), fontSize: 7.5, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldRow(String label, String value, {bool mono = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: _lbl),
      SizedBox(height: 1),
      Text(value, style: mono ? _val.copyWith(letterSpacing: 1.5, fontFamily: 'monospace', fontSize: 8.5) : _val, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
  }
}

// ─── PAN Card (Realistic) ───

class _PanCardWidget extends StatelessWidget {
  final IdentityEntry entry;
  const _PanCardWidget({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: AspectRatio(
        aspectRatio: 1.586,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Color(0xFFE8F4FD), Color(0xFFB8E0F7), Color(0xFF7CC8EE), Color(0xFFAEDBF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Stack(
            children: [
              // Subtle watermark circle in background
              Positioned(
                right: -20, top: 20,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ashoka emblem
                        Image.asset('assets/misc/emblem.png', height: 26, fit: BoxFit.contain),
                        SizedBox(width: 8),
                        // Hindi + English titles
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('आयकर विभाग', style: TextStyle(color: Color(0xFF1A3C5E), fontSize: 10, fontWeight: FontWeight.w800)),
                              Text('INCOME TAX DEPARTMENT', style: TextStyle(color: Color(0xFF2C5E8A), fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                            ],
                          ),
                        ),
                        // GOVT OF INDIA text (right side, vertical-style)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('भारत सरकार', style: TextStyle(color: Color(0xFF1A3C5E), fontSize: 10, fontWeight: FontWeight.w800)),
                            Text('GOVT. OF INDIA', style: TextStyle(color: Color(0xFF2C5E8A), fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    // Subtitle
                    Row(children: [
                      Expanded(child: Text(
                        'स्थायी लेखा संख्या कार्ड / Permanent Account Number Card',
                        style: TextStyle(color: Color(0xFF3A6D99), fontSize: 6, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                    Divider(height: 8, thickness: 0.5, color: Color(0xFF8ABBD9)),
                    // PAN Number
                    Center(
                      child: Text(
                        entry.number.toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFF0D2137),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Spacer(),
                    // Name
                    _field('नाम / Name', entry.name.toUpperCase()),
                    SizedBox(height: 4),
                    // Father's name
                    if (entry.fatherMotherName != null && entry.fatherMotherName!.isNotEmpty)
                      _field("पिता का नाम / Father's Name", entry.fatherMotherName!.toUpperCase()),
                    Spacer(),
                    // Bottom row: DOB + Signature placeholder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (entry.dateOfBirth != null)
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('जन्म की तारीख', style: TextStyle(color: Color(0xFF3A6D99), fontSize: 6)),
                            Text('Date of Birth', style: TextStyle(color: Color(0xFF3A6D99), fontSize: 5)),
                            Text(entry.dateOfBirth!, style: TextStyle(color: Color(0xFF0D2137), fontSize: 10, fontWeight: FontWeight.w700)),
                          ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Container(
                            width: 50,
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF8ABBD9), width: 0.5))),
                            child: SizedBox(height: 12),
                          ),
                          Text('हस्ताक्षर / Signature', style: TextStyle(color: Color(0xFF3A6D99), fontSize: 5)),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Color(0xFF3A6D99), fontSize: 6, fontWeight: FontWeight.w500)),
      SizedBox(height: 1),
      Text(value, style: TextStyle(color: Color(0xFF0D2137), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3), overflow: TextOverflow.ellipsis),
    ]);
  }
}

// ─── Aadhaar Card (Realistic, Flippable) ───

class _AadhaarCardWidget extends StatefulWidget {
  final IdentityEntry entry;
  const _AadhaarCardWidget({required this.entry});

  @override
  State<_AadhaarCardWidget> createState() => _AadhaarCardWidgetState();
}

class _AadhaarCardWidgetState extends State<_AadhaarCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    if (_showBack) _ctrl.reverse(); else _ctrl.forward();
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1.586,
          child: AnimatedBuilder(
            listenable: _anim,
            builder: (context, _) {
              final angle = _anim.value * math.pi;
              final isBack = angle > math.pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                child: isBack
                    ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: _buildBack())
                    : _buildFront(),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Indian tricolor strip painted across the top
  Widget _tricolorBand() {
    return SizedBox(
      height: 18,
      child: Row(children: [
        Expanded(flex: 1, child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFFFF9933),
              const Color(0xFFFF9933).withValues(alpha: 0.6),
              const Color(0xFFFF9933).withValues(alpha: 0.2),
            ]),
          ),
        )),
        Expanded(flex: 1, child: Container(color: Colors.white)),
        Expanded(flex: 1, child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF138808).withValues(alpha: 0.2),
              const Color(0xFF138808).withValues(alpha: 0.6),
              const Color(0xFF138808),
            ]),
          ),
        )),
      ]),
    );
  }

  /// UIDAI / Aadhaar logo from asset
  Widget _uidaiLogo({double size = 28}) {
    return Image.asset('assets/misc/Aadhaar.png', height: size, fit: BoxFit.contain);
  }

  /// Ashoka emblem from asset
  Widget _ashokaEmblem({double size = 22}) {
    return Image.asset('assets/misc/emblem.png', height: size, fit: BoxFit.contain);
  }

  Widget _buildFront() {
    final e = widget.entry;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(children: [
        // Tricolor band
        _tricolorBand(),
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Row(children: [
            _ashokaEmblem(size: 18),
            SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('भारत सरकार', style: TextStyle(color: Color(0xFF333333), fontSize: 7, fontWeight: FontWeight.w700)),
              Text('Government of India', style: TextStyle(color: Color(0xFF555555), fontSize: 6, fontWeight: FontWeight.w500)),
            ])),
            Column(children: [
              Text('आधार', style: TextStyle(color: Color(0xFFE03E2D), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text('AADHAAR', style: TextStyle(color: Color(0xFF555555), fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 2)),
            ]),
            SizedBox(width: 6),
            _uidaiLogo(size: 24),
          ]),
        ),
        Divider(height: 6, thickness: 0.5, color: Color(0xFFDDDDDD)),
        // Body — centered details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(e.name, style: TextStyle(color: Color(0xFF222222), fontSize: 13, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              if (e.dateOfBirth != null)
                _infoLine('DOB', e.dateOfBirth!),
              if (e.gender != null)
                _infoLine('Gender', e.gender!),
            ]),
          ),
        ),
        // Aadhaar number
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: Text(
              e.formattedAadhaar,
              style: TextStyle(color: Color(0xFF222222), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 4, fontFamily: 'monospace'),
            ),
          ),
        ),
        // Bottom strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          color: const Color(0xFFF5F5F5),
          child: Row(children: [
            Icon(Icons.language, size: 8, color: Color(0xFF999999)),
            SizedBox(width: 3),
            Text('www.uidai.gov.in', style: TextStyle(color: Color(0xFF888888), fontSize: 6, letterSpacing: 0.3)),
            Spacer(),
            Icon(Icons.phone, size: 7, color: Color(0xFF999999)),
            SizedBox(width: 2),
            Text('1947', style: TextStyle(color: Color(0xFF888888), fontSize: 6)),
            SizedBox(width: 8),
            Icon(Icons.email_outlined, size: 7, color: Color(0xFF999999)),
            SizedBox(width: 2),
            Text('help@uidai.gov.in', style: TextStyle(color: Color(0xFF888888), fontSize: 6)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBack() {
    final e = widget.entry;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(children: [
        // Tricolor band
        _tricolorBand(),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
          child: Row(children: [
            _ashokaEmblem(size: 16),
            SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('भारत सरकार | Government of India', style: TextStyle(color: Color(0xFF555555), fontSize: 6, fontWeight: FontWeight.w600)),
              Text('Unique Identification Authority of India', style: TextStyle(color: Color(0xFF777777), fontSize: 5.5)),
            ])),
            _uidaiLogo(size: 20),
          ]),
        ),
        Divider(height: 8, thickness: 0.5, color: Color(0xFFDDDDDD)),
        // Address & S/o section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              if (e.sonDaughterOf != null && e.sonDaughterOf!.isNotEmpty) ...[
                _infoLine('S/o / D/o / W/o', e.sonDaughterOf!),
                SizedBox(height: 4),
              ],
              if (e.address != null && e.address!.isNotEmpty) ...[
                Text('Address:', style: TextStyle(color: Color(0xFF888888), fontSize: 7, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(e.address!, style: TextStyle(color: Color(0xFF333333), fontSize: 9, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
              if ((e.sonDaughterOf == null || e.sonDaughterOf!.isEmpty) && (e.address == null || e.address!.isEmpty))
                Center(child: Text('No address or details added', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 9, fontStyle: FontStyle.italic))),
            ]),
          ),
        ),
        // Aadhaar number (also on back)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: Text(
              e.formattedAadhaar,
              style: TextStyle(color: Color(0xFF222222), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 4, fontFamily: 'monospace'),
            ),
          ),
        ),
        // Bottom strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          color: const Color(0xFFF5F5F5),
          child: Row(children: [
            Icon(Icons.language, size: 8, color: Color(0xFF999999)),
            SizedBox(width: 3),
            Text('www.uidai.gov.in', style: TextStyle(color: Color(0xFF888888), fontSize: 6)),
            Spacer(),
            Text('Tap to flip', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 6, fontStyle: FontStyle.italic)),
          ]),
        ),
      ]),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Text('$label: ', style: TextStyle(color: Color(0xFF888888), fontSize: 8, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: TextStyle(color: Color(0xFF333333), fontSize: 9, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

/// Paints a simplified UIDAI fingerprint logo with rainbow concentric arcs
class _UidaiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final colors = [
      const Color(0xFFE03E2D), // red
      const Color(0xFFFF9933), // saffron
      const Color(0xFFFFC107), // yellow
      const Color(0xFF4CAF50), // green
      const Color(0xFF2196F3), // blue
      const Color(0xFF673AB7), // purple
    ];
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final radius = (i + 2) * size.width * 0.065;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.85,
        math.pi * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper for flip animation
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;
  AnimatedBuilder({super.key, required super.listenable, required this.builder, this.child});
  @override
  Widget build(BuildContext context) => builder(context, child);
}

// ─── Detail Sheet ───

class _DetailSheet extends StatefulWidget {
  final IdentityEntry entry;
  const _DetailSheet({required this.entry});
  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _showNum = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.of(context).border, borderRadius: BorderRadius.circular(2)))),
          SizedBox(height: 20),
          Row(children: [
            Text(e.type.icon, style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(child: Text(e.displayDocName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.of(context).textPrimary))),
          ]),
          SizedBox(height: 20),
          if (e.name.isNotEmpty) ...[_row('Name', e.name), SizedBox(height: 10)],
          _row('Number', _showNum ? (e.type == IdentityType.aadhaar ? e.formattedAadhaar : e.number) : e.maskedNumber,
            trailing: IconButton(icon: Icon(_showNum ? Icons.visibility_off : Icons.visibility, size: 20, color: AppColors.of(context).textSecondary), onPressed: () => setState(() => _showNum = !_showNum)),
            copyValue: e.number),
          if (e.dateOfBirth != null) ...[SizedBox(height: 10), _row('Date of Birth', e.dateOfBirth!)],
          if (e.gender != null) ...[SizedBox(height: 10), _row('Gender', e.gender!)],
          if (e.fatherMotherName != null) ...[SizedBox(height: 10), _row("Father's / Mother's Name", e.fatherMotherName!)],
          if (e.sonDaughterOf != null) ...[SizedBox(height: 10), _row('S/o, D/o, W/o', e.sonDaughterOf!)],
          if (e.fatherMotherHusbandName != null) ...[SizedBox(height: 10), _row("Father/Mother/Husband", e.fatherMotherHusbandName!)],
          if (e.sonOf != null) ...[SizedBox(height: 10), _row('S/o, D/o, W/o', e.sonOf!)],
          if (e.issueDate != null) ...[SizedBox(height: 10), _row('Date of Issue', e.issueDate!)],
          if (e.validThrough != null) ...[SizedBox(height: 10), _row('Valid Through', e.validThrough!)],
          if (e.doi != null) ...[SizedBox(height: 10), _row('DOI (Initial Issue)', e.doi!)],
          if (e.bloodGroup != null) ...[SizedBox(height: 10), _row('Blood Group', e.bloodGroup!)],
          if (e.cov != null) ...[SizedBox(height: 10), _row('Class of Vehicle', e.cov!)],
          if (e.dlScope != null) ...[SizedBox(height: 10), _row('Scope', e.dlScope!)],
          if (e.address != null) ...[SizedBox(height: 10), _row('Address', e.address!)],
          if (e.notes != null) ...[SizedBox(height: 10), _row('Notes', e.notes!)],
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Widget? trailing, String? copyValue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.of(context).backgroundDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.of(context).border)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.of(context).textMuted)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, color: AppColors.of(context).textPrimary)),
        ])),
        if (trailing != null) trailing,
        if (copyValue != null)
          IconButton(icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.accentCyan), onPressed: () {
            ClipboardService.copyWithAutoClear(copyValue);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied — auto-clears in 15s')));
          }),
      ]),
    );
  }
}
