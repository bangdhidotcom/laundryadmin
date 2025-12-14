// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../pages/manajemen_order_page.dart';

// Handler background wajib ada di luar class (top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("BG Notif: ${message.messageId}");
}

class AdminNotificationService {
  static final AdminNotificationService _instance =
      AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Request Permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Local Notification (Pastikan icon 'logo_notif' ada di folder drawable)
    // Jika tidak ada logo_notif, ganti string di bawah ini ke '@mipmap/ic_launcher'
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Setup Listeners
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // FOREGROUND: Tampilkan Notifikasi saat aplikasi dibuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Pesan masuk saat Foreground: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // BACKGROUND: Handle klik saat aplikasi berjalan di background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 Notifikasi diklik dari background!");
      _safeNavigation(message.data);
    });

    // TERMINATED: Handle klik saat aplikasi mati total
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("🔔 Aplikasi dibuka dari Notifikasi (Terminated)");
      Future.delayed(const Duration(seconds: 2), () {
        _safeNavigation(initialMessage.data);
      });
    }

    // Subscribe ke topic (PENTING: Agar semua admin dapat notif serentak)
    await _firebaseMessaging.subscribeToTopic('admin_orders'); // Opsional jika pakai topic
    
    // 4. Update Token Otomatis
    updateAdminToken();
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      updateAdminToken();
    });
  }

  // --- LOGIKA NAVIGASI (SAFE NAVIGATION) ---
  static void _onNotificationTap(NotificationResponse details) {
    if (details.payload != null) {
      try {
        final data = json.decode(details.payload!);
        if (data is Map<String, dynamic>) {
          _instance._safeNavigation(data);
        } else {
          _instance._safeNavigation(Map<String, dynamic>.from(data));
        }
      } catch (e) {
        print("Error parsing payload: $e");
      }
    }
  }

  void _safeNavigation(Map<String, dynamic> data) {
    // Payload 'new_order' dikirim dari Supabase Edge Function
    if (data['type'] == 'new_order') {
      print("🚀 Navigasi ke Manajemen Order...");
      
      // Cek apakah GetX sudah siap
      if (Get.context != null) {
        Get.to(() => const ManajemenOrderPage());
      } else {
        // Retry mechanism
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (Get.context != null) {
            Get.to(() => const ManajemenOrderPage());
          }
        });
      }
    }
  }

  // --- TAMPILKAN NOTIFIKASI ---
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'admin_order_notif_v2',
            'Order Masuk',
            channelDescription: 'Notifikasi order baru untuk admin',
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFF005f9f),
            sound: const RawResourceAndroidNotificationSound('notification'),
            playSound: true, 
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // --- FUNGSI UPDATE TOKEN KE DB ---
  Future<void> updateAdminToken() async {
    try {
      // Delay sedikit memastikan sesi auth siap
      await Future.delayed(const Duration(seconds: 2));
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        print("⚠️ Admin belum login, skip simpan token.");
        return;
      }

      String? token = await _firebaseMessaging.getToken();
      if (token == null) return;
      print("FCM Token Admin: $token");

      final supabase = Supabase.instance.client;

      // Upsert data admin
      final Map<String, dynamic> data = {
        'id': user.id,
        'email': user.email,
        'fcm_token': token,
        'role': 'admin',
      };

      // Coba ambil nama dari metadata jika ada
      if (user.userMetadata?['name'] != null) {
        data['name'] = user.userMetadata!['name'];
      } else {
        // Fallback name jika tidak ada (opsional)
        data['name'] = user.email?.split('@')[0] ?? 'Admin';
      }

      await supabase.from('admins').upsert(data);
      print("✅ Token Admin berhasil disimpan.");
    } catch (e) {
      print("Info: Gagal auto-save token (mungkin koneksi): $e");
    }
  }
}