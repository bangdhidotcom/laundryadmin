// [GANTI SELURUH ISI FILE: lib/catalog_screen.dart]

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:laundry3b1titik0/screens/detail_screen.dart';
import 'package:laundry3b1titik0/controllers/catalog_controller.dart';

class LaundryService {
  final String name;
  final String price;
  final IconData icon;
  final String description;
  final String? imageUrl; // <-- TAMBAHKAN INI

  LaundryService({
    required this.name,
    required this.price,
    required this.icon,
    required this.description,
    this.imageUrl, // <-- TAMBAHKAN INI
  });

  factory LaundryService.fromJson(Map<String, dynamic> json) {
    final serviceName = json['service_name'] as String? ?? 'Unknown Service';
    final iconData = getIconFromString(serviceName);

    String priceString;
    final priceNum = (json['price'] as num?)?.toDouble();

    if (priceNum != null) {
      priceString = 'Rp ${priceNum.toStringAsFixed(0)}';
    } else {
      priceString = 'Harga tidak diatur';
    }

    return LaundryService(
      name: serviceName,
      price: priceString,
      icon: iconData,
      description: json['description'] ?? '',
      imageUrl: json['image_url'] as String?, // <-- TAMBAHKAN INI
    );
  }

  // --- LOGIKA SMART MAPPING IKON (TETAP SAMA) ---
  static IconData getIconFromString(String serviceName) {
    String nameLower = serviceName.toLowerCase();

    if (nameLower.contains('sepatu')) {
      return Icons.ice_skating;
    }
    if (nameLower.contains('jas') || nameLower.contains('dry clean')) {
      return Icons.dry_cleaning;
    }
    if (nameLower.contains('bed cover') || nameLower.contains('sprei')) {
      return Icons.king_bed;
    }
    if (nameLower.contains('kemeja') || nameLower.contains('gaun')) {
      return Icons.checkroom;
    }
    if (nameLower.contains('setrika')) {
      return Icons.iron;
    }
    if (nameLower.contains('tas') || nameLower.contains('ransel')) {
      return Icons.shopping_bag;
    }
    
    return Icons.local_laundry_service;
  }
}

class CatalogScreen extends GetView<CatalogController> {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CatalogController catalogController = Get.put(CatalogController());

    final Size screenSize = MediaQuery.of(context).size;
    final int crossAxisCount = screenSize.width > 600 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Layanan'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              catalogController.refreshServices();
            },
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Obx(() {
        if (catalogController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (catalogController.services.isEmpty) {
          return const Center(child: Text('Tidak ada layanan tersedia'));
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: catalogController.services.length,
            itemBuilder: (context, index) {
              return ServiceCard(service: catalogController.services[index]);
            },
          ),
        );
      }),
    );
  }
}

class ServiceCard extends StatefulWidget {
  const ServiceCard({super.key, required this.service});

  final LaundryService service;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final double elevation = _isPressed ? 8.0 : 2.0;
    final EdgeInsets padding = _isPressed
        ? const EdgeInsets.all(16.0)
        : const EdgeInsets.all(12.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          Get.to(() => DetailScreen(service: widget.service));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              blurRadius: elevation,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Kita tidak perlu lagi buildCompactCard/buildWideCard
            // Kita satukan logikanya agar lebih mudah dibaca
            return buildCardContent(context);
          },
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK KONTEN KARTU ---
  Widget buildCardContent(BuildContext context) {
    final service = widget.service;
    Widget displayWidget;
    String heroTag;

    // --- LOGIKA FALLBACK ---
    if (service.imageUrl != null && service.imageUrl!.isNotEmpty) {
      // 1. Jika ADA URL Gambar
      heroTag = 'service-image-${service.name}';
      displayWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          service.imageUrl!,
          fit: BoxFit.cover,
          width: 50, // Ukuran bisa disesuaikan
          height: 50,
          // Loading builder agar rapi
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              width: 50,
              height: 50,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          // Error builder jika gagal load
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 50,
              height: 50,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
            );
          },
        ),
      );
    } else {
      // 2. Jika TIDAK ADA URL, pakai Ikon Otomatis
      heroTag = 'service-icon-${service.name}';
      displayWidget = Icon(
        service.icon,
        size: 40,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: heroTag, // Gunakan tag dinamis
          child: Material(
            type: MaterialType.transparency,
            child: displayWidget, // Tampilkan widget dinamis
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.service.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.service.price,
          style: TextStyle(color: Colors.red[700], fontSize: 12),
        ),
      ],
    );
  }
}