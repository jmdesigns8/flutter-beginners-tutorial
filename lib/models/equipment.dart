import 'package:flutter/material.dart';

class Equipment {
  final String id;
  final String name;
  final int colorValue;
  final bool isActive;

  const Equipment({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isActive = true,
  });

  Color get color => Color(colorValue);

  static final List<Equipment> defaults = const [
    Equipment(id: 'e1', name: 'T450 Skid Steer',    colorValue: 0xFFFF9800),
    Equipment(id: 'e2', name: 'Dump Trailer',         colorValue: 0xFF2196F3),
    Equipment(id: 'e3', name: 'Dodge 1500 Pickup',    colorValue: 0xFF4CAF50),
    Equipment(id: 'e4', name: 'Small Trailer',        colorValue: 0xFF9C27B0),
    Equipment(id: 'e5', name: 'Kia Optima',           colorValue: 0xFFF44336),
    Equipment(id: 'e6', name: 'Ford F250 Pickup',     colorValue: 0xFF795548),
  ];

  Equipment copyWith({String? name, int? colorValue, bool? isActive}) => Equipment(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'isActive': isActive,
      };

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        isActive: (json['isActive'] as bool?) ?? true,
      );
}
