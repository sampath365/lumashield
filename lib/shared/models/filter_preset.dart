import 'package:flutter/foundation.dart';

/// A saved filter configuration the user can recall with one tap.
@immutable
class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.name,
    required this.intensity,
    required this.kelvin,
    this.customColor,
    this.createdAt,
    this.favourite = false,
  });

  final String id;
  final String name;
  final int intensity;
  final int kelvin;
  final int? customColor;
  final DateTime? createdAt;
  final bool favourite;

  FilterPreset copyWith({
    String? name,
    int? intensity,
    int? kelvin,
    int? customColor,
    bool clearCustomColor = false,
    bool? favourite,
  }) => FilterPreset(
    id: id,
    name: name ?? this.name,
    intensity: intensity ?? this.intensity,
    kelvin: kelvin ?? this.kelvin,
    customColor: clearCustomColor ? null : (customColor ?? this.customColor),
    createdAt: createdAt,
    favourite: favourite ?? this.favourite,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'intensity': intensity,
    'kelvin': kelvin,
    'customColor': customColor,
    'createdAt': createdAt?.toIso8601String(),
    'favourite': favourite,
  };

  factory FilterPreset.fromJson(Map<String, dynamic> json) => FilterPreset(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Preset',
    intensity: (json['intensity'] as num?)?.toInt() ?? 40,
    kelvin: (json['kelvin'] as num?)?.toInt() ?? 4500,
    customColor: (json['customColor'] as num?)?.toInt(),
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.tryParse(json['createdAt'] as String),
    favourite: json['favourite'] as bool? ?? false,
  );
}
