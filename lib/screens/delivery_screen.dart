// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:marquee/marquee.dart'; // Library Teks Berjalan
import 'package:laundry3b1titik0/controllers/delivery_controller.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DeliveryController controller = Get.put(DeliveryController());
    
    // Controller untuk menggerakkan peta saat list diklik
    final MapController mapController = MapController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kurir'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => controller.refreshMapData()),
        ],
      ),
      body: Stack(
        children: [
          // 1. LAYER PETA
          Obx(() => FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: controller.centerLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.laundry3b.app',
              ),
              // Layer Garis Rute (Polyline) - Muncul saat OTW
              PolylineLayer(polylines: controller.routePolyline.toList()),
              
              // Layer Pin Tujuan
              MarkerLayer(markers: controller.mapMarkers.toList()),

              // Layer Posisi Kurir (Titik Biru)
              if (controller.courierPosition.value != null)
                MarkerLayer(markers: [
                  Marker(
                    point: controller.courierPosition.value!,
                    width: 24, height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)]
                      ),
                    ),
                  )
                ]),
            ],
          )),

          // 2. WEATHER BAR (TETAP DIPERTAHANKAN)
          Positioned(
            top: 10, left: 10, right: 10,
            child: _buildWeatherBar(context, controller),
          ),

          // 3. LIST TUGAS (DRAGGABLE SHEET)
          DraggableScrollableSheet(
            initialChildSize: 0.25,
            minChildSize: 0.15,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Get.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Obx(() {
                  final orders = controller.activeOrders;
                  
                  return Column(
                    children: [
                      // Handle Bar
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: 40, height: 5,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      
                      // Judul
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Antrian Tugas (${orders.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Icon(Icons.sort, color: Colors.grey),
                          ],
                        ),
                      ),
                      const Divider(),

                      // List Data
                      Expanded(
                        child: orders.isEmpty 
                        ? const Center(child: Text("Semua tugas selesai! Istirahat.")) 
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final isPickup = order.isPickup;
                              final themeColor = isPickup ? Colors.red : Colors.blue;
                              
                              // Logic Tombol
                              String btnText = "MULAI";
                              IconData btnIcon = Icons.play_arrow;
                              Color btnColor = themeColor;
                              bool isActive = false;

                              if (order.deliveryStatus == 'otw') {
                                btnText = "SAMPAI / DETAIL";
                                btnIcon = Icons.flag;
                                btnColor = Colors.green; // Ubah jadi hijau kalau OTW
                                isActive = true;
                              }

                              // Cek apakah tombol harus disable (karena ada order lain yg aktif)
                              bool isLocked = controller.currentActiveOrderId.value != null && 
                                              controller.currentActiveOrderId.value != order.id;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                elevation: 2,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: themeColor.withOpacity(0.1),
                                    child: Icon(isPickup ? Icons.upload : Icons.download, color: themeColor),
                                  ),
                                  title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(order.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      // Badge Status
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.deliveryStatus.toUpperCase(),
                                          style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.grey),
                                        ),
                                      )
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Tombol Fokus Peta
                                      IconButton(
                                        icon: const Icon(Icons.gps_fixed, color: Colors.grey),
                                        onPressed: () {
                                          if (order.latitude != null && order.longitude != null) {
                                            mapController.move(LatLng(order.latitude!, order.longitude!), 15);
                                          }
                                        },
                                      ),
                                      // Tombol Aksi Utama (Mulai / Sampai)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: btnColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: Icon(btnIcon, size: 14),
                                        label: Text(btnText, style: const TextStyle(fontSize: 11)),
                                        onPressed: isLocked ? null : () => controller.onMainActionButtonPressed(order),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ),
                    ],
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherBar(BuildContext context, DeliveryController controller) {
    return Obx(() {
      final weather = controller.weatherData.value;
      final advice = controller.weatherAdvice.value;
      
      if (weather == null) return const SizedBox.shrink();

      // DETEKSI TEMA (Gelap/Terang)
      final isDark = Get.isDarkMode;

      // PALET WARNA DINAMIS
      final cardColor = isDark ? const Color(0xFF1E1E1E).withOpacity(0.95) : Colors.white.withOpacity(0.95);
      final iconBgColor = isDark ? Colors.grey[800] : Colors.blue[50];
      final textColor = isDark ? Colors.white : Colors.black87;
      final tempColor = isDark ? Colors.blue[200] : Colors.blue[800];
      
      // Warna Teks Marquee (Peringatan tetap Merah/Kuning biar waspada)
      final marqueeColor = advice.contains("HUJAN") 
          ? (isDark ? Colors.redAccent : Colors.red[800]) 
          : (isDark ? Colors.blueAccent : Colors.blue[900]);

      return Card(
        elevation: 6,
        // Tambahkan border tipis di mode gelap agar batasnya jelas
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: isDark ? BorderSide(color: Colors.grey[700]!, width: 0.5) : BorderSide.none,
        ),
        color: cardColor, 
        child: Container(
          height: 55, // Sedikit lebih tinggi biar lega
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // 1. IKON CUACA (Kontras Tinggi)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor, 
                  shape: BoxShape.circle,
                  // Efek bayangan tipis
                  boxShadow: [
                    if (!isDark) 
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Image.network(
                  weather.getIconUrl(),
                  width: 32, height: 32,
                  errorBuilder: (_,__,___) => Icon(Icons.cloud_off, size: 20, color: textColor),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 2. SUHU & KOTA
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.toStringAsFixed(0)}°C',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: tempColor),
                  ),
                  Text(
                    weather.cityName,
                    style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // 3. GARIS PEMBATAS
              Container(width: 1, height: 30, color: textColor.withOpacity(0.2)),
              
              const SizedBox(width: 12),
              
              // 4. TEKS BERJALAN (Marquee)
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: Marquee(
                    text: "$advice  |  INFO: ${controller.customMarquee.value}      ",
                    style: TextStyle(
                      color: marqueeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: const Duration(seconds: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}