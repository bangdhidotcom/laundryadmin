// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ManajemenPromoPage extends StatefulWidget {
  const ManajemenPromoPage({Key? key}) : super(key: key);

  @override
  State<ManajemenPromoPage> createState() => _ManajemenPromoPageState();
}

class _ManajemenPromoPageState extends State<ManajemenPromoPage> {
  final _supabaseService = SupabaseService();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addPromo() async {
    if (_codeController.text.isEmpty || _discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi semua field wajib'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _supabaseService.addPromo({
        'code': _codeController.text,
        'discount_percent': double.parse(_discountController.text),
        'description': _descriptionController.text,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      _codeController.clear();
      _discountController.clear();
      _descriptionController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Promo'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Promo Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Kode Promo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.local_offer),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              decoration: InputDecoration(
                labelText: 'Diskon (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.percent),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addPromo,
                child: const Text('Tambah Promo'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Promo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder(
              future: _supabaseService.getPromos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return const Center(child: Text('Belum ada promo'));
                }
                final promos = snapshot.data as List;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.discount),
                        title: Text(promo['code'] ?? ''),
                        subtitle: Text(promo['description'] ?? ''),
                        trailing: Chip(
                          label: Text('${promo['discount_percent']}%'),
                          backgroundColor: Colors.green[200],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
