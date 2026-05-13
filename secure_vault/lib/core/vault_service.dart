import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/vault_model.dart';
import '../shared/constants.dart';
import 'crypto_service.dart';

/// Manages the vault lifecycle: create, unlock, read, update, lock.
/// The vault is stored as a single encrypted JSON blob.
/// 
/// All storage is scoped per-user via UID — each account has its own
/// vault file, salt, verifier, and encrypted files directory.
///
/// Security note: Salt and verifier are stored in shared_preferences.
/// These are NOT secrets — they're designed to be stored alongside 
/// encrypted data (like how bcrypt stores salt in the hash). 
/// The security comes from the master password + PBKDF2 key derivation.
class VaultService {
  SecretKey? _currentKey;
  VaultModel? _currentVault;
  String? _currentUid;
  
  /// The current derived key (null if locked). Needed by file encryption.
  SecretKey? get currentKey => _currentKey;

  /// Whether the vault is currently unlocked and in memory.
  bool get isUnlocked => _currentKey != null && _currentVault != null;

  /// The current decrypted vault (null if locked).
  VaultModel? get vault => _currentVault;

  /// Check if a vault has been created before for this user.
  Future<bool> vaultExists(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey(uid, AppConstants.vaultExistsKey)) ?? false;
  }

  /// Creates a new vault with the given master password for the given user.
  Future<void> createVault(String masterPassword, String uid) async {
    _currentUid = uid;
    final prefs = await SharedPreferences.getInstance();
    
    // Generate salt
    final salt = CryptoService.generateSalt();
    
    // Derive key
    final key = await CryptoService.deriveKey(masterPassword, salt);
    
    // Create verifier
    final verifier = await CryptoService.createVerifier(key);
    
    // Create empty vault
    final emptyVault = VaultModel.empty();
    
    // Encrypt and save
    final vaultJson = jsonEncode(emptyVault.toJson());
    final encrypted = await CryptoService.encrypt(
      Uint8List.fromList(utf8.encode(vaultJson)),
      key,
    );
    
    // Save encrypted vault to file
    await _saveVaultFile(uid, encrypted);
    
    // Store salt and verifier (not secrets — security comes from KDF)
    await prefs.setString(_prefKey(uid, AppConstants.saltKey), base64.encode(salt));
    await prefs.setString(_prefKey(uid, AppConstants.verifierKey), verifier);
    await prefs.setBool(_prefKey(uid, AppConstants.vaultExistsKey), true);
    
    // Keep in memory
    _currentKey = key;
    _currentVault = emptyVault;
  }

  /// Unlocks the vault with the master password for the given user.
  Future<bool> unlockVault(String masterPassword, String uid) async {
    _currentUid = uid;
    final prefs = await SharedPreferences.getInstance();
    
    // Read salt
    final saltBase64 = prefs.getString(_prefKey(uid, AppConstants.saltKey));
    if (saltBase64 == null) {
      throw CryptoException('Vault configuration not found');
    }
    final salt = Uint8List.fromList(base64.decode(saltBase64));
    
    // Derive key
    final key = await CryptoService.deriveKey(masterPassword, salt);
    
    // Verify password
    final verifier = prefs.getString(_prefKey(uid, AppConstants.verifierKey));
    if (verifier == null) {
      throw CryptoException('Vault verifier not found');
    }
    
    final isValid = await CryptoService.verifyPassword(key, verifier);
    if (!isValid) {
      return false;
    }
    
    // Read and decrypt vault
    final encryptedData = await _readVaultFile(uid);
    if (encryptedData == null) {
      _currentKey = key;
      _currentVault = VaultModel.empty();
      await saveVault();
      return true;
    }
    
    final decrypted = await CryptoService.decrypt(encryptedData, key);
    final vaultJson = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
    
    _currentKey = key;
    _currentVault = VaultModel.fromJson(vaultJson);
    _currentUid = uid;
    
    return true;
  }

  /// Saves the current vault state.
  Future<void> saveVault() async {
    if (_currentKey == null || _currentVault == null || _currentUid == null) {
      throw StateError('Vault is not unlocked');
    }
    
    _currentVault!.updatedAt = DateTime.now();
    
    final vaultJson = jsonEncode(_currentVault!.toJson());
    final encrypted = await CryptoService.encrypt(
      Uint8List.fromList(utf8.encode(vaultJson)),
      _currentKey!,
    );
    
    await _saveVaultFile(_currentUid!, encrypted);
  }

  /// Locks the vault — clears key and data from memory.
  void lockVault() {
    _currentKey = null;
    _currentVault = null;
    _currentUid = null;
  }

  /// Deletes the vault entirely for the given user.
  Future<void> deleteVault(String uid) async {
    lockVault();
    
    final file = await _getVaultFile(uid);
    if (await file.exists()) {
      await file.delete();
    }
    
    final filesDir = await _getFilesDirectory(uid);
    if (await filesDir.exists()) {
      await filesDir.delete(recursive: true);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey(uid, AppConstants.saltKey));
    await prefs.remove(_prefKey(uid, AppConstants.verifierKey));
    await prefs.remove(_prefKey(uid, AppConstants.vaultExistsKey));
  }

  /// Changes the master password.
  Future<void> changeMasterPassword(String newPassword, String uid) async {
    if (_currentVault == null) {
      throw StateError('Vault must be unlocked to change password');
    }
    _currentUid = uid;
    
    final prefs = await SharedPreferences.getInstance();
    final newSalt = CryptoService.generateSalt();
    final newKey = await CryptoService.deriveKey(newPassword, newSalt);
    final newVerifier = await CryptoService.createVerifier(newKey);
    
    _currentKey = newKey;
    await saveVault();
    
    await prefs.setString(_prefKey(uid, AppConstants.saltKey), base64.encode(newSalt));
    await prefs.setString(_prefKey(uid, AppConstants.verifierKey), newVerifier);
  }

  /// Gets encrypted vault as base64 for cloud sync.
  Future<String?> getEncryptedVaultBase64() async {
    if (_currentUid == null) return null;
    final data = await _readVaultFile(_currentUid!);
    if (data == null) return null;
    return base64.encode(data);
  }

  /// Gets the salt as base64 for cloud sync.
  Future<String?> getSaltBase64(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey(uid, AppConstants.saltKey));
  }

  /// Gets the verifier for cloud sync.
  Future<String?> getVerifier(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey(uid, AppConstants.verifierKey));
  }

  /// Imports encrypted vault + credentials from cloud sync.
  /// Called when a user logs in on a new device and their vault exists in the cloud.
  Future<void> importFromCloud({
    required String uid,
    required String encryptedBlobBase64,
    required String saltBase64,
    required String verifier,
  }) async {
    final data = Uint8List.fromList(base64.decode(encryptedBlobBase64));
    await _saveVaultFile(uid, data);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(uid, AppConstants.saltKey), saltBase64);
    await prefs.setString(_prefKey(uid, AppConstants.verifierKey), verifier);
    await prefs.setBool(_prefKey(uid, AppConstants.vaultExistsKey), true);
  }

  /// Reloads the in-memory vault from a remote encrypted blob.
  /// Used for live sync — decrypts using the already-derived key
  /// so no master password re-entry is needed.
  Future<bool> reloadFromBlob(String encryptedBlobBase64, String uid) async {
    if (_currentKey == null) return false;
    
    try {
      final data = Uint8List.fromList(base64.decode(encryptedBlobBase64));
      // Also persist locally
      await _saveVaultFile(uid, data);
      
      final decrypted = await CryptoService.decrypt(data, _currentKey!);
      final vaultJson = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      _currentVault = VaultModel.fromJson(vaultJson);
      _currentUid = uid;
      return true;
    } catch (e) {
      print('[VaultService] reloadFromBlob failed: $e');
      return false;
    }
  }

  // --- Private helpers ---

  /// Creates a per-user SharedPreferences key.
  String _prefKey(String uid, String key) => '${key}_$uid';

  Future<File> _getVaultFile(String uid) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/vault_$uid.enc');
  }

  Future<Directory> _getFilesDirectory(String uid) async {
    final dir = await getApplicationSupportDirectory();
    final filesDir = Directory('${dir.path}/${AppConstants.filesDirectory}_$uid');
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    return filesDir;
  }

  Future<void> _saveVaultFile(String uid, Uint8List data) async {
    final file = await _getVaultFile(uid);
    await file.writeAsBytes(data, flush: true);
  }

  Future<Uint8List?> _readVaultFile(String uid) async {
    final file = await _getVaultFile(uid);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }
}
