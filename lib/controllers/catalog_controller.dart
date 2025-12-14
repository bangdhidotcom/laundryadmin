// [GANTI SELURUH ISI FILE lib/controllers/catalog_controller.dart]

// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/screens/catalog_screen.dart';

class CatalogController extends GetxController {
  final isLoading = true.obs;
  final services = <LaundryService>[].obs;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      isLoading.value = true;

      // --- PERBAIKAN DI SINI ---
      // Ganti dari 'laundry_services' ke 'pricing'
      // Ganti 'id' ke 'service_name' untuk pengurutan
      final response = await _supabase
          .from('pricing') // Mengambil dari tabel yg benar
          .select()
          .order('service_name', ascending: true); // Urutkan berdasarkan nama

      if (response.isNotEmpty) {
        // Factory LaundryService.fromJson sudah kita perbarui di file
        // catalog_screen.dart untuk membaca data dari tabel 'pricing'
        final List<LaundryService> loadedServices = (response as List)
            .map((service) => LaundryService.fromJson(service))
            .toList();

        services.assignAll(loadedServices);
        print('Sukses memuat ${loadedServices.length} layanan dari tabel pricing');
      } else {
        print('Tidak ada layanan ditemukan di tabel pricing');
      }
    } catch (e) {
      print('Error memuat layanan: ${e.toString()}');
      Get.snackbar(
        'Error',
        'Gagal memuat layanan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void refreshServices() {
    fetchServices();
  }
}