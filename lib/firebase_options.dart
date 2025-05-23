// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: "AIzaSyANfq_jphHTILCr_EsWILKpdlQn-2BcEI4",
      authDomain: "tswcd2-87a16.firebaseapp.com",
      databaseURL: "https://tswcd2-87a16-default-rtdb.firebaseio.com",
      projectId: "tswcd2-87a16",
      storageBucket: "tswcd2-87a16.appspot.com",
      messagingSenderId: "886894692072",
      appId: "1:886894692072:web:ac29eba4fde453d7ae6b5d",
      measurementId: "G-CHW00D8PJS"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB1jy_wJiRcGjt_rwBQQR7ImM0sFtViIqE',
    appId: '1:886894692072:android:65e99c705a0f6ddbae6b5d',
    messagingSenderId: '886894692072',
    projectId: 'tswcd2-87a16',
    storageBucket: 'tswcd2-87a16.appspot.com',
  );
}
