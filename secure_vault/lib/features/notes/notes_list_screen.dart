import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'note_form_screen.dart';

class NotesListScreen extends ConsumerWidget {
  NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider).vault;
    final notes = vault?.notes ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Notes'),
        actions: [
          IconButton(icon: Icon(Icons.add_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen()))),
        ],
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppColors.noteColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.note_rounded, size: 40, color: AppColors.noteColor),
                  ),
                  SizedBox(height: 20),
                  Text('No Notes Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                  SizedBox(height: 8),
                  Text('Add your first secure note', style: TextStyle(color: AppColors.of(context).textMuted)),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen())),
                    icon: Icon(Icons.add_rounded), label: Text('Add Note'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.of(context).cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.of(context).border)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(entry: note))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.noteColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.note_rounded, color: AppColors.noteColor, size: 22),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                                  SizedBox(height: 4),
                                  Text(note.preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: AppColors.of(context).textMuted)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: AppColors.of(context).textMuted, size: 18),
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen(entry: note)));
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('Delete Note'),
                                      content: Text('This action cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.accentRed), child: Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) ref.read(vaultProvider.notifier).deleteNote(note.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: notes.isNotEmpty
          ? FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormScreen())), child: Icon(Icons.add_rounded))
          : null,
    );
  }
}
