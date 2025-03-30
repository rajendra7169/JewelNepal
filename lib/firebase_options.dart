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
    apiKey: 'AIzaSyCV7F85qUmNtpVbrJcEJyIu71n2uWYh2eE',
    appId: '1:811753341316:web:158e7a8776313bb9579dd1',
    messagingSenderId: '811753341316',
    projectId: 'jewelneapl',
    authDomain: 'jewelneapl.firebaseapp.com',
    storageBucket: 'jewelneapl.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMF7kcWor2RxauifY0-BI6KSvMc82zG3k',
    appId: '1:811753341316:android:9f1e38e6a3575d3d579dd1',
    messagingSenderId: '811753341316',
    projectId: 'jewelneapl',
    storageBucket: 'jewelneapl.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-ALp2FI-0TM7W1QL2hEd-5t_V-qEtfYU',
    appId: '1:811753341316:ios:10bfe4b125d49303579dd1',
    messagingSenderId: '811753341316',
    projectId: 'jewelneapl',
    storageBucket: 'jewelneapl.firebasestorage.app',
    iosBundleId: 'com.example.jewelryApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD-ALp2FI-0TM7W1QL2hEd-5t_V-qEtfYU',
    appId: '1:811753341316:ios:10bfe4b125d49303579dd1',
    messagingSenderId: '811753341316',
    projectId: 'jewelneapl',
    storageBucket: 'jewelneapl.firebasestorage.app',
    iosBundleId: 'com.example.jewelryApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCV7F85qUmNtpVbrJcEJyIu71n2uWYh2eE',
    appId: '1:811753341316:web:cc04646b148648de579dd1',
    messagingSenderId: '811753341316',
    projectId: 'jewelneapl',
    authDomain: 'jewelneapl.firebaseapp.com',
    storageBucket: 'jewelneapl.firebasestorage.app',
  );
}
