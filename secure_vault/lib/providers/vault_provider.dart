import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/vault_service.dart';
import '../core/sync_service.dart';
import '../core/file_encryption_service.dart';
import '../models/vault_model.dart';
import '../models/password_entry.dart';
import '../models/card_entry.dart';
import '../models/identity_entry.dart';
import '../models/note_entry.dart';
import '../models/file_entry.dart';
import 'auth_provider.dart';

// --- Services ---
final vaultServiceProvider = Provider<VaultService>((ref) => VaultService());
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

// --- Vault State ---
enum VaultStatus { uninitialized, locked, unlocked, loading, error }

class VaultState {
  final VaultStatus status;
  final VaultModel? vault;
  final String? errorMessage;
  final SecretKey? key;

  VaultState({
    this.status = VaultStatus.uninitialized,
    this.vault,
    this.errorMessage,
    this.key,
  });

  VaultState copyWith({
    VaultStatus? status,
    VaultModel? vault,
    String? errorMessage,
    SecretKey? key,
  }) {
    return VaultState(
      status: status ?? this.status,
      vault: vault ?? this.vault,
      errorMessage: errorMessage,
      key: key ?? this.key,
    );
  }
}

// --- Vault Notifier ---
class VaultNotifier extends StateNotifier<VaultState> {
  final VaultService _vaultService;
  final SyncService _syncService;
  final String? _uid;
  StreamSubscription<String?>? _syncSubscription;
  String? _lastRemoteUpdate;
  bool _isPushing = false;

  VaultNotifier(this._vaultService, this._syncService, this._uid) : super(VaultState()) {
    _init();
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (_uid == null) {
      state = VaultState(status: VaultStatus.uninitialized);
      return;
    }

    state = VaultState(status: VaultStatus.loading);
    final localExists = await _vaultService.vaultExists(_uid);
    if (!mounted) return;

    if (!localExists) {
      // No local vault for this account — check cloud
      try {
        final remoteVault = await _syncService.fetchVault(_uid);
        if (!mounted) return;
        
        if (remoteVault != null) {
          final remoteBlob = remoteVault['vaultData'] as String?;
          final remoteSalt = remoteVault['salt'] as String?;
          final remoteVerifier = remoteVault['verifier'] as String?;
          
          if (remoteBlob != null && remoteSalt != null && remoteVerifier != null) {
            // Import vault + salt + verifier from cloud
            await _vaultService.importFromCloud(
              uid: _uid,
              encryptedBlobBase64: remoteBlob,
              saltBase64: remoteSalt,
              verifier: remoteVerifier,
            );
            if (!mounted) return;
            print('[VaultProvider] Imported vault from cloud for uid=$_uid');
            state = VaultState(status: VaultStatus.locked);
            return;
          }
        }
      } catch (e) {
        print('[VaultProvider] Cloud fetch failed: $e');
        // Fallback to local if offline or error
      }
    }

    if (!mounted) return;
    state = VaultState(
      status: localExists ? VaultStatus.locked : VaultStatus.uninitialized,
    );
  }

  Future<bool> createVault(String masterPassword) async {
    if (_uid == null) return false;
    state = state.copyWith(status: VaultStatus.loading);
    try {
      await _vaultService.createVault(masterPassword, _uid);
      state = VaultState(
        status: VaultStatus.unlocked,
        vault: _vaultService.vault,
        key: _vaultService.currentKey,
      );
      // Immediately push the new, empty vault to Firestore to establish the document
      await _saveAndNotify();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: VaultStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> unlockVault(String masterPassword) async {
    if (_uid == null) return false;
    state = state.copyWith(status: VaultStatus.loading);
    try {
      final success = await _vaultService.unlockVault(masterPassword, _uid);
      if (success) {
        state = VaultState(
          status: VaultStatus.unlocked,
          vault: _vaultService.vault,
          key: _vaultService.currentKey,
        );
        _startSyncListener();
      } else {
        state = VaultState(
          status: VaultStatus.locked,
          errorMessage: 'Incorrect master password',
        );
      }
      return success;
    } catch (e) {
      state = VaultState(
        status: VaultStatus.locked,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void lockVault() {
    _vaultService.lockVault();
    state = VaultState(status: VaultStatus.locked);
  }

  Future<void> deleteVault() async {
    if (_uid == null) return;
    // Delete local
    await _vaultService.deleteVault(_uid);
    
    // Delete from cloud if synced
    try {
      await _syncService.deleteVault(_uid);
    } catch (e) {
      // Ignored
    }
    
    if (!mounted) return;
    state = VaultState(status: VaultStatus.uninitialized);
  }

  Future<void> changeMasterPassword(String newPassword) async {
    if (_uid == null) return;
    await _vaultService.changeMasterPassword(newPassword, _uid);
    state = state.copyWith(key: _vaultService.currentKey);
    // Push updated salt/verifier to cloud
    await _syncToCloud();
  }

  // --- Password Operations ---
  Future<void> addPassword(PasswordEntry entry) async {
    state.vault!.passwords.add(entry);
    await _saveAndNotify();
  }

  Future<void> updatePassword(PasswordEntry entry) async {
    final idx = state.vault!.passwords.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      state.vault!.passwords[idx] = entry;
      await _saveAndNotify();
    }
  }

  Future<void> deletePassword(String id) async {
    state.vault!.passwords.removeWhere((e) => e.id == id);
    await _saveAndNotify();
  }

  // --- Card Operations ---
  Future<void> addCard(CardEntry entry) async {
    state.vault!.cards.add(entry);
    await _saveAndNotify();
  }

  Future<void> updateCard(CardEntry entry) async {
    final idx = state.vault!.cards.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      state.vault!.cards[idx] = entry;
      await _saveAndNotify();
    }
  }

  Future<void> deleteCard(String id) async {
    state.vault!.cards.removeWhere((e) => e.id == id);
    await _saveAndNotify();
  }

  // --- Identity Operations ---
  Future<void> addIdentity(IdentityEntry entry) async {
    state.vault!.identities.add(entry);
    await _saveAndNotify();
  }

  Future<void> updateIdentity(IdentityEntry entry) async {
    final idx = state.vault!.identities.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      state.vault!.identities[idx] = entry;
      await _saveAndNotify();
    }
  }

  Future<void> deleteIdentity(String id) async {
    state.vault!.identities.removeWhere((e) => e.id == id);
    await _saveAndNotify();
  }

  // --- Note Operations ---
  Future<void> addNote(NoteEntry entry) async {
    state.vault!.notes.add(entry);
    await _saveAndNotify();
  }

  Future<void> updateNote(NoteEntry entry) async {
    final idx = state.vault!.notes.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      state.vault!.notes[idx] = entry;
      await _saveAndNotify();
    }
  }

  Future<void> deleteNote(String id) async {
    state.vault!.notes.removeWhere((e) => e.id == id);
    await _saveAndNotify();
  }

  // --- File Operations ---
  Future<void> addEncryptedFile(PlatformFile platformFile) async {
    if (state.key == null || _uid == null) return;

    Uint8List? bytes = platformFile.bytes;
    if (bytes == null && platformFile.path != null) {
      bytes = await File(platformFile.path!).readAsBytes();
    }
    if (bytes == null) return;

    final fileEntry = await FileEncryptionService.encryptAndSaveFile(
      fileData: bytes,
      originalName: platformFile.name,
      mimeType: _getMimeType(platformFile.name),
      key: state.key!,
      uid: _uid,
    );

    state.vault!.files.add(fileEntry);
    await _saveAndNotify();
  }

  Future<Uint8List?> decryptFile(FileEntry fileEntry) async {
    if (state.key == null || _uid == null) return null;
    try {
      return await FileEncryptionService.decryptFile(
        fileName: fileEntry.fileName,
        key: state.key!,
        uid: _uid,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteFile(String id) async {
    if (_uid == null) return;
    final entry = state.vault!.files.firstWhere((e) => e.id == id);
    await FileEncryptionService.deleteFile(entry.fileName, _uid);
    state.vault!.files.removeWhere((e) => e.id == id);
    await _saveAndNotify();
  }

  // --- Sync Listeners ---
  void _startSyncListener() {
    if (_uid == null) return;
    _syncSubscription?.cancel();
    
    _syncSubscription = _syncService.listenForChanges(_uid!).listen((updatedAt) async {
      if (updatedAt == null) return;
      
      // Ignore if we caused this update
      if (_isPushing || _lastRemoteUpdate == updatedAt) return;
      
      print('[VaultProvider] Remote change detected ($updatedAt). Reloading vault...');
      
      try {
        final remoteVault = await _syncService.fetchVault(_uid!);
        if (remoteVault != null) {
          final blob = remoteVault['vaultData'] as String?;
          if (blob != null) {
            final success = await _vaultService.reloadFromBlob(blob, _uid!);
            if (success && mounted) {
              _lastRemoteUpdate = updatedAt;
              // Update state with new data
              state = VaultState(
                status: VaultStatus.unlocked,
                vault: _vaultService.vault,
                key: state.key,
              );
              print('[VaultProvider] Vault live-reloaded successfully');
            }
          }
        }
      } catch (e) {
        print('[VaultProvider] Live-reload failed: $e');
      }
    });
  }

  // --- Helpers ---
  Future<void> _saveAndNotify() async {
    await _vaultService.saveVault();
    if (!mounted) return;

    // Update UI immediately so it feels instant
    state = VaultState(
      status: VaultStatus.unlocked,
      vault: _vaultService.vault,
      key: state.key,
    );
    
    // Sync to Firebase in the background (non-blocking)
    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    if (_uid == null) return;
    
    _isPushing = true;
    final blob = await _vaultService.getEncryptedVaultBase64();
    final salt = await _vaultService.getSaltBase64(_uid);
    final verifier = await _vaultService.getVerifier(_uid);
    
    if (blob != null && salt != null && verifier != null) {
      try {
        await _syncService.pushVault(
          uid: _uid,
          encryptedBlob: blob,
          saltBase64: salt,
          verifier: verifier,
        );
        _lastRemoteUpdate = state.vault?.updatedAt.toIso8601String();
        // ignore: avoid_print
        print('[SecureVault] Sync to Firebase successful (${blob.length} chars)');
      } catch (e) {
        // ignore: avoid_print
        print('[SecureVault] Sync to Firebase FAILED: $e');
      } finally {
        _isPushing = false;
      }
    } else {
      _isPushing = false;
      // ignore: avoid_print
      print('[SecureVault] Sync skipped: missing blob, salt, or verifier');
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}

// --- Provider ---
final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  final service = ref.watch(vaultServiceProvider);
  final syncService = ref.watch(syncServiceProvider);
  final user = ref.watch(authStateProvider).value;
  return VaultNotifier(service, syncService, user?.uid);
});
