# Laundry 3B 1.0 - Dokumentasi Implementasi Tugas 1-4

**Aplikasi Mobile Manajemen Laundry dengan Flutter, GetX, Hive, dan Supabase**

---

## 📋 Daftar Isi

1. [Tugas 1: Implementasi shared_preferences untuk Tema](#tugas-1-implementasi-shared_preferences-untuk-tema)
2. [Tugas 2: Implementasi Hive untuk Cache Data Cuaca](#tugas-2-implementasi-hive-untuk-cache-data-cuaca)
3. [Tugas 3: Implementasi Supabase untuk Data Layanan Laundry](#tugas-3-implementasi-supabase-untuk-data-layanan-laundry)
4. [Tugas 4: Supabase Auth di Splash Screen](#tugas-4-supabase-auth-di-splash-screen)
5. [Instalasi & Setup](#instalasi--setup)
6. [Testing](#testing)

---

## 🎨 Tugas 1: Implementasi shared_preferences untuk Tema

### Tujuan
Menambahkan fitur tema gelap/terang yang persistent menggunakan `shared_preferences`.

### File yang Ditambah/Dimodifikasi

#### 1. **lib/services/theme_service.dart** (File Baru)
```dart
// Buat file baru dengan GetxService
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemeService extends GetxService {
  late SharedPreferences _prefs;
  var isDarkMode = false.obs;

  Future<ThemeService> init() async {
    _prefs = await SharedPreferences.getInstance();
    isDarkMode.value = _prefs.getBool('isDarkMode') ?? false;
    return this;
  }

  Future<void> saveTheme(bool isDark) async {
    isDarkMode.value = isDark;
    await _prefs.setBool('isDarkMode', isDark);
  }

  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFF005f9f),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF005f9f),
    );
  }
}
```

#### 2. **lib/main.dart** (Dimodifikasi)
```dart
// Tambahkan inisialisasi ThemeService
await Get.putAsync(() => ThemeService().init());

// GetMaterialApp akan otomatis menggunakan ThemeService
themeMode: themeService.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
```

#### 3. **lib/profile_screen.dart** (Dimodifikasi)
```dart
// Tambahkan SwitchListTile untuk toggle tema
SwitchListTile(
  title: const Text('Mode Gelap'),
  subtitle: const Text('Aktifkan tema gelap'),
  value: themeService.isDarkMode.value,
  onChanged: (value) {
    themeService.saveTheme(value);
  },
),
```

### Package yang Ditambahkan
```yaml
dependencies:
  shared_preferences: ^2.0.0
```

---

## 💾 Tugas 2: Implementasi Hive untuk Cache Data Cuaca (Mode Offline)

### Tujuan
Mengimplementasikan caching data cuaca menggunakan Hive agar aplikasi bisa berjalan offline.

### File yang Ditambah/Dimodifikasi

#### 1. **lib/models/weather_model.dart** (Dimodifikasi)
```dart
// Tambahkan anotasi @HiveType dan @HiveField
import 'package:hive/hive.dart';

part 'weather_model.g.dart';

@HiveType(typeId: 0)
class WeatherModel extends HiveObject {
  @HiveField(0)
  final String cityName;

  @HiveField(1)
  final double temperature;

  @HiveField(2)
  final String description;

  // ... properti lainnya
}
```

#### 2. **lib/models/forecast_model.dart** (Dimodifikasi)
```dart
import 'package:hive/hive.dart';

part 'forecast_model.g.dart';

@HiveType(typeId: 1)
class ForecastModel extends HiveObject {
  @HiveField(0)
  final List<ForecastItem> list;
  // ...
}

@HiveType(typeId: 2)
class ForecastItem extends HiveObject {
  @HiveField(0)
  final DateTime dateTime;

  @HiveField(1)
  final String description;
  // ...
}
```

#### 3. **lib/main.dart** (Dimodifikasi)
```dart
// Initialize Hive
await Hive.initFlutter();
Hive.registerAdapter(WeatherModelAdapter());
Hive.registerAdapter(ForecastModelAdapter());
Hive.registerAdapter(ForecastItemAdapter());
```

#### 4. **lib/controllers/delivery_controller.dart** (Dimodifikasi)
```dart
// Tambahkan di onInit():
Future<void> _initializeHiveBoxes() async {
  _weatherBox = await Hive.openBox<WeatherModel>('weather');
  _forecastBox = await Hive.openBox<ForecastItem>('forecast');
}

// Tambahkan metode untuk load cache:
void _loadCachedData() {
  if (_weatherBox.isNotEmpty) {
    weatherData.value = _weatherBox.getAt(0);
  }
  forecastList.addAll(_forecastBox.values);
}

// Tambahkan metode untuk save cache:
Future<void> _saveCachedData(WeatherModel weather, List<ForecastItem> forecasts) async {
  await _weatherBox.clear();
  await _weatherBox.add(weather);
  
  await _forecastBox.clear();
  for (var forecast in forecasts) {
    await _forecastBox.add(forecast);
  }
}

// Di fetchWeatherHttp() dan fetchWeatherDio():
_loadCachedData(); // Load cache terlebih dahulu

// Setelah API berhasil:
if (response.statusCode == 200) {
  final newWeather = WeatherModel.fromJson(jsonData);
  weatherData.value = newWeather;
  await _saveCachedData(newWeather, forecastList);
}

// Saat error/offline:
catch (e) {
  if (weatherData.value != null) {
    errorMessage.value = 'Gagal update data. Menampilkan data cache terakhir.';
  }
}
```

### Package yang Ditambahkan
```yaml
dependencies:
  hive: ^2.0.0
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.0
  build_runner: ^2.0.0
```

### Command untuk Generate Adapter
```bash
flutter pub run build_runner build
```

---

## 🌐 Tugas 3: Implementasi Supabase untuk Data Layanan Laundry

### Tujuan
Mengganti data statis dengan data dinamis dari Supabase database.

### File yang Ditambah/Dimodifikasi

#### 1. **lib/main.dart** (Dimodifikasi)
```dart
// Initialize Supabase
await Supabase.initialize(
  url: 'https://gozewnowaiddmlvjvffu.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

#### 2. **lib/models/laundry_service.dart** (Dimodifikasi di catalog_screen.dart)
```dart
class LaundryService {
  final int id;
  final String name;
  final int price;
  final String icon;

  LaundryService({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
  });

  // Factory untuk parse data dari Supabase
  factory LaundryService.fromJson(Map<String, dynamic> json) {
    return LaundryService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      icon: json['icon'] ?? '',
    );
  }
}
```

#### 3. **lib/controllers/catalog_controller.dart** (File Baru)
```dart
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/models/laundry_service.dart';

class CatalogController extends GetxController {
  var isLoading = false.obs;
  var services = <LaundryService>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchServices();
  }

  Future<void> fetchServices() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('laundry_services')
          .select();

      services.value = (response as List)
          .map((item) => LaundryService.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching services: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
```

#### 4. **lib/catalog_screen.dart** (Dimodifikasi)
```dart
// Ubah dari StatelessWidget menjadi GetView<CatalogController>
class CatalogScreen extends GetView<CatalogController> {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inisialisasi controller
    Get.put(CatalogController());

    return Obx(
      () => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: controller.services.length,
              itemBuilder: (context, index) {
                final service = controller.services[index];
                return Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(service.name),
                      Text('Rp ${service.price}'),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
```

### Struktur Tabel Supabase (laundry_services)
```sql
CREATE TABLE laundry_services (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  price INTEGER NOT NULL,
  icon VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Package yang Ditambahkan
```yaml
dependencies:
  supabase_flutter: ^1.0.0
```

---

## 🔐 Tugas 4: Supabase Auth di Splash Screen

### Tujuan
Mengimplementasikan autentikasi Supabase dengan pengecekan session di splash screen.

### File yang Ditambah/Dimodifikasi

#### 1. **lib/splash_screen.dart** (Dimodifikasi)
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/main_page.dart';
import 'package:laundry3b1titik0/screens/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthSession();
  }

  Future<void> _checkAuthSession() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      Get.offAll(() => const MainPage());
    } else {
      Get.offAll(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 200),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

#### 2. **lib/screens/login_page.dart** (File Baru)
```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:laundry3b1titik0/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        Get.offAll(() => const MainPage());
      }
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF005f9f),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005f9f),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 Instalasi & Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd laundry3b1titik0
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Hive Adapter
```bash
flutter pub run build_runner build
```

### 4. Setup Supabase
- Buat project di [Supabase](https://supabase.com)
- Update URL dan Anon Key di `lib/main.dart`
- Buat tabel `laundry_services` di Supabase
- Buat user test di Authentication menu

### 5. Run Aplikasi
```bash
flutter run
```

---

## 🧪 Testing

### Test Tugas 1: Tema
1. Buka app → Profile Screen
2. Toggle "Mode Gelap"
3. Tema berubah → Restart app → Tema tetap persisten ✅

### Test Tugas 2: Hive Cache
1. Buka Delivery Screen
2. Matikan internet
3. Data cuaca masih tampil dari cache ✅
4. Nyalakan internet → Data update ✅

### Test Tugas 3: Supabase Services
1. Buka Catalog Screen
2. Data dimuat dari Supabase, bukan hardcoded ✅
3. Loading indicator tampil saat fetch ✅

### Test Tugas 4: Auth
1. Buka app tanpa login
2. Redirect ke Login Page ✅
3. Login dengan email & password → Redirect ke Main Page ✅
4. Restart app → Tetap di Main Page (sudah login) ✅

---

## 📁 Struktur File

```
lib/
├── main.dart                          (Main entry point + Supabase init)
├── splash_screen.dart                 (Auth check)
├── models/
│   ├── weather_model.dart             (+@HiveType)
│   └── forecast_model.dart            (+@HiveType)
├── services/
│   └── theme_service.dart             (NEW)
├── controllers/
│   ├── delivery_controller.dart        (+Hive cache logic)
│   └── catalog_controller.dart         (NEW)
└── screens/
    ├── login_page.dart                (NEW)
    ├── profile_screen.dart            (+SwitchListTile)
    └── catalog_screen.dart            (+GetView + Obx)
```

---

## 📦 Dependencies Summary

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.0.0
  hive: ^2.0.0
  hive_flutter: ^1.1.0
  shared_preferences: ^2.0.0
  supabase_flutter: ^1.0.0
  http: ^0.13.0
  dio: ^4.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.0
  build_runner: ^2.0.0
```

---

## ✅ Checklist Implementasi

- [x] Tugas 1: shared_preferences untuk tema
- [x] Tugas 2: Hive untuk cache data cuaca
- [x] Tugas 3: Supabase untuk data layanan
- [x] Tugas 4: Supabase Auth di splash screen

---

## 📝 Catatan Penting

1. **Developer Mode**: Pastikan Developer Mode diaktifkan di Windows untuk symlink support
2. **Build Runner**: Jalankan `flutter pub run build_runner build` jika ada error adapter
3. **Supabase Key**: Jangan commit Supabase key ke repository publik
4. **Testing User**: Buat user test di Supabase dashboard sebelum login

---

**Created**: November 2025
**Project**: Laundry 3B 1.0
