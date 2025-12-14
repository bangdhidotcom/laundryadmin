// [GANTI SELURUH ISI FILE lib/home_screen.dart]

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/screens/catalog_screen.dart'; // Tetap ada untuk tombol 'Manajemen Layanan' (SOP)
import 'package:laundry3b1titik0/screens/delivery_screen.dart';
import 'package:laundry3b1titik0/pages/data_outlet_page.dart';
import 'package:laundry3b1titik0/pages/laporan_keuangan_page.dart';
import 'package:laundry3b1titik0/pages/data_pelanggan_page.dart';
import 'package:laundry3b1titik0/pages/manajemen_promo_page.dart';
// --- PERUBAHAN NAMA FILE ---
import 'package:laundry3b1titik0/pages/kelola_layanan_page.dart'; // Import file baru
// --- AKHIR PERUBAHAN ---
import 'package:laundry3b1titik0/pages/panduan_sop_page.dart';
import 'package:laundry3b1titik0/pages/lihat_antrian_page.dart';
import 'package:laundry3b1titik0/pages/manajemen_order_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_3b.png',
              height: 80,
              color: Colors.white,
              colorBlendMode: BlendMode.modulate,
            ),
            const SizedBox(width: 12),
            const Text(
              'Laundry 3B - Admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildWelcomeHeader(context),
          Transform.translate(
            offset: const Offset(0.0, -70.0),
            child: _buildInfoCard(context),
          ),
          _buildMenuSection(context),
          const SizedBox(height: 24),
          _buildPromoSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
      decoration: const BoxDecoration(
        color: Color(0xFF005f9f),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Operasional',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ringkasan status laundry hari ini.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final Color cardColor = Theme.of(context).colorScheme.errorContainer;
    final Color textColor = Theme.of(context).colorScheme.onErrorContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor, // Gunakan warna errorContainer
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Perlu Perhatian',
              style: TextStyle(
                  color: textColor.withOpacity(0.8), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '7 Order Antri Pickup',
              style: TextStyle(
                color: textColor, // Gunakan warna onErrorContainer
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Get.to(() => const LihatAntrianPage());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor, // Gunakan warna onErrorContainer
                side: BorderSide(color: textColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Lihat Antrian Pickup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.05),
                blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Kontrol',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildMenuGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.add_shopping_cart,
        'label': 'Manajemen Order',
        'page': const ManajemenOrderPage(),
      },
      // --- PERUBAHAN UI MENU ---
      // Tombol ini (Manajemen Layanan) kita pertahankan
      // Sesuai konsep, ini untuk melihat SOP
      {
        'icon': Icons.inventory_2,
        'label': 'Manajemen Layanan',
        'page': const CatalogScreen(),
      },
      // --- AKHIR PERUBAHAN ---
      {
        'icon': Icons.delivery_dining,
        'label': 'Manajemen Kurir',
        'page': const DeliveryScreen(),
      },
      {
        'icon': Icons.store,
        'label': 'Data Outlet',
        'page': const DataOutletPage(),
      },
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Laporan Keuangan',
        'page': const LaporanKeuanganPage(),
      },
      {
        'icon': Icons.people,
        'label': 'Data Pelanggan',
        'page': const DataPelangganPage(),
      },
      {
        'icon': Icons.confirmation_number,
        'label': 'Manajemen Promo',
        'page': const ManajemenPromoPage(),
      },
      {
        'icon': Icons.edit_note,
        'label': 'Kelola Layanan',
        'page': const KelolaLayananPage(),
      },
      {
        'icon': Icons.menu_book,
        'label': 'Panduan SOP',
        'page': const PanduanSopPage(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100.0,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return HomeMenuButton(
          icon: item['icon'],
          label: item['label'],
          page: item['page'],
        );
      },
    );
  }

  Widget _buildPromoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pemberitahuan Sistem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildPromoBanner(context),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perlu Perhatian',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mesin Pengering #2 dijadwalkan maintenance sore ini pukul 16:00.',
                  style: TextStyle(
                      fontSize: 14,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.campaign,
              color: Theme.of(context).colorScheme.secondary, size: 50),
        ],
      ),
    );
  }
}

class HomeMenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Widget? page;

  const HomeMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.page,
  });

  @override
  State<HomeMenuButton> createState() => _HomeMenuButtonState();
}

class _HomeMenuButtonState extends State<HomeMenuButton> {
  bool _isInteracting = false;
  static const Duration _animDuration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final scale = _isInteracting ? 0.95 : 1.0;
    final bgColor = _isInteracting
        ? primaryColor.withOpacity(0.2)
        : primaryColor.withOpacity(0.1);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isInteracting = true),
      onTapUp: (_) {
        setState(() => _isInteracting = false);

        if (widget.page != null) {
          Get.to(() => widget.page!);
        }
      },
      onTapCancel: () => setState(() => _isInteracting = false),
      child: AnimatedScale(
        scale: scale,
        duration: _animDuration,
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: _animDuration,
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).textTheme.bodySmall?.color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}