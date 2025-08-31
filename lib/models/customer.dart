import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/models/dessert.dart';

enum CustomerType {
  bear,
  rabbit,
  cat,
  dog,
  fox,
  panda,
}

enum CustomerState {
  entering,
  browsing,
  ordering,
  waiting,
  eating,
  leaving,
}

enum OrderType {
  mergedDessert, // Orders a specific merged dessert level (1-10 from merge grid)
  craftedDessert,    // Orders a specific crafted dessert (complex recipes)
}

class Customer {
  final String id;
  final CustomerType type;
  final String name;
  final String emoji;
  CustomerState state;
  double x;
  double y;
  double targetX;
  double targetY;
  final int patience;
  int currentPatience;
  final List<int> preferredDesserts;
  int? orderLevel; // For merged dessert orders (level 1-10)
  OrderType? orderType;
  int? orderCraftedDessertId; // For crafted dessert orders
  final double speed;
  final Color color;
  String? assignedTableId; // ID of the table this customer is sitting at
  bool isSeated; // Whether customer has successfully taken a seat

  Customer({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
    this.state = CustomerState.entering,
    this.x = 0.0,
    this.y = 0.0,
    this.targetX = 0.0,
    this.targetY = 0.0,
    required this.patience,
    int? currentPatience,
    required this.preferredDesserts,
    this.orderLevel,
    this.orderType,
    this.orderCraftedDessertId,
    this.speed = 1.0,
    required this.color,
    this.assignedTableId,
    this.isSeated = false,
  }) : currentPatience = currentPatience ?? patience;

  static Customer generateRandomCustomer() {
    final random = Random();
    final types = CustomerType.values;
    final type = types[random.nextInt(types.length)];
    
    final customerData = _customerData[type]!;
    
    // Randomly choose between merged desserts and crafted desserts
    // 70% chance for merged dessert, 30% chance for crafted dessert (since crafted are more valuable)
    final orderType = random.nextDouble() < 0.7 ? OrderType.mergedDessert : OrderType.craftedDessert;
    
    int? orderLevel;
    int? orderCraftedDessertId;
    
    if (orderType == OrderType.mergedDessert) {
      // Order a random merged dessert level (1-10 from merge grid)
      orderLevel = 1 + random.nextInt(10);
    } else {
      // Order a random crafted dessert (1-10 dessert IDs)
      orderCraftedDessertId = 1 + random.nextInt(10);
    }
    
    return Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: customerData['name'],
      emoji: customerData['emoji'],
      patience: 30 + random.nextInt(30), // 30-60 seconds
      preferredDesserts: List.generate(
        2 + random.nextInt(4), 
        (_) => 1 + random.nextInt(10)
      ),
      orderLevel: orderLevel,
      orderType: orderType,
      orderCraftedDessertId: orderCraftedDessertId,
      speed: 0.8 + random.nextDouble() * 0.4, // 0.8-1.2 speed
      color: customerData['color'],
    );
  }

  static const Map<CustomerType, Map<String, dynamic>> _customerData = {
    CustomerType.bear: {
      'name': 'Bear',
      'emoji': '🐻',
      'color': Color(0xFF8B4513),
    },
    CustomerType.rabbit: {
      'name': 'Rabbit',
      'emoji': '🐰',
      'color': Color(0xFFFFF8DC),
    },
    CustomerType.cat: {
      'name': 'Cat',
      'emoji': '🐱',
      'color': Color(0xFF696969),
    },
    CustomerType.dog: {
      'name': 'Dog',
      'emoji': '🐶',
      'color': Color(0xFFCD853F),
    },
    CustomerType.fox: {
      'name': 'Fox',
      'emoji': '🦊',
      'color': Color(0xFFFF4500),
    },
    CustomerType.panda: {
      'name': 'Panda',
      'emoji': '🐼',
      'color': Color(0xFF000000),
    },
  };

  void updatePosition(double deltaTime) {
    if (x != targetX || y != targetY) {
      final dx = targetX - x;
      final dy = targetY - y;
      final distance = sqrt(dx * dx + dy * dy);
      
      if (distance > 0.1) {
        final moveDistance = speed * deltaTime * 60;
        final ratio = min(moveDistance / distance, 1.0);
        
        x += dx * ratio;
        y += dy * ratio;
      } else {
        x = targetX;
        y = targetY;
      }
    }
  }

  void setTarget(double newTargetX, double newTargetY) {
    targetX = newTargetX;
    targetY = newTargetY;
  }

  void decreasePatience() {
    if (currentPatience > 0) {
      currentPatience--;
    }
  }

  bool isImpatient() => currentPatience <= 5;
  
  bool hasLeftCafe() => currentPatience <= 0;

  String getOrderDescription() {
    if (orderType == OrderType.mergedDessert && orderLevel != null) {
      final mergedDessert = Dessert.getDessertByLevel(orderLevel!);
      return '${mergedDessert.emoji} ${mergedDessert.name} (Merged)';
    } else if (orderType == OrderType.craftedDessert && orderCraftedDessertId != null) {
      final craftedDessert = CraftableDessert.getDessertById(orderCraftedDessertId!);
      if (craftedDessert != null) {
        return '${craftedDessert.emoji} ${craftedDessert.name} (Crafted)';
      }
    }
    return 'Unknown Order';
  }

  Customer copyWith({
    String? id,
    CustomerType? type,
    String? name,
    String? emoji,
    CustomerState? state,
    double? x,
    double? y,
    double? targetX,
    double? targetY,
    int? patience,
    int? currentPatience,
    List<int>? preferredDesserts,
    int? orderLevel,
    OrderType? orderType,
    int? orderCraftedDessertId,
    double? speed,
    Color? color,
    String? assignedTableId,
    bool? isSeated,
  }) {
    return Customer(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      state: state ?? this.state,
      x: x ?? this.x,
      y: y ?? this.y,
      targetX: targetX ?? this.targetX,
      targetY: targetY ?? this.targetY,
      patience: patience ?? this.patience,
      currentPatience: currentPatience ?? this.currentPatience,
      preferredDesserts: preferredDesserts ?? this.preferredDesserts,
      orderLevel: orderLevel ?? this.orderLevel,
      orderType: orderType ?? this.orderType,
      orderCraftedDessertId: orderCraftedDessertId ?? this.orderCraftedDessertId,
      speed: speed ?? this.speed,
      color: color ?? this.color,
      assignedTableId: assignedTableId ?? this.assignedTableId,
      isSeated: isSeated ?? this.isSeated,
    );
  }
}