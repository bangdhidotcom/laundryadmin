import 'package:flutter/material.dart';
import 'catalog_screen.dart';

class DetailScreen extends StatelessWidget {
  final LaundryService service;

  const DetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // Ambil warna dari Tema
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    Widget displayWidget;
    String heroTag;

    if (service.imageUrl != null && service.imageUrl!.isNotEmpty) {
      // 1. Jika ADA URL Gambar
      heroTag = 'service-image-${service.name}';
      displayWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Image.network(
          service.imageUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) =>
              Container(
                width: 120,
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 60, color: Colors.grey),
              ),
        ),
      );
    } else {
      // 2. Jika TIDAK ADA URL, pakai Ikon Otomatis
      heroTag = 'service-icon-${service.name}';
      displayWidget = Icon(
        service.icon,
        size: 120,
        color: colorScheme.primary,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SOP & Catatan Layanan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: heroTag,
              child: Material(
                type: MaterialType.transparency,
                child: displayWidget,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              service.name,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                // Warna teks otomatis dari tema
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              service.price,
              style: textTheme.headlineSmall?.copyWith(
                // Biarkan merah, ini semantik
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Ringkasan SOP (Standard Operating Procedure):',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                // Warna teks otomatis dari tema
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getSop(service.name), // SOP Statis
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.5,
                // Warna teks otomatis dari tema
              ),
            ),

            // Tampilkan deskripsi/catatan tambahan jika ada
            if (service.description.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Catatan Tambahan:',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  // Warna teks otomatis dari tema
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service.description, // Data dari "Kelola Layanan"
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  // Warna teks otomatis dari tema
                  fontStyle: FontStyle.italic,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Fungsi SOP Statis ini kita biarkan
  String _getSop(String serviceName) {
    // Kita buat case-insensitive agar lebih kuat
    String nameLower = serviceName.toLowerCase();

    if (nameLower.contains('sepatu')) {
      return '1. Cek bahan sepatu (Canvas/Kulit). \n2. Gunakan sikat & sabun khusus. \n3. Keringkan di ruang angin, JANGAN dijemur matahari langsung.';
    }
    if (nameLower.contains('dry clean') || nameLower.contains('jas')) {
      return '1. Cek label garmen. \n2. Gunakan solvent (Perchloroethylene) di mesin Dry Clean. \n3. Proses finishing menggunakan setrika uap khusus.';
    }
    if (nameLower.contains('bed cover')) {
      return '1. Gunakan mesin kapasitas besar (min. 15kg). \n2. Pastikan bed cover terendam sempurna. \n3. Proses pengeringan 100% di mesin pengering agar tidak apek.';
    }
    if (nameLower.contains('tas') || nameLower.contains('ransel')) {
      return '1. Kosongkan isi tas. \n2. Bersihkan debu (vakum jika perlu). \n3. Gunakan sikat halus & sabun khusus. \n4. Keringkan di ruang angin.';
    }
    if (nameLower.contains('setrika')) {
      return '1. Siapkan setrika uap. \n2. Semprotkan pelicin jika perlu. \n3. Lipat & kemas dengan rapi.';
    }
    // Default SOP
    return '1. Pisahkan pakaian putih & berwarna. \n2. Timbang berat kering. \n3. Masukkan ke mesin cuci, set deterjen & pelembut. \n4. Keringkan 100% di mesin pengering.';
  }
}