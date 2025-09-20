import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/furniture.dart';
import 'package:fufu_dessert2/services/database_service.dart';

class CafeProvider with ChangeNotifier {
  // Simple grid system - 24x24 cells, each cell represents 0.5 world units (increased from 20x20)
  static const int gridSize = 24;
  static const double cellSize = 30.0; // Each cell is 30px in UI (reduced from 40)
  
  // 2D array to store furniture IDs at each position
  List<List<String?>> _furnitureGrid = List.generate(
    gridSize,
    (i) => List.generate(gridSize, (j) => null),
  );
  
  // List of all placed furniture
  List<PlacedFurniture> _placedFurniture = [];
  
  // Edit mode state
  bool _isInEditMode = false;
  PlacedFurniture? _selectedFurniture;
  bool _isDragging = false;
  
  // Preview state for drag
  int? _previewX;
  int? _previewY;
  int? _previewWidth;
  int? _previewHeight;
  bool _previewValid = false;
  
  // Getters
  List<PlacedFurniture> get placedFurniture => _placedFurniture;
  bool get isInEditMode => _isInEditMode;
  PlacedFurniture? get selectedFurniture => _selectedFurniture;
  bool get isDragging => _isDragging;
  int? get previewX => _previewX;
  int? get previewY => _previewY;
  int? get previewWidth => _previewWidth;
  int? get previewHeight => _previewHeight;
  bool get previewValid => _previewValid;
  
  // Callback for when seating capacity changes
  VoidCallback? onSeatingCapacityChanged;
  
  // MEMORY OPTIMIZATION: Debounce capacity change notifications
  Timer? _capacityChangeTimer;
  
  // Calculate total attraction bonus from all placed furniture
  int get totalAttractionBonus {
    try {
      return _placedFurniture.fold(0, (sum, furniture) => sum + furniture.furniture.attractionBonus);
    } catch (e) {
      debugPrint('Error calculating attraction bonus: $e');
      return 0;
    }
  }
  
  // Calculate total seating capacity from all placed seating furniture
  int get totalSeatingCapacity {
    try {
      return _placedFurniture.fold(0, (sum, furniture) => sum + furniture.furniture.seatingCapacity);
    } catch (e) {
      debugPrint('Error calculating seating capacity: $e');
      return 8; // Default capacity for 2 four-person tables
    }
  }
  
  // Get number of tables/seating furniture placed
  int get tableCount {
    try {
      return _placedFurniture.where((furniture) => 
        furniture.furniture.type == FurnitureType.table || 
        furniture.furniture.type == FurnitureType.seating
      ).length;
    } catch (e) {
      debugPrint('Error counting tables: $e');
      return 2; // Default to 2 tables
    }
  }
  
  // Calculate maximum tables allowed based on shop level (every 3 levels = +1 table)
  int getMaxTablesForLevel(int shopLevel) {
    return 2 + ((shopLevel - 1) ~/ 3); // Start with 2, +1 every 3 levels
  }
  
  CafeProvider() {
    _initializeCafe();
  }
  
  // MEMORY OPTIMIZATION: Debounced capacity change notification
  void _notifySeatingCapacityChanged() {
    _capacityChangeTimer?.cancel();
    _capacityChangeTimer = Timer(const Duration(milliseconds: 500), () {
      _notifySeatingCapacityChanged();
    });
  }
  
  void _initializeCafe() async {
    await loadCafeState();
    if (_placedFurniture.isEmpty) {
      _placeDefaultFurniture();
    }

    // TEMPORARY FIX: Reset furniture positions if they got corrupted
    // Remove this after furniture positions are fixed
    // resetFurniturePositions(); // Fixed - furniture positions restored

    // IMPORTANT: Always ensure door wall exists AFTER loading saved state
    // This must come after loadCafeState() to prevent saved data from overwriting the wall
    _ensureDoorWallExists();

    // Align all furniture to grid positions for proper placement
    // _alignFurnitureToGrid(); // Temporarily disabled to fix coordinate issues

    _rebuildGrid(); // Rebuild grid after ensuring wall exists
    saveCafeState(); // Save the state with the wall included
  }
  
  void _placeDefaultFurniture() {
    // Place default furniture - cash register, display case, and 2 two-person tables (4 total seats)
    // Use grid-aligned positions for proper placement within cafe boundary
    try {
      final cashRegister = Furniture.furnitureItems.firstWhere(
        (f) => f.type == FurnitureType.cashRegister,
        orElse: () => Furniture.furnitureItems.first,
      );
      final displayCase = Furniture.furnitureItems.firstWhere(
        (f) => f.type == FurnitureType.displayCase,
        orElse: () => Furniture.furnitureItems.first,
      );
      final table2Seat = Furniture.furnitureItems.firstWhere(
        (f) => f.id == 'table_2_seat',
        orElse: () => Furniture.furnitureItems.firstWhere(
          (f) => f.type == FurnitureType.table && f.seatingCapacity == 2,
          orElse: () => Furniture.furnitureItems.firstWhere(
            (f) => f.type == FurnitureType.table,
            orElse: () => Furniture.furnitureItems.first,
          ),
        ),
      );
      final doorWall = Furniture.furnitureItems.firstWhere(
        (f) => f.id == 'door_wall',
        orElse: () => Furniture.furnitureItems.first,
      );
      final plant = Furniture.furnitureItems.firstWhere(
        (f) => f.id == 'plant_1',
        orElse: () => Furniture.furnitureItems.firstWhere(
          (f) => f.type == FurnitureType.plant,
          orElse: () => Furniture.furnitureItems.first,
        ),
      );
      final menu = Furniture.furnitureItems.firstWhere(
        (f) => f.id == 'menu_board',
        orElse: () => Furniture.furnitureItems.firstWhere(
          (f) => f.name.toLowerCase().contains('menu'),
          orElse: () => Furniture.furnitureItems.first,
        ),
      );

      final defaultItems = [
        // Door wall at edge of grid
        PlacedFurniture(
          id: 'default_door_wall',
          furniture: doorWall,
          x: 5.0, // Left edge of visible grid
          y: 5.0, // Top edge of visible grid
        ),
        PlacedFurniture(
          id: 'default_register',
          furniture: cashRegister,
          x: 8.0, // Within grid range 5-17
          y: 7.0, // Within grid range 5-15
        ),
        PlacedFurniture(
          id: 'default_display',
          furniture: displayCase,
          x: 12.0, // Within grid range 5-17
          y: 7.0, // Within grid range 5-15
        ),
        // First 2-person table
        PlacedFurniture(
          id: 'default_table_1',
          furniture: table2Seat,
          x: 7.0, // Within grid range 5-17
          y: 10.0, // Within grid range 5-15
        ),
        // Second 2-person table
        PlacedFurniture(
          id: 'default_table_2',
          furniture: table2Seat,
          x: 11.0, // Within grid range 5-17
          y: 10.0, // Within grid range 5-15
        ),
        // Plant decoration
        PlacedFurniture(
          id: 'default_plant',
          furniture: plant,
          x: 6.0, // Within grid range 5-17
          y: 12.0, // Within grid range 5-15
        ),
        // Menu board
        PlacedFurniture(
          id: 'default_menu',
          furniture: menu,
          x: 14.0, // Within grid range 5-17
          y: 9.0, // Within grid range 5-15
        ),
      ];

      _placedFurniture = defaultItems;
      _rebuildGrid();
      notifyListeners();
      // Force customer provider to update max customers when default furniture is placed - IMMEDIATE
      onSeatingCapacityChanged?.call();
    } catch (e) {
      debugPrint('Error placing default furniture: $e');
      // Fallback: create minimal furniture setup
      _placedFurniture = [];
      notifyListeners();
      onSeatingCapacityChanged?.call();
    }
  }
  
  // Ensure door wall is present - call this after loading saved state
  void _ensureDoorWallExists() {
    // Always remove and re-add door wall to ensure it's always visible with correct rotation
    _placedFurniture.removeWhere((furniture) => furniture.id == 'default_door_wall');
    
    // Always add the door wall
    {
      try {
        final doorWall = Furniture.furnitureItems.firstWhere(
          (f) => f.id == 'door_wall',
          orElse: () => Furniture.furnitureItems.first,
        );
        
        final doorWallFurniture = PlacedFurniture(
          id: 'default_door_wall',
          furniture: doorWall,
          x: 0.0, // Left edge
          y: 0.0, // Top edge
          rotation: 0.0, // No rotation - keep as default front wall
        );
        
        _placedFurniture.add(doorWallFurniture);
        notifyListeners();
        // Force customer provider to update after adding door wall
        _notifySeatingCapacityChanged();
        
        print('✅ Added door wall as default front wall (no rotation) - triggering sync');
      } catch (e) {
        print('❌ Error adding door wall: $e');
      }
    }
  }

  // Reset furniture to default positions (call this to fix corrupted coordinates)
  void resetFurniturePositions() {
    _placedFurniture.clear();
    _placeDefaultFurniture();
    saveCafeState();
    notifyListeners();
  }

  // Align all furniture to grid positions to ensure proper placement
  void _alignFurnitureToGrid() {
    List<PlacedFurniture> alignedFurniture = [];

    for (var furniture in _placedFurniture) {
      // Convert world coordinates to grid coordinates
      int gridX = (furniture.x - 5).round().clamp(0, 12);
      int gridY = (furniture.y - 5).round().clamp(0, 10);

      // Check if this position is within a reasonable cafe floor area
      // For now, we use a simple rectangular area that should be safe
      if (gridX >= 1 && gridX <= 10 && gridY >= 1 && gridY <= 8) {
        // Position is within safe area, align to grid
        final alignedX = (gridX + 5).toDouble();
        final alignedY = (gridY + 5).toDouble();

        alignedFurniture.add(PlacedFurniture(
          id: furniture.id,
          furniture: furniture.furniture,
          x: alignedX,
          y: alignedY,
          rotation: furniture.rotation,
        ));
      } else {
        // Position is outside safe area, find a safe grid position
        Point<int>? safePos = _findSafeGridPosition(gridX, gridY);
        if (safePos != null) {
          final safeX = (safePos.x + 5).toDouble();
          final safeY = (safePos.y + 5).toDouble();

          alignedFurniture.add(PlacedFurniture(
            id: furniture.id,
            furniture: furniture.furniture,
            x: safeX,
            y: safeY,
            rotation: furniture.rotation,
          ));
        }
        // If no safe position found, exclude this furniture
      }
    }

    _placedFurniture = alignedFurniture;
  }

  // Find a safe grid position within the cafe floor area
  Point<int>? _findSafeGridPosition(int startX, int startY) {
    // Define safe area within the cafe floor
    const safeArea = [
      Point(2, 2), Point(3, 2), Point(4, 2), Point(5, 2), Point(6, 2), Point(7, 2), Point(8, 2),
      Point(2, 3), Point(3, 3), Point(4, 3), Point(5, 3), Point(6, 3), Point(7, 3), Point(8, 3),
      Point(2, 4), Point(3, 4), Point(4, 4), Point(5, 4), Point(6, 4), Point(7, 4), Point(8, 4),
      Point(2, 5), Point(3, 5), Point(4, 5), Point(5, 5), Point(6, 5), Point(7, 5), Point(8, 5),
      Point(2, 6), Point(3, 6), Point(4, 6), Point(5, 6), Point(6, 6), Point(7, 6), Point(8, 6),
      Point(2, 7), Point(3, 7), Point(4, 7), Point(5, 7), Point(6, 7), Point(7, 7), Point(8, 7),
    ];

    // Find the closest safe position
    Point<int>? closest;
    double closestDistance = double.infinity;

    for (var pos in safeArea) {
      final distance = sqrt(pow(pos.x - startX, 2) + pow(pos.y - startY, 2));
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = pos;
      }
    }

    return closest;
  }

  // Rebuild the grid from furniture positions
  void _rebuildGrid() {
    // MEMORY OPTIMIZATION: Only clear and rebuild if necessary
    if (_furnitureGrid.length != gridSize || 
        (_furnitureGrid.isNotEmpty && _furnitureGrid[0].length != gridSize)) {
      _furnitureGrid = List.generate(
        gridSize,
        (i) => List.generate(gridSize, (j) => null),
      );
    } else {
      // Clear existing grid efficiently
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          _furnitureGrid[i][j] = null;
        }
      }
    }
    
    // Place each furniture in grid
    for (final furniture in _placedFurniture) {
      final gridX = (furniture.x / 0.5).round();
      final gridY = (furniture.y / 0.5).round();
      final width = (furniture.furniture.width / 0.5).round();
      final height = (furniture.furniture.height / 0.5).round();
      
      // Fill grid cells
      for (int y = gridY; y < gridY + height && y < gridSize; y++) {
        for (int x = gridX; x < gridX + width && x < gridSize; x++) {
          if (x >= 0 && y >= 0) {
            _furnitureGrid[y][x] = furniture.id;
          }
        }
      }
    }
  }
  
  // Toggle edit mode
  void toggleEditMode() {
    _isInEditMode = !_isInEditMode;
    if (!_isInEditMode) {
      _selectedFurniture = null;
      _clearPreview();
    }
    notifyListeners();
  }
  
  // Select furniture
  void selectFurniture(String? furnitureId) {
    if (furnitureId != null) {
      _selectedFurniture = _placedFurniture.firstWhere(
        (f) => f.id == furnitureId,
        orElse: () => _placedFurniture.first,
      );
    } else {
      _selectedFurniture = null;
    }
    notifyListeners();
  }
  
  // Start dragging
  void startDragging(String furnitureId) {
    _isDragging = true;
    selectFurniture(furnitureId);
    notifyListeners();
  }
  
  // Update drag preview
  void updateDragPreview(double screenX, double screenY) {
    if (!_isDragging || _selectedFurniture == null) return;
    
    
    // Convert screen position to grid coordinates
    final gridX = (screenX / cellSize).floor();
    final gridY = (screenY / cellSize).floor();
    
    final width = (_selectedFurniture!.furniture.width / 0.5).round();
    final height = (_selectedFurniture!.furniture.height / 0.5).round();
    
    
    _previewX = gridX;
    _previewY = gridY;
    _previewWidth = width;
    _previewHeight = height;
    
    // Check if position is valid
    _previewValid = _isValidPosition(gridX, gridY, width, height, _selectedFurniture!.id);
    
    
    notifyListeners();
  }
  
  // Check if position is valid
  bool _isValidPosition(int gridX, int gridY, int width, int height, String excludeId) {
    // Check bounds
    if (gridX < 0 || gridY < 0 || 
        gridX + width > gridSize || 
        gridY + height > gridSize) {
      return false;
    }
    
    // Check for collisions (excluding current furniture)
    for (int y = gridY; y < gridY + height; y++) {
      for (int x = gridX; x < gridX + width; x++) {
        final occupant = _furnitureGrid[y][x];
        if (occupant != null && occupant != excludeId) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  // Finish dragging and place furniture
  void finishDragging() {
    if (!_isDragging || _selectedFurniture == null || !_previewValid) {
      _isDragging = false;
      _clearPreview();
      notifyListeners();
      return;
    }
    
    // Convert grid position back to world coordinates
    final worldX = _previewX! * 0.5;
    final worldY = _previewY! * 0.5;
    
    // Update furniture position
    final index = _placedFurniture.indexWhere((f) => f.id == _selectedFurniture!.id);
    if (index >= 0) {
      _placedFurniture[index] = _selectedFurniture!.copyWith(
        x: worldX,
        y: worldY,
      );
      
      _rebuildGrid();
      saveCafeState();
      // Force customer provider to update max customers when furniture moves
      _notifySeatingCapacityChanged();
    }
    
    _isDragging = false;
    _clearPreview();
    notifyListeners();
  }
  
  // Clear preview
  void _clearPreview() {
    _previewX = null;
    _previewY = null;
    _previewWidth = null;
    _previewHeight = null;
    _previewValid = false;
  }
  
  // Cancel dragging
  void cancelDragging() {
    _isDragging = false;
    _clearPreview();
    notifyListeners();
  }
  
  // Save and load state
  Future<void> saveCafeState() async {
    try {
      final db = DatabaseService();
      await db.saveCafeState({
        'placedFurniture': _placedFurniture.map((f) => {
          'id': f.id,
          'furnitureId': f.furniture.id,
          'x': f.x,
          'y': f.y,
          'rotation': f.rotation,
        }).toList(),
      });
    } catch (e) {
      debugPrint('Error saving cafe state: $e');
    }
  }
  
  Future<void> loadCafeState() async {
    try {
      final db = DatabaseService();
      final cafeState = await db.loadCafeState();
      
      if (cafeState != null) {
        final furnitureData = cafeState['placedFurniture'] as List<dynamic>?;
        if (furnitureData != null) {
          _placedFurniture = furnitureData.map((data) {
            final furnitureId = data['furnitureId'] as String;
            final furniture = Furniture.furnitureItems.firstWhere(
              (f) => f.id == furnitureId,
              orElse: () => Furniture.furnitureItems.isNotEmpty 
                ? Furniture.furnitureItems.first 
                : const Furniture(
                    id: 'fallback',
                    type: FurnitureType.table,
                    name: 'Fallback Table',
                    emoji: '🪑',
                    level: 1,
                    price: 0,
                    width: 1.0,
                    height: 1.0,
                    color: Colors.brown,
                    attractionBonus: 0,
                    canUpgrade: false,
                    seatingCapacity: 4,
                  ),
            );
            
            return PlacedFurniture(
              id: data['id'] as String,
              furniture: furniture,
              x: (data['x'] as num).toDouble(),
              y: (data['y'] as num).toDouble(),
              rotation: (data['rotation'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();
        }
      }
      
      notifyListeners();
      // Force customer provider to update max customers when cafe state loads - IMMEDIATE
      onSeatingCapacityChanged?.call();
    } catch (e) {
      debugPrint('Error loading cafe state: $e');
    }
  }
  
  // Check if position is valid for placing furniture
  bool isValidPositionPublic(int gridX, int gridY, int width, int height, String excludeId) {
    return _isValidPosition(gridX, gridY, width, height, excludeId);
  }
  
  // Add new furniture to the cafe
  void addNewFurniture(PlacedFurniture furniture) {
    _placedFurniture.add(furniture);
    _rebuildGrid();
    saveCafeState();
    notifyListeners();
    // Force customer provider to update max customers when furniture changes
    _notifySeatingCapacityChanged();
  }
  
  // Sell furniture and return 50% of original price
  int sellFurniture(String furnitureId) {
    final index = _placedFurniture.indexWhere((f) => f.id == furnitureId);
    if (index >= 0) {
      final furniture = _placedFurniture[index];
      final sellPrice = (furniture.furniture.price * 0.5).round(); // 50% return
      
      _placedFurniture.removeAt(index);
      _selectedFurniture = null; // Clear selection since furniture is sold
      _rebuildGrid();
      saveCafeState();
      notifyListeners();
      // Force customer provider to update max customers when furniture changes
      _notifySeatingCapacityChanged();
      
      return sellPrice;
    }
    return 0;
  }
  
  // Upgrade existing furniture
  bool upgradeFurniture(String furnitureId, Furniture upgradedFurniture) {
    final index = _placedFurniture.indexWhere((f) => f.id == furnitureId);
    if (index >= 0) {
      final oldFurniture = _placedFurniture[index];
      _placedFurniture[index] = oldFurniture.copyWith(furniture: upgradedFurniture);
      _rebuildGrid();
      saveCafeState();
      notifyListeners();
      // Force customer provider to update max customers when furniture changes
      _notifySeatingCapacityChanged();
      return true;
    }
    return false;
  }
  
  // Check if furniture can be upgraded
  bool canUpgradeFurniture(String furnitureId) {
    final furniture = _placedFurniture.firstWhere(
      (f) => f.id == furnitureId,
      orElse: () => _placedFurniture.first,
    );
    return furniture.furniture.canUpgrade && furniture.furniture.upgradeId != null;
  }
  
  // Get upgrade furniture for a placed furniture
  Furniture? getUpgradeFurniture(String furnitureId) {
    final furniture = _placedFurniture.firstWhere(
      (f) => f.id == furnitureId,
      orElse: () => _placedFurniture.first,
    );
    if (furniture.furniture.upgradeId != null) {
      return Furniture.getById(furniture.furniture.upgradeId!);
    }
    return null;
  }
  
  // Replace all placed furniture (used for cafe synchronization)
  void replaceAllFurniture(List<PlacedFurniture> newFurniture) {
    _placedFurniture = newFurniture;
    _rebuildGrid();
    saveCafeState();
    notifyListeners();
    _notifySeatingCapacityChanged();
  }

  // Complete reset to initial state
  Future<void> resetToInitialState() async {
    try {
      debugPrint('🔄 CafeProvider: Starting reset to initial state...');
      
      // Clear all state
      _isInEditMode = false;
      _selectedFurniture = null;
      _isDragging = false;
      _clearPreview();
      debugPrint('🔄 CafeProvider: Cleared edit mode state');
      
      // Clear furniture grid
      _furnitureGrid = List.generate(
        gridSize,
        (i) => List.generate(gridSize, (j) => null),
      );
      debugPrint('🔄 CafeProvider: Cleared furniture grid (${gridSize}x$gridSize)');
      
      // Clear placed furniture list
      _placedFurniture.clear();
      debugPrint('🔄 CafeProvider: Cleared placed furniture list');
      
      // Place default furniture again
      _placeDefaultFurniture();
      debugPrint('🔄 CafeProvider: Placed default furniture (${_placedFurniture.length} items)');
      
      // Rebuild grid with default furniture
      _rebuildGrid();
      debugPrint('🔄 CafeProvider: Rebuilt furniture grid');
      
      // Save the reset state
      await saveCafeState();
      debugPrint('🔄 CafeProvider: Saved reset state to database');
      
      notifyListeners();
      // Force customer provider to update max customers after reset
      _notifySeatingCapacityChanged();
      debugPrint('🔄 CafeProvider: Reset complete - notified listeners and updated seating capacity');
    } catch (e) {
      debugPrint('❌ CafeProvider: Error resetting cafe state: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    // MEMORY CLEANUP: Cancel debounce timer
    _capacityChangeTimer?.cancel();
    
    // MEMORY CLEANUP: Clear collections
    _placedFurniture.clear();
    for (int i = 0; i < _furnitureGrid.length; i++) {
      _furnitureGrid[i].clear();
    }
    _furnitureGrid.clear();
    
    // MEMORY CLEANUP: Null callback
    onSeatingCapacityChanged = null;
    
    super.dispose();
  }

}