// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  State<AddOrderPage> createState() => _AddOrderPageState();
}

class _AddOrderPageState extends State<AddOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  final Distance _distanceCalculator = const Distance();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedService;
  double _servicePrice = 0;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _outlets = [];
  bool _isLoading = false;

  String _selectedDelivery = 'Reguler';
  double _deliveryFee = 10000;
  LatLng? _pickedLocation;
  
  Map<String, dynamic>? _nearestOutlet;
  double _distanceToOutlet = 0;
  double _maxRadiusKm = 6.0;

  final LatLng _defaultCenter = const LatLng(-7.9666, 112.6326);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabaseService.getPricing(),
        _supabaseService.getOutlets(),
        _supabaseService.getConfigValue('max_radius_km'),
      ]);
      
      if (mounted) {
        setState(() {
          _services = results[0] as List<Map<String, dynamic>>;
          _outlets = results[1] as List<Map<String, dynamic>>;
          final radiusString = results[2] as String;
          if (radiusString.isNotEmpty) {
            _maxRadiusKm = double.tryParse(radiusString) ?? 6.0;
          }
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  void _updateDeliveryFee(String? type) {
    if (type == null) return;
    setState(() {
      _selectedDelivery = type;
      switch (type) {
        case 'Hemat': _deliveryFee = 5000; break;
        case 'Reguler': _deliveryFee = 10000; break;
        case 'Express': _deliveryFee = 20000; break;
      }
    });
  }

  // --- LOGIKA GEOFENCING & DIALOG KEREN ---
  void _checkNearestOutlet(LatLng userLocation) {
    if (_outlets.isEmpty) {
      Get.snackbar('Error', 'Belum ada data outlet!');
      return;
    }

    double minDistance = double.infinity;
    Map<String, dynamic>? closest;

    for (var outlet in _outlets) {
      if (outlet['latitude'] != null && outlet['longitude'] != null) {
        final outletLoc = LatLng(outlet['latitude'], outlet['longitude']);
        final distance = _distanceCalculator.as(LengthUnit.Kilometer, userLocation, outletLoc);
        if (distance < minDistance) {
          minDistance = distance;
          closest = outlet;
        }
      }
    }

    setState(() {
      _pickedLocation = userLocation;
      _distanceToOutlet = minDistance;
      _nearestOutlet = closest;
    });

    // DIALOG PERINGATAN KEREN (CUSTOM)
    if (minDistance > _maxRadiusKm) {
      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent, // Biar rounded corner terlihat
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.not_listed_location, size: 50, color: Colors.red[700]),
                ),
                const SizedBox(height: 15),
                Text(
                  "Di Luar Jangkauan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Get.isDarkMode ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 10),
                Text(
                  "Jarak lokasi ini ${minDistance.toStringAsFixed(1)} KM.\nBatas maksimal kami hanya $_maxRadiusKm KM.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Get.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _showLocationPicker();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Pilih Lokasi Lain"),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
      setState(() => _pickedLocation = null);
    } else {
      Get.snackbar(
        "Lokasi Tercover ✅", 
        "Outlet: ${closest?['name']} (${minDistance.toStringAsFixed(1)} KM)",
        backgroundColor: Colors.green[700],
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
      );
    }
  }

  void _showLocationPicker() {
    LatLng tempLocation = _pickedLocation ?? _defaultCenter;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: tempLocation,
                  initialZoom: 14,
                  onTap: (_, latlng) {
                    tempLocation = latlng;
                    (ctx as Element).markNeedsBuild();
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
                        point: tempLocation,
                        width: 80, height: 80,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                      ),
                      ..._outlets.map((o) {
                        if (o['latitude'] == null) return const Marker(point: LatLng(0,0), child: SizedBox());
                        return Marker(
                          point: LatLng(o['latitude'], o['longitude']),
                          width: 60, height: 60,
                          child: const Icon(Icons.store, color: Colors.blue, size: 30),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _checkNearestOutlet(tempLocation);
                  },
                  child: const Text('Cek Lokasi Ini'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      Get.snackbar('Error', 'Pilih jenis layanan');
      return;
    }
    if (_pickedLocation == null || _nearestOutlet == null) {
      Get.snackbar('Error', 'Wajib Pin Lokasi & Masuk Radius Area');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final order = Order(
        customerName: _nameController.text,
        serviceType: _selectedService!,
        totalCost: _servicePrice,
        address: _addressController.text,
        orderDate: DateTime.now(),
        status: 'pending', // Status awal selalu pending -> pickup
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        latitude: _pickedLocation?.latitude,
        longitude: _pickedLocation?.longitude,
        deliveryType: _selectedDelivery,
        deliveryFee: _deliveryFee,
        outletId: _nearestOutlet!['id'],
      );

      await _supabaseService.addOrder(order);

      if (!mounted) return;
      Get.back(result: true);
      Get.snackbar('Sukses', 'Order masuk ke ${_nearestOutlet!['name']}');
    } catch (e) {
      Get.snackbar('Error', 'Gagal: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // VARIABEL TEMA (UNTUK DARK MODE)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? const Color(0xFF1E1E1E) : Colors.blue[50];
    final borderColor = isDark ? Colors.grey[800]! : Colors.blue[200]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.blue[200] : const Color(0xFF005f9f);

    final grandTotal = _servicePrice + _deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Order Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Pelanggan', labelColor!),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor HP', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Layanan Laundry', labelColor),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(labelText: 'Pilih Layanan', prefixIcon: Icon(Icons.local_laundry_service)),
                // Set dropdown color untuk dark mode
                dropdownColor: isDark ? Colors.grey[900] : Colors.white, 
                items: _services.map((s) => DropdownMenuItem(
                  value: s['service_name'] as String,
                  child: Text("${s['service_name']} - Rp ${s['price']}", 
                    style: TextStyle(color: textColor)),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedService = val;
                    final s = _services.firstWhere((element) => element['service_name'] == val);
                    _servicePrice = (s['price'] ?? 0).toDouble();
                  });
                },
              ),

              const SizedBox(height: 20),
              _buildSectionTitle('Pengiriman & Lokasi', labelColor),
              
              if (_nearestOutlet != null && _pickedLocation != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.green.withOpacity(0.1) : Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tercover oleh: ${_nearestOutlet!['name']}", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                            Text("Jarak: ${_distanceToOutlet.toStringAsFixed(2)} KM", style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7))),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),

              DropdownButtonFormField<String>(
                value: _selectedDelivery,
                decoration: const InputDecoration(labelText: 'Tipe Pengiriman', prefixIcon: Icon(Icons.motorcycle)),
                dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                items: ['Hemat', 'Reguler', 'Express'].map((type) {
                  double fee = (type == 'Hemat') ? 5000 : (type == 'Reguler' ? 10000 : 20000);
                  return DropdownMenuItem(value: type, child: Text("$type - Rp ${fee.toStringAsFixed(0)}", style: TextStyle(color: textColor)));
                }).toList(),
                onChanged: _updateDeliveryFee,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap', prefixIcon: Icon(Icons.home)),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showLocationPicker,
                  icon: Icon(_pickedLocation == null ? Icons.map : Icons.check_circle, 
                             color: _pickedLocation == null ? Colors.grey : Colors.green),
                  label: Text(_pickedLocation == null ? 'Pin Lokasi (Cek Radius)' : 'Lokasi Terpilih (Ubah?)'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan Tambahan', prefixIcon: Icon(Icons.note)),
              ),
              
              const SizedBox(height: 24),
              
              // CONTAINER TOTAL BAYAR (ADAPTIVE DARK MODE)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: containerColor, // <-- Warna berubah sesuai tema
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildCostRow('Biaya Laundry', _servicePrice, textColor),
                    _buildCostRow('Ongkir ($_selectedDelivery)', _deliveryFee, textColor),
                    Divider(color: borderColor),
                    _buildCostRow('TOTAL BAYAR', grandTotal, textColor, isTotal: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005f9f),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SIMPAN ORDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildCostRow(String label, double value, Color textColor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 16 : 14, color: textColor)),
          Text(
            'Rp ${value.toStringAsFixed(0)}', 
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, 
              fontSize: isTotal ? 16 : 14, 
              color: isTotal ? Colors.green : textColor
            )
          ),
        ],
      ),
    );
  }
}