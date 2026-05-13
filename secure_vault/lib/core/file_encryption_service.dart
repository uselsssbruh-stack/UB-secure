import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/file_entry.dart';
import '../shared/constants.dart';
import 'crypto_service.dart';

/// Handles individual file encryption/decryption.
/// Files are encrypted with AES-256-GCM using unique nonces
/// and stored locally — never synced to cloud.
/// All file paths are scoped per-user via UID.
class FileEncryptionService {
  FileEncryptionService._();

  /// Encrypts a file and saves it to the encrypted files directory.
  /// Returns a [FileEntry] with metadata.
  static Future<FileEntry> encryptAndSaveFile({
    required Uint8List fileData,
    required String originalName,
    required String mimeType,
    required SecretKey key,
    required String uid,
  }) async {
    final fileId = Uuid().v4();
    final encryptedFileName = '$fileId.enc';

    // Encrypt file data
    final encryptedData = await CryptoService.encrypt(fileData, key);

    // Save to files directory
    final filesDir = await _getFilesDirectory(uid);
    final outFile = File('${filesDir.path}/$encryptedFileName');
    await outFile.writeAsBytes(encryptedData, flush: true);

    return FileEntry(
      id: fileId,
      fileName: encryptedFileName,
      originalName: originalName,
      mimeType: mimeType,
      fileSize: fileData.length,
    );
  }

  /// Decrypts a file in memory — never writes plaintext to disk.
  /// Returns the decrypted bytes for display/preview.
  static Future<Uint8List> decryptFile({
    required String fileName,
    required SecretKey key,
    required String uid,
  }) async {
    final filesDir = await _getFilesDirectory(uid);
    final encFile = File('${filesDir.path}/$fileName');

    if (!await encFile.exists()) {
      throw FileSystemException('Encrypted file not found', encFile.path);
    }

    final encryptedData = await encFile.readAsBytes();
    return await CryptoService.decrypt(encryptedData, key);
  }

  /// Deletes an encrypted file from disk.
  static Future<void> deleteFile(String fileName, String uid) async {
    final filesDir = await _getFilesDirectory(uid);
    final file = File('${filesDir.path}/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Gets the encrypted files directory, scoped per user.
  static Future<Directory> _getFilesDirectory(String uid) async {
    final dir = await getApplicationSupportDirectory();
    final filesDir = Directory('${dir.path}/${AppConstants.filesDirectory}_$uid');
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }
}
