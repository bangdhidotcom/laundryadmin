// lib/screens/splash_screen.dart
// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/pages/main_page.dart';
import 'package:laundry3b1titik0/pages/login_page.dart';
import 'package:laundry3b1titik0/services/admin_notification_service.dart'; // <--- WAJIB ADA

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });

    _startApp(); // Panggil fungsi startApp
  }

  Future<void> _startApp() async {
    // 1. INIT NOTIFIKASI DI SINI (AMAN)
    try {
      await AdminNotificationService().init();
      print("✅ Notifikasi Service Started in Splash");
    } catch (e) {
      print("⚠️ Warning Init Notif: $e");
    }

    // 2. Delay animasi
    await Future.delayed(const Duration(seconds: 2));

    // 3. Cek Login
    if (mounted) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        Get.offAll(() => const MainPage());
      } else {
        Get.offAll(() => const LoginPage());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset('assets/images/logo_3b.png', height: 400),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
