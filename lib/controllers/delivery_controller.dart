// ignore_for_file: avoid_print, unused_element

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart'; // WAJIB ADA DI PUBSPEC

import 'package:laundry3b1titik0/models/order_model.dart';
import 'package:laundry3b1titik0/models/weather_model.dart';
import 'package:laundry3b1titik0/models/forecast_model.dart';
import 'package:laundry3b1titik0/services/supabase_service.dart';
import 'package:laundry3b1titik0/screens/task_detail_screen.dart'; // Halaman Baru
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryController extends GetxController {
  // --- SERVICE ---
  final _supabaseService = SupabaseService();
  final Dio _dio = Dio();

  // --- STATE CUACA (DIPERTAHANKAN) ---
  var weatherData = Rx<WeatherModel?>(null);
  var forecastList = <ForecastItem>[].obs;
  var weatherAdvice = ''.obs;
  var customMarquee = ''.obs;
  var isWeatherLoading = true.obs;

  // --- STATE PETA & LOGISTIK (DIUPGRADE) ---
  var activeOrders = <Order>[].obs; // List Order Object
  var mapMarkers = <Marker>[].obs;
  var routePolyline = <Polyline>[].obs; // Garis Rute
  var isMapLoading = true.obs;

  // --- STATE KURIR ---
  var currentActiveOrderId = RxnString(); // ID Order yg sedang OTW
  var courierPosition = Rxn<LatLng>(); // Lokasi Kurir Realtime
  StreamSubscription<Position>? _positionStream;

  // Posisi Default (Malang Kota)
  final LatLng centerLocation = const LatLng(-7.9666, 112.6326);

  // --- CONFIG CUACA ---
  String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  final String _cityName = 'Malang';

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  @override
  void onClose() {
    _positionStream?.cancel(); // Matikan GPS saat keluar
    super.onClose();
  }

  Future<void> _initializeData() async {
    // 1. Nyalakan GPS Tracker
    _initLocationService();

    // 2. Load Data Peta
    await refreshMapData();

    // 3. Load Cuaca
    await _loadWeather();
  }

  // ==================== 1. LOGIC GPS & RUTE ====================
  Future<void> _initLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Dengarkan lokasi kurir setiap bergerak 10 meter
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          courierPosition.value = LatLng(position.latitude, position.longitude);

          // Jika sedang ada tugas aktif, update garis rute dari posisi kurir ke tujuan
          if (currentActiveOrderId.value != null) {
            _updatePolyline();
          }
        });
  }

  Future<void> _updateCourierLocationToDb(Position position) async {
    try {
      // Asumsi: Admin yang login menggunakan ID Kurir 1.
      // Di aplikasi real, ID ini harus diambil dari profil user yang login.
      const int myCourierId = 1; 

      await Supabase.instance.client.from('couriers').update({
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', myCourierId);
      
      // print("📍 Lokasi terkirim ke DB: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("⚠️ Gagal kirim lokasi ke DB: $e");
    }
  }

  void _updatePolyline() {
    if (courierPosition.value == null || currentActiveOrderId.value == null) {
      routePolyline.clear();
      return;
    }

    // Cari order yang sedang aktif
    final targetOrder = activeOrders.firstWhereOrNull(
      (o) => o.id == currentActiveOrderId.value,
    );

    if (targetOrder != null &&
        targetOrder.latitude != null &&
        targetOrder.longitude != null) {
      final isPickup = targetOrder.isPickup;

      // Gambar Garis Lurus (Kurir -> Pelanggan)
      routePolyline.value = [
        Polyline(
          points: [
            courierPosition.value!,
            LatLng(targetOrder.latitude!, targetOrder.longitude!),
          ],
          color: isPickup ? Colors.red : Colors.blue,
          strokeWidth: 4.0,
        ),
      ];
    }
  }

  // ==================== 2. LOGIC DATA PETA (MARKERS) ====================
  Future<void> refreshMapData() async {
    isMapLoading.value = true;
    try {
      // Ambil Data Order (Pickup & Delivery)
      final rawOrders = await _supabaseService.getActiveLogisticsOrders();
      activeOrders.value = rawOrders;

      // Ambil Data Outlet (Untuk Marker Toko)
      final outlets = await _supabaseService.getOutlets();

      mapMarkers.clear();

      // A. Marker Outlet (Toko)
      for (var outlet in outlets) {
        if (outlet['latitude'] != null && outlet['longitude'] != null) {
          mapMarkers.add(
            Marker(
              point: LatLng(outlet['latitude'], outlet['longitude']),
              width: 60,
              height: 60,
              child: const Icon(Icons.store, color: Colors.purple, size: 40),
            ),
          );
        }
      }

      // B. Marker Orders (Merah/Biru)
      // Cek apakah ada yang statusnya OTW di Database?
      final otwOrder = rawOrders.firstWhereOrNull(
        (o) => o.deliveryStatus == 'otw',
      );
      if (otwOrder != null) {
        currentActiveOrderId.value = otwOrder.id;
        _updatePolyline();
      } else {
        currentActiveOrderId.value = null;
        routePolyline.clear();
      }

      for (var order in rawOrders) {
        if (order.latitude != null && order.longitude != null) {
          final isPickup = order.isPickup;
          final isActive = order.id == currentActiveOrderId.value;

          mapMarkers.add(
            Marker(
              point: LatLng(order.latitude!, order.longitude!),
              width: 80,
              height: 80,
              child: Column(
                children: [
                  Icon(
                    isPickup ? Icons.location_on : Icons.local_shipping,
                    color: isPickup ? Colors.red : Colors.blue,
                    size: isActive ? 50 : 35, // Besar jika sedang aktif
                  ),
                  if (isActive) // Label jika aktif
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      color: Colors.white,
                      child: const Text(
                        "TUJUAN",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error map: $e');
    } finally {
      isMapLoading.value = false;
    }
  }

  Future<void> _startTask(Order order) async {
    // Validasi: Jangan mulai 2 tugas
    if (currentActiveOrderId.value != null &&
        currentActiveOrderId.value != order.id) {
      Get.snackbar(
        "Tugas Lain Aktif",
        "Selesaikan tugas yang sedang berjalan dulu!",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      await _supabaseService.updateDeliveryStatus(order.id!, 'otw');
      currentActiveOrderId.value = order.id;
      refreshMapData(); // Redraw map & polyline
      Get.snackbar("Mulai Jalan", "Navigasi aktif ke ${order.customerName}");
    } catch (e) {
      Get.snackbar("Error", "$e");
    }
  }

  // [PERBAIKAN LOGIKA] Navigasi dengan fitur "Batal Otomatis"
  // [PERBAIKAN 1] Logic Arrive: Reset Senyap (Tanpa Notif)
  Future<void> _arriveAtLocation(Order order) async {
    try {
      await _supabaseService.updateDeliveryStatus(order.id!, 'arrived');

      // Tunggu hasil dari halaman detail
      final result = await Get.to(() => TaskDetailScreen(order: order));

      // Jika result == true, berarti sukses dari tombol "Selesaikan"
      if (result == true) {
        // Sukses: Tidak perlu lakukan apa-apa, map akan refresh otomatis
      } else {
        // Jika result == null (User tekan Back Manual / Batal)
        print("User kembali tanpa selesai. Auto-revert ke pending.");

        // Reset status DB kembali ke 'pending' secara SENYAP
        await _supabaseService.updateDeliveryStatus(order.id!, 'pending');

        // Reset State Lokal
        currentActiveOrderId.value = null;
        routePolyline.clear();
        refreshMapData();
      }
    } catch (e) {
      Get.snackbar("Error", "$e");
    }
  }

  // [PERBAIKAN 2] Tombol OK: Navigasi Lebih Kuat
  Future<void> completeTask(Order order, File proofImage) async {
    try {
      // 1. Upload & Update Database
      final url = await _supabaseService.uploadProofPhoto(
        proofImage,
        order.id!,
      );
      final mainStatus = order.isPickup ? 'process' : 'done';

      await _supabaseService.completeLogisticsTask(
        orderId: order.id!,
        mainStatus: mainStatus,
        proofUrl: url,
        isPickup: order.isPickup,
      );

      // 2. Dialog Sukses
      Get.defaultDialog(
        title: "Berhasil! ✅",
        titleStyle: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        middleText: "Tugas selesai. Lanjut ke order berikutnya?",
        barrierDismissible: false,
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            // [LOGIKA BARU] Menutup Dialog & Halaman dengan Paksa

            // 1. Tutup Dialog dulu
            if (Get.isDialogOpen ?? false) {
              Get.back();
            }

            // 2. Kirim sinyal SUKSES (true) ke fungsi _arriveAtLocation
            Get.back(result: true);
          },
          child: const Text(
            "OK, Lanjut Tugas",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      // Reset State Lokal (Jaga-jaga)
      currentActiveOrderId.value = null;
      routePolyline.clear();
      refreshMapData();
    } catch (e) {
      Get.snackbar(
        "Gagal",
        "Error: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // [TAMBAHAN] Update Logic Tombol agar 'arrived' yang nyangkut bisa dibuka
  void onMainActionButtonPressed(Order order) {
    final status = order.deliveryStatus.toLowerCase().trim();

    if (status == 'pending' || status == '') {
      _startTask(order);
    } else if (status == 'otw') {
      _arriveAtLocation(order);
    }
    // TAMBAHAN: Jika status terlanjur 'arrived' (nyangkut), tetap buka detailnya
    // Nanti kalau diback, dia akan kena auto-revert di fungsi _arriveAtLocation
    else if (status == 'arrived') {
      _arriveAtLocation(order);
    } else {
      Get.snackbar("Info", "Status: $status. Tidak ada aksi tersedia.");
    }
  }

  // ==================== 4. LOGIC CUACA (TETAP ADA) ====================
  Future<void> _loadWeather() async {
    isWeatherLoading.value = true;
    try {
      var box = await Hive.openBox<WeatherModel>('weather');
      if (box.isNotEmpty) {
        weatherData.value = box.getAt(0);
        _updateAdvice();
      }

      final response = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather?q=$_cityName&appid=$_apiKey&units=metric&lang=id',
      );

      final newWeather = WeatherModel.fromJson(response.data);
      weatherData.value = newWeather;

      await box.clear();
      await box.add(newWeather);
      _updateAdvice();
    } catch (e) {
      print('Weather load error: $e');
    } finally {
      isWeatherLoading.value = false;
    }
  }

  void _updateAdvice() {
    if (weatherData.value == null) return;
    String desc = weatherData.value!.description.toLowerCase();
    if (desc.contains('hujan')) {
      weatherAdvice.value = "⚠️ HUJAN: Siapkan jas hujan!";
    } else if (desc.contains('mendung')) {
      weatherAdvice.value = "⛅ MENDUNG: Waspada hujan.";
    } else {
      weatherAdvice.value = "✅ CERAH: Aman.";
    }
  }
}
