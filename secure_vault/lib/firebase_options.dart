import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: "AIzaSyDQgObQXNYLyfRhETZjmsmaQzLV2_th1pk",
      authDomain: "trialerproject.firebaseapp.com",
      projectId: "trialerproject",
      storageBucket: "trialerproject.firebasestorage.app",
      messagingSenderId: "902407932968",
      appId: "1:902407932968:web:ea70d01c4f7eaa6135791d",
    );
  }
}
