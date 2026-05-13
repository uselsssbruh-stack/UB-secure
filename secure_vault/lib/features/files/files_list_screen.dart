import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/file_entry.dart';
import '../../providers/vault_provider.dart';
import '../../shared/theme/app_colors.dart';

class FilesListScreen extends ConsumerWidget {
  FilesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider).vault;
    final files = vault?.files ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypted Files'),
        actions: [
          IconButton(icon: Icon(Icons.add_rounded), onPressed: () => _pickAndEncrypt(context, ref)),
        ],
      ),
      body: files.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 80, height: 80,
                    decoration: BoxDecoration(color: AppColors.fileColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.folder_rounded, size: 40, color: AppColors.fileColor)),
                  SizedBox(height: 20),
                  Text('No Files Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                  SizedBox(height: 8),
                  Text('Import and encrypt images or PDFs', style: TextStyle(color: AppColors.of(context).textMuted)),
                  SizedBox(height: 4),
                  Text('Files are stored locally — never synced to cloud', style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12)),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _pickAndEncrypt(context, ref),
                    icon: Icon(Icons.add_rounded), label: Text('Import File'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: files.length,
              itemBuilder: (context, index) => _buildFileCard(context, ref, files[index]),
            ),
      floatingActionButton: files.isNotEmpty
          ? FloatingActionButton(onPressed: () => _pickAndEncrypt(context, ref), child: Icon(Icons.add_rounded))
          : null,
    );
  }

  Future<void> _pickAndEncrypt(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'pdf', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encrypting file...'), duration: Duration(seconds: 1)),
      );
    }

    await ref.read(vaultProvider.notifier).addEncryptedFile(result.files.first);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File encrypted and stored securely ✓')),
      );
    }
  }

  Widget _buildFileCard(BuildContext context, WidgetRef ref, FileEntry file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.of(context).cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.of(context).border)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewFile(context, ref, file),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppColors.fileColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getFileIcon(file), color: AppColors.fileColor, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file.originalName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
                      SizedBox(height: 2),
                      Text('${file.fileSizeFormatted} • Encrypted', style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted)),
                    ],
                  ),
                ),
                // View
                IconButton(
                  icon: Icon(Icons.visibility_rounded, size: 20, color: AppColors.accentCyan),
                  tooltip: 'Decrypt & View',
                  onPressed: () => _viewFile(context, ref, file),
                ),
                // Download (decrypt and save)
                IconButton(
                  icon: Icon(Icons.download_rounded, size: 20, color: AppColors.accentGreen),
                  tooltip: 'Decrypt & Download',
                  onPressed: () => _downloadFile(context, ref, file),
                ),
                // Delete
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: AppColors.accentRed),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete File'),
                        content: Text('This file will be permanently deleted.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: AppColors.accentRed), child: Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) ref.read(vaultProvider.notifier).deleteFile(file.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Decrypt file and save to user-chosen location
  Future<void> _downloadFile(BuildContext context, WidgetRef ref, FileEntry file) async {
    // Let user pick save location
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save decrypted file',
      fileName: file.originalName,
    );

    if (outputPath == null) return;

    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decrypting file...'), duration: Duration(seconds: 1)),
      );
    }

    final bytes = await ref.read(vaultProvider.notifier).decryptFile(file);

    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decrypt file')),
        );
      }
      return;
    }

    try {
      final outFile = File(outputPath);
      await outFile.writeAsBytes(bytes, flush: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: ${outFile.path}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  Future<void> _viewFile(BuildContext context, WidgetRef ref, FileEntry file) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    final bytes = await ref.read(vaultProvider.notifier).decryptFile(file);
    if (context.mounted) Navigator.pop(context); // close loading

    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decrypt file')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (file.isImage) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(file.originalName),
            actions: [
              IconButton(
                icon: Icon(Icons.download_rounded),
                tooltip: 'Download',
                onPressed: () => _downloadFile(context, ref, file),
              ),
            ],
          ),
          backgroundColor: AppColors.of(context).backgroundDark,
          body: InteractiveViewer(
            child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
          ),
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(file.originalName),
            actions: [
              IconButton(
                icon: Icon(Icons.download_rounded),
                tooltip: 'Download',
                onPressed: () => _downloadFile(context, ref, file),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              String.fromCharCodes(bytes),
              style: TextStyle(color: AppColors.of(context).textPrimary, fontFamily: 'monospace', fontSize: 13),
            ),
          ),
        ),
      ));
    }
  }

  IconData _getFileIcon(FileEntry file) {
    if (file.isImage) return Icons.image_rounded;
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    return Icons.insert_drive_file_rounded;
  }
}
