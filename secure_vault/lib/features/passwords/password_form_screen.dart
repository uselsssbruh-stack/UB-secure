import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto_service.dart';
import '../../models/password_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';

class PasswordFormScreen extends ConsumerStatefulWidget {
  final PasswordEntry? entry;
  PasswordFormScreen({super.key, this.entry});

  @override
  ConsumerState<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends ConsumerState<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _urlController;
  late TextEditingController _notesController;
  bool _obscurePassword = true;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _usernameController = TextEditingController(text: widget.entry?.username ?? '');
    _passwordController = TextEditingController(text: widget.entry?.password ?? '');
    _urlController = TextEditingController(text: widget.entry?.url ?? '');
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final password = CryptoService.generatePassword(length: 20);
    _passwordController.text = password;
    setState(() => _obscurePassword = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final updated = widget.entry!.copyWith(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      await ref.read(vaultProvider.notifier).updatePassword(updated);
    } else {
      final entry = PasswordEntry(
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      await ref.read(vaultProvider.notifier).addPassword(entry);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Password' : 'Add Password'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _titleController,
                label: 'Title',
                icon: Icons.label_outline,
                validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
              ),
              SizedBox(height: 16),
              _buildField(
                controller: _usernameController,
                label: 'Username / Email',
                icon: Icons.person_outline,
                validator: (v) => v?.isEmpty == true ? 'Username is required' : null,
              ),
              SizedBox(height: 16),
              // Password field with generate button
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: AppColors.of(context).textPrimary),
                validator: (v) => v?.isEmpty == true ? 'Password is required' : null,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.accentCyan),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.of(context).textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      IconButton(
                        icon: Icon(Icons.auto_awesome, color: AppColors.accentGold, size: 20),
                        tooltip: 'Generate Password',
                        onPressed: _generatePassword,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildField(
                controller: _urlController,
                label: 'URL (optional)',
                icon: Icons.link,
              ),
              SizedBox(height: 16),
              _buildField(
                controller: _notesController,
                label: 'Notes (optional)',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Update Password' : 'Save Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.of(context).textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.accentCyan),
      ),
    );
  }
}
