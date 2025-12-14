// ignore_for_file: use_super_parameters, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';

class LihatAntrianPage extends StatefulWidget {
  const LihatAntrianPage({Key? key}) : super(key: key);

  @override
  State<LihatAntrianPage> createState() => _LihatAntrianPageState();
}

class _LihatAntrianPageState extends State<LihatAntrianPage> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrian Pickup'), elevation: 0),
      body: FutureBuilder<List<Order>>(
        future: _supabaseService.getOrdersByStatus('pickup'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada antrian pickup'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(order.serviceType),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Layanan', order.serviceType),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Biaya',
                            'Rp ${order.totalCost.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow('Alamat', order.address),
                          const SizedBox(height: 8),
                          _buildInfoRow('Status', order.status.toUpperCase()),
                          if (order.notes != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoRow('Catatan', order.notes!),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await _supabaseService.updateOrderStatus(
                                  order.id!,
                                  'washing',
                                );
                                setState(() {});
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Status diperbarui ke Washing',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text('Mulai Pencucian'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
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
}
