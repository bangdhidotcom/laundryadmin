// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/controllers/main_page_controller.dart';
import 'package:laundry3b1titik0/screens/home_screen.dart';
import 'package:laundry3b1titik0/screens/orders_screen.dart';
import 'package:laundry3b1titik0/screens/chat_screen.dart';
import 'package:laundry3b1titik0/screens/profile_screen.dart';
import 'package:laundry3b1titik0/pages/add_order_page.dart';
import 'package:laundry3b1titik0/pages/data_outlet_page.dart';
import 'package:laundry3b1titik0/pages/laporan_keuangan_page.dart';
import 'package:laundry3b1titik0/pages/data_pelanggan_page.dart';
import 'package:laundry3b1titik0/pages/manajemen_promo_page.dart';
import 'package:laundry3b1titik0/pages/kelola_layanan_page.dart';
import 'package:laundry3b1titik0/pages/panduan_sop_page.dart';
import 'package:laundry3b1titik0/pages/lihat_antrian_page.dart';

class MainPage extends GetView<MainPageController> {
  const MainPage({super.key});

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    OrdersScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final MainPageController controller = Get.put(MainPageController());

    return Scaffold(
      body: Obx(() {
        return Center(
          child: _widgetOptions.elementAt(controller.selectedIndex.value),
        );
      }),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),

          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Data Order',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              activeIcon: Icon(Icons.forum),
              label: 'Koordinasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          ],

          currentIndex: controller.selectedIndex.value,
          onTap: (index) => controller.changePage(index),
        ),
      ),
    );
  }
}
