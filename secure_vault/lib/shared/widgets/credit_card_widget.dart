import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/card_entry.dart';

// ─── Logo Asset Helpers ───

String? _bankLogoPath(String? bankName) {
  if (bankName == null || bankName.isEmpty) return null;
  const map = {
    'State Bank of India (SBI)': 'assets/banks/sbi.png',
    'HDFC Bank': 'assets/banks/hdfc.png',
    'ICICI Bank': 'assets/banks/icici.png',
    'Axis Bank': 'assets/banks/axis.png',
    'Kotak Mahindra Bank': 'assets/banks/kotak.png',
    'Punjab National Bank (PNB)': 'assets/banks/pnb.png',
    'Bank of Baroda (BOB)': 'assets/banks/bank of borada.png',
    'Canara Bank': 'assets/banks/canara.png',
    'Union Bank of India': 'assets/banks/union.png',
    'IndusInd Bank': 'assets/banks/indusind.png',
    'Yes Bank': 'assets/banks/yes bank.png',
    'IDBI Bank': 'assets/banks/idbi.png',
    'Bank of India (BOI)': 'assets/banks/bank-of-india.png',
    'Central Bank of India': 'assets/banks/central bank of india.png',
    'Indian Bank': 'assets/banks/indian bank.png',
    'Federal Bank': 'assets/banks/federal.png',
    'South Indian Bank': 'assets/banks/south indian bank.png',
    'RBL Bank': 'assets/banks/rbl bank.png',
    'Bandhan Bank': 'assets/banks/bandhan.png',
    'IDFC First Bank': 'assets/banks/idfc.png',
    'Citibank': 'assets/banks/citibank.png',
    'HSBC': 'assets/banks/hsbc.png',
    'Standard Chartered': 'assets/banks/standard-chartered.png',
    'Deutsche Bank': 'assets/banks/deutsche.png',
    'Barclays': 'assets/banks/barclays.png',
    'Karnataka Bank': 'assets/banks/karnataka.png',
  };
  return map[bankName];
}

String? _providerLogoPath(CardProvider provider) {
  const map = {
    CardProvider.visa: 'assets/providers/visa.png',
    CardProvider.mastercard: 'assets/providers/Mastercard.png',
    CardProvider.rupay: 'assets/providers/rupay.png',
    CardProvider.amex: 'assets/providers/Amex.png',
    CardProvider.discover: 'assets/providers/discover.png',
    CardProvider.dinersClub: 'assets/providers/dinerclub.png',
    CardProvider.maestro: 'assets/providers/maestro.png',
  };
  return map[provider];
}

/// A realistic credit/debit card widget with proper aspect ratio and flip animation.
class CreditCardWidget extends StatefulWidget {
  final String cardNumber;
  final String cardholderName;
  final String expiryDate;
  final String cvv;
  final String cardType;
  final CardProvider provider;
  final String? issuingBank;
  final CardScope? scope;
  final bool showBack;
  final VoidCallback? onTap;

  CreditCardWidget({
    super.key,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.cvv,
    required this.cardType,
    this.provider = CardProvider.visa,
    this.issuingBank,
    this.scope,
    this.showBack = false,
    this.onTap,
  });

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<CreditCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _showBack = widget.showBack;
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));
    if (_showBack) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showBack) { _controller.reverse(); } else { _controller.forward(); }
    setState(() => _showBack = !_showBack);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: _AnimBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
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
    );
  }

  /// Curated premium card gradients — real bank card colors only.
  /// Each card gets a unique pick based on bank + provider + type hash.
  static const _cardPalette = [
    // 0: Matte Black
    LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF141414)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 1: Midnight Navy
    LinearGradient(colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0A1520)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 2: Gunmetal Steel
    LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF3D5266), Color(0xFF243342)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 3: Deep Burgundy
    LinearGradient(colors: [Color(0xFF3B1520), Color(0xFF52202E), Color(0xFF2E1018)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 4: Royal Indigo
    LinearGradient(colors: [Color(0xFF1A1040), Color(0xFF2A1B5C), Color(0xFF150D35)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 5: Dark Slate Blue
    LinearGradient(colors: [Color(0xFF1E2A3A), Color(0xFF2C3E52), Color(0xFF182430)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 6: Obsidian
    LinearGradient(colors: [Color(0xFF111111), Color(0xFF1E1E1E), Color(0xFF0A0A0A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 7: Deep Plum
    LinearGradient(colors: [Color(0xFF2A1230), Color(0xFF3E1C48), Color(0xFF220E28)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 8: Charcoal Bronze
    LinearGradient(colors: [Color(0xFF2C2418), Color(0xFF3E3425), Color(0xFF241E14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 9: Titanium Dark
    LinearGradient(colors: [Color(0xFF262B30), Color(0xFF363D44), Color(0xFF1E2226)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 10: Dark Sapphire
    LinearGradient(colors: [Color(0xFF0C1445), Color(0xFF141E5C), Color(0xFF0A1038)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    // 11: Espresso
    LinearGradient(colors: [Color(0xFF2C1810), Color(0xFF3E2518), Color(0xFF24140C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  ];

  LinearGradient _getCardGradient() {
    final key = '${widget.issuingBank ?? ''}_${widget.provider.name}_${widget.cardType}';
    int hash = 0;
    for (int i = 0; i < key.length; i++) {
      hash = key.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return _cardPalette[hash.abs() % _cardPalette.length];
  }

  /// Provider logo from asset image
  Widget _buildProviderLogo({double height = 40}) {
    final path = _providerLogoPath(widget.provider);
    if (path != null) {
      return SizedBox(
        height: height,
        child: Image.asset(path, height: height, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fallbackProviderText()),
      );
    }
    return _fallbackProviderText();
  }

  Widget _fallbackProviderText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(widget.provider == CardProvider.other ? 'CARD' : widget.provider.label.toUpperCase(),
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
    );
  }

  /// Bank logo from asset image
  Widget _buildBankLogo({double height = 44}) {
    final path = _bankLogoPath(widget.issuingBank);
    if (path != null) {
      return SizedBox(
        height: height,
        child: Image.asset(path, height: height, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fallbackBankText()),
      );
    }
    return _fallbackBankText();
  }

  Widget _fallbackBankText() {
    if (widget.issuingBank != null && widget.issuingBank!.isNotEmpty) {
      return Text(widget.issuingBank!.toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
          overflow: TextOverflow.ellipsis);
    }
    return SizedBox.shrink();
  }

  Widget _buildFront() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _getCardGradient(),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: provider logo (right)
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Bank logo (larger, prominent)
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildBankLogo(height: 44),
                if (widget.scope != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(widget.scope!.label.toUpperCase(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 7, letterSpacing: 1.5)),
                  ),
              ]),
            ),
            _buildProviderLogo(height: 40),
          ]),
          SizedBox(height: 6),
          // Chip (smaller, beside card)
          Container(
            width: 36, height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: LinearGradient(colors: [Color(0xFFDBA800), Color(0xFFF5D75E), Color(0xFFDBA800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Center(child: Icon(Icons.memory, size: 14, color: Color(0xFF8B6914))),
          ),
          Spacer(),
          // Card number
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCardNumber(widget.cardNumber),
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w500, letterSpacing: 3, fontFamily: 'monospace'),
            ),
          ),
          Spacer(),
          // Bottom row
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CARDHOLDER', style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: 1)),
                SizedBox(height: 2),
                Text(widget.cardholderName.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('EXPIRES', style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: 1)),
              SizedBox(height: 2),
              Text(widget.expiryDate, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ]),
            SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(widget.cardType.toUpperCase(),
                  style: TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF0D1117)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(children: [
        SizedBox(height: 20),
        Container(width: double.infinity, height: 36, color: const Color(0xFF2A2A2A)),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 32,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 12),
                child: Text(widget.cvv,
                    style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, letterSpacing: 3)),
              ),
            ),
          ]),
        ),
        SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
              alignment: Alignment.centerRight,
              child: Text('CVV', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, letterSpacing: 1))),
        ),
        Spacer(),
        // Bottom: Bank name (left) + Provider logo (right)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bank name text (left)
              Expanded(
                child: (widget.issuingBank != null && widget.issuingBank!.isNotEmpty && widget.issuingBank != 'Other')
                    ? Text(
                        widget.issuingBank!.toUpperCase(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis,
                      )
                    : SizedBox.shrink(),
              ),
              // Provider logo (right)
              _buildProviderLogo(height: 20),
            ],
          ),
        ),
      ]),
    );
  }

  String _formatCardNumber(String number) {
    final clean = number.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }
}

class _AnimBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  const _AnimBuilder({required this.animation, required this.builder});

  @override
  Widget build(BuildContext context) => _AnimBuilderInner(listenable: animation, builder: builder);
}

class _AnimBuilderInner extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  const _AnimBuilderInner({required super.listenable, required this.builder});

  @override
  Widget build(BuildContext context) => builder(context, null);
}
