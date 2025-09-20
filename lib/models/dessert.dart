import 'package:flutter/material.dart';

class Dessert {
  final int level;
  final String name;
  final String emoji;
  final int baseValue;
  final Color color;

  const Dessert({
    required this.level,
    required this.name,
    required this.emoji,
    required this.baseValue,
    required this.color,
  });

  static const List<Dessert> dessertLevels = [
    // Base Ingredients (Levels 1-10) - BALANCED PROGRESSION
    Dessert(level: 1, name: 'Flour', emoji: '🌾', baseValue: 2, color: Color(0xFFF5DEB3)),
    Dessert(level: 2, name: 'Sugar', emoji: '🍬', baseValue: 5, color: Color(0xFFFFFFE0)),
    Dessert(level: 3, name: 'Milk', emoji: '🥛', baseValue: 12, color: Color(0xFFF0F8FF)),
    Dessert(level: 4, name: 'Butter', emoji: '🧈', baseValue: 28, color: Color(0xFFFFD700)),
    Dessert(level: 5, name: 'Eggs', emoji: '🥚', baseValue: 65, color: Color(0xFFFFE4B5)),
    Dessert(level: 6, name: 'Chocolate', emoji: '🍫', baseValue: 150, color: Color(0xFFD2691E)),
    Dessert(level: 7, name: 'Strawberries', emoji: '🍓', baseValue: 340, color: Color(0xFFFF69B4)),
    Dessert(level: 8, name: 'Vanilla', emoji: '🌟', baseValue: 750, color: Color(0xFFFFF8DC)),
    Dessert(level: 9, name: 'Cream', emoji: '🍦', baseValue: 1650, color: Color(0xFFF5F5DC)),
    Dessert(level: 10, name: 'Honey', emoji: '🍯', baseValue: 3600, color: Color(0xFFFFB347)),
  ];

  static Dessert getDessertByLevel(int level) {
    return dessertLevels.firstWhere((d) => d.level == level, orElse: () => dessertLevels.first);
  }
}

class GridDessert {
  final int id;
  final Dessert dessert;
  final int gridX;
  final int gridY;

  GridDessert({
    required this.id,
    required this.dessert,
    required this.gridX,
    required this.gridY,
  });

  GridDessert copyWith({
    int? id,
    Dessert? dessert,
    int? gridX,
    int? gridY,
  }) {
    return GridDessert(
      id: id ?? this.id,
      dessert: dessert ?? this.dessert,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
    );
  }
}