import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/category_card.dart';
import '../passwords/passwords_list_screen.dart';
import '../cards/cards_list_screen.dart';
import '../identities/identities_list_screen.dart';
import '../notes/notes_list_screen.dart';
import '../files/files_list_screen.dart';
import '../unlock/unlock_screen.dart';

import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Auto-lock timer
  DateTime _lastActivity = DateTime.now();

  void _resetActivity() {
    _lastActivity = DateTime.now();
  }

  void _lock() {
    ref.read(vaultProvider.notifier).lockVault();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UnlockScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultProvider);
    final vault = vaultState.vault;

    if (vault == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: _resetActivity,
      onPanDown: (_) => _resetActivity(),
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      // App Logo
                      Image.asset(
                        'assets/logo/UBsecureLogoWithTitle.png',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      Spacer(),
                      // Settings button
                      _buildActionButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        onPressed: () => _navigate(SettingsScreen()),
                      ),
                      SizedBox(width: 12),
                      // Lock button
                      _buildActionButton(
                        icon: Icons.lock_rounded,
                        tooltip: 'Lock Vault',
                        onPressed: _lock,
                      ),
                    ],
                  ),
                ),
              ),

              // Stats bar
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentCyan.withValues(alpha: 0.08),
                        AppColors.accentPurple.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Total Items', '${vault.totalItems}', AppColors.accentCyan),
                      Container(width: 1, height: 36, color: AppColors.of(context).border),
                      _buildStat('Passwords', '${vault.passwords.length}', AppColors.passwordColor),
                      Container(width: 1, height: 36, color: AppColors.of(context).border),
                      _buildStat('Cards', '${vault.cards.length}', AppColors.cardColor),
                      Container(width: 1, height: 36, color: AppColors.of(context).border),
                      _buildStat('Files', '${vault.files.length}', AppColors.fileColor),
                    ],
                  ),
                ),
              ),

              // Section title
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                ),
              ),

              // Category grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    CategoryCard(
                      icon: Icons.key_rounded,
                      title: 'Passwords',
                      count: vault.passwords.length,
                      accentColor: AppColors.passwordColor,
                      onTap: () => _navigate(PasswordsListScreen()),
                    ),
                    CategoryCard(
                      icon: Icons.credit_card_rounded,
                      title: 'Cards',
                      count: vault.cards.length,
                      accentColor: AppColors.cardColor,
                      onTap: () => _navigate(CardsListScreen()),
                    ),
                    CategoryCard(
                      icon: Icons.badge_rounded,
                      title: 'Identities',
                      count: vault.identities.length,
                      accentColor: AppColors.identityColor,
                      onTap: () => _navigate(IdentitiesListScreen()),
                    ),
                    CategoryCard(
                      icon: Icons.note_rounded,
                      title: 'Notes',
                      count: vault.notes.length,
                      accentColor: AppColors.noteColor,
                      onTap: () => _navigate(NotesListScreen()),
                    ),
                    CategoryCard(
                      icon: Icons.folder_rounded,
                      title: 'Files',
                      count: vault.files.length,
                      accentColor: AppColors.fileColor,
                      onTap: () => _navigate(FilesListScreen()),
                    ),
                  ]),
                ),
              ),

              // Recent items section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                  child: Row(
                    children: [
                      Text(
                        'Recent Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Last updated ${_formatTime(vault.updatedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.of(context).textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent items list
              if (vault.totalItems == 0)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.of(context).border),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 48,
                          color: AppColors.of(context).textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your vault is empty',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start by adding passwords, cards, or notes',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.of(context).textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (vault.passwords.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final items = vault.passwords
                          .toList()
                        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                      if (index >= items.length || index >= 5) return null;
                      final item = items[index];
                      return _buildRecentItem(
                        icon: Icons.key_rounded,
                        color: AppColors.passwordColor,
                        title: item.title,
                        subtitle: item.username,
                        time: item.updatedAt,
                        onTap: () => _navigate(PasswordsListScreen()),
                      );
                    },
                    childCount: vault.passwords.length.clamp(0, 5),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.of(context).textSecondary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.of(context).textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Material(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.of(context).textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.of(context).textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
