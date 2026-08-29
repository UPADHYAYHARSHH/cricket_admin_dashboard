// File generated for Cricket Admin Dashboard
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCgKW_q7BeK8ph0hsJ90-gz9URU4TXfcIE',
    appId: '1:6843481967:web:c4b2f04d2b45ab1fcc729a',
    messagingSenderId: '6843481967',
    projectId: 'box-cricket-df427',
    authDomain: 'box-cricket-df427.firebaseapp.com',
    storageBucket: 'box-cricket-df427.firebasestorage.app',
    measurementId: 'G-FS902TH19V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDD1eiwwO6WNgjTYA59Es99r6ncQgIpvXQ',
    appId: '1:6843481967:android:57ad42711093fdf3cc729a',
    messagingSenderId: '6843481967',
    projectId: 'box-cricket-df427',
    storageBucket: 'box-cricket-df427.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtPd4ZimKi0RtzJmlHULjkMdNP1VuyqEk',
    appId: '1:6843481967:ios:20424a2994cfdc17cc729a',
    messagingSenderId: '6843481967',
    projectId: 'box-cricket-df427',
    storageBucket: 'box-cricket-df427.firebasestorage.app',
    iosBundleId: 'com.example.boxCricketNew',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAPcP9A64rJnenha0LRq7vEOIzS9PISFwU',
    appId: '1:1066185787341:ios:18fe9dd46625b6c4c6e684',
    messagingSenderId: '1066185787341',
    projectId: 'box-cricket-72b9b',
    storageBucket: 'box-cricket-72b9b.firebasestorage.app',
    iosBundleId: 'com.example.boxCricketNew',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgKW_q7BeK8ph0hsJ90-gz9URU4TXfcIE',
    appId: '1:6843481967:web:c4b2f04d2b45ab1fcc729a',
    messagingSenderId: '6843481967',
    projectId: 'box-cricket-df427',
    authDomain: 'box-cricket-df427.firebaseapp.com',
    storageBucket: 'box-cricket-df427.firebasestorage.app',
    measurementId: 'G-FS902TH19V',
  );
}
