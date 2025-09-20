import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/furniture.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/services/audio_service.dart';

class CustomerProvider with ChangeNotifier {
  // Base values - will be scaled by shop level
  static const int baseMaxCustomers = 4;
  static const int baseCustomerSpawnInterval = 10; // seconds
  static const int autoFeedDelaySeconds = 8; // Auto-feed delay in seconds - OPTIMIZED
  
  List<Customer> _customers = [];
  Timer? _spawnTimer;
  Timer? _updateTimer;
  Timer? _autoFeedTimer;
  final math.Random _random = math.Random();
  int _shopLevel = 1; // Track current shop level
  final Map<String, DateTime> _customerOrderTime = {}; // Track when customers started ordering
  
  List<Customer> get customers => _customers;
  int get customerCount => _customers.length;
  
  // Dynamic properties that scale with seating capacity
  int get maxCustomers {
    try {
      if (getSeatingCapacity == null) {
        return 8; // Default capacity when callback not set
      }
      final seatingCapacity = getSeatingCapacity!.call();
      return seatingCapacity.clamp(2, 50); // Allow up to 50 customers max
    } catch (e) {
      debugPrint('Error getting seating capacity: $e');
      return 8; // Fallback to default capacity
    }
  }
  int get customerSpawnInterval => (baseCustomerSpawnInterval - (_shopLevel * 0.5)).clamp(3, 10).round();
  double get cafeAttraction => _calculateTotalAttraction();
  int get shopLevel => _shopLevel;

  CustomerProvider() {
    _startCustomerSpawning();
    _startCustomerUpdates();
  }

  // Update shop level and restart timers with new intervals
  void updateShopLevel(int newLevel) {
    if (_shopLevel != newLevel) {
      _shopLevel = newLevel;
      
      // Restart spawning timer with new interval
      _spawnTimer?.cancel();
      _startCustomerSpawning();
      
      notifyListeners();
    }
  }

  // Callbacks to get data from CafeProvider
  int Function()? getFurnitureAttraction;
  int Function()? getSeatingCapacity;
  List<PlacedFurniture> Function()? getSeatingFurniture;
  
  // Calculate total attraction from furniture
  double _calculateTotalAttraction() {
    try {
      int furnitureBonus = 0;
      if (getFurnitureAttraction != null) {
        final result = getFurnitureAttraction!.call();
        furnitureBonus = result;
      }
      return 50.0 + (_shopLevel * 10) + furnitureBonus; // Base + level + furniture
    } catch (e) {
      debugPrint('Error calculating attraction: $e');
      return 50.0 + (_shopLevel * 10); // Fallback to base + level only
    }
  }

  void _startCustomerSpawning() {
    _spawnTimer = Timer.periodic(
      Duration(seconds: customerSpawnInterval),
      (_) => _trySpawnCustomer(),
    );
  }

  void _startCustomerUpdates() {
    _updateTimer = Timer.periodic(
      const Duration(milliseconds: 100), // 10 FPS - MEMORY OPTIMIZED
      (_) => _updateCustomers(),
    );
    
    // Start auto-feeding timer
    _startAutoFeeding();
  }
  
  void _startAutoFeeding() {
    _autoFeedTimer = Timer.periodic(
      const Duration(seconds: 2), // Check every 2 seconds
      (_) => _checkAutoFeed(),
    );
  }

  void _trySpawnCustomer() {
    // Check if store is open before spawning new customers
    final bool isStoreOpen = getIsStoreOpenCallback?.call() ?? true;
    
    if (!isStoreOpen) {
      // Store is closed - no new customers can enter
      return;
    }
    
    // STRICT ENFORCEMENT: Only allow customers up to available seating capacity
    final currentCustomers = _customers.length;
    final availableSeats = maxCustomers;
    
    if (currentCustomers >= availableSeats) {
      // No available seats - no new customers allowed
      debugPrint('🚫 Cannot spawn customer: cafe at full capacity ($currentCustomers/$availableSeats)');
      return;
    }
    
    _spawnCustomer();
  }

  void _spawnCustomer() {
    // DOUBLE-CHECK: Ensure we still have capacity before spawning
    if (_customers.length >= maxCustomers) {
      debugPrint('🚫 Spawn cancelled: capacity reached during spawn process (${_customers.length}/$maxCustomers)');
      return;
    }
    
    // Sync check: if GameProvider has a different level, update ours
    if (getCurrentShopLevelCallback != null) {
      final actualLevel = getCurrentShopLevelCallback!();
      if (actualLevel != _shopLevel) {
        debugPrint('🔧 SYNC FIX: CustomerProvider level was $_shopLevel, GameProvider is $actualLevel - syncing now!');
        _shopLevel = actualLevel;
      }
    }
    
    final customer = Customer.generateRandomCustomer(shopLevel: _shopLevel);

    // Use boundary-constrained positions
    final validBounds = _getFloorGridBounds();
    final enterPos = _getRandomValidPosition(validBounds);
    final targetPos = _getRandomValidPosition(validBounds);

    // Set spawn position within floor boundaries
    customer.x = enterPos.dx;
    customer.y = enterPos.dy;
    customer.targetX = targetPos.dx;
    customer.targetY = targetPos.dy;
    customer.state = CustomerState.entering;
    
    // FINAL SAFETY CHECK: Ensure we don't exceed capacity
    if (_customers.length >= maxCustomers) {
      debugPrint('🚫 Customer rejected at final check: capacity full (${_customers.length}/$maxCustomers)');
      return;
    }
    
    _customers.add(customer);
    debugPrint('✅ Customer spawned: ${customer.name} ${customer.emoji} (${_customers.length}/$maxCustomers)');
    
    // Play customer enter sound effect
    AudioService().playSoundEffect(SoundEffect.customerEnter);
    
    notifyListeners();
    
    // Schedule state transitions
    _scheduleCustomerBehavior(customer);
  }

  void _scheduleCustomerBehavior(Customer customer) {
    // Enter -> Browse (1.5 seconds - OPTIMIZED)
    Timer(Duration(milliseconds: 1500), () {
      if (_customers.contains(customer) && customer.state == CustomerState.entering) {
        customer.state = CustomerState.walkingToCounter;
        _moveCustomerToBrowse(customer);
        notifyListeners();
      }
    });
    
    // Browse -> Order (3-5 seconds - OPTIMIZED)
    Timer(Duration(seconds: 3 + _random.nextInt(3)), () {
      if (_customers.contains(customer) && customer.state == CustomerState.walkingToCounter) {
        customer.state = CustomerState.ordering;
        _moveCustomerToOrder(customer);
        // Track when customer started ordering for auto-feed
        _customerOrderTime[customer.id] = DateTime.now();
        // Play doorbell sound when customer places an order
        AudioService().playSoundEffect(SoundEffect.doorbell);
        notifyListeners();
      }
    });
  }

  void _moveCustomerToBrowse(Customer customer) {
    // Move to a random browsing position
    customer.setTarget(
      1.0 + _random.nextDouble() * 8.0,
      2.0 + _random.nextDouble() * 6.0,
    );
  }

  void _moveCustomerToOrder(Customer customer) {
    // Move to cash register area (front counter)
    customer.setTarget(9.0 + _random.nextDouble() * 2.0, 4.0 + _random.nextDouble() * 2.0);
    
    // Generate an order
    customer.orderLevel = customer.preferredDesserts.isNotEmpty 
        ? customer.preferredDesserts[_random.nextInt(customer.preferredDesserts.length)]
        : 1 + _random.nextInt(5);
  }

  // Serve customer with item from storage - returns true if successful
  bool serveCustomerFromStorage(String customerId) {
    final customerIndex = _customers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return false;
    
    final customer = _customers[customerIndex];
    
    if (customer.state != CustomerState.ordering) {
      return false;
    }
    
    bool serviceSuccessful = false;
    
    // Handle different order types
    if (customer.orderType == OrderType.mergedDessert && customer.orderLevel != null) {
      // Customer wants a merged dessert from storage
      final requestedLevel = customer.orderLevel!;
      if (serveDessertCallback != null && serveDessertCallback!(requestedLevel)) {
        serviceSuccessful = true;
      }
    } else if (customer.orderType == OrderType.craftedDessert && customer.orderCraftedDessertId != null) {
      // Customer wants a crafted dessert
      final requestedDessertId = customer.orderCraftedDessertId!;
      if (serveCraftedDessertCallback != null && serveCraftedDessertCallback!(requestedDessertId)) {
        serviceSuccessful = true;
      }
    }
    
    if (!serviceSuccessful) {
      // Customer is disappointed - they leave
      customer.state = CustomerState.leaving;
      _moveCustomerToExit(customer);
      
      Timer(const Duration(seconds: 2), () {
        _customers.remove(customer);
        // Play customer leave sound effect
        AudioService().playSoundEffect(SoundEffect.customerLeave);
        notifyListeners();
      });
      
      return false;
    }
    
    // Customer is satisfied!
    final satisfaction = 1.0; // Perfect satisfaction for exact match
    
    // Calculate payment with patience-based reward multiplier
    int basePayment;
    if (customer.orderType == OrderType.craftedDessert && customer.orderCraftedDessertId != null) {
      final craftedDessert = CraftableDessert.getDessertById(customer.orderCraftedDessertId!);
      basePayment = craftedDessert?.baseValue ?? 50;
    } else {
      final dessert = Dessert.getDessertByLevel(customer.orderLevel ?? 1);
      basePayment = dessert.baseValue;
    }
    
    final rewardMultiplier = customer.rewardMultiplier;
    final payment = (basePayment * satisfaction * rewardMultiplier).round();
    
    // Debug payment calculation
    debugPrint('💰 Payment Debug: basePayment=$basePayment, satisfaction=$satisfaction, rewardMultiplier=$rewardMultiplier, finalPayment=$payment, patience=${customer.patience}');
    
    // Notify game provider about payment
    if (onCustomerServedCallback != null) {
      onCustomerServedCallback!(payment, satisfaction > 0.7);
    }
    
    // Play money merge sound effect when successfully serving customer
    AudioService().playSoundEffect(SoundEffect.moneyMerge);
    
    // First, customer goes to waiting state (food is being prepared)
    final waitingCustomerIndex = _customers.indexWhere((c) => c.id == customerId);
    if (waitingCustomerIndex != -1) {
      _customers[waitingCustomerIndex] = _customers[waitingCustomerIndex].copyWith(state: CustomerState.sitting);
      notifyListeners();
    }
    
    // After a short wait, try to assign a table and start eating
    Timer(Duration(seconds: 1 + _random.nextInt(2)), () {
      final hasTable = _assignTableToCustomer(customerId);
      
      if (hasTable) {
        // Customer successfully got a table and food - now they eat
        // Schedule leaving after eating (1-3 seconds - OPTIMIZED)
        Timer(Duration(seconds: 1 + _random.nextInt(3)), () {
          final customerIndex = _customers.indexWhere((c) => c.id == customerId);
          if (customerIndex != -1) {
            final currentCustomer = _customers[customerIndex];
            _releaseTableFromCustomer(customerId);
            _customers[customerIndex] = currentCustomer.copyWith(state: CustomerState.leaving);
            _moveCustomerToExit(_customers[customerIndex]);
            notifyListeners();
            
            Timer(const Duration(seconds: 2), () {
              _customers.removeWhere((c) => c.id == customerId);
              notifyListeners();
            });
          }
        });
      } else {
        // No table available but they got their dessert - they leave happy but quickly
        final customerIndex = _customers.indexWhere((c) => c.id == customerId);
        if (customerIndex != -1) {
          _customers[customerIndex] = _customers[customerIndex].copyWith(state: CustomerState.leaving);
          _moveCustomerToExit(_customers[customerIndex]);
          notifyListeners();
          
          Timer(const Duration(seconds: 2), () {
            _customers.removeWhere((c) => c.id == customerId);
            // Play customer leave sound effect
            AudioService().playSoundEffect(SoundEffect.customerLeave);
            notifyListeners();
          });
        }
      }
    });
    
    notifyListeners();
    return true;
  }
  
  // Legacy method - kept for compatibility but now serves from storage
  void serveCustomer(String customerId, int dessertLevel) {
    // This method is deprecated - use serveCustomerFromStorage instead
    debugPrint('Warning: serveCustomer is deprecated, use serveCustomerFromStorage');
  }
  
  // Serve customer directly with ingredient from grid
  bool serveCustomerDirectly(String customerId, int dessertLevel) {
    final customerIndex = _customers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return false;
    
    final customer = _customers[customerIndex];
    
    if (customer.state != CustomerState.ordering) {
      return false;
    }
    
    // Check if customer wants this dessert level
    bool serviceSuccessful = false;
    if (customer.orderType == OrderType.mergedDessert && customer.orderLevel == dessertLevel) {
      serviceSuccessful = true;
    }
    
    if (!serviceSuccessful) {
      return false;
    }
    
    // Customer is satisfied!
    final satisfaction = 1.0; // Perfect satisfaction for exact match
    
    // Calculate payment with patience-based reward multiplier
    final dessert = Dessert.getDessertByLevel(dessertLevel);
    final basePayment = dessert.baseValue;
    final rewardMultiplier = customer.rewardMultiplier;
    final payment = (basePayment * satisfaction * rewardMultiplier).round();
    
    // Notify game provider about payment
    if (onCustomerServedCallback != null) {
      onCustomerServedCallback!(payment, satisfaction > 0.7);
    }
    
    // Play money merge sound effect when successfully serving customer
    AudioService().playSoundEffect(SoundEffect.moneyMerge);
    
    // First, customer goes to waiting state (food is being prepared)
    final waitingCustomerIndex = _customers.indexWhere((c) => c.id == customerId);
    if (waitingCustomerIndex != -1) {
      _customers[waitingCustomerIndex] = _customers[waitingCustomerIndex].copyWith(state: CustomerState.sitting);
      notifyListeners();
    }
    
    // After a short wait, try to assign a table and start eating
    Timer(Duration(seconds: 1 + _random.nextInt(2)), () {
      final hasTable = _assignTableToCustomer(customerId);
    
    if (hasTable) {
      // Customer successfully got a table - they will eat
      // Note: _assignTableToCustomer already sets state to eating
      
      // Schedule leaving after eating (1-3 seconds - OPTIMIZED)
      Timer(Duration(seconds: 1 + _random.nextInt(3)), () {
        final customerIndex = _customers.indexWhere((c) => c.id == customerId);
        if (customerIndex != -1) {
          final currentCustomer = _customers[customerIndex];
          _releaseTableFromCustomer(customerId);
          _customers[customerIndex] = currentCustomer.copyWith(state: CustomerState.leaving);
          _moveCustomerToExit(_customers[customerIndex]);
          notifyListeners();
          
          Timer(const Duration(seconds: 2), () {
            _customers.removeWhere((c) => c.id == customerId);
            notifyListeners();
          });
        }
      });
      } else {
        // No table available but they got their dessert - they leave happy but quickly
        final customerIndex = _customers.indexWhere((c) => c.id == customerId);
        if (customerIndex != -1) {
          _customers[customerIndex] = _customers[customerIndex].copyWith(state: CustomerState.leaving);
          _moveCustomerToExit(_customers[customerIndex]);
          notifyListeners();
          
          Timer(const Duration(seconds: 2), () {
            _customers.removeWhere((c) => c.id == customerId);
            // Play customer leave sound effect
            AudioService().playSoundEffect(SoundEffect.customerLeave);
            notifyListeners();
          });
        }
      }
    });
    
    notifyListeners();
    return true;
  }

  void _moveCustomerToExit(Customer customer) {
    // Exit through the top of the store (same as entrance)
    customer.setTarget(8.0 + _random.nextDouble() * 4.0, 0.0);
  }

  void _updateCustomers() {
    final deltaTime = 0.1; // 10 FPS - MEMORY OPTIMIZED
    
    for (final customer in _customers.toList()) {
      // Update position
      customer.updatePosition(deltaTime);
      
      // Update patience system
      customer.updatePatience(deltaTime);
      
      // Handle impatient customers
      if (customer.isLeaving && customer.state != CustomerState.leaving) {
        customer.state = CustomerState.leaving;
        _moveCustomerToExit(customer);
        
        // Apply timeout penalty
        onCustomerTimeoutCallback?.call(customer.patience);
        
        // Customer left without being served - lose satisfaction/reputation
        onCustomerServedCallback?.call(0, false);
        
        Timer(const Duration(seconds: 2), () {
          _customers.remove(customer);
          notifyListeners();
        });
      }
    }
    
    notifyListeners();
  }


  // Callback for when customer is served (to be set by GameProvider)
  Function(int payment, bool wasHappy)? onCustomerServedCallback;
  
  // Callback for when customer times out (to be set by GameProvider)
  Function(int patienceRemaining)? onCustomerTimeoutCallback;

  // Floor boundary helpers to constrain customers within floor area
  Rect _getFloorGridBounds() {
    // Ultra-conservative bounds that are definitely within the red floor outline center
    // Using only the very center of the diamond-shaped floor area to ensure visibility
    return const Rect.fromLTWH(12.0, 12.5, 3.0, 2.0); // x: 12-15, y: 12.5-14.5 (tiny central area)
  }

  Offset _getRandomValidPosition(Rect bounds) {
    return Offset(
      bounds.left + _random.nextDouble() * bounds.width,
      bounds.top + _random.nextDouble() * bounds.height,
    );
  }

  // Callback to get current shop level from GameProvider (fallback sync)
  int Function()? getCurrentShopLevelCallback;
  
  // Callback to check if store is open (from GameProvider)
  bool Function()? getIsStoreOpenCallback;
  
  // Callback to serve merged dessert from storage (to be set by GameProvider)
  bool Function(int dessertLevel)? serveDessertCallback;
  
  // Callback to serve crafted dessert from storage (to be set by GameProvider)
  bool Function(int dessertId)? serveCraftedDessertCallback;
  
  // Callback to check if storage has crafted items available (to be set by GameProvider)
  bool Function(int dessertId)? hasStorageCraftedItemCallback;

  Customer? getCustomerAt(double x, double y) {
    for (final customer in _customers) {
      final distance = math.sqrt(math.pow(customer.x - x, 2) + math.pow(customer.y - y, 2));
      if (distance < 0.5) { // 0.5 unit radius for interaction
        return customer;
      }
    }
    return null;
  }

  List<Customer> getOrderingCustomers() {
    return _customers.where((c) => c.state == CustomerState.ordering).toList();
  }

  // Check if any ordering customer wants a specific merged dessert level
  bool isAnyCustomerWantingLevel(int level) {
    return _customers.any((customer) => 
      customer.state == CustomerState.ordering && 
      customer.orderType == OrderType.mergedDessert && 
      customer.orderLevel == level
    );
  }

  // Check if any ordering customer wants a specific crafted dessert
  bool isAnyCustomerWantingCraftedDessert(int craftedDessertId) {
    return _customers.any((customer) => 
      customer.state == CustomerState.ordering && 
      customer.orderType == OrderType.craftedDessert && 
      customer.orderCraftedDessertId == craftedDessertId
    );
  }

  void removeAllCustomers() {
    debugPrint('🔄 CustomerProvider: Removing all customers (${_customers.length} total)');
    _customers.clear();
    debugPrint('🔄 CustomerProvider: All customers removed - notifying listeners');
    notifyListeners();
  }
  
  // Force update of customer limits when seating capacity changes
  void updateSeatingCapacity() {
    debugPrint('🪑 CustomerProvider: Seating capacity updated - new max customers: $maxCustomers');
    notifyListeners();
  }

  // Table management methods - improved distribution
  PlacedFurniture? _findAvailableTable() {
    try {
      final seatingFurniture = getSeatingFurniture?.call() ?? <PlacedFurniture>[];
      final seatingTables = seatingFurniture.where((furniture) => 
        furniture.furniture.seatingCapacity > 0
      ).toList();
    
      if (seatingTables.isEmpty) return null;
      
      // Create a list of tables with their occupancy
      List<Map<String, dynamic>> tableOccupancy = seatingTables.map((table) {
        final customersAtTable = _customers.where((customer) => 
          customer.assignedTableId == table.id
        ).length;
        
        return {
          'table': table,
          'occupancy': customersAtTable,
          'capacity': table.furniture.seatingCapacity,
          'utilization': customersAtTable / table.furniture.seatingCapacity,
        };
      }).toList();
      
      // Filter tables that have available seats
      final availableTables = tableOccupancy.where((tableInfo) => 
        tableInfo['occupancy'] < tableInfo['capacity']
      ).toList();
      
      if (availableTables.isEmpty) return null;
      
      // Sort by utilization (prefer less crowded tables) and then by capacity (prefer larger tables)
      availableTables.sort((a, b) {
        // First priority: lower utilization (spread customers out)
        final utilizationComparison = (a['utilization'] as double).compareTo(b['utilization'] as double);
        if (utilizationComparison != 0) return utilizationComparison;
        
        // Second priority: larger capacity (better for groups)
        return -(a['capacity'] as int).compareTo(b['capacity'] as int);
      });
      
      return availableTables.first['table'] as PlacedFurniture;
    } catch (e) {
      debugPrint('Error finding available table: $e');
      return null; // No table available if error occurs
    }
  }
  
  bool _assignTableToCustomer(String customerId) {
    try {
      final customer = _customers.firstWhere(
        (c) => c.id == customerId,
        orElse: () => _customers.isNotEmpty ? _customers.first : Customer(
          id: customerId,
          type: CustomerType.bear,
          name: 'Fallback Customer',
          emoji: '🐻',
          x: 0,
          y: 0,
          targetX: 0,
          targetY: 0,
          state: CustomerState.ordering,
          patience: 100,
          preferredDesserts: [1],
          color: Colors.brown,
        ),
      );
      
      final availableTable = _findAvailableTable();
      if (availableTable != null && availableTable.furniture.seatingCapacity > 0) {
        // Calculate seating position around the table
        final customersAtTable = _customers.where((c) => 
          c.assignedTableId == availableTable.id
        ).length;
        
        final tablePos = _calculateSeatingPosition(availableTable, customersAtTable);
      
        // Update customer with table assignment
        final index = _customers.indexWhere((c) => c.id == customerId);
        if (index >= 0) {
          _customers[index] = customer.copyWith(
            assignedTableId: availableTable.id,
            targetX: tablePos['x']!,
            targetY: tablePos['y']!,
            state: CustomerState.eating,
            isSeated: true,
          );
          notifyListeners();
          return true;
        }
      }
      
      return false; // No available table
    } catch (e) {
      debugPrint('Error assigning table to customer: $e');
      return false; // No table assigned due to error
    }
  }
  
  Map<String, double> _calculateSeatingPosition(PlacedFurniture table, int seatIndex) {
    try {
      final tableX = table.x;
      final tableY = table.y;
      final tableWidth = table.furniture.width;
      final tableHeight = table.furniture.height;
      final capacity = table.furniture.seatingCapacity;
    
    // Calculate positions around the table perimeter
    if (capacity <= 2) {
      // Small table - sit on opposite sides
      if (seatIndex == 0) {
        return {'x': tableX + tableWidth * 0.25, 'y': tableY + tableHeight * 0.5};
      } else {
        return {'x': tableX + tableWidth * 0.75, 'y': tableY + tableHeight * 0.5};
      }
    } else if (capacity <= 4) {
      // 4-person table - sit on four sides
      switch (seatIndex) {
        case 0: return {'x': tableX + tableWidth * 0.5, 'y': tableY - 0.3}; // Top
        case 1: return {'x': tableX + tableWidth + 0.3, 'y': tableY + tableHeight * 0.5}; // Right
        case 2: return {'x': tableX + tableWidth * 0.5, 'y': tableY + tableHeight + 0.3}; // Bottom
        default: return {'x': tableX - 0.3, 'y': tableY + tableHeight * 0.5}; // Left
      }
    } else if (capacity <= 6) {
      // 6-person table - distributed around perimeter
      final angles = [0, 60, 120, 180, 240, 300];
      final angle = angles[seatIndex % 6] * (3.14159 / 180); // Convert to radians
      final radius = (tableWidth + tableHeight) * 0.4;
      final centerX = tableX + tableWidth * 0.5;
      final centerY = tableY + tableHeight * 0.5;
      
      return {
        'x': centerX + radius * cos(angle),
        'y': centerY + radius * sin(angle),
      };
    } else {
      // Large table - arranged in rows
      final seatsPerSide = (capacity / 2).ceil();
      final sideIndex = seatIndex % 2; // 0 = top/bottom, 1 = sides
      final positionInSide = seatIndex ~/ 2;
      
      if (sideIndex == 0) {
        // Top and bottom sides
        final isTop = positionInSide % 2 == 0;
        final seatPosition = (positionInSide ~/ 2) / (seatsPerSide - 1);
        return {
          'x': tableX + tableWidth * seatPosition,
          'y': isTop ? tableY - 0.4 : tableY + tableHeight + 0.4,
        };
      } else {
        // Left and right sides
        final isRight = positionInSide % 2 == 0;
        final seatPosition = (positionInSide ~/ 2) / (seatsPerSide - 1);
        return {
          'x': isRight ? tableX + tableWidth + 0.4 : tableX - 0.4,
          'y': tableY + tableHeight * seatPosition,
        };
      }
    }
    } catch (e) {
      debugPrint('Error calculating seating position: $e');
      // Fallback to default position near table center
      return {'x': table.x + 0.5, 'y': table.y + 0.5};
    }
  }
  
  // Check for customers that should be auto-fed from storage
  void _checkAutoFeed() {
    final now = DateTime.now();
    
    for (final customer in _customers.toList()) {
      if (customer.state == CustomerState.ordering) {
        final orderTime = _customerOrderTime[customer.id];
        if (orderTime != null) {
          final waitingTime = now.difference(orderTime).inSeconds;
          
          // Auto-feed after specified delay - ONLY for crafted desserts from storage
          if (waitingTime >= autoFeedDelaySeconds && customer.orderType == OrderType.craftedDessert) {
            bool canAutoFeed = false;
            
            // Check if storage has the required crafted dessert
            if (customer.orderCraftedDessertId != null) {
              canAutoFeed = hasStorageCraftedItemCallback?.call(customer.orderCraftedDessertId!) ?? false;
            }
            
            if (canAutoFeed) {
              final orderInfo = customer.orderType == OrderType.craftedDessert 
                ? 'crafted dessert ID ${customer.orderCraftedDessertId}' 
                : 'merged dessert level ${customer.orderLevel}';
              debugPrint('🤖 AUTO-FEED: Attempting to serve customer ${customer.id} with $orderInfo after ${waitingTime}s wait');
              // Auto-serve the customer from storage
              final success = serveCustomerFromStorage(customer.id);
              if (success) {
                // Remove from tracking since they've been served
                _customerOrderTime.remove(customer.id);
              } else {
              }
            }
          }
        }
      } else {
        // Remove from tracking if customer is no longer ordering
        _customerOrderTime.remove(customer.id);
      }
    }
  }
  
  // Helper math functions for positioning
  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
  
  void _releaseTableFromCustomer(String customerId) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index >= 0) {
      _customers[index] = _customers[index].copyWith(
        assignedTableId: null,
        isSeated: false,
      );
    }
  }

  @override
  void dispose() {
    // MEMORY CLEANUP: Cancel all timers
    _spawnTimer?.cancel();
    _updateTimer?.cancel();
    _autoFeedTimer?.cancel();
    
    // MEMORY CLEANUP: Clear all collections
    _customers.clear();
    _customerOrderTime.clear();
    
    // MEMORY CLEANUP: Null callbacks to prevent retention
    onCustomerServedCallback = null;
    onCustomerTimeoutCallback = null;
    getCurrentShopLevelCallback = null;
    getIsStoreOpenCallback = null;
    serveDessertCallback = null;
    serveCraftedDessertCallback = null;
    hasStorageCraftedItemCallback = null;
    getFurnitureAttraction = null;
    getSeatingCapacity = null;
    getSeatingFurniture = null;
    
    super.dispose();
  }
}