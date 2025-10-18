// lib/models/category.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String name;
  final int iconCodePoint; // store codePoint as int
  final int colorValue;    // store color.value as int
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    String? id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Category copyWith({
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return Category(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? 'Unknown',
      iconCodePoint: parseInt(json['iconCodePoint']),
      colorValue: parseInt(json['colorValue']),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(parseInt(json['createdAt']))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(parseInt(json['updatedAt']))
          : DateTime.now(),
    );
  }

  /// Helpful defaults (only int values and Icons.* constants used to get codePoint)
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'health',
        name: 'Health',
        iconCodePoint: Icons.favorite.codePoint,
        colorValue: Colors.red.value,
      ),
      Category(
        id: 'fitness',
        name: 'Fitness',
        iconCodePoint: Icons.fitness_center.codePoint,
        colorValue: Colors.orange.value,
      ),
      Category(
        id: 'work',
        name: 'Work',
        iconCodePoint: Icons.work.codePoint,
        colorValue: Colors.blue.value,
      ),
      Category(
        id: 'learning',
        name: 'Learning',
        iconCodePoint: Icons.school.codePoint,
        colorValue: Colors.green.value,
      ),
      Category(
        id: 'mindfulness',
        name: 'Mindfulness',
        iconCodePoint: Icons.self_improvement.codePoint,
        colorValue: Colors.purple.value,
      ),
      Category(
        id: 'social',
        name: 'Social',
        iconCodePoint: Icons.people.codePoint,
        colorValue: Colors.teal.value,
      ),
    ];
  }
}

/// Optional: mapping from id -> const IconData for UI to prefer. This file still does NOT create IconData.
const Map<String, IconData> kCategoryIconConstants = {
  'health': Icons.favorite,
  'fitness': Icons.fitness_center,
  'work': Icons.work,
  'learning': Icons.school,
  'mindfulness': Icons.self_improvement,
  'social': Icons.people,
};
