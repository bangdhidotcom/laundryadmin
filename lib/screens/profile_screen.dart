// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../services/theme_service.dart';
import '../pages/login_page.dart';
import '../pages/data_outlet_page.dart';
import '../pages/kelola_layanan_page.dart';
import '../pages/manajemen_promo_page.dart';
import '../pages/laporan_keuangan_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabaseService = SupabaseService();
  final _radiusController = TextEditingController();
  final _marqueeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final radius = await _supabaseService.getConfigValue('max_radius_km');
      final marquee = await _supabaseService.getConfigValue('marquee_text');
      
      _radiusController.text = radius;
      _marqueeController.text = marquee;
    } catch (e) {
      debugPrint('Error load settings: $e'); // Gunakan debugPrint agar aman
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateConfigValue('max_radius_km', _radiusController.text);
      await _supabaseService.updateConfigValue('marquee_text', _marqueeController.text);
      
      Get.snackbar('Sukses', 'Pengaturan berhasil disimpan!', 
        backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan: $e', 
        backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeService themeService = Get.find();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Admin'),
        actions: [
          // Tombol Ganti Tema
          Obx(() => IconButton(
            icon: Icon(themeService.isDarkMode.value ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeService.switchTheme(),
            tooltip: 'Ganti Tema',
          )),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. PROFIL ADMIN
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text("Administrator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("admin@laundry3b.com", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),

              // 2. OPERASIONAL
              _buildHeader("Kontrol Operasional"),
              TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Batas Radius (KM)',
                  prefixIcon: Icon(Icons.radar),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _marqueeController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Teks Info Berjalan',
                  prefixIcon: Icon(Icons.campaign),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text("SIMPAN PERUBAHAN"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),

              // 3. MENU MANAJEMEN
              _buildHeader("Master Data"),
              _buildMenuTile(Icons.store, "Data Outlet", "Lokasi cabang", () => Get.to(() => const DataOutletPage())),
              _buildMenuTile(Icons.local_laundry_service, "Layanan", "Harga cucian", () => Get.to(() => const KelolaLayananPage())),
              _buildMenuTile(Icons.discount, "Promo", "Voucher diskon", () => Get.to(() => const ManajemenPromoPage())),
              _buildMenuTile(Icons.monetization_on, "Keuangan", "Laporan omzet", () => Get.to(() => const LaporanKeuanganPage())),

              const SizedBox(height: 20),
              
              // 4. LOGOUT
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Hapus sesi Supabase juga biar aman
                    SupabaseService().signOut(); 
                    Get.offAll(() => const LoginPage());
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Keluar Aplikasi", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title, 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        )
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.blue[50], 
            borderRadius: BorderRadius.circular(8)
          ),
          child: Icon(icon, color: isDark ? Colors.blue[200] : Colors.blue[800]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}