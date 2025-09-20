import 'package:flutter/material.dart';

class CraftableDessert {
  final int id;
  final String name;
  final String emoji;
  final List<int> requiredIngredients; // List of ingredient levels needed
  final int baseValue;
  final Color color;
  final String description;
  final int unlocksAtLevel; // Shop level required to unlock this recipe

  const CraftableDessert({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredIngredients,
    required this.baseValue,
    required this.color,
    required this.description,
    required this.unlocksAtLevel,
  });

  static const List<CraftableDessert> dessertRecipes = [
    // LEVEL 2: First Recipe - Learning Phase
    CraftableDessert(
      id: 1,
      name: 'Cookies',
      emoji: '🍪',
      requiredIngredients: [1, 2], // Flour + Sugar
      baseValue: 25,
      color: Color(0xFFD2691E),
      description: 'Teaching recipe: Shows crafting basics',
      unlocksAtLevel: 2,
    ),
    
    // LEVEL 3: Simple Recipes
    CraftableDessert(
      id: 2,
      name: 'Pancakes',
      emoji: '🥞',
      requiredIngredients: [1, 3], // Flour + Milk
      baseValue: 30,
      color: Color(0xFFFFD700),
      description: 'Fluffy pancakes',
      unlocksAtLevel: 3,
    ),
    
    CraftableDessert(
      id: 3,
      name: 'Buttered Toast',
      emoji: '🍞',
      requiredIngredients: [1, 4], // Flour + Butter
      baseValue: 35,
      color: Color(0xFFFFA500),
      description: 'Simple buttered toast',
      unlocksAtLevel: 3,
    ),
    
    // LEVEL 4: Medium Complexity (3-ingredient recipes)
    CraftableDessert(
      id: 4,
      name: 'Simple Muffin',
      emoji: '🧁',
      requiredIngredients: [1, 2, 3], // Flour + Sugar + Milk
      baseValue: 65,
      color: Color(0xFFFF69B4),
      description: 'Basic muffin with milk',
      unlocksAtLevel: 4,
    ),
    
    CraftableDessert(
      id: 5,
      name: 'Scrambled Eggs',
      emoji: '🍳',
      requiredIngredients: [5, 4, 3], // Eggs + Butter + Milk
      baseValue: 70,
      color: Color(0xFFFFF8DC),
      description: 'Fluffy scrambled eggs',
      unlocksAtLevel: 4,
    ),
    
    CraftableDessert(
      id: 6,
      name: 'Basic Donuts',
      emoji: '🍩',
      requiredIngredients: [1, 2, 5], // Flour + Sugar + Eggs
      baseValue: 75,
      color: Color(0xFFFFB6C1),
      description: 'Simple glazed donuts',
      unlocksAtLevel: 4,
    ),
    
    // LEVEL 5: Intermediate Recipes (Chocolate unlocked)
    CraftableDessert(
      id: 7,
      name: 'Hot Chocolate',
      emoji: '☕',
      requiredIngredients: [6, 3, 2], // Chocolate + Milk + Sugar
      baseValue: 95,
      color: Color(0xFF8B4513),
      description: 'Warm hot chocolate',
      unlocksAtLevel: 5,
    ),
    
    CraftableDessert(
      id: 8,
      name: 'Chocolate Muffin',
      emoji: '🧁',
      requiredIngredients: [1, 6, 5], // Flour + Chocolate + Eggs
      baseValue: 110,
      color: Color(0xFF654321),
      description: 'Rich chocolate muffin',
      unlocksAtLevel: 5,
    ),
    
    // LEVEL 6: Complex Recipes (4-ingredient, Strawberries unlocked)
    CraftableDessert(
      id: 9,
      name: 'Berry Pie',
      emoji: '🥧',
      requiredIngredients: [1, 4, 7, 2], // Flour + Butter + Strawberries + Sugar
      baseValue: 140,
      color: Color(0xFFFF1493),
      description: 'Fresh berry pie',
      unlocksAtLevel: 6,
    ),
    
    CraftableDessert(
      id: 10,
      name: 'Simple Cake',
      emoji: '🎂',
      requiredIngredients: [1, 2, 4, 5], // Flour + Sugar + Butter + Eggs
      baseValue: 160,
      color: Color(0xFFFFB6C1),
      description: 'Classic simple cake',
      unlocksAtLevel: 6,
    ),
    
    CraftableDessert(
      id: 11,
      name: 'Strawberry Milk',
      emoji: '🥤',
      requiredIngredients: [7, 3, 2], // Strawberries + Milk + Sugar
      baseValue: 120,
      color: Color(0xFFFFB6C1),
      description: 'Sweet strawberry milk',
      unlocksAtLevel: 6,
    ),
    
    // LEVEL 7: Advanced Recipes (Vanilla unlocked)
    CraftableDessert(
      id: 12,
      name: 'Vanilla Pudding',
      emoji: '🍮',
      requiredIngredients: [3, 2, 5, 8], // Milk + Sugar + Eggs + Vanilla
      baseValue: 190,
      color: Color(0xFFFFFACD),
      description: 'Smooth vanilla pudding',
      unlocksAtLevel: 7,
    ),
    
    CraftableDessert(
      id: 13,
      name: 'Vanilla Cupcake',
      emoji: '🧁',
      requiredIngredients: [1, 2, 5, 8], // Flour + Sugar + Eggs + Vanilla
      baseValue: 200,
      color: Color(0xFFFFE4E1),
      description: 'Fluffy vanilla cupcake',
      unlocksAtLevel: 7,
    ),
    
    // LEVEL 8: Master Recipes (Cream unlocked, 5-ingredient)
    CraftableDessert(
      id: 14,
      name: 'Cream Cake',
      emoji: '🍰',
      requiredIngredients: [1, 2, 4, 5, 9], // Flour + Sugar + Butter + Eggs + Cream
      baseValue: 280,
      color: Color(0xFFF5F5DC),
      description: 'Luxurious cream cake',
      unlocksAtLevel: 8,
    ),
    
    CraftableDessert(
      id: 15,
      name: 'Chocolate Cream',
      emoji: '🍫',
      requiredIngredients: [6, 9, 2, 8], // Chocolate + Cream + Sugar + Vanilla
      baseValue: 260,
      color: Color(0xFF8B4513),
      description: 'Rich chocolate cream dessert',
      unlocksAtLevel: 8,
    ),
    
    // LEVEL 9: Expert Recipes (Honey unlocked)
    CraftableDessert(
      id: 16,
      name: 'Honey Cake',
      emoji: '🍰',
      requiredIngredients: [1, 2, 4, 5, 10], // Flour + Sugar + Butter + Eggs + Honey
      baseValue: 320,
      color: Color(0xFFFFD700),
      description: 'Sweet honey cake',
      unlocksAtLevel: 9,
    ),
    
    CraftableDessert(
      id: 17,
      name: 'Honey Pancakes',
      emoji: '🥞',
      requiredIngredients: [1, 3, 5, 10, 4], // Flour + Milk + Eggs + Honey + Butter
      baseValue: 340,
      color: Color(0xFFFFA500),
      description: 'Fluffy honey pancakes',
      unlocksAtLevel: 9,
    ),
    
    // LEVEL 10+: Ultimate Recipes (Premium multi-ingredient)
    CraftableDessert(
      id: 18,
      name: "Master's Delight",
      emoji: '🏆',
      requiredIngredients: [1, 2, 6, 7, 8, 9], // Flour + Sugar + Chocolate + Strawberries + Vanilla + Cream
      baseValue: 500,
      color: Color(0xFF9370DB),
      description: 'The ultimate dessert creation',
      unlocksAtLevel: 10,
    ),
    
    CraftableDessert(
      id: 19,
      name: 'Royal Cake',
      emoji: '👑',
      requiredIngredients: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], // All 10 ingredients
      baseValue: 1000,
      color: Color(0xFFFFD700),
      description: 'The crown jewel of desserts',
      unlocksAtLevel: 10,
    ),
  ];

  static CraftableDessert? getDessertById(int id) {
    try {
      return dessertRecipes.firstWhere((dessert) => dessert.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get available recipes based on shop level (progressive unlock system)
  static List<CraftableDessert> getAvailableRecipes(int shopLevel) {
    return dessertRecipes.where((recipe) => recipe.unlocksAtLevel <= shopLevel).toList();
  }

  // Get all desserts that can be crafted with available ingredients AND shop level
  static List<CraftableDessert> getAvailableDesserts(List<int> availableIngredientLevels, int shopLevel) {
    
    final availableDesserts = dessertRecipes.where((dessert) {
      // Must be unlocked at current shop level
      if (dessert.unlocksAtLevel > shopLevel) {
        return false;
      }
      
      // Must have all required ingredients
      final hasAllIngredients = dessert.requiredIngredients.every((requiredLevel) {
        return availableIngredientLevels.contains(requiredLevel);
      });
      
      if (!hasAllIngredients) {
        return false;
      }
      
      return true;
    }).toList();
    
    return availableDesserts;
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