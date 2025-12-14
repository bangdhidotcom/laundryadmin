import 'dart:convert';
import 'package:hive/hive.dart';

part 'weather_model.g.dart';

@HiveType(typeId: 0)
class WeatherModel extends HiveObject {
  @HiveField(0)
  final String cityName;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double temperature;

  @HiveField(3)
  final String iconCode;

  WeatherModel({
    required this.cityName,
    required this.description,
    required this.temperature,
    required this.iconCode,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final weather = json['weather'][0];
    final main = json['main'];

    return WeatherModel(
      cityName: json['name'] ?? 'Unknown City',
      description: weather['description'] ?? 'No description',
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      iconCode: weather['icon'] ?? '01d',
    );
  }

  String getIconUrl() {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }
}

WeatherModel weatherModelFromJson(String str) =>
    WeatherModel.fromJson(json.decode(str));
