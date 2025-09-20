import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/models/dessert.dart';

enum CustomerType {
  bear,
  rabbit,
  cat,
  fox,
  panda,
}

enum CustomerState {
  entering,        // Walking from entrance to counter
  walkingToCounter, // Moving to ordering position
  ordering,        // At counter placing order
  walkingToTable,  // Moving to find/sit at table
  sitting,         // Sitting at table
  eating,          // Eating food at table
  walkingToExit,   // Walking from table to exit door
  leaving,         // Exiting through door
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
  double _patienceAccumulator = 0.0; // Accumulates fractional patience loss
  final List<int> preferredDesserts;
  int? orderLevel; // For merged dessert orders (level 1-10)
  OrderType? orderType;
  int? orderCraftedDessertId; // For crafted dessert orders
  final double speed;
  final Color color;
  String? assignedTableId; // ID of the table this customer is sitting at
  bool isSeated; // Whether customer has successfully taken a seat
  
  // Pathfinding properties
  List<Offset> currentPath = []; // Current path to follow
  int currentPathIndex = 0; // Current waypoint in path
  bool isMoving = false; // Whether customer is actively moving
  Offset? nextWaypoint; // Next target waypoint
  double eatingTimer = 0.0; // Timer for eating duration
  final double eatingDuration; // How long to eat (in seconds)

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
    this.eatingDuration = 10.0, // Default 10 seconds eating time
  }) : currentPatience = currentPatience ?? patience;

  // Weighted merged dessert level selection - scaled to shop level
  static int _selectWeightedMergedLevel(Random random, int shopLevel) {
    // Max level customers can order is shopLevel + 2 (to provide slight challenge)
    final maxLevel = (shopLevel + 2).clamp(1, 10);
    
    // Generate weights based on available levels
    final weights = <double>[];
    for (int level = 1; level <= maxLevel; level++) {
      if (level <= shopLevel) {
        // Levels at or below shop level - high probability
        weights.add(10.0 - (level - 1) * 1.0); // 10.0, 9.0, 8.0, etc.
      } else {
        // Challenge levels (shopLevel + 1, shopLevel + 2) - low probability
        final challengeBonus = level - shopLevel;
        weights.add(3.0 / challengeBonus); // 3.0, 1.5 for +1, +2 levels
      }
    }
    
    final totalWeight = weights.reduce((a, b) => a + b);
    final randomValue = random.nextDouble() * totalWeight;
    
    double currentWeight = 0.0;
    for (int i = 0; i < weights.length; i++) {
      currentWeight += weights[i];
      if (randomValue <= currentWeight) {
        final level = i + 1;
        return level;
      }
    }
    
    // Fallback
    return 1;
  }

  // Weighted recipe selection - heavily favor lower-level desserts
  static CraftableDessert _selectWeightedRecipe(List<CraftableDessert> availableRecipes, Random random) {
    // Create weights: higher level = exponentially lower chance
    final weights = <double>[];
    for (final recipe in availableRecipes) {
      // Weight formula: Higher level = exponentially lower probability
      // Level 2: weight = 10.0, Level 3: weight = 7.0, Level 4: weight = 5.0, etc.
      double weight;
      switch (recipe.unlocksAtLevel) {
        case 2: weight = 10.0; break;  // 44% chance (Cookies)
        case 3: weight = 7.0; break;   // 31% chance (Pancakes, Toast)
        case 4: weight = 4.0; break;   // 17% chance (Muffins, Eggs, Donuts)
        case 5: weight = 2.5; break;   // 11% chance (Hot Chocolate, Chocolate Muffin)
        case 6: weight = 1.5; break;   // 6% chance (Berry Pie, Simple Cake, Strawberry Milk)
        case 7: weight = 0.8; break;   // 3% chance (Vanilla desserts)
        case 8: weight = 0.4; break;   // 1.5% chance (Cream desserts)
        case 9: weight = 0.2; break;   // 0.8% chance (Honey desserts)
        case 10: weight = 0.1; break;  // 0.4% chance (Master's Delight, Royal Cake)
        default: weight = 0.05; break; // 0.2% chance (any higher levels)
      }
      weights.add(weight);
    }
    
    // Calculate total weight
    final totalWeight = weights.reduce((a, b) => a + b);
    
    // Generate random number between 0 and totalWeight
    final randomValue = random.nextDouble() * totalWeight;
    
    // Find which recipe was selected
    double currentWeight = 0.0;
    for (int i = 0; i < availableRecipes.length; i++) {
      currentWeight += weights[i];
      if (randomValue <= currentWeight) {
        return availableRecipes[i];
      }
    }
    
    // Fallback (shouldn't happen)
    return availableRecipes.first;
  }

  static Customer generateRandomCustomer({int shopLevel = 1}) {
    final random = Random();
    final types = CustomerType.values;
    final type = types[random.nextInt(types.length)];
    
    final customerData = _customerData[type]!;
    
    // Randomly choose between merged desserts and crafted desserts
    // 70% chance for merged dessert, 30% chance for crafted dessert (since crafted are more valuable)
    final randomChoice = random.nextDouble();
    OrderType orderType = randomChoice < 0.7 ? OrderType.mergedDessert : OrderType.craftedDessert;
    
    int? orderLevel;
    int? orderCraftedDessertId;
    
    if (orderType == OrderType.mergedDessert) {
      // Order a weighted random merged dessert level scaled to shop level
      orderLevel = _selectWeightedMergedLevel(random, shopLevel);
      debugPrint('✅ Customer at shop level $shopLevel ordered merged dessert level $orderLevel');
    } else {
      // Order a weighted random crafted dessert (favor lower-level desserts)
      final availableRecipes = CraftableDessert.getAvailableRecipes(shopLevel);
      if (availableRecipes.isNotEmpty) {
        final selectedRecipe = _selectWeightedRecipe(availableRecipes, random);
        orderCraftedDessertId = selectedRecipe.id;
        debugPrint('✅ Selected crafted dessert: ${selectedRecipe.name} (ID: ${selectedRecipe.id})');
      } else {
        // Fallback to merged dessert if no crafted recipes available
        debugPrint('❌ No crafted recipes available! Falling back to merged dessert');
        orderType = OrderType.mergedDessert;
        orderLevel = _selectWeightedMergedLevel(random, shopLevel);
        debugPrint('✅ Customer at shop level $shopLevel ordered merged dessert level $orderLevel (fallback)');
      }
    }
    
    return Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      name: customerData['name'],
      emoji: customerData['emoji'],
      patience: 45 + random.nextInt(46), // 45-90 seconds - BALANCED RANGE
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

  // Pathfinding methods
  void setPath(List<Offset> path) {
    currentPath = List.from(path);
    currentPathIndex = 0;
    isMoving = path.isNotEmpty;
    if (isMoving && currentPath.isNotEmpty) {
      nextWaypoint = currentPath[0];
      setTarget(nextWaypoint!.dx, nextWaypoint!.dy);
    }
  }

  void updatePathMovement(double deltaTime) {
    if (!isMoving || currentPath.isEmpty) return;

    updatePosition(deltaTime);

    // Check if reached current waypoint
    final currentPos = Offset(x, y);
    if (nextWaypoint != null && (currentPos - nextWaypoint!).distance < 5.0) {
      currentPathIndex++;
      
      if (currentPathIndex >= currentPath.length) {
        // Reached end of path
        isMoving = false;
        currentPath.clear();
        currentPathIndex = 0;
        nextWaypoint = null;
        onPathComplete();
      } else {
        // Move to next waypoint
        nextWaypoint = currentPath[currentPathIndex];
        setTarget(nextWaypoint!.dx, nextWaypoint!.dy);
      }
    }
  }

  // Called when customer completes current path
  void onPathComplete() {
    switch (state) {
      case CustomerState.entering:
        state = CustomerState.walkingToCounter;
        break;
      case CustomerState.walkingToCounter:
        state = CustomerState.ordering;
        break;
      case CustomerState.walkingToTable:
        state = CustomerState.sitting;
        isSeated = true;
        break;
      case CustomerState.walkingToExit:
        state = CustomerState.leaving;
        break;
      default:
        break;
    }
  }

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
    double? eatingDuration,
  }) {
    final newCustomer = Customer(
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
      eatingDuration: eatingDuration ?? this.eatingDuration,
    );
    
    // Copy pathfinding state
    newCustomer.currentPath = List.from(currentPath);
    newCustomer.currentPathIndex = currentPathIndex;
    newCustomer.isMoving = isMoving;
    newCustomer.nextWaypoint = nextWaypoint;
    newCustomer.eatingTimer = eatingTimer;
    
    return newCustomer;
  }

  // Patience management methods
  void decreasePatience(int amount) {
    currentPatience = (currentPatience - amount).clamp(0, patience);
  }

  void updatePatience(double deltaTime) {
    // Handle eating timer
    if (state == CustomerState.eating) {
      eatingTimer += deltaTime;
      if (eatingTimer >= eatingDuration) {
        state = CustomerState.walkingToExit;
        eatingTimer = 0.0;
      }
      return; // Don't decrease patience while eating
    }
    
    // Only decrease patience when ordering, waiting, or moving to table
    if (state == CustomerState.ordering || 
        state == CustomerState.walkingToCounter ||
        state == CustomerState.walkingToTable ||
        state == CustomerState.sitting) {
      // Accumulate patience loss over time (1 point per second)
      _patienceAccumulator += deltaTime;
      
      // When accumulator reaches 1 second, decrease patience by 1
      if (_patienceAccumulator >= 1.0) {
        decreasePatience(_patienceAccumulator.floor());
        _patienceAccumulator -= _patienceAccumulator.floor();
      }
    }
  }

  double get patienceRatio => patience > 0 ? currentPatience / patience : 0.0;

  bool get isImpatient => currentPatience <= patience * 0.3; // Impatient at 30%
  bool get isAngry => currentPatience <= patience * 0.1; // Angry at 10%
  bool get isLeaving => currentPatience <= 0; // Leaves when patience runs out

  Color get patienceColor {
    if (patienceRatio > 0.7) return Colors.green;
    if (patienceRatio > 0.4) return Colors.orange;
    if (patienceRatio > 0.1) return Colors.red;
    return Colors.red.shade900;
  }

  // Calculate reward multiplier based on remaining patience - BALANCED
  double get rewardMultiplier {
    if (patienceRatio >= 0.5) return 1.8; // 180% reward for happy (50%+)
    if (patienceRatio >= 0.3) return 1.4; // 140% reward for content (30-50%)
    if (patienceRatio >= 0.15) return 1.0; // 100% reward for neutral (15-30%)
    if (patienceRatio >= 0.05) return 0.7; // 70% reward for impatient (5-15%)
    return 0.5; // 50% reward for angry (0-5%)
  }
}