import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated automatically using credentials for `hiwotnet-c97fd`.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXqF_q1eMHT6jitta6p50fWhFR7m9j9gA',
    appId: '1:971403708389:web:12efeed9eb8fab4981510c',
    messagingSenderId: '971403708389',
    projectId: 'hiwotnet-c97fd',
    authDomain: 'hiwotnet-c97fd.firebaseapp.com',
    databaseURL: 'https://hiwotnet-c97fd-default-rtdb.firebaseio.com',
    storageBucket: 'hiwotnet-c97fd.firebasestorage.app',
    measurementId: 'G-4HLVVQTB26',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXqF_q1eMHT6jitta6p50fWhFR7m9j9gA',
    appId: '1:971403708389:web:12efeed9eb8fab4981510c',
    messagingSenderId: '971403708389',
    projectId: 'hiwotnet-c97fd',
    authDomain: 'hiwotnet-c97fd.firebaseapp.com',
    databaseURL: 'https://hiwotnet-c97fd-default-rtdb.firebaseio.com',
    storageBucket: 'hiwotnet-c97fd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXqF_q1eMHT6jitta6p50fWhFR7m9j9gA',
    appId: '1:971403708389:web:12efeed9eb8fab4981510c',
    messagingSenderId: '971403708389',
    projectId: 'hiwotnet-c97fd',
    authDomain: 'hiwotnet-c97fd.firebaseapp.com',
    databaseURL: 'https://hiwotnet-c97fd-default-rtdb.firebaseio.com',
    storageBucket: 'hiwotnet-c97fd.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBXqF_q1eMHT6jitta6p50fWhFR7m9j9gA',
    appId: '1:971403708389:web:12efeed9eb8fab4981510c',
    messagingSenderId: '971403708389',
    projectId: 'hiwotnet-c97fd',
    authDomain: 'hiwotnet-c97fd.firebaseapp.com',
    databaseURL: 'https://hiwotnet-c97fd-default-rtdb.firebaseio.com',
    storageBucket: 'hiwotnet-c97fd.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBXqF_q1eMHT6jitta6p50fWhFR7m9j9gA',
    appId: '1:971403708389:web:12efeed9eb8fab4981510c',
    messagingSenderId: '971403708389',
    projectId: 'hiwotnet-c97fd',
    authDomain: 'hiwotnet-c97fd.firebaseapp.com',
    databaseURL: 'https://hiwotnet-c97fd-default-rtdb.firebaseio.com',
    storageBucket: 'hiwotnet-c97fd.firebasestorage.app',
  );
}
