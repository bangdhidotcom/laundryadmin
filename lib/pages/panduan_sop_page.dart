// ignore_for_file: use_super_parameters, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';

class PanduanSopPage extends StatelessWidget {
  const PanduanSopPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan SOP'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Penerimaan Order', [
              'Cek form order lengkap (nama, alamat, jenis layanan, harga)',
              'Catat item yang diterima dengan detail',
              'Buat nomor tracking untuk customer',
              'Informasikan estimasi waktu selesai',
            ]),
            const SizedBox(height: 16),
            _buildSection('2. Proses Pencucian', [
              'Pisahkan item berdasarkan jenis dan warna',
              'Pilih deterjen dan suhu air yang sesuai',
              'Gunakan mesin cuci sesuai kapasitas',
              'Pantau proses pencucian secara berkala',
            ]),
            const SizedBox(height: 16),
            _buildSection('3. Pengeringan & Finishing', [
              'Keringkan dengan mesin pengering sesuai jenis bahan',
              'Lakukan penyetrikaan jika perlu',
              'Lipat atau gantung dengan rapi',
              'Kemasan produk dengan plastik/tas',
            ]),
            const SizedBox(height: 16),
            _buildSection('4. Pengiriman/Pengambilan', [
              'Konfirmasi dengan customer sebelum pengiriman',
              'Catat tanda terima dari customer',
              'Fotografi barang sebelum dikirim (opsional)',
              'Update status order ke "Completed"',
            ]),
            const SizedBox(height: 16),
            _buildSection('5. Standar Kualitas', [
              'Tidak ada noda atau kerusakan pada bahan',
              'Aroma deterjen yang segar',
              'Pengemasan yang rapi dan aman',
              'Pengiriman tepat waktu sesuai komitmen',
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
