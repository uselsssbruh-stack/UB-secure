class AppConstants {
  AppConstants._();

  static const String appName = 'UB Secure';
  static const String appVersion = '1.0.0';
  static const String vaultFileName = 'vault.enc';
  static const String filesDirectory = 'encrypted_files';
  static const String saltKey = 'vault_salt';
  static const String verifierKey = 'vault_verifier';
  static const String kdfParamsKey = 'kdf_params';
  static const String vaultExistsKey = 'vault_exists';

  // KDF parameters (Argon2id-equivalent using HKDF + PBKDF2 fallback)
  static const int pbkdf2Iterations = 600000;
  static const int keyLength = 32; // 256 bits
  static const int saltLength = 16; // 128 bits
  static const int nonceLength = 12; // 96 bits for AES-GCM

  // Security
  static const int clipboardClearSeconds = 15;
  static const int autoLockMinutes = 5;
  static const int maxLoginAttempts = 5;

  // UI
  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 20.0;
  static const String maskCharacter = '•';
  static const String maskedPassword = '••••••••••••';
  static const String maskedCardNumber = '•••• •••• •••• ';
  static const String maskedCVV = '•••';
}
