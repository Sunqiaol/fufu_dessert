import 'package:flutter/material.dart';

enum FurnitureType {
  displayCase,
  cashRegister,
  table,
  sofa,
  plant,
  counter,
  decoration,
  seating,
  lighting,
  entertainment,
  kitchen,
  storage,
  service,
  premium,
}

class Furniture {
  final String id;
  final FurnitureType type;
  final String name;
  final String emoji;
  final int level;
  final int price;
  final double width;
  final double height;
  final Color color;
  final int attractionBonus;
  final bool canUpgrade;
  final int seatingCapacity; // Number of people this furniture can seat (0 if not seating)
  final int upgradePrice; // Cost to upgrade this furniture
  final String? upgradeId; // ID of the upgraded version

  const Furniture({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
    required this.level,
    required this.price,
    required this.width,
    required this.height,
    required this.color,
    required this.attractionBonus,
    required this.canUpgrade,
    this.seatingCapacity = 0,
    this.upgradePrice = 0,
    this.upgradeId,
  });

  static const List<Furniture> furnitureItems = [
    // === DISPLAY CASES & SERVICE ===
    Furniture(
      id: 'display_case_1',
      type: FurnitureType.displayCase,
      name: 'Basic Display Case',
      emoji: '🗄️',
      level: 1,
      price: 50,
      width: 2.0,
      height: 1.0,
      color: Color(0xFF8B4513),
      attractionBonus: 5,
      canUpgrade: true,
    ),
    Furniture(
      id: 'display_case_2',
      type: FurnitureType.displayCase,
      name: 'Glass Display Case',
      emoji: '🍰',
      level: 2,
      price: 150,
      width: 2.0,
      height: 1.0,
      color: Color(0xFFDDA0DD),
      attractionBonus: 12,
      canUpgrade: true,
    ),
    Furniture(
      id: 'display_case_3',
      type: FurnitureType.displayCase,
      name: 'Premium Dessert Showcase',
      emoji: '🧁',
      level: 3,
      price: 400,
      width: 3.0,
      height: 1.0,
      color: Color(0xFFFFB6C1),
      attractionBonus: 25,
      canUpgrade: false,
    ),
    
    // === CASH REGISTERS & SERVICE ===
    Furniture(
      id: 'cash_register_1',
      type: FurnitureType.cashRegister,
      name: 'Basic Register',
      emoji: '💰',
      level: 1,
      price: 100,
      width: 1.0,
      height: 1.0,
      color: Color(0xFF696969),
      attractionBonus: 10,
      canUpgrade: true,
    ),
    Furniture(
      id: 'cash_register_2',
      type: FurnitureType.cashRegister,
      name: 'Digital POS System',
      emoji: '💳',
      level: 2,
      price: 300,
      width: 1.0,
      height: 1.0,
      color: Color(0xFF4169E1),
      attractionBonus: 20,
      canUpgrade: true,
    ),
    Furniture(
      id: 'self_service',
      type: FurnitureType.service,
      name: 'Self-Service Kiosk',
      emoji: '📱',
      level: 3,
      price: 800,
      width: 1.0,
      height: 1.0,
      color: Color(0xFF000080),
      attractionBonus: 35,
      canUpgrade: false,
    ),
    
    // === SEATING - TABLES (Capacity System) ===
    // Level 1 - Basic 4-person tables (2 tables = 8 capacity at start)
    Furniture(
      id: 'table_2_seat',
      type: FurnitureType.table,
      name: '2-Person Table',
      emoji: '🪑',
      level: 1,
      price: 50,
      width: 1.0,
      height: 1.0,
      color: Color(0xFFD2691E),
      attractionBonus: 3,
      canUpgrade: true,
      seatingCapacity: 2,
      upgradePrice: 30,
      upgradeId: 'table_4_seat',
    ),
    Furniture(
      id: 'table_4_seat',
      type: FurnitureType.table,
      name: '4-Person Table',
      emoji: '🪑',
      level: 1,
      price: 80,
      width: 1.5,
      height: 1.5,
      color: Color(0xFFCD853F),
      attractionBonus: 6,
      canUpgrade: true,
      seatingCapacity: 4,
      upgradePrice: 50,
      upgradeId: 'table_6_seat',
    ),
    Furniture(
      id: 'table_6_seat',
      type: FurnitureType.table,
      name: '6-Person Round Table',
      emoji: '⭕',
      level: 2,
      price: 150,
      width: 2.0,
      height: 2.0,
      color: Color(0xFFB8860B),
      attractionBonus: 10,
      canUpgrade: true,
      seatingCapacity: 6,
      upgradePrice: 80,
      upgradeId: 'table_8_seat',
    ),
    Furniture(
      id: 'table_8_seat',
      type: FurnitureType.table,
      name: '8-Person Long Table',
      emoji: '🏛️',
      level: 3,
      price: 250,
      width: 3.0,
      height: 1.5,
      color: Color(0xFF8B4513),
      attractionBonus: 15,
      canUpgrade: true,
      seatingCapacity: 8,
      upgradePrice: 120,
      upgradeId: 'table_10_seat',
    ),
    Furniture(
      id: 'table_10_seat',
      type: FurnitureType.table,
      name: '10-Person Grand Table',
      emoji: '👑',
      level: 4,
      price: 400,
      width: 3.0,
      height: 2.0,
      color: Color(0xFF4B0082),
      attractionBonus: 25,
      canUpgrade: false,
      seatingCapacity: 10,
    ),
    
    // Booth seating - more efficient space usage
    Furniture(
      id: 'booth_4_seat',
      type: FurnitureType.seating,
      name: '4-Person Booth',
      emoji: '🛋️',
      level: 2,
      price: 120,
      width: 2.0,
      height: 1.0,
      color: Color(0xFF708090),
      attractionBonus: 12,
      canUpgrade: true,
      seatingCapacity: 4,
      upgradePrice: 60,
      upgradeId: 'booth_6_seat',
    ),
    Furniture(
      id: 'booth_6_seat',
      type: FurnitureType.seating,
      name: '6-Person Corner Booth',
      emoji: '🏠',
      level: 3,
      price: 200,
      width: 2.0,
      height: 2.0,
      color: Color(0xFF800080),
      attractionBonus: 20,
      canUpgrade: false,
      seatingCapacity: 6,
    ),
    
    // === SEATING - SOFAS & CHAIRS ===
    Furniture(
      id: 'sofa_1',
      type: FurnitureType.sofa,
      name: 'Cozy Sofa',
      emoji: '🛋️',
      level: 1,
      price: 80,
      width: 2.0,
      height: 1.0,
      color: Color(0xFF708090),
      attractionBonus: 8,
      canUpgrade: true,
    ),
    Furniture(
      id: 'armchair',
      type: FurnitureType.seating,
      name: 'Velvet Armchair',
      emoji: '🪑',
      level: 2,
      price: 120,
      width: 1.0,
      height: 1.0,
      color: Color(0xFF800080),
      attractionBonus: 12,
      canUpgrade: true,
    ),
    Furniture(
      id: 'luxury_sofa',
      type: FurnitureType.premium,
      name: 'Luxury Sectional',
      emoji: '🛏️',
      level: 4,
      price: 500,
      width: 3.0,
      height: 2.0,
      color: Color(0xFF4B0082),
      attractionBonus: 40,
      canUpgrade: false,
    ),
    
    // === PLANTS & DECORATION ===
    Furniture(
      id: 'plant_1',
      type: FurnitureType.plant,
      name: 'Small Plant',
      emoji: '🌱',
      level: 1,
      price: 20,
      width: 0.5,
      height: 0.5,
      color: Color(0xFF90EE90),
      attractionBonus: 2,
      canUpgrade: true,
    ),
    Furniture(
      id: 'fern',
      type: FurnitureType.plant,
      name: 'Fern Plant',
      emoji: '🌿',
      level: 2,
      price: 50,
      width: 1.0,
      height: 1.0,
      color: Color(0xFF228B22),
      attractionBonus: 6,
      canUpgrade: true,
    ),
    Furniture(
      id: 'tree_plant',
      type: FurnitureType.plant,
      name: 'Indoor Tree',
      emoji: '🌳',
      level: 3,
      price: 150,
      width: 1.5,
      height: 1.5,
      color: Color(0xFF006400),
      attractionBonus: 12,
      canUpgrade: false,
    ),
    Furniture(
      id: 'flower_arrangement',
      type: FurnitureType.decoration,
      name: 'Flower Arrangement',
      emoji: '🌸',
      level: 2,
      price: 60,
      width: 0.5,
      height: 0.5,
      color: Color(0xFFFFB6C1),
      attractionBonus: 8,
      canUpgrade: false,
    ),
    
    // === LIGHTING ===
    Furniture(
      id: 'lamp',
      type: FurnitureType.lighting,
      name: 'Table Lamp',
      emoji: '🕯️',
      level: 1,
      price: 40,
      width: 0.5,
      height: 0.5,
      color: Color(0xFFFFD700),
      attractionBonus: 4,
      canUpgrade: true,
    ),
    Furniture(
      id: 'chandelier',
      type: FurnitureType.lighting,
      name: 'Crystal Chandelier',
      emoji: '💎',
      level: 4,
      price: 800,
      width: 2.0,
      height: 1.0,
      color: Color(0xFFE6E6FA),
      attractionBonus: 50,
      canUpgrade: false,
    ),
    
    // === ENTERTAINMENT ===
    Furniture(
      id: 'bookshelf',
      type: FurnitureType.entertainment,
      name: 'Bookshelf',
      emoji: '📚',
      level: 2,
      price: 90,
      width: 1.0,
      height: 2.0,
      color: Color(0xFF8B4513),
      attractionBonus: 10,
      canUpgrade: true,
    ),
    Furniture(
      id: 'tv',
      type: FurnitureType.entertainment,
      name: 'Wall TV',
      emoji: '📺',
      level: 3,
      price: 300,
      width: 2.0,
      height: 0.5,
      color: Color(0xFF000000),
      attractionBonus: 20,
      canUpgrade: true,
    ),
    Furniture(
      id: 'piano',
      type: FurnitureType.entertainment,
      name: 'Baby Grand Piano',
      emoji: '🎹',
      level: 5,
      price: 2000,
      width: 3.0,
      height: 2.0,
      color: Color(0xFF000000),
      attractionBonus: 80,
      canUpgrade: false,
    ),
    
    // === KITCHEN & STORAGE ===
    Furniture(
      id: 'counter',
      type: FurnitureType.counter,
      name: 'Service Counter',
      emoji: '🏪',
      level: 1,
      price: 100,
      width: 3.0,
      height: 1.0,
      color: Color(0xFF8FBC8F),
      attractionBonus: 8,
      canUpgrade: true,
    ),
    Furniture(
      id: 'coffee_machine',
      type: FurnitureType.kitchen,
      name: 'Espresso Machine',
      emoji: '☕',
      level: 2,
      price: 250,
      width: 1.0,
      height: 1.0,
      color: Color(0xFF8B4513),
      attractionBonus: 18,
      canUpgrade: true,
    ),
    Furniture(
      id: 'oven',
      type: FurnitureType.kitchen,
      name: 'Professional Oven',
      emoji: '🔥',
      level: 3,
      price: 600,
      width: 2.0,
      height: 1.0,
      color: Color(0xFF708090),
      attractionBonus: 25,
      canUpgrade: false,
    ),
    Furniture(
      id: 'fridge',
      type: FurnitureType.storage,
      name: 'Display Fridge',
      emoji: '❄️',
      level: 2,
      price: 400,
      width: 1.0,
      height: 2.0,
      color: Color(0xFFE0E0E0),
      attractionBonus: 22,
      canUpgrade: true,
    ),
    
    // === PREMIUM ITEMS ===
    Furniture(
      id: 'fountain',
      type: FurnitureType.premium,
      name: 'Chocolate Fountain',
      emoji: '⛲',
      level: 5,
      price: 1500,
      width: 2.0,
      height: 2.0,
      color: Color(0xFF8B4513),
      attractionBonus: 100,
      canUpgrade: false,
    ),
    Furniture(
      id: 'aquarium',
      type: FurnitureType.premium,
      name: 'Large Aquarium',
      emoji: '🐠',
      level: 4,
      price: 800,
      width: 3.0,
      height: 1.0,
      color: Color(0xFF4169E1),
      attractionBonus: 60,
      canUpgrade: false,
    ),
  ];

  // Helper methods for furniture management
  static List<Furniture> getAvailableForLevel(int shopLevel) {
    return furnitureItems.where((furniture) => furniture.level <= shopLevel).toList();
  }

  static List<Furniture> getByType(FurnitureType type) {
    return furnitureItems.where((furniture) => furniture.type == type).toList();
  }

  static Furniture? getById(String id) {
    try {
      return furnitureItems.firstWhere((furniture) => furniture.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<FurnitureType> getUnlockedTypes(int shopLevel) {
    Set<FurnitureType> unlockedTypes = {};
    for (var furniture in furnitureItems) {
      if (furniture.level <= shopLevel) {
        unlockedTypes.add(furniture.type);
      }
    }
    return unlockedTypes.toList();
  }
}

class PlacedFurniture {
  final String id;
  final Furniture furniture;
  final double x;
  final double y;
  final double rotation;
  final bool? justPlaced;

  PlacedFurniture({
    required this.id,
    required this.furniture,
    required this.x,
    required this.y,
    this.rotation = 0.0,
    this.justPlaced,
  });

  PlacedFurniture copyWith({
    String? id,
    Furniture? furniture,
    double? x,
    double? y,
    double? rotation,
    bool? justPlaced,
  }) {
    return PlacedFurniture(
      id: id ?? this.id,
      furniture: furniture ?? this.furniture,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      justPlaced: justPlaced ?? this.justPlaced,
    );
  }
}