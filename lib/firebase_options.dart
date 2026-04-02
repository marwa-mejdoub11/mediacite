// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
/*
Remplacer les valeurs par celles de ton google-services.json :
current_key → apiKey
mobilesdk_app_id → appId
project_id → projectId
storage_bucket → storageBucket
project_number → messagingSenderId*/

class DefaultFirebaseOptions {
 static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "AIzaSyBg10waejuFAmM8zZX4l0cQSVuI42orph4",
    appId: "1:810482541780:android:5b41c7cb88bb25067f8741",
     messagingSenderId: "810482541780",
     projectId: "flutter-firebase-2cb6d",
    storageBucket: "flutter-firebase-2cb6d.firebasestorage.app",
  );
}