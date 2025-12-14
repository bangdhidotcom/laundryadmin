// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LaporanKeuanganPage extends StatefulWidget {
  const LaporanKeuanganPage({Key? key}) : super(key: key);

  @override
  State<LaporanKeuanganPage> createState() => _LaporanKeuanganPageState();
}

class _LaporanKeuanganPageState extends State<LaporanKeuanganPage> {
  final _supabaseService = SupabaseService();

  Future<Map<String, dynamic>> _getFinancialReport() async {
    try {
      final orders = await _supabaseService.getOrders();
      double totalIncome = 0;
      int completedOrders = 0;

      for (var order in orders) {
        if (order.status == 'completed') {
          totalIncome += order.totalCost;
          completedOrders++;
        }
      }

      return {
        'totalIncome': totalIncome,
        'completedOrders': completedOrders,
        'pendingOrders': orders.where((o) => o.status == 'pending').length,
        'inProcessOrders': orders
            .where((o) => o.status == 'washing' || o.status == 'ready')
            .length,
      };
    } catch (e) {
      throw Exception('Gagal mengambil data laporan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan'), elevation: 0),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getFinancialReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final totalIncome = data['totalIncome'] as double? ?? 0;
          final completedOrders = data['completedOrders'] as int? ?? 0;
          final pendingOrders = data['pendingOrders'] as int? ?? 0;
          final inProcessOrders = data['inProcessOrders'] as int? ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Keuangan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pendapatan',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${totalIncome.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Status Pesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard(
                      'Selesai',
                      completedOrders.toString(),
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Tertunda',
                      pendingOrders.toString(),
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Proses',
                      inProcessOrders.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total',
                      (completedOrders + pendingOrders + inProcessOrders)
                          .toString(),
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
