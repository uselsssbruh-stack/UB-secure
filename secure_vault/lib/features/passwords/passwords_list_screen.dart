import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/clipboard_service.dart';
import '../../models/password_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'password_form_screen.dart';

class PasswordsListScreen extends ConsumerWidget {
  PasswordsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider).vault;
    final passwords = vault?.passwords ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Passwords'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PasswordFormScreen()),
            ),
          ),
        ],
      ),
      body: passwords.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: passwords.length,
              itemBuilder: (context, index) {
                final entry = passwords[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PasswordCard(entry: entry),
                );
              },
            ),
      floatingActionButton: passwords.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PasswordFormScreen()),
              ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.passwordColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.key_rounded, size: 40, color: AppColors.passwordColor),
          ),
          SizedBox(height: 20),
          Text(
            'No Passwords Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first password entry',
            style: TextStyle(color: AppColors.of(context).textMuted),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PasswordFormScreen()),
            ),
            icon: Icon(Icons.add_rounded),
            label: Text('Add Password'),
          ),
        ],
      ),
    );
  }
}

// ─── Clean password card ───

class _PasswordCard extends ConsumerStatefulWidget {
  final PasswordEntry entry;
  const _PasswordCard({required this.entry});

  @override
  ConsumerState<_PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends ConsumerState<_PasswordCard> {
  bool _showPassword = false;

  void _copy(String value, String label) {
    ClipboardService.copyWithAutoClear(value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied — auto-clears in 15s'), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _launchUrl(String url) async {
    String urlStr = url;
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Could not launch
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.of(context).cardDark : AppColors.of(context).surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.of(context).border.withValues(alpha: 0.5) : AppColors.of(context).border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top: icon + title + url + menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key icon
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.key_rounded, size: 20, color: AppColors.accentCyan),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: TextStyle(
                        color: AppColors.of(context).textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    if (e.url != null && e.url!.isNotEmpty) ...[
                      SizedBox(height: 2),
                      InkWell(
                        onTap: () => _launchUrl(e.url!),
                        child: Text(
                          e.url!.replaceAll(RegExp(r'https?://'), '').replaceAll(RegExp(r'/$'), ''),
                          style: TextStyle(
                            color: AppColors.accentCyan,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accentCyan.withValues(alpha: 0.5),
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: AppColors.of(context).textMuted, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: isDark ? AppColors.of(context).surfaceLight : AppColors.of(context).surfaceDark,
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: AppColors.of(context).textPrimary))),
                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.accentRed))),
                ],
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PasswordFormScreen(entry: e)));
                  } else if (value == 'delete') {
                    final confirm = await _confirmDelete(context);
                    if (confirm) ref.read(vaultProvider.notifier).deletePassword(e.id);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 14),
          // Username row
          _buildField(
            label: 'USERNAME',
            value: e.username,
            actions: [
              _buildActionButton(
                icon: Icons.copy_rounded,
                onTap: () => _copy(e.username, 'Username'),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Password row
          _buildField(
            label: 'PASSWORD',
            value: _showPassword ? e.password : '••••••••••••',
            isMonospace: _showPassword,
            actions: [
              _buildActionButton(
                icon: _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                onTap: () => setState(() => _showPassword = !_showPassword),
              ),
              SizedBox(width: 6),
              _buildActionButton(
                icon: Icons.copy_rounded,
                onTap: () => _copy(e.password, 'Password'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    bool isMonospace = false,
    required List<Widget> actions,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.of(context).textMuted,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: isMonospace ? 'monospace' : null,
                  letterSpacing: isMonospace ? 0.5 : 0,
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.of(context).textSecondary),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Password'),
            content: Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
                child: Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
