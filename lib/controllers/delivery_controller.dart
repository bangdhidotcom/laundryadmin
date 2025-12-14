// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:laundry3b1titik0/models/order_model.dart';
import 'package:laundry3b1titik0/models/weather_model.dart';
import 'package:laundry3b1titik0/models/forecast_model.dart';
import 'package:laundry3b1titik0/services/supabase_service.dart';
import 'package:laundry3b1titik0/screens/task_detail_screen.dart';

class DeliveryController extends GetxController {
  // --- SERVICE ---
  final _supabaseService = SupabaseService();
  final Dio _dio = Dio();
  final _supabase = Supabase.instance.client;

  // --- STATE CUACA ---
  var weatherData = Rx<WeatherModel?>(null);
  var forecastList = <ForecastItem>[].obs;
  var weatherAdvice = ''.obs;
  var isWeatherLoading = true.obs;

  var customMarquee = 'Selamat bekerja! Tetap semangat antar pesanan.'.obs;

  // --- STATE PETA & LOGISTIK ---
  var activeOrders = <Order>[].obs;
  var mapMarkers = <Marker>[].obs;
  var routePolyline = <Polyline>[].obs;
  var isMapLoading = true.obs;

  // --- STATE KURIR (OTOMATIS) ---
  int? _myCourierId; // ID Kurir dinamis (bukan hardcode)
  var currentActiveOrderId = RxnString();
  var courierPosition = Rxn<LatLng>();
  StreamSubscription<Position>? _positionStream;

  // Posisi Default (Malang Kota)
  final LatLng centerLocation = const LatLng(-7.9259, 112.5953);

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
    _positionStream?.cancel();
    super.onClose();
  }

  Future<void> _initializeData() async {
    // 1. Identifikasi Kurir (OTOMATIS)
    await _getOrRegisterCourierId();

    // 2. Nyalakan GPS Tracker
    _initLocationService();

    // 3. Load Data Peta & Cuaca
    await refreshMapData();
    await _loadWeather();
  }

  // ==================== 0. LOGIC IDENTITAS KURIR (OTOMATIS) ====================
  // Ini fungsi pengganti hardcode. Dia mencari ID kurir berdasarkan Login.
  Future<void> _getOrRegisterCourierId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print("⚠️ User belum login, tidak bisa identifikasi kurir.");
        return;
      }

      // Cek apakah user ini sudah ada di tabel 'couriers'?
      final response = await _supabase
          .from('couriers')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();

      if (response != null) {
        _myCourierId = response['id'];
        print("✅ Identitas Kurir Ditemukan: ID $_myCourierId");
      } else {
        // Jika BELUM ADA, buatkan data kurir baru secara otomatis
        print("ℹ️ User baru, mendaftarkan sebagai kurir...");
        
        final newCourier = await _supabase
            .from('couriers')
            .insert({
              'name': user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'Admin',
              'auth_id': user.id,
              'status': 'active',
              'phone': user.phone ?? '-',
              'current_lat': centerLocation.latitude,
              'current_lng': centerLocation.longitude,
            })
            .select('id')
            .single();
            
        _myCourierId = newCourier['id'];
        print("✅ Kurir Baru Terdaftar: ID $_myCourierId");
      }
    } catch (e) {
      print("❌ Gagal Identifikasi Kurir: $e");
    }
  }

  // ==================== 1. LOGIC GPS & DB UPDATE ====================
  Future<void> _initLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Dengarkan lokasi kurir setiap bergerak 10 meter
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      courierPosition.value = LatLng(position.latitude, position.longitude);

      // Update Database Otomatis
      _updateCourierLocationToDb(position);

      // Update UI Garis
      if (currentActiveOrderId.value != null) {
        _updatePolyline();
      }
    });
  }

  // 🔥 FUNGSI UPDATE LOKASI (SUDAH DINAMIS) 🔥
  Future<void> _updateCourierLocationToDb(Position position) async {
    if (_myCourierId == null) return; // Tunggu identitas loaded

    try {
      await _supabase.from('couriers').update({
        'current_lat': position.latitude,
        'current_lng': position.longitude,
        'last_updated': DateTime.now().toIso8601String(),
        'status': currentActiveOrderId.value != null ? 'busy' : 'active',
      }).eq('id', _myCourierId!); // Gunakan ID dinamis
      
      // print("📡 Lokasi terkirim (Kurir $_myCourierId)");
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

      // Update Garis: Dari Posisi Kurir ke Pelanggan
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
      final rawOrders = await _supabaseService.getActiveLogisticsOrders();
      activeOrders.value = rawOrders;
      final outlets = await _supabaseService.getOutlets();

      mapMarkers.clear();

      // Marker Outlet
      for (var outlet in outlets) {
        if (outlet['latitude'] != null && outlet['longitude'] != null) {
          mapMarkers.add(
            Marker(
              point: LatLng(outlet['latitude'], outlet['longitude']),
              width: 60, height: 60,
              child: const Icon(Icons.store, color: Colors.purple, size: 40),
            ),
          );
        }
      }

      // Logic Cek Order OTW
      final otwOrder = rawOrders.firstWhereOrNull((o) => o.deliveryStatus == 'otw');
      if (otwOrder != null) {
        currentActiveOrderId.value = otwOrder.id;
        _updatePolyline();
      } else {
        currentActiveOrderId.value = null;
        routePolyline.clear();
      }

      // Marker Orders
      for (var order in rawOrders) {
        if (order.latitude != null && order.longitude != null) {
          final isPickup = order.isPickup;
          final isActive = order.id == currentActiveOrderId.value;

          mapMarkers.add(
            Marker(
              point: LatLng(order.latitude!, order.longitude!),
              width: 80, height: 80,
              child: Column(
                children: [
                  Icon(
                    isPickup ? Icons.location_on : Icons.local_shipping,
                    color: isPickup ? Colors.red : Colors.blue,
                    size: isActive ? 50 : 35,
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      color: Colors.white,
                      child: const Text("TUJUAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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

  // ==================== 3. LOGIC TOMBOL AKSI ====================
  Future<void> _startTask(Order order) async {
    if (currentActiveOrderId.value != null && currentActiveOrderId.value != order.id) {
      Get.snackbar("Tugas Lain Aktif", "Selesaikan tugas yang sedang berjalan dulu!", backgroundColor: Colors.orange);
      return;
    }

    try {
      // 1. Update status order jadi OTW
      await _supabaseService.updateDeliveryStatus(order.id!, 'otw');
      
      // 2. Link Kurir ke Order (PENTING AGAR USER TAHU SIAPA KURIRNYA)
      if (_myCourierId != null) {
        await _supabase.from('orders').update({
          'courier_id': _myCourierId // Masukkan ID kurir otomatis
        }).eq('id', order.id!);
      }

      currentActiveOrderId.value = order.id;
      refreshMapData();
      Get.snackbar("Mulai Jalan", "Navigasi aktif ke ${order.customerName}");
    } catch (e) {
      Get.snackbar("Error", "$e");
    }
  }

  Future<void> _arriveAtLocation(Order order) async {
    try {
      await _supabaseService.updateDeliveryStatus(order.id!, 'arrived');
      final result = await Get.to(() => TaskDetailScreen(order: order));

      if (result == true) {
        // Task Selesai
      } else {
        // Batal / Back -> Revert ke Pending
        await _supabaseService.updateDeliveryStatus(order.id!, 'pending');
        currentActiveOrderId.value = null;
        routePolyline.clear();
        refreshMapData();
      }
    } catch (e) {
      Get.snackbar("Error", "$e");
    }
  }

  Future<void> completeTask(Order order, File proofImage) async {
    try {
      final url = await _supabaseService.uploadProofPhoto(proofImage, order.id!);
      final mainStatus = order.isPickup ? 'process' : 'done';

      await _supabaseService.completeLogisticsTask(
        orderId: order.id!,
        mainStatus: mainStatus,
        proofUrl: url,
        isPickup: order.isPickup,
      );

      Get.defaultDialog(
        title: "Berhasil! ✅",
        middleText: "Tugas selesai. Lanjut ke order berikutnya?",
        barrierDismissible: false,
        confirm: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () {
            if (Get.isDialogOpen ?? false) Get.back();
            Get.back(result: true);
          },
          child: const Text("OK, Lanjut Tugas", style: TextStyle(color: Colors.white)),
        ),
      );

      currentActiveOrderId.value = null;
      routePolyline.clear();
      refreshMapData();
    } catch (e) {
      Get.snackbar("Gagal", "Error: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void onMainActionButtonPressed(Order order) {
    final status = order.deliveryStatus.toLowerCase().trim();
    if (status == 'pending' || status == '') {
      _startTask(order);
    } else if (status == 'otw' || status == 'arrived') {
      _arriveAtLocation(order);
    } else {
      Get.snackbar("Info", "Status: $status. Tidak ada aksi tersedia.");
    }
  }

  // ==================== 4. LOGIC CUACA ====================
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