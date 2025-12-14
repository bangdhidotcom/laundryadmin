// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/supabase_service.dart';

class DataOutletPage extends StatefulWidget {
  const DataOutletPage({super.key});

  @override
  State<DataOutletPage> createState() => _DataOutletPageState();
}

class _DataOutletPageState extends State<DataOutletPage> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _outlets = [];
  bool _isLoading = true;

  // Default Location (Malang) - Titik awal saat buka peta
  final LatLng _defaultCenter = const LatLng(-7.9666, 112.6326);

  @override
  void initState() {
    super.initState();
    _fetchOutlets();
  }

  Future<void> _fetchOutlets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.getOutlets();
      setState(() {
        _outlets = data;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data outlet: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FORM DIALOG (TAMBAH / EDIT) ---
  void _showOutletDialog({Map<String, dynamic>? outlet}) {
    final nameController = TextEditingController(text: outlet?['name'] ?? '');
    final addressController = TextEditingController(text: outlet?['address'] ?? '');
    final phoneController = TextEditingController(text: outlet?['phone'] ?? '');
    
    // Jika edit, ambil lokasi dari database. Jika baru, null.
    LatLng? pickedLocation;
    if (outlet != null && outlet['latitude'] != null && outlet['longitude'] != null) {
      pickedLocation = LatLng(outlet['latitude'], outlet['longitude']);
    }

    // Helper untuk update UI Dialog saat lokasi dipilih
    // Kita butuh StatefulBuilder di dalam dialog agar tampilan tombol berubah
    showDialog(
      context: context,
      builder: (context) {
        // Variable lokal di dalam dialog untuk menampung lokasi sementara
        LatLng? tempLocation = pickedLocation;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(outlet == null ? 'Tambah Outlet' : 'Edit Outlet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Outlet', prefixIcon: Icon(Icons.store)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Nomor Telepon', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.home)),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    // TOMBOL PILIH LOKASI
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Buka Map Picker & Tunggu hasilnya
                          final result = await _openMapPicker(tempLocation ?? _defaultCenter);
                          if (result != null) {
                            setStateDialog(() {
                              tempLocation = result;
                            });
                          }
                        },
                        icon: Icon(
                          tempLocation == null ? Icons.map : Icons.check_circle,
                          color: tempLocation == null ? Colors.grey : Colors.green,
                        ),
                        label: Text(
                          tempLocation == null ? 'Set Titik Lokasi (Wajib)' : 'Lokasi Terpilih (Ubah?)',
                          style: TextStyle(
                            color: tempLocation == null ? Colors.grey[700] : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: tempLocation == null ? Colors.grey : Colors.green),
                        ),
                      ),
                    ),
                    if (tempLocation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Lat: ${tempLocation!.latitude.toStringAsFixed(5)}, Lng: ${tempLocation!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || addressController.text.isEmpty) {
                      Get.snackbar('Error', 'Nama dan Alamat wajib diisi');
                      return;
                    }
                    if (tempLocation == null) {
                      Get.snackbar('Error', 'Lokasi peta wajib dipilih!');
                      return;
                    }

                    try {
                      if (outlet == null) {
                        // Tambah Baru
                        await _supabaseService.addOutlet(
                          nameController.text,
                          addressController.text,
                          phoneController.text,
                          lat: tempLocation!.latitude,
                          lng: tempLocation!.longitude,
                        );
                      } else {
                        // Update Existing
                        await _supabaseService.updateOutlet(
                          outlet['id'],
                          nameController.text,
                          addressController.text,
                          phoneController.text,
                          lat: tempLocation!.latitude,
                          lng: tempLocation!.longitude,
                        );
                      }
                      Navigator.pop(context);
                      _fetchOutlets(); // Refresh List
                      Get.snackbar('Sukses', 'Data outlet berhasil disimpan');
                    } catch (e) {
                      Get.snackbar('Error', e.toString());
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- MAP PICKER DIALOG (Fungsi Helper) ---
  Future<LatLng?> _openMapPicker(LatLng initialCenter) async {
    LatLng selected = initialCenter;
    
    return await showDialog<LatLng>(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15,
                  onTap: (_, latlng) {
                    selected = latlng;
                    (ctx as Element).markNeedsBuild(); // Force rebuild dialog
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.laundry3b',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selected,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on, color: Colors.blue, size: 50),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: const Text('Gunakan Lokasi Ini'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HAPUS DATA ---
  void _confirmDelete(int id) {
    Get.defaultDialog(
      title: 'Hapus Outlet?',
      middleText: 'Data yang dihapus tidak bisa dikembalikan.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          await _supabaseService.deleteOutlet(id);
          Get.back();
          _fetchOutlets();
          Get.snackbar('Sukses', 'Outlet berhasil dihapus');
        } catch (e) {
          Get.snackbar('Error', e.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Outlet')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOutletDialog(),
        backgroundColor: const Color(0xFF005f9f),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _outlets.isEmpty
              ? const Center(child: Text('Belum ada data outlet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _outlets.length,
                  itemBuilder: (context, index) {
                    final item = _outlets[index];
                    final hasLoc = item['latitude'] != null;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasLoc ? Colors.blue[100] : Colors.grey[200],
                          child: Icon(Icons.store, color: hasLoc ? Colors.blue : Colors.grey),
                        ),
                        title: Text(item['name'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.phone, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(item['phone'] ?? '-', style: const TextStyle(fontSize: 12)),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(child: Text(item['address'] ?? '-', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showOutletDialog(outlet: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}