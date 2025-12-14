import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laundry3b1titik0/controllers/delivery_controller.dart';
import 'package:laundry3b1titik0/models/order_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final Order order;
  const TaskDetailScreen({super.key, required this.order});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final DeliveryController controller = Get.find();
  File? _proofImage;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Ambil foto dari kamera, kompres biar upload cepat
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 40);
    
    if (image != null) {
      setState(() {
        _proofImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.order.isPickup;
    final themeColor = isPickup ? Colors.red : Colors.blue;
    final titleText = isPickup ? "Selesaikan Penjemputan" : "Selesaikan Pengantaran";

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Detail Pelanggan
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: themeColor),
                        const SizedBox(width: 10),
                        Text(widget.order.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(widget.order.address)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Detail Tagihan (Khusus Delivery)
            if (!isPickup) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Tagihan", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Rp ${widget.order.totalCost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 3. Upload Bukti
            Text("Bukti Foto ${isPickup ? 'Jemput' : 'Serah Terima'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[400]!),
                  image: _proofImage != null
                      ? DecorationImage(image: FileImage(_proofImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _proofImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 60, color: Colors.grey[600]),
                          const SizedBox(height: 10),
                          const Text("Ketuk untuk ambil foto"),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            // 4. Tombol Submit
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_proofImage == null || _isSubmitting)
                    ? null // Disable jika belum foto
                    : () async {
                        setState(() => _isSubmitting = true);
                        
                        // 1. Jalankan proses simpan ke database
                        await controller.completeTask(widget.order, _proofImage!);
                        
                        setState(() => _isSubmitting = false);

                        // 2. Tampilkan Dialog Sukses & Redirect
                        Get.defaultDialog(
                          title: "Berhasil! ✅",
                          titleStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          middleText: "Tugas selesai. Data dan bukti foto berhasil disimpan.",
                          barrierDismissible: false, // User wajib klik tombol OK
                          confirm: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () {
                              Get.back(); // Tutup Dialog
                              Get.back(); // KEMBALI KE HALAMAN KURIR (MAP)
                            },
                            child: const Text("OK, Lanjut Tugas", style: TextStyle(color: Colors.white)),
                          ),
                        );
                      },
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SELESAIKAN TUGAS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}