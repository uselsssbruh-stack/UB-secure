import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/note_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';

class NoteFormScreen extends ConsumerStatefulWidget {
  final NoteEntry? entry;
  NoteFormScreen({super.key, this.entry});

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _contentController = TextEditingController(text: widget.entry?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isEditing) {
      final updated = widget.entry!.copyWith(title: _titleController.text.trim(), content: _contentController.text.trim());
      await ref.read(vaultProvider.notifier).updateNote(updated);
    } else {
      final entry = NoteEntry(title: _titleController.text.trim(), content: _contentController.text.trim());
      await ref.read(vaultProvider.notifier).addNote(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Note' : 'Add Note'),
        actions: [TextButton(onPressed: _save, child: Text('Save', style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.w600)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                validator: (v) => (v?.isEmpty ?? true) ? 'Title is required' : null,
                decoration: InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title, color: AppColors.accentGreen)),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                style: TextStyle(color: AppColors.of(context).textPrimary, fontSize: 15, height: 1.6),
                validator: (v) => (v?.isEmpty ?? true) ? 'Content is required' : null,
                maxLines: 15,
                minLines: 8,
                decoration: InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 160), child: Icon(Icons.note_outlined, color: AppColors.accentGreen)),
                ),
              ),
              SizedBox(height: 32),
              SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _save, child: Text(_isEditing ? 'Update Note' : 'Save Note'))),
            ],
          ),
        ),
      ),
    );
  }
}
