// Hand-assembled from the Firebase console config files.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this project.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCv_qEqyjwgfjDy6y0vdo86-sIJIFPP1Sg',
    appId: '1:571605457687:android:225d423573a603e7c33552',
    messagingSenderId: '571605457687',
    projectId: 'packer-36524',
    storageBucket: 'packer-36524.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAV7pk3EjU4auoV2LzlZweJ_I7CgHbgo_8',
    appId: '1:571605457687:ios:0f3e21bdc803023fc33552',
    messagingSenderId: '571605457687',
    projectId: 'packer-36524',
    storageBucket: 'packer-36524.firebasestorage.app',
    iosBundleId: 'com.zyntaxes.packer',
  );
}
