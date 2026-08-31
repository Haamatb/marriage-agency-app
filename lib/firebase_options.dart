// ─────────────────────────────────────────────────────────────────────────────
// firebase_options.dart — FlutterFire configuration
// Project: off-hom
// ─────────────────────────────────────────────────────────────────────────────
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.linux:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not configured for ${defaultTargetPlatform.name}.\n'
          'Run: flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID',
        );
    }
  }

  // ────────────────────────────────────────────────────────────────────────
  // Android Firebase config
  // ────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCi5TEN8iQ0MGXUP_lLABS3zrazaW9W48Q',
    appId: '1:96670932071:android:bfd390ccb03ef2bdeb48c2',
    messagingSenderId: '96670932071',
    projectId: 'off-hom',
    storageBucket: 'off-hom.firebasestorage.app',
  );

  // ────────────────────────────────────────────────────────────────────────
  // Windows Firebase config
  // ────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBCollf6PO5VttkUXfZlv0S8P6MBrXKmRs',
    appId: '1:96670932071:web:b6c5a41bb28515d0eb48c2',
    messagingSenderId: '96670932071',
    projectId: 'off-hom',
    authDomain: 'off-hom.firebaseapp.com',
    storageBucket: 'off-hom.firebasestorage.app',
  );

  // ────────────────────────────────────────────────────────────────────────
  // macOS Firebase config
  // ────────────────────────────────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBCollf6PO5VttkUXfZlv0S8P6MBrXKmRs',
    appId: '1:96670932071:ios:bfd390ccb03ef2bdeb48c2',
    messagingSenderId: '96670932071',
    projectId: 'off-hom',
    storageBucket: 'off-hom.firebasestorage.app',
    iosBundleId: 'com.legaloffice.marriageAgencyApp',
  );
}
