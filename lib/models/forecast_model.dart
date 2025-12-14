import 'dart:convert';
import 'package:hive/hive.dart';

part 'forecast_model.g.dart';

@HiveType(typeId: 1)
class ForecastModel extends HiveObject {
  @HiveField(0)
  final List<ForecastItem> list;

  ForecastModel({required this.list});

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      list: (json['list'] as List)
          .map((item) => ForecastItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

@HiveType(typeId: 2)
class ForecastItem extends HiveObject {
  @HiveField(0)
  final DateTime dateTime;

  @HiveField(1)
  final String description;

  ForecastItem({required this.dateTime, required this.description});

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    return ForecastItem(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      description: json['weather'][0]['description'] ?? '',
    );
  }
}

ForecastModel forecastModelFromJson(String str) =>
    ForecastModel.fromJson(json.decode(str));
