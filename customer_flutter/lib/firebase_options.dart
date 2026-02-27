// Firebase configuration for DukaSell

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdL-yVTqy_UuOitJA5rz5aDmiEKWfJDKc',
    appId: '1:173428267051:android:6b1ce8e805825c6a1fb26e',
    messagingSenderId: '173428267051',
    projectId: 'dukasell',
    storageBucket: 'dukasell.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBWNI4arRau-IPocmDRgsYkaG2bwLVGczY',
    appId: '1:173428267051:ios:3a8baab27e6cd6c61fb26e',
    messagingSenderId: '173428267051',
    projectId: 'dukasell',
    storageBucket: 'dukasell.firebasestorage.app',
    androidClientId: '173428267051-ac4rdigrclqmkgo2mi75gm42d6bkidnl.apps.googleusercontent.com',
    iosClientId: '173428267051-lsjq7189bau00ka7chharnib0vhq1jbr.apps.googleusercontent.com',
    iosBundleId: 'com.dukasell.dukasellCustomer',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDd5TtjRzV8Ph4GrtnVAymmhP7KedLq80k',
    appId: '1:173428267051:web:63b2fe762cb9089b1fb26e',
    messagingSenderId: '173428267051',
    projectId: 'dukasell',
    authDomain: 'dukasell.firebaseapp.com',
    storageBucket: 'dukasell.firebasestorage.app',
    measurementId: 'G-XSVM8TX8FM',
  );
}
