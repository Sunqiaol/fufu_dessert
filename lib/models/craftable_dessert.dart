import 'package:flutter/material.dart';

class CraftableDessert {
  final int id;
  final String name;
  final String emoji;
  final List<int> requiredIngredients; // List of ingredient levels needed
  final int baseValue;
  final Color color;
  final String description;

  const CraftableDessert({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredIngredients,
    required this.baseValue,
    required this.color,
    required this.description,
  });

  static const List<CraftableDessert> dessertRecipes = [
    // Basic Desserts
    CraftableDessert(
      id: 1,
      name: 'Cookies',
      emoji: '🍪',
      requiredIngredients: [1, 2, 4], // Flour + Sugar + Butter
      baseValue: 100,
      color: Color(0xFFD2691E),
      description: 'Classic homemade cookies',
    ),
    
    CraftableDessert(
      id: 2,
      name: 'Cupcake',
      emoji: '🧁',
      requiredIngredients: [1, 2, 5, 8], // Flour + Sugar + Eggs + Vanilla
      baseValue: 200,
      color: Color(0xFFFF69B4),
      description: 'Fluffy vanilla cupcake',
    ),
    
    CraftableDessert(
      id: 3,
      name: 'Pancakes',
      emoji: '🥞',
      requiredIngredients: [1, 3, 5, 10], // Flour + Milk + Eggs + Honey
      baseValue: 150,
      color: Color(0xFFFFD700),
      description: 'Stack of fluffy pancakes with honey',
    ),
    
    // Intermediate Desserts
    CraftableDessert(
      id: 4,
      name: 'Chocolate Cake',
      emoji: '🍰',
      requiredIngredients: [1, 5, 4, 6], // Flour + Eggs + Butter + Chocolate
      baseValue: 300,
      color: Color(0xFF8B4513),
      description: 'Rich chocolate cake',
    ),
    
    CraftableDessert(
      id: 5,
      name: 'Cheesecake',
      emoji: '🍰',
      requiredIngredients: [9, 2, 5, 8], // Cream + Sugar + Eggs + Vanilla
      baseValue: 350,
      color: Color(0xFFFFF8DC),
      description: 'Creamy vanilla cheesecake',
    ),
    
    CraftableDessert(
      id: 6,
      name: 'Strawberry Tart',
      emoji: '🍓',
      requiredIngredients: [1, 7, 9], // Flour + Strawberries + Cream
      baseValue: 250,
      color: Color(0xFFFF1493),
      description: 'Fresh strawberry tart with cream',
    ),
    
    // Advanced Desserts
    CraftableDessert(
      id: 7,
      name: 'Donuts',
      emoji: '🍩',
      requiredIngredients: [1, 2, 3, 4], // Flour + Sugar + Milk + Butter
      baseValue: 180,
      color: Color(0xFFFFB6C1),
      description: 'Glazed donuts',
    ),
    
    CraftableDessert(
      id: 8,
      name: 'Pudding',
      emoji: '🍮',
      requiredIngredients: [3, 5, 8, 2], // Milk + Eggs + Vanilla + Sugar
      baseValue: 220,
      color: Color(0xFFFFFACD),
      description: 'Smooth vanilla pudding',
    ),
    
    CraftableDessert(
      id: 9,
      name: 'Macarons',
      emoji: '🧁',
      requiredIngredients: [5, 2, 9, 8], // Eggs + Sugar + Cream + Vanilla
      baseValue: 400,
      color: Color(0xFFDDA0DD),
      description: 'Delicate French macarons',
    ),
    
    // Ultimate Dessert
    CraftableDessert(
      id: 10,
      name: 'Rainbow Cake',
      emoji: '🎂',
      requiredIngredients: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], // All ingredients
      baseValue: 1000,
      color: Color(0xFF9370DB),
      description: 'Ultimate rainbow cake using all ingredients',
    ),
  ];

  static CraftableDessert? getDessertById(int id) {
    try {
      return dessertRecipes.firstWhere((dessert) => dessert.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get all desserts that can be crafted with available ingredients
  static List<CraftableDessert> getAvailableDesserts(List<int> availableIngredientLevels) {
    return dessertRecipes.where((dessert) {
      return dessert.requiredIngredients.every((requiredLevel) {
        return availableIngredientLevels.contains(requiredLevel);
      });
    }).toList();
  }

  // Check if a dessert can be crafted with current storage
  bool canCraftWith(Map<int, int> ingredientQuantities) {
    return requiredIngredients.every((requiredLevel) {
      return (ingredientQuantities[requiredLevel] ?? 0) >= 1;
    });
  }

  // Get missing ingredients for crafting
  List<int> getMissingIngredients(List<int> availableIngredientLevels) {
    return requiredIngredients.where((requiredLevel) {
      return !availableIngredientLevels.contains(requiredLevel);
    }).toList();
  }
}

// Storage item for desserts
class DessertStorageItem {
  final int dessertId;
  final int quantity;
  final DateTime addedAt;

  const DessertStorageItem({
    required this.dessertId,
    required this.quantity,
    required this.addedAt,
  });

  DessertStorageItem copyWith({
    int? dessertId,
    int? quantity,
    DateTime? addedAt,
  }) {
    return DessertStorageItem(
      dessertId: dessertId ?? this.dessertId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dessertId': dessertId,
      'quantity': quantity,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory DessertStorageItem.fromJson(Map<String, dynamic> json) {
    return DessertStorageItem(
      dessertId: json['dessertId'] as int,
      quantity: json['quantity'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int),
    );
  }
}