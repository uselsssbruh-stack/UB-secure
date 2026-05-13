# UB Secure - Zero-Knowledge Encrypted Vault

A secure, zero-knowledge encrypted vault application for Android and Windows built with Flutter. Safely store and manage sensitive information with military-grade encryption.

## Overview

UB Secure is a cross-platform application that provides a secure, private vault for storing sensitive data including passwords, notes, files, and personal information. All data is encrypted locally on your device using advanced cryptographic algorithms, ensuring complete privacy and security.

## Features

- **Zero-Knowledge Architecture**: Your data is encrypted locally; no data leaves your device unencrypted
- **Military-Grade Encryption**: Uses modern cryptographic algorithms for data protection
- **Cross-Platform Support**: Works on Android and Windows devices
- **Local Storage**: All data stored locally on your device for maximum privacy
- **File Support**: Securely store files alongside sensitive data
- **State Management**: Efficient state management using Riverpod
- **User-Friendly Interface**: Intuitive UI for easy data management
- **No Cloud Dependency**: Complete offline functionality

## Tech Stack

- **Framework**: Flutter 3.11.5+
- **Language**: Dart
- **Cryptography**: Cryptography package v2.7.0+
- **State Management**: Flutter Riverpod v2.6.1+
- **Local Storage**: Path Provider, Shared Preferences
- **File Management**: File Picker
- **UI Components**: Cupertino Icons

## Installation

### Prerequisites

- Flutter SDK 3.11.5 or higher
- Dart SDK 3.11.5 or higher
- Android SDK (for Android builds) or Windows SDK (for Windows builds)
- A supported IDE (VS Code, Android Studio, or IntelliJ IDEA)

### Setup

1. Clone the repository:
```bash
git clone git@github.com:uselsssbruh-stack/UB-secure.git
cd UB-secure/secure_vault
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
# Android
flutter run -d android

# Windows
flutter run -d windows
```

## Project Structure

```
secure_vault/
├── lib/                      # Dart source code
├── android/                  # Android native code
├── windows/                  # Windows native code
├── assets/                   # Images, fonts, and other assets
├── test/                     # Unit and widget tests
├── pubspec.yaml             # Project configuration and dependencies
├── analysis_options.yaml    # Dart analysis rules
├── README.md
├── LICENSE
└── .gitignore
```

## Building

### Android Build

```bash
flutter build apk
# or for release
flutter build apk --release
```

### Windows Build

```bash
flutter build windows
# or for release
flutter build windows --release
```

## Security Features

- **End-to-End Encryption**: All data encrypted before storage
- **No Cloud Storage**: Data never leaves your device
- **Secure Key Management**: Cryptographic keys stored securely
- **Local Authentication**: Optional biometric/PIN authentication
- **No Tracking**: Complete privacy, no telemetry or analytics

## Dependencies

### Core Dependencies
- `flutter`: Flutter framework
- `cupertino_icons`: iOS-style icons

### Cryptography
- `cryptography`: Modern cryptographic algorithms for encryption

### State Management
- `flutter_riverpod`: Reactive state management

### Storage
- `path_provider`: Access device file system paths
- `shared_preferences`: Local key-value storage

### Utilities
- `uuid`: UUID generation for unique identifiers
- `intl`: Internationalization and localization
- `file_picker`: File selection from device storage
- `url_launcher`: Open URLs and handle links

## Development

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

### Format Code

```bash
dart format lib/
```

### Lint Code

```bash
flutter pub run custom_lint
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Author

**Abhijith Krishna G**

## Security & Privacy

- All encryption is performed locally on your device
- No data is transmitted to any server
- No accounts or registration required
- Complete control over your encrypted data
- Open-source for transparency

## Support & Issues

For bug reports and feature requests, please open an issue on the GitHub repository.

## Roadmap

- Cloud sync with end-to-end encryption (optional)
- Biometric authentication improvements
- Enhanced file encryption support
- Dark mode improvements
- Additional platforms (iOS, macOS, Linux)
- Advanced search and organization features

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Cryptography Dart Package](https://pub.dev/packages/cryptography)
- [Flutter Riverpod](https://riverpod.dev/)

## Disclaimer

This application is provided as-is for educational and personal use. While we take security seriously, users are responsible for their own data security and backup strategies.
