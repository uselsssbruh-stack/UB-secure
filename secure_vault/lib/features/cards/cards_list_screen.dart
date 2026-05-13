import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/clipboard_service.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/credit_card_widget.dart';
import 'card_form_screen.dart';

class CardsListScreen extends ConsumerWidget {
  CardsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider).vault;
    final cards = vault?.cards ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardFormScreen())),
          ),
        ],
      ),
      body: cards.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: CreditCardWidget(
                          cardNumber: card.maskedNumber,
                          cardholderName: card.cardholderName,
                          expiryDate: card.expiryDate,
                          cvv: card.cvv,
                          cardType: card.cardType.name,
                          provider: card.provider,
                          issuingBank: card.displayBank,
                          scope: card.scope,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _chip(context, 'Copy Number', Icons.copy_rounded, () {
                            ClipboardService.copyWithAutoClear(card.cardNumber);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Card number copied — auto-clears in 15s')),
                            );
                          }),
                          SizedBox(width: 8),
                          _chip(context, 'Edit', Icons.edit_rounded, () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CardFormScreen(entry: card)));
                          }),
                          SizedBox(width: 8),
                          _chip(context, 'Delete', Icons.delete_outline, () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Delete Card'),
                                content: Text('This cannot be undone.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.accentRed), child: Text('Delete')),
                                ],
                              ),
                            );
                            if (ok == true) ref.read(vaultProvider.notifier).deleteCard(card.id);
                          }, danger: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: cards.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardFormScreen())),
              child: Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.cardColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.credit_card_rounded, size: 40, color: AppColors.cardColor),
          ),
          SizedBox(height: 20),
          Text('No Cards Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
          SizedBox(height: 8),
          Text('Add your first payment card', style: TextStyle(color: AppColors.of(context).textMuted)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardFormScreen())),
            icon: Icon(Icons.add_rounded),
            label: Text('Add Card'),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    return Material(
      color: danger ? AppColors.accentRed.withValues(alpha: 0.1) : AppColors.of(context).cardDark,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: danger ? AppColors.accentRed : AppColors.of(context).textSecondary),
              SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: danger ? AppColors.accentRed : AppColors.of(context).textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
