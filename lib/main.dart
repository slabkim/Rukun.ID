import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart'; // Di web wajib, di Android/iOS opsional bila ada google-services.json/plist
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hindari inisialisasi ganda saat hot-restart dan dukung konfigurasi native di Android/iOS.
  if (Firebase.apps.isEmpty) {
    try {
      if (kIsWeb) {
        // Web wajib pakai options dari FlutterFire CLI
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        // Android/iOS: gunakan konfigurasi native (google-services.json / GoogleService-Info.plist)
        // Jika belum ada, Anda masih bisa pakai DefaultFirebaseOptions setelah di-generate.
        await Firebase.initializeApp();
      }
    } catch (e, st) {
      // Jangan block UI bila Firebase gagal init; log saja.
      // Ini memungkinkan aplikasi tetap terbuka agar Anda bisa melihat pesan kesalahan.
      debugPrint('Firebase init failed: $e\n$st');
    }
  }

  // Init local notifications
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(const RukunApp());
}
