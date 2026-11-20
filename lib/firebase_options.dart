import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCRfqbs7a1XlpgY8D8w4gfrdju7c1dcOF8',
    appId: '1:463092625779:web:c79e4febdddcbe27741506',
    messagingSenderId: '463092625779',
    projectId: 'fns-traders-karachi',
    authDomain: 'fns-traders-karachi.firebaseapp.com',
    storageBucket: 'fns-traders-karachi.firebasestorage.app',
    measurementId: 'G-5F55D3WJ1P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCexV1V2buIZxkMp8UWLrEVyvNZbS-5_jc',
    appId: '1:463092625779:android:ca1ff7fe26440ad5741506',
    messagingSenderId: '463092625779',
    projectId: 'fns-traders-karachi',
    storageBucket: 'fns-traders-karachi.firebasestorage.app',
  );
}
