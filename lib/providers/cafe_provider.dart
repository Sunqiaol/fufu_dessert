import 'dart:async';
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
  
  void _initializeCafe() async {
    await loadCafeState();
    if (_placedFurniture.isEmpty) {
      _placeDefaultFurniture();
    }
    _rebuildGrid();
  }
  
  void _placeDefaultFurniture() {
    // Place default furniture - cash register, display case, and 2 four-person tables
    try {
      final cashRegister = Furniture.furnitureItems.firstWhere(
        (f) => f.type == FurnitureType.cashRegister,
        orElse: () => Furniture.furnitureItems.first,
      );
      final displayCase = Furniture.furnitureItems.firstWhere(
        (f) => f.type == FurnitureType.displayCase,
        orElse: () => Furniture.furnitureItems.first,
      );
      final table4Seat = Furniture.furnitureItems.firstWhere(
        (f) => f.id == 'table_4_seat',
        orElse: () => Furniture.furnitureItems.firstWhere(
          (f) => f.type == FurnitureType.table,
          orElse: () => Furniture.furnitureItems.first,
        ),
      );
      
      final defaultItems = [
        PlacedFurniture(
          id: 'default_register',
          furniture: cashRegister,
          x: 4.0, // Grid position 8
          y: 4.0, // Grid position 8
        ),
        PlacedFurniture(
          id: 'default_display',
          furniture: displayCase,
          x: 8.0, // Grid position 16
          y: 4.0, // Grid position 8
        ),
        // First 4-person table
        PlacedFurniture(
          id: 'default_table_1',
          furniture: table4Seat,
          x: 2.0, // Grid position 4
          y: 1.5, // Grid position 3
        ),
        // Second 4-person table
        PlacedFurniture(
          id: 'default_table_2',
          furniture: table4Seat,
          x: 6.0, // Grid position 12
          y: 1.5, // Grid position 3
        ),
      ];
      
      _placedFurniture = defaultItems;
      _rebuildGrid();
      notifyListeners();
    } catch (e) {
      debugPrint('Error placing default furniture: $e');
      // Fallback: create minimal furniture setup
      _placedFurniture = [];
      notifyListeners();
    }
  }
  
  // Rebuild the grid from furniture positions
  void _rebuildGrid() {
    // Clear grid
    _furnitureGrid = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => null),
    );
    
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
    print('Starting drag for furniture: $furnitureId'); // Debug
    _isDragging = true;
    selectFurniture(furnitureId);
    notifyListeners();
  }
  
  // Update drag preview
  void updateDragPreview(double screenX, double screenY) {
    if (!_isDragging || _selectedFurniture == null) return;
    
    print('Drag preview update: ($screenX, $screenY)'); // Debug
    
    // Convert screen position to grid coordinates
    final gridX = (screenX / cellSize).floor();
    final gridY = (screenY / cellSize).floor();
    
    final width = (_selectedFurniture!.furniture.width / 0.5).round();
    final height = (_selectedFurniture!.furniture.height / 0.5).round();
    
    print('Grid position: ($gridX, $gridY), Size: (${width}x$height)'); // Debug
    
    _previewX = gridX;
    _previewY = gridY;
    _previewWidth = width;
    _previewHeight = height;
    
    // Check if position is valid
    _previewValid = _isValidPosition(gridX, gridY, width, height, _selectedFurniture!.id);
    
    print('Preview valid: $_previewValid'); // Debug
    
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
  
  // Complete reset to initial state
  Future<void> resetToInitialState() async {
    try {
      // Clear all state
      _isInEditMode = false;
      _selectedFurniture = null;
      _isDragging = false;
      _clearPreview();
      
      // Clear furniture grid
      _furnitureGrid = List.generate(
        gridSize,
        (i) => List.generate(gridSize, (j) => null),
      );
      
      // Clear placed furniture list
      _placedFurniture.clear();
      
      // Place default furniture again
      _placeDefaultFurniture();
      
      // Rebuild grid with default furniture
      _rebuildGrid();
      
      // Save the reset state
      await saveCafeState();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting cafe state: $e');
      rethrow;
    }
  }

  // Debug: Print grid
  void printGrid() {
    print('=== FURNITURE GRID ===');
    for (int y = 0; y < gridSize; y++) {
      final row = _furnitureGrid[y].map((cell) => cell?.substring(0, 1) ?? '.').join('');
      print('$y: $row');
    }
    print('===================');
  }
}