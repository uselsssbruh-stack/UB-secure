import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../shared/constants.dart';

/// Zero-knowledge cryptography service.
/// All encryption/decryption happens client-side only.
/// No plaintext data ever leaves this service unencrypted.
class CryptoService {
  CryptoService._();

  static final AesGcm _aesGcm = AesGcm.with256bits();

  /// Derives a 256-bit key from master password + salt using PBKDF2-HMAC-SHA256.
  /// This is computationally expensive by design to resist brute-force attacks.
  static Future<SecretKey> deriveKey(String masterPassword, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: AppConstants.pbkdf2Iterations,
      bits: AppConstants.keyLength * 8,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(masterPassword)),
      nonce: salt,
    );

    return secretKey;
  }

  /// Generates a cryptographically random salt.
  static Uint8List generateSalt() {
    final bytes = Uint8List(AppConstants.saltLength);
    fillBytesWithSecureRandom(bytes);
    return bytes;
  }

  /// Generates a cryptographically random nonce for AES-GCM.
  static Uint8List generateNonce() {
    final bytes = Uint8List(AppConstants.nonceLength);
    fillBytesWithSecureRandom(bytes);
    return bytes;
  }

  /// Fills a byte list with cryptographically secure random bytes.
  static void fillBytesWithSecureRandom(Uint8List bytes) {
    final random = SecureRandom.fast;
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
  }

  /// Encrypts plaintext using AES-256-GCM.
  /// Returns: nonce (12 bytes) + ciphertext + MAC (16 bytes)
  static Future<Uint8List> encrypt(Uint8List plaintext, SecretKey key) async {
    final nonce = generateNonce();

    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );

    // Combine: nonce + ciphertext + MAC
    final result = Uint8List(
      nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    result.setAll(0, nonce);
    result.setAll(nonce.length, secretBox.cipherText);
    result.setAll(nonce.length + secretBox.cipherText.length, secretBox.mac.bytes);

    return result;
  }

  /// Decrypts data encrypted with [encrypt].
  /// Input: nonce (12 bytes) + ciphertext + MAC (16 bytes)
  static Future<Uint8List> decrypt(Uint8List data, SecretKey key) async {
    if (data.length < AppConstants.nonceLength + 16) {
      throw CryptoException('Data too short to contain valid encrypted content');
    }

    final nonce = data.sublist(0, AppConstants.nonceLength);
    final macStart = data.length - 16;
    final cipherText = data.sublist(AppConstants.nonceLength, macStart);
    final mac = Mac(data.sublist(macStart));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    try {
      final plaintext = await _aesGcm.decrypt(
        secretBox,
        secretKey: key,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw CryptoException('Decryption failed — incorrect password or corrupted data');
    }
  }

  /// Encrypts a string and returns base64-encoded result.
  static Future<String> encryptString(String plaintext, SecretKey key) async {
    final encrypted = await encrypt(Uint8List.fromList(utf8.encode(plaintext)), key);
    return base64.encode(encrypted);
  }

  /// Decrypts a base64-encoded string.
  static Future<String> decryptString(String base64Data, SecretKey key) async {
    final data = base64.decode(base64Data);
    final decrypted = await decrypt(Uint8List.fromList(data), key);
    return utf8.decode(decrypted);
  }

  /// Creates a verification hash from the master password.
  /// This is stored (encrypted) to verify the password on unlock
  /// without storing the password itself.
  static Future<String> createVerifier(SecretKey key) async {
    // Encrypt a known string to use as password verifier
    const verifierPlaintext = 'UB_SECURE_VAULT_VERIFIER_V1';
    return await encryptString(verifierPlaintext, key);
  }

  /// Verifies the master password by trying to decrypt the verifier.
  static Future<bool> verifyPassword(SecretKey key, String storedVerifier) async {
    try {
      final decrypted = await decryptString(storedVerifier, key);
      return decrypted == 'UB_SECURE_VAULT_VERIFIER_V1';
    } catch (e) {
      return false;
    }
  }

  /// Generates a secure random password.
  static String generatePassword({
    int length = 20,
    bool uppercase = true,
    bool lowercase = true,
    bool digits = true,
    bool special = true,
  }) {
    String chars = '';
    if (uppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (lowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (digits) chars += '0123456789';
    if (special) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    if (chars.isEmpty) chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

    final random = SecureRandom.fast;
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);

  @override
  String toString() => 'CryptoException: $message';
}
