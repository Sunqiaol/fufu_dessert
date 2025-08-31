import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/furniture.dart';
import 'package:fufu_dessert2/services/audio_service.dart';

class CustomerProvider with ChangeNotifier {
  // Base values - will be scaled by shop level
  static const int baseMaxCustomers = 4;
  static const int baseCustomerSpawnInterval = 10; // seconds
  
  List<Customer> _customers = [];
  Timer? _spawnTimer;
  Timer? _updateTimer;
  final math.Random _random = math.Random();
  int _shopLevel = 1; // Track current shop level
  
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
      const Duration(milliseconds: 16), // ~60 FPS
      (_) => _updateCustomers(),
    );
  }

  void _trySpawnCustomer() {
    if (_customers.length < maxCustomers) {
      _spawnCustomer();
    }
  }

  void _spawnCustomer() {
    final customer = Customer.generateRandomCustomer();
    
    // Set spawn position (entrance)
    customer.x = 0.0;
    customer.y = 5.0;
    customer.targetX = 2.0 + _random.nextDouble() * 6.0;
    customer.targetY = 3.0 + _random.nextDouble() * 4.0;
    customer.state = CustomerState.entering;
    
    _customers.add(customer);
    
    // Play customer enter sound effect
    AudioService().playSoundEffect(SoundEffect.customerEnter);
    
    notifyListeners();
    
    // Schedule state transitions
    _scheduleCustomerBehavior(customer);
  }

  void _scheduleCustomerBehavior(Customer customer) {
    // Enter -> Browse (2-3 seconds)
    Timer(Duration(seconds: 2 + _random.nextInt(2)), () {
      if (_customers.contains(customer) && customer.state == CustomerState.entering) {
        customer.state = CustomerState.browsing;
        _moveCustomerToBrowse(customer);
        notifyListeners();
      }
    });
    
    // Browse -> Order (3-5 seconds)
    Timer(Duration(seconds: 5 + _random.nextInt(3)), () {
      if (_customers.contains(customer) && customer.state == CustomerState.browsing) {
        customer.state = CustomerState.ordering;
        _moveCustomerToOrder(customer);
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
    // Move to cash register area
    customer.setTarget(2.0, 2.5);
    
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
    
    // Play serve sound effect
    AudioService().playSoundEffect(SoundEffect.serve);
    
    // Try to assign a table to the customer
    final hasTable = _assignTableToCustomer(customerId);
    
    if (hasTable) {
      // Customer successfully got a table - they will eat
      // Schedule leaving after eating
      Timer(Duration(seconds: 5 + _random.nextInt(6)), () {
        if (_customers.contains(customer)) {
          _releaseTableFromCustomer(customerId);
          customer.state = CustomerState.leaving;
          _moveCustomerToExit(customer);
          
          Timer(const Duration(seconds: 2), () {
            _customers.remove(customer);
            notifyListeners();
          });
        }
      });
    } else {
      // No table available but they got their dessert - they leave happy but quickly
      customer.state = CustomerState.leaving;
      _moveCustomerToExit(customer);
      
      Timer(const Duration(seconds: 2), () {
        _customers.remove(customer);
        // Play customer leave sound effect
        AudioService().playSoundEffect(SoundEffect.customerLeave);
        notifyListeners();
      });
    }
    
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
    
    // Calculate payment
    final dessert = Dessert.getDessertByLevel(dessertLevel);
    final basePayment = dessert.baseValue;
    final payment = (basePayment * satisfaction).round();
    
    // Notify game provider about payment
    if (onCustomerServedCallback != null) {
      onCustomerServedCallback!(payment, satisfaction > 0.7);
    }
    
    // Play serve sound effect
    AudioService().playSoundEffect(SoundEffect.serve);
    
    // Try to assign a table to the customer
    final hasTable = _assignTableToCustomer(customerId);
    
    if (hasTable) {
      // Customer successfully got a table - they will eat
      customer.state = CustomerState.eating;
      
      // Schedule leaving after eating
      Timer(Duration(seconds: 5 + _random.nextInt(6)), () {
        if (_customers.contains(customer)) {
          _releaseTableFromCustomer(customerId);
          customer.state = CustomerState.leaving;
          _moveCustomerToExit(customer);
          
          Timer(const Duration(seconds: 2), () {
            _customers.remove(customer);
            notifyListeners();
          });
        }
      });
    } else {
      // No table available but they got their dessert - they leave happy but quickly
      customer.state = CustomerState.leaving;
      _moveCustomerToExit(customer);
      
      Timer(const Duration(seconds: 2), () {
        _customers.remove(customer);
        // Play customer leave sound effect
        AudioService().playSoundEffect(SoundEffect.customerLeave);
        notifyListeners();
      });
    }
    
    notifyListeners();
    return true;
  }

  double _calculateSatisfaction(int expectedLevel, int actualLevel) {
    if (actualLevel >= expectedLevel) {
      return 1.0; // Perfect satisfaction
    } else if (actualLevel >= expectedLevel - 1) {
      return 0.8; // Good satisfaction
    } else if (actualLevel >= expectedLevel - 2) {
      return 0.5; // Okay satisfaction
    } else {
      return 0.2; // Poor satisfaction
    }
  }

  int _calculatePayment(int dessertLevel, double satisfaction) {
    final basePay = Dessert.getDessertByLevel(dessertLevel).baseValue;
    return (basePay * satisfaction * (0.8 + _random.nextDouble() * 0.4)).round();
  }


  void _moveCustomerToExit(Customer customer) {
    customer.setTarget(0.0, 5.0);
  }

  void _updateCustomers() {
    final deltaTime = 1 / 60.0; // Assuming 60 FPS
    
    for (final customer in _customers.toList()) {
      // Update position
      customer.updatePosition(deltaTime);
      
      // Decrease patience
      if (customer.state == CustomerState.ordering || customer.state == CustomerState.waiting) {
        if (_random.nextDouble() < 0.01) { // 1% chance per frame
          customer.decreasePatience();
          
          if (customer.hasLeftCafe()) {
            customer.state = CustomerState.leaving;
            _moveCustomerToExit(customer);
            
            Timer(const Duration(seconds: 2), () {
              _customers.remove(customer);
              notifyListeners();
            });
          }
        }
      }
    }
    
    notifyListeners();
  }

  void _onCustomerServed(int payment, bool wasHappy) {
    // This would normally call back to GameProvider
    // For now, we'll implement this as a callback system
    onCustomerServedCallback?.call(payment, wasHappy);
  }

  // Callback for when customer is served (to be set by GameProvider)
  Function(int payment, bool wasHappy)? onCustomerServedCallback;
  
  // Callback to serve merged dessert from storage (to be set by GameProvider)
  bool Function(int dessertLevel)? serveDessertCallback;
  
  // Callback to serve crafted dessert from storage (to be set by GameProvider)
  bool Function(int dessertId)? serveCraftedDessertCallback;

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

  void removeAllCustomers() {
    _customers.clear();
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
    _spawnTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}