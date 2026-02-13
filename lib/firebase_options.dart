import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDKCeQ63wcow_G54r1CtxxPqED-773oQM8',
    appId: '1:226271839103:web:0177a2d003b64eeed4504a',
    messagingSenderId: '226271839103',
    projectId: 'novotel-westlands-in-house-app',
    authDomain: 'novotel-westlands-in-house-app.firebaseapp.com',
    storageBucket: 'novotel-westlands-in-house-app.firebasestorage.app',
    measurementId: 'G-3BPQB00GBP',
  );

  // Android config - uses same project, update with google-services.json values if different
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKCeQ63wcow_G54r1CtxxPqED-773oQM8',
    appId: '1:226271839103:web:0177a2d003b64eeed4504a',
    messagingSenderId: '226271839103',
    projectId: 'novotel-westlands-in-house-app',
    storageBucket: 'novotel-westlands-in-house-app.firebasestorage.app',
  );

  // iOS config - uses same project, update with GoogleService-Info.plist values if different
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDKCeQ63wcow_G54r1CtxxPqED-773oQM8',
    appId: '1:226271839103:web:0177a2d003b64eeed4504a',
    messagingSenderId: '226271839103',
    projectId: 'novotel-westlands-in-house-app',
    storageBucket: 'novotel-westlands-in-house-app.firebasestorage.app',
    iosBundleId: 'com.novotel.inhouse',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDKCeQ63wcow_G54r1CtxxPqED-773oQM8',
    appId: '1:226271839103:web:0177a2d003b64eeed4504a',
    messagingSenderId: '226271839103',
    projectId: 'novotel-westlands-in-house-app',
    storageBucket: 'novotel-westlands-in-house-app.firebasestorage.app',
    iosBundleId: 'com.novotel.inhouse',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDKCeQ63wcow_G54r1CtxxPqED-773oQM8',
    appId: '1:226271839103:web:0177a2d003b64eeed4504a',
    messagingSenderId: '226271839103',
    projectId: 'novotel-westlands-in-house-app',
    storageBucket: 'novotel-westlands-in-house-app.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDKCeQ63wcow_G54r1CtxxPqED-773oQM8',
    appId: '1:226271839103:web:0177a2d003b64eeed4504a',
    messagingSenderId: '226271839103',
    projectId: 'novotel-westlands-in-house-app',
    storageBucket: 'novotel-westlands-in-house-app.firebasestorage.app',
  );
}
