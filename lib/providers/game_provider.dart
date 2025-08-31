import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/storage.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/services/database_service.dart';
import 'package:fufu_dessert2/services/audio_service.dart';

class GameProvider with ChangeNotifier {
  static const int gridWidth = 7;
  static const int gridHeight = 10;
  
  List<List<GridDessert?>> _grid = List.generate(
    gridHeight,
    (_) => List.generate(gridWidth, (_) => null),
  );
  
  int _coins = 100;
  int _score = 0;
  int _shopLevel = 1;
  int _nextDessertId = 1;
  final Random _random = Random();
  Timer? _autoSaveTimer;
  
  // Storage system for desserts
  late Storage _storage;
  
  void _initializeStorage() {
    try {
      _storage = Storage();
    } catch (e) {
      debugPrint('Error initializing storage: $e');
      _storage = Storage(); // Fallback
    }
  }
  
  // Callback for shop level changes
  Function(int)? onShopLevelChanged;
  
  // Selection system for manual merging
  List<Point<int>> _selectedCells = [];
  int? _selectedLevel;
  
  // Sell mode system
  bool _isSellMode = false;
  List<Point<int>> _selectedForSale = [];
  
  // Debouncing for saves to reduce resource usage
  Timer? _saveTimer;

  List<List<GridDessert?>> get grid => _grid;
  int get coins => _coins;
  int get score => _score;
  int get shopLevel => _shopLevel;
  Storage get storage => _storage;
  bool get isSellMode => _isSellMode;
  List<Point<int>> get selectedForSale => _selectedForSale;
  List<Point<int>> get selectedCells => _selectedCells;
  int? get selectedLevel => _selectedLevel;

  GameProvider() {
    _initializeStorage();
    _initializeGame();
    _startAutoSave();
  }

  void _initializeGame() async {
    await loadGameState();
    if (_isGridEmpty()) {
      _fillRandomSpaces(7); // Start with ingredients appropriate for 5x7 grid
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      saveGameState();
    });
  }

  bool _isGridEmpty() {
    return _grid.every((row) => row.every((cell) => cell == null));
  }

  void _fillRandomSpaces(int count) {
    final emptySpaces = <Point<int>>[];
    
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (_grid[y][x] == null) {
          emptySpaces.add(Point(x, y));
        }
      }
    }
    
    emptySpaces.shuffle(_random);
    final spacesToFill = min(count, emptySpaces.length);
    
    for (int i = 0; i < spacesToFill; i++) {
      final point = emptySpaces[i];
      final dessert = Dessert.getDessertByLevel(_generateWeightedRandomLevel());
      
      _grid[point.y][point.x] = GridDessert(
        id: _nextDessertId++,
        dessert: dessert,
        gridX: point.x,
        gridY: point.y,
      );
    }
    
    notifyListeners();
  }

  /// Generate random dessert level with balanced probabilities
  /// Heavily weighted toward low levels for proper game progression
  int _generateWeightedRandomLevel() {
    final roll = _random.nextInt(1000); // 0-999 for more precise control
    
    // Ultra rare high levels (0.6% total)
    if (roll < 1) return 10;      // 0.1% chance (1/1000)
    if (roll < 3) return 9;       // 0.2% chance (2/1000)
    if (roll < 6) return 8;       // 0.3% chance (3/1000)
    
    // Rare mid-high levels (2.9% total) 
    if (roll < 15) return 7;      // 0.9% chance (9/1000)
    if (roll < 35) return 6;      // 2.0% chance (20/1000)
    
    // Uncommon mid levels (7% total)
    if (roll < 70) return 5;      // 3.5% chance (35/1000)
    if (roll < 105) return 4;     // 3.5% chance (35/1000)
    
    // Common low levels (89.5% total) - main gameplay
    if (roll < 405) return 3;     // 30% chance (300/1000)
    if (roll < 705) return 2;     // 30% chance (300/1000)  
    return 1;                     // 29.5% chance (295/1000)
  }

  void generateRandomDessert() {
    _fillRandomSpaces(1);
  }


  bool isSelected(int x, int y) {
    return _selectedCells.contains(Point(x, y));
  }

  bool canSelectMore() {
    return _selectedCells.length < 3;
  }

  bool canMerge() {
    return _selectedCells.length == 3;
  }

  void selectCell(int x, int y) {
    // Handle sell mode selection
    if (_isSellMode) {
      selectCellForSale(x, y);
      return;
    }
    
    final point = Point(x, y);
    final dessert = _grid[y][x];
    
    if (dessert == null) {
      // Empty cell - generate random dessert at random locations
      _fillRandomSpaces(1);
      
      // Play sound effect
      AudioService().playSoundEffect(SoundEffect.merge);
      
      return;
    }
    
    // Manual merge selection for filled cells
    // If this cell is already selected, deselect it
    if (_selectedCells.contains(point)) {
      _selectedCells.remove(point);
      if (_selectedCells.isEmpty) {
        _selectedLevel = null;
      }
      notifyListeners();
      return;
    }
    
    // If no level is selected yet, set it
    if (_selectedLevel == null) {
      _selectedLevel = dessert.dessert.level;
      _selectedCells.add(point);
      notifyListeners();
      return;
    }
    
    // If this dessert matches the selected level and we have room
    if (dessert.dessert.level == _selectedLevel && _selectedCells.length < 3) {
      _selectedCells.add(point);
      
      // AUTO-MERGE when we reach 3 selected!
      if (_selectedCells.length == 3) {
        // Small delay for visual feedback, then auto-merge
        Future.delayed(const Duration(milliseconds: 300), () {
          attemptMerge();
        });
      }
      
      notifyListeners();
      return;
    }
    
    // If clicking on a different dessert type, reset selection to new type
    if (dessert.dessert.level != _selectedLevel) {
      clearSelection();
      _selectedLevel = dessert.dessert.level;
      _selectedCells.add(point);
      notifyListeners();
      return;
    }
  }

  void clearSelection() {
    _selectedCells.clear();
    _selectedLevel = null;
    notifyListeners();
  }

  bool attemptMerge() {
    if (_selectedCells.length != 3 || _selectedLevel == null) {
      return false;
    }
    
    // Verify all selected cells still have the right dessert level
    for (final point in _selectedCells) {
      final dessert = _grid[point.y][point.x];
      if (dessert == null || dessert.dessert.level != _selectedLevel) {
        clearSelection();
        return false;
      }
    }
    
    // Remove the 3 selected desserts
    for (final point in _selectedCells) {
      _grid[point.y][point.x] = null;
    }
    
    // Create upgraded dessert(s) with bonus probability
    final firstPoint = _selectedCells[0];
    final nextLevel = min(_selectedLevel! + 1, 10);
    final newDessert = Dessert.getDessertByLevel(nextLevel);
    
    // Determine number of desserts to create based on probability
    int dessertsToCreate = 1; // Default: 1 dessert
    final roll = _random.nextDouble();
    
    if (roll < 0.1) { // 1/10 chance (10%) for 3 desserts
      dessertsToCreate = 3;
    } else if (roll < 1.0/3.0) { // 1/3 chance (33.3%) for 2 desserts
      dessertsToCreate = 2;
    }
    
    // Place the first dessert at the merge location
    _grid[firstPoint.y][firstPoint.x] = GridDessert(
      id: _nextDessertId++,
      dessert: newDessert,
      gridX: firstPoint.x,
      gridY: firstPoint.y,
    );
    
    // Place additional desserts in empty spaces if bonus triggered
    if (dessertsToCreate > 1) {
      final emptySpaces = <Point<int>>[];
      
      // Find empty spaces (excluding the first position)
      for (int y = 0; y < gridHeight; y++) {
        for (int x = 0; x < gridWidth; x++) {
          if (_grid[y][x] == null && !(x == firstPoint.x && y == firstPoint.y)) {
            emptySpaces.add(Point(x, y));
          }
        }
      }
      
      emptySpaces.shuffle(_random);
      final bonusDessertsToPlace = min(dessertsToCreate - 1, emptySpaces.length);
      
      // Place bonus desserts
      for (int i = 0; i < bonusDessertsToPlace; i++) {
        final point = emptySpaces[i];
        _grid[point.y][point.x] = GridDessert(
          id: _nextDessertId++,
          dessert: newDessert,
          gridX: point.x,
          gridY: point.y,
        );
      }
      
      // Show bonus message
      if (bonusDessertsToPlace > 0) {
        final totalCreated = bonusDessertsToPlace + 1;
        debugPrint('🎉 Manual Merge Bonus! Created $totalCreated x ${newDessert.name}!');
      }
    }
    
    // Award score points for merging achievement
    _score += newDessert.baseValue * 2;
    
    // Play merge sound effect
    AudioService().playSoundEffect(SoundEffect.merge);
    
    // Check for shop level upgrade
    _checkShopLevelUpgrade();
    
    // Clear selection
    clearSelection();
    
    // Auto-generate new ingredients to keep the game flowing
    _fillRandomSpaces(1);
    
    // Save game state
    saveGameState();
    
    notifyListeners();
    return true;
  }

  
  // Sell mode methods
  void toggleSellMode() {
    _isSellMode = !_isSellMode;
    if (!_isSellMode) {
      _selectedForSale.clear();
    }
    // Also clear merge selection when switching modes
    clearSelection();
    notifyListeners();
  }
  
  void selectCellForSale(int x, int y) {
    if (!_isSellMode) return;
    
    final point = Point(x, y);
    final dessert = _grid[y][x];
    
    if (dessert == null) return;
    
    if (_selectedForSale.contains(point)) {
      _selectedForSale.remove(point);
    } else {
      _selectedForSale.add(point);
    }
    
    notifyListeners();
  }
  
  bool isSelectedForSale(int x, int y) {
    return _selectedForSale.contains(Point(x, y));
  }
  
  void clearSellSelection() {
    _selectedForSale.clear();
    notifyListeners();
  }
  
  // Sell selected desserts to storage
  int sellSelectedDesserts() {
    if (_selectedForSale.isEmpty) return 0;
    
    int soldCount = 0;
    
    // Sort by row (bottom to top) to avoid index issues when removing
    final sortedPoints = List<Point<int>>.from(_selectedForSale);
    sortedPoints.sort((a, b) => b.y.compareTo(a.y));
    
    for (final point in sortedPoints) {
      final dessert = _grid[point.y][point.x];
      if (dessert != null) {
        // Add to storage
        _storage.addDessert(dessert.dessert.level);
        
        // Remove from grid
        _grid[point.y][point.x] = null;
        soldCount++;
      }
    }
    
    if (soldCount > 0) {
      // Generate new desserts to fill the gaps
      _fillRandomSpaces(soldCount);
      
      // Clear selection
      _selectedForSale.clear();
      
      // Save state
      saveGameState();
    }
    
    notifyListeners();
    return soldCount;
  }

  // Store all items currently on the grid
  int storeAllItems() {
    int storedCount = 0;
    
    // Collect all non-null desserts from the grid
    final allDesserts = <GridDessert>[];
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        final dessert = _grid[y][x];
        if (dessert != null) {
          allDesserts.add(dessert);
        }
      }
    }
    
    // Store each dessert and clear from grid
    for (final dessert in allDesserts) {
      // Add to storage
      _storage.addDessert(dessert.dessert.level);
      
      // Remove from grid
      _grid[dessert.gridY][dessert.gridX] = null;
      
      storedCount++;
    }
    
    if (storedCount > 0) {
      // Generate new desserts to fill the empty grid
      _fillRandomSpaces(storedCount);
      
      // Clear any selections
      _selectedForSale.clear();
      _selectedCells.clear();
      _selectedLevel = null;
      
      // Play sound effect
      AudioService().playSoundEffect(SoundEffect.sell);
      
      // Save state
      saveGameState();
    }
    
    notifyListeners();
    return storedCount;
  }


  List<Point<int>> findSameLevelDessertsOnGrid(int level) {
    final desserts = <Point<int>>[];
    
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (_grid[y][x]?.dessert.level == level) {
          desserts.add(Point(x, y));
        }
      }
    }
    
    return desserts;
  }


  void _checkShopLevelUpgrade() {
    final requiredScore = _shopLevel * 1000;
    if (_score >= requiredScore) {
      final oldLevel = _shopLevel;
      _shopLevel++;
      _coins += _shopLevel * 50; // Level up bonus
      
      // Notify other providers about level change
      if (onShopLevelChanged != null) {
        onShopLevelChanged!(_shopLevel);
      }
      
      debugPrint('🎉 CAFÉ LEVEL UP! Level $oldLevel → $_shopLevel');
      debugPrint('💰 Bonus: ${_shopLevel * 50} coins earned!');
    }
  }

  void earnCoins(int amount) {
    _coins += amount;
    _score += amount * 5;
    _checkShopLevelUpgrade();
    
    // Play coin sound effect
    AudioService().playSoundEffect(SoundEffect.coin);
    
    notifyListeners();
  }
  
  // Sell dessert from grid to storage
  bool sellDessertToStorage(int row, int col) {
    final gridDessert = _grid[row][col];
    if (gridDessert == null) return false;
    
    // Add dessert to storage
    _storage.addDessert(gridDessert.dessert.level);
    
    // Remove from grid
    _grid[row][col] = null;
    
    // Generate a new ingredient to keep the grid flowing
    _fillRandomSpaces(1);
    
    notifyListeners();
    saveGameState();
    return true;
  }
  
  // Serve dessert from storage to customer (this will generate coins)
  bool serveDessertFromStorage(int dessertLevel) {
    if (!_storage.hasEnough(dessertLevel)) {
      return false;
    }
    
    _storage.removeDessert(dessertLevel);
    
    // Calculate payment based on dessert level
    final dessert = Dessert.getDessertByLevel(dessertLevel);
    final payment = dessert.baseValue;
    earnCoins(payment);
    
    saveGameState();
    return true;
  }
  
  void spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      notifyListeners();
      saveGameState();
    }
  }

  // Dessert crafting methods
  bool canCraftDessert(int dessertId) {
    final dessert = CraftableDessert.getDessertById(dessertId);
    if (dessert == null) return false;

    // Check if we have all required ingredients in the grid
    final requiredIngredients = List<int>.from(dessert.requiredIngredients);
    
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        final cell = _grid[row][col];
        if (cell != null) {
          final index = requiredIngredients.indexOf(cell.dessert.level);
          if (index != -1) {
            requiredIngredients.removeAt(index);
          }
        }
      }
    }

    return requiredIngredients.isEmpty;
  }

  bool craftDessert(int dessertId) {
    final dessert = CraftableDessert.getDessertById(dessertId);
    if (dessert == null || !canCraftDessert(dessertId)) {
      return false;
    }

    // Remove required ingredients from grid
    final requiredIngredients = List<int>.from(dessert.requiredIngredients);
    
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        final cell = _grid[row][col];
        if (cell != null) {
          final index = requiredIngredients.indexOf(cell.dessert.level);
          if (index != -1) {
            _grid[row][col] = null;
            requiredIngredients.removeAt(index);
          }
        }
      }
    }
    
    // Fill empty spaces with new random desserts
    for (int i = 0; i < dessert.requiredIngredients.length; i++) {
      generateRandomDessert();
    }

    // Add crafted dessert to storage
    _storage.addCraftedDessert(dessertId);

    // Award score for successful crafting
    _score += dessert.baseValue ~/ 10; // 10% of dessert value as score

    // Play craft sound effect
    AudioService().playSoundEffect(SoundEffect.craft);

    notifyListeners();
    saveGameState();
    return true;
  }

  // Craft multiple desserts (for mini-game rewards) - consumes ingredients once, creates multiple desserts
  bool craftDessertMultiple(int dessertId, int quantity) {
    final dessert = CraftableDessert.getDessertById(dessertId);
    if (dessert == null || !canCraftDessert(dessertId) || quantity <= 0) {
      return false;
    }

    // Remove required ingredients from grid (only once)
    final requiredIngredients = List<int>.from(dessert.requiredIngredients);
    
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        final cell = _grid[row][col];
        if (cell != null) {
          final index = requiredIngredients.indexOf(cell.dessert.level);
          if (index != -1) {
            _grid[row][col] = null;
            requiredIngredients.removeAt(index);
          }
        }
      }
    }
    
    // Fill empty spaces with new random desserts
    for (int i = 0; i < dessert.requiredIngredients.length; i++) {
      generateRandomDessert();
    }

    // Add multiple crafted desserts to storage
    _storage.addCraftedDessert(dessertId, quantity: quantity);

    // Award score for successful crafting (multiply by quantity)
    _score += (dessert.baseValue ~/ 10) * quantity; // 10% of dessert value as score per dessert

    // Play craft sound effect
    AudioService().playSoundEffect(SoundEffect.craft);

    notifyListeners();
    saveGameState();
    return true;
  }

  // Consume ingredients for match game (regardless of success/failure)
  bool consumeIngredientsForMatchGame(int dessertId) {
    final dessert = CraftableDessert.getDessertById(dessertId);
    if (dessert == null || !canCraftDessert(dessertId)) {
      return false;
    }

    // Remove required ingredients from grid (only once)
    final requiredIngredients = List<int>.from(dessert.requiredIngredients);
    
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        final cell = _grid[row][col];
        if (cell != null) {
          final index = requiredIngredients.indexOf(cell.dessert.level);
          if (index != -1) {
            _grid[row][col] = null;
            requiredIngredients.removeAt(index);
          }
        }
      }
    }
    
    // Fill empty spaces with new random desserts
    for (int i = 0; i < dessert.requiredIngredients.length; i++) {
      generateRandomDessert();
    }

    notifyListeners();
    saveGameState();
    return true;
  }

  // Serve crafted dessert to customer
  bool serveCraftedDessert(int dessertId) {
    if (!_storage.removeCraftedDessert(dessertId)) {
      return false;
    }

    // Calculate payment based on dessert value
    final dessert = CraftableDessert.getDessertById(dessertId);
    if (dessert != null) {
      final payment = dessert.baseValue;
      earnCoins(payment);
    }

    saveGameState();
    return true;
  }

  // Get available craftable desserts based on grid ingredients
  List<CraftableDessert> getAvailableCraftableDesserts() {
    final availableIngredientLevels = _getGridIngredientLevels();
    return CraftableDessert.getAvailableDesserts(availableIngredientLevels);
  }

  // Get missing ingredients for a dessert
  List<int> getMissingIngredients(int dessertId) {
    final dessert = CraftableDessert.getDessertById(dessertId);
    if (dessert == null) return [];

    final availableIngredientLevels = _getGridIngredientLevels();
    return dessert.getMissingIngredients(availableIngredientLevels);
  }
  
  // Helper method to get all ingredient levels available in the grid
  List<int> _getGridIngredientLevels() {
    final levels = <int>[];
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        final cell = _grid[row][col];
        if (cell != null) {
          levels.add(cell.dessert.level);
        }
      }
    }
    return levels;
  }

  Future<void> saveGameState() async {
    // Cancel any pending save
    _saveTimer?.cancel();
    
    // Debounce saves to reduce database load
    _saveTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final db = DatabaseService();
        await db.saveGameState({
          'coins': _coins,
          'score': _score,
          'shopLevel': _shopLevel,
          'nextDessertId': _nextDessertId,
          'storage': _storage.toJson(),
        });
        
        await db.saveDessertGrid(_grid);
      } catch (e) {
        debugPrint('Error saving game state: $e');
      }
    });
  }
  
  // Force immediate save (for critical moments like app closing)
  Future<void> saveGameStateImmediate() async {
    _saveTimer?.cancel();
    try {
      final db = DatabaseService();
      await db.saveGameState({
        'coins': _coins,
        'score': _score,
        'shopLevel': _shopLevel,
        'nextDessertId': _nextDessertId,
        'storage': _storage.toJson(),
      });
      
      await db.saveDessertGrid(_grid);
    } catch (e) {
      debugPrint('Error saving game state: $e');
    }
  }

  Future<void> loadGameState() async {
    try {
      final db = DatabaseService();
      final gameState = await db.loadGameState();
      
      if (gameState != null) {
        _coins = gameState['coins'] ?? 100;
        _score = gameState['score'] ?? 0;
        
        // Load storage
        if (gameState['storage'] != null) {
          _storage = Storage.fromJson(gameState['storage'] as Map<String, dynamic>);
        }
        _shopLevel = gameState['shopLevel'] ?? 1;
        _nextDessertId = gameState['nextDessertId'] ?? 1;
      }
      
      final grid = await db.loadDessertGrid();
      if (grid != null && _isValidGridSize(grid)) {
        _grid = grid;
      } else {
        // Grid size mismatch or invalid - create new grid with current dimensions
        debugPrint('Grid size mismatch detected, creating new grid with current dimensions (${gridWidth}x${gridHeight})');
        _grid = List.generate(
          gridHeight,
          (_) => List.generate(gridWidth, (_) => null),
        );
        _fillRandomSpaces(5); // Fill with some initial desserts (reduced for 7x10 grid)
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading game state: $e');
    }
  }

  // Complete reset to initial state
  Future<void> resetToInitialState() async {
    try {
      // Clear all internal state
      _coins = 100;
      _score = 0;
      _shopLevel = 1;
      _nextDessertId = 1;
      
      // Clear grid
      _grid = List.generate(
        gridHeight,
        (_) => List.generate(gridWidth, (_) => null),
      );
      
      // Clear selections
      clearSelection();
      clearSellSelection();
      _isSellMode = false;
      
      // Reset storage
      _initializeStorage();
      
      // Fill grid with initial ingredients
      _fillRandomSpaces(7);
      
      // Save the reset state
      await saveGameState();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting game state: $e');
      rethrow;
    }
  }

  // Check if the loaded grid has the correct dimensions
  bool _isValidGridSize(List<List<GridDessert?>> grid) {
    if (grid.length != gridHeight) return false;
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].length != gridWidth) return false;
    }
    return true;
  }

  // Experience and level methods for UI display
  int getShopExperience() {
    // Calculate current experience based on score and level
    // This is a simple implementation - adjust based on your game's leveling system
    return _score % 1000; // Experience resets every 1000 points
  }
  
  int getRequiredExperience() {
    // Calculate required experience for next level
    return 1000; // Simple: always need 1000 points to level up
  }


  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    saveGameState();
    super.dispose();
  }
}