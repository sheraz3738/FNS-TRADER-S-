import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCexV1V2buIZxkMp8UWLrEVyvNZbS-5_jc',
    appId: '1:463092625779:android:ca1ff7fe26440ad5741506',
    messagingSenderId: '463092625779',
    projectId: 'fns-traders-karachi',
    storageBucket: 'fns-traders-karachi.firebasestorage.app',
  );
}
