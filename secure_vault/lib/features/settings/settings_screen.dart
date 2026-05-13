import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Appearance'),
          SizedBox(height: 16),
          _buildThemeToggle(context, ref, themeMode),
          
          SizedBox(height: 48),
          
          _buildSectionHeader('Account Management'),
          SizedBox(height: 16),
          _buildLogoutButton(context, ref),
          
          SizedBox(height: 48),
          
          _buildSectionHeader('Danger Zone', color: AppColors.accentRed),
          SizedBox(height: 16),
          _buildClearDataButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = AppColors.accentCyan}) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: color),
        SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        children: ThemeMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return InkWell(
            onTap: () {
              ref.read(themeProvider.notifier).setTheme(mode);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    mode == ThemeMode.system
                        ? Icons.brightness_auto_rounded
                        : mode == ThemeMode.light
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                    color: isSelected ? AppColors.accentCyan : AppColors.of(context).textSecondary,
                  ),
                  SizedBox(width: 16),
                  Text(
                    mode.name[0].toUpperCase() + mode.name.substring(1),
                    style: TextStyle(
                      color: isSelected ? AppColors.of(context).textPrimary : AppColors.of(context).textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                  Spacer(),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: AppColors.accentCyan),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: InkWell(
        onTap: () async {
          // Lock local vault so it doesn't stay in memory
          ref.read(vaultProvider.notifier).lockVault();
          // Sign out of Firebase
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded, color: AppColors.accentPurple, size: 20),
              ),
              SizedBox(width: 16),
              Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearDataButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          _showClearDataDialog(context, ref);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_forever_rounded, color: AppColors.accentRed, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear Vault Data',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Permanently delete your local vault and Firebase cloud backup',
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontSize: 12,
                      ),
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

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
            SizedBox(width: 8),
            Text('Are you absolutely sure?', style: TextStyle(color: AppColors.accentRed)),
          ],
        ),
        content: Text(
          'This will permanently delete your entire vault from your device AND delete your backup from the Firebase Cloud.\n\nThis action cannot be undone.',
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.of(context).textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Delete vault (local and cloud)
              await ref.read(vaultProvider.notifier).deleteVault();
              
              if (context.mounted) {
                // Return to home
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
