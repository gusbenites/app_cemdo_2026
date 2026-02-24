import 'package:app_cemdo/data/models/supply_model.dart';

class Service {
  final int id;
  final String label;
  final String tag;
  final List<Supply> supplies;

  Service({
    required this.id,
    required this.label,
    required this.tag,
    required this.supplies,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      label: json['label'],
      tag: json['tag'],
      supplies: (json['supplies'] as List<dynamic>)
          .map((supplyJson) => Supply.fromJson(supplyJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'tag': tag,
      'supplies': supplies.map((s) => s.toJson()).toList(),
    };
  }
}
