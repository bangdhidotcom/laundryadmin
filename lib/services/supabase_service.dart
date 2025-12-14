// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> addOrder(Order order) async {
    try {
      await _supabase.from('orders').insert(order.toMap());
    } catch (e) {
      throw Exception('Gagal menambah order: $e');
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('order_date', ascending: false);
      return (response as List)
          .map((item) => Order.fromMap(item, item['id'].toString()))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil orders: $e');
    }
  }

  Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('status', status)
          .order('order_date', ascending: false);
      return (response as List)
          .map((item) => Order.fromMap(item, item['id'].toString()))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil orders: $e');
    }
  }

  Future<void> updateOrderStatus(String id, String newStatus) async {
    try {
      final Map<String, dynamic> updates = {'status': newStatus};

      if (newStatus == 'delivery') {
        updates['delivery_status'] = 'pending';
      }

      await _supabase.from('orders').update(updates).eq('id', int.parse(id));
    } catch (e) {
      throw Exception('Gagal update status: $e');
    }
  }

  Future<List<Order>> getActiveLogisticsOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .or('status.eq.pickup,status.eq.delivery')
          .order('order_date');

      return (response as List)
          .map((e) => Order.fromMap(e, e['id'].toString()))
          .toList();
    } catch (e) {
      throw Exception('Gagal ambil data logistik: $e');
    }
  }

  Future<String> getConfigValue(String key) async {
    try {
      final response = await _supabase
          .from('app_config')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      return response?['value'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> updateConfigValue(String key, String value) async {
    try {
      await _supabase.from('app_config').upsert({'key': key, 'value': value});
    } catch (e) {
      throw Exception('Gagal simpan pengaturan: $e');
    }
  }

  Future<void> updateOrder(
    String orderId,
    String customerName,
    String serviceType,
    double totalCost,
  ) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'customer_name': customerName,
            'service_type': serviceType,
            'total_cost': totalCost,
          })
          .eq('id', int.parse(orderId));
    } catch (e) {
      throw Exception('Gagal update order: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _supabase.from('orders').delete().eq('id', int.parse(orderId));
    } catch (e) {
      throw Exception('Gagal hapus order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOutlets() async {
    try {
      final response = await _supabase
          .from('outlets')
          .select()
          .order('created_at');
      return response;
    } catch (e) {
      throw Exception('Gagal mengambil data outlet: $e');
    }
  }

  Future<void> addOutlet(
    String name,
    String address,
    String phone, {
    double? lat,
    double? lng,
  }) async {
    try {
      await _supabase.from('outlets').insert({
        'name': name,
        'address': address,
        'phone': phone,
        'latitude': lat,
        'longitude': lng,
      });
    } catch (e) {
      throw Exception('Gagal tambah outlet: $e');
    }
  }

  Future<void> updateOutlet(
    int id,
    String name,
    String address,
    String phone, {
    double? lat,
    double? lng,
  }) async {
    try {
      await _supabase
          .from('outlets')
          .update({
            'name': name,
            'address': address,
            'phone': phone,
            'latitude': lat,
            'longitude': lng,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal update outlet: $e');
    }
  }

  Future<void> deleteOutlet(int id) async {
    try {
      await _supabase.from('outlets').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal hapus outlet: $e');
    }
  }

  Future<void> addCustomer(Map<String, dynamic> customer) async {
    try {
      await _supabase.from('customers').insert(customer);
    } catch (e) {
      throw Exception('Gagal menambah customer: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      return await _supabase.from('customers').select();
    } catch (e) {
      throw Exception('Gagal mengambil customers: $e');
    }
  }

  Future<void> setPricing(Map<String, dynamic> pricing) async {
    try {
      await _supabase.from('pricing').insert(pricing);
    } catch (e) {
      throw Exception('Gagal menetapkan harga: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPricing() async {
    try {
      final response = await _supabase
          .from('pricing')
          .select()
          .order('service_name', ascending: true);
      return response;
    } catch (e) {
      throw Exception('Gagal mengambil pricing: $e');
    }
  }

  Future<void> updatePricing(int id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('pricing').update(data).eq('id', id);
    } catch (e) {
      throw Exception('Gagal update harga: $e');
    }
  }

  Future<void> deletePricing(int id) async {
    try {
      await _supabase.from('pricing').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal hapus harga: $e');
    }
  }

  Future<String> uploadServiceImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileExtension = p.extension(image.name);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'public/$fileName';

      await _supabase.storage
          .from('gambar_layanan')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from('gambar_layanan')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload gambar: $e');
    }
  }

  Future<void> deleteServiceImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length > 2) {
        final filePath = pathSegments
            .sublist(pathSegments.indexOf('public'))
            .join('/');
        await _supabase.storage.from('gambar_layanan').remove([filePath]);
      }
    } catch (e) {
      print('Gagal hapus gambar lama: $e');
    }
  }

  Future<void> addPromo(Map<String, dynamic> promo) async {
    try {
      await _supabase.from('promos').insert(promo);
    } catch (e) {
      throw Exception('Gagal menambah promo: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPromos() async {
    try {
      return await _supabase.from('promos').select();
    } catch (e) {
      throw Exception('Gagal mengambil promos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCouriers() async {
    try {
      return await _supabase.from('couriers').select();
    } catch (e) {
      throw Exception('Gagal mengambil data kurir: $e');
    }
  }

  Future<void> updateCourierLocation(int id, double lat, double lng) async {
    try {
      await _supabase
          .from('couriers')
          .update({
            'current_lat': lat,
            'current_lng': lng,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Gagal update lokasi kurir: $e');
    }
  }

  Future<void> updateOrderLocation(
    String orderId,
    double lat,
    double lng,
  ) async {
    try {
      await _supabase
          .from('orders')
          .update({'latitude': lat, 'longitude': lng})
          .eq('id', int.parse(orderId));
    } catch (e) {
      throw Exception('Gagal update lokasi order: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> updateDeliveryStatus(
    String orderId,
    String deliveryStatus,
  ) async {
    try {
      await _supabase
          .from('orders')
          .update({'delivery_status': deliveryStatus})
          .eq('id', int.parse(orderId));
    } catch (e) {
      throw Exception('Gagal update status pengiriman: $e');
    }
  }

  Future<String> uploadProofPhoto(File file, String orderId) async {
    try {
      final fileExt = p.extension(file.path);
      final fileName =
          'proof_$orderId${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = 'public/$fileName';

      await _supabase.storage
          .from('laundry-proofs')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = _supabase.storage
          .from('laundry-proofs')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload bukti foto: $e');
    }
  }

  Future<void> completeLogisticsTask({
    required String orderId,
    required String mainStatus,
    required String proofUrl,
    required bool isPickup,
  }) async {
    try {
      final dataToUpdate = {
        'status': mainStatus,
        'delivery_status': 'completed',
      };

      if (isPickup) {
        dataToUpdate['pickup_proof_url'] = proofUrl;
      } else {
        dataToUpdate['delivery_proof_url'] = proofUrl;
        dataToUpdate['payment_status'] = 'paid';
      }

      await _supabase
          .from('orders')
          .update(dataToUpdate)
          .eq('id', int.parse(orderId));
    } catch (e) {
      throw Exception('Gagal menyelesaikan tugas: $e');
    }
  }
}
