// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
// import '../services/admin_notification_service.dart'; // HAPUS INI JIKA TIDAK DIPAKAI LAGI DI SINI
import 'add_order_page.dart';

class ManajemenOrderPage extends StatefulWidget {
  const ManajemenOrderPage({super.key});

  @override
  State<ManajemenOrderPage> createState() => _ManajemenOrderPageState();
}

class _ManajemenOrderPageState extends State<ManajemenOrderPage> {
  final _supabaseService = SupabaseService();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Order'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('pickup', 'Jemput'),
                const SizedBox(width: 8),
                _buildFilterChip('process', 'Cuci'),
                const SizedBox(width: 8),
                _buildFilterChip('delivery', 'Antar'),
                const SizedBox(width: 8),
                _buildFilterChip('done', 'Selesai'),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _filterStatus == 'all'
                  ? _supabaseService.getOrders()
                  : _supabaseService.getOrdersByStatus(_filterStatus),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada order'));
                }

                final orders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 80,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const AddOrderPage());
          if (result == true) {
            setState(() {});
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Order',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF005f9f),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF005f9f),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);
    final formattedPrice =
        'Rp ${order.totalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            order.status == 'pickup'
                ? Icons.location_on
                : order.status == 'delivery'
                ? Icons.local_shipping
                : Icons.shopping_bag,
            color: statusColor,
          ),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${order.serviceType} • $formattedPrice'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Pelanggan', order.customerName),
                const SizedBox(height: 8),
                _buildInfoRow('Layanan', order.serviceType),
                const SizedBox(height: 8),
                _buildInfoRow('Alamat', order.address),
                const SizedBox(height: 8),
                _buildInfoRow('Biaya', formattedPrice),
                if (order.notes != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Catatan', order.notes!),
                ],
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (order.status == 'pending')
                      Expanded(
                        child: _actionButton(
                          'Konfirmasi Jemput',
                          Colors.orange,
                          () => _updateStatus(order, 'pickup'),
                        ),
                      ),
                    if (order.status == 'pickup')
                      Expanded(
                        child: _actionButton(
                          'Mulai Cuci',
                          Colors.purple,
                          () => _updateStatus(order, 'process'),
                        ),
                      ),
                    if (order.status == 'process')
                      Expanded(
                        child: _actionButton(
                          'Siap Antar',
                          Colors.blue,
                          () => _updateStatus(order, 'delivery'),
                        ),
                      ),
                    if (order.status == 'delivery')
                      Expanded(
                        child: _actionButton(
                          'Selesaikan',
                          Colors.green,
                          () => _updateStatus(order, 'done'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDialog(order),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(order),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text),
    );
  }

  Future<void> _updateStatus(Order order, String newStatus) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      // 1. Cukup update database saja.
      // Notifikasi ke user akan dikirim OTOMATIS oleh Supabase Edge Function & Trigger.
      await _supabaseService.updateOrderStatus(order.id!, newStatus);

      Get.back(); // Tutup loading

      Get.snackbar(
        'Berhasil',
        'Status diubah menjadi ${newStatus.toUpperCase()}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      setState(() {});

    } catch (e) {
      Get.back();
      Get.snackbar(
        'Gagal Update',
        'Terjadi kesalahan database: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'pickup':
        return Colors.red;
      case 'process':
        return Colors.purple;
      case 'delivery':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'pickup':
        return 'Dijemput';
      case 'process':
        return 'Dicuci';
      case 'delivery':
        return 'Diantar';
      case 'done':
        return 'Selesai';
      default:
        return status.toUpperCase();
    }
  }

  void _showEditDialog(Order order) {
    final nameController = TextEditingController(text: order.customerName);
    final serviceController = TextEditingController(text: order.serviceType);
    final costController = TextEditingController(
      text: order.totalCost.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(labelText: 'Jenis Layanan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Biaya'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabaseService.updateOrder(
                  order.id!,
                  nameController.text,
                  serviceController.text,
                  double.parse(costController.text),
                );
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                setState(() {});
                Get.snackbar(
                  'Sukses',
                  'Order berhasil diupdate',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  '$e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Order order) {
    Get.defaultDialog(
      title: 'Hapus Order?',
      middleText: 'Hapus order dari ${order.customerName}?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await _supabaseService.deleteOrder(order.id!);
          setState(() {});
          Get.snackbar(
            'Sukses',
            'Order dihapus',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Error',
            '$e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }
}