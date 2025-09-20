import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Point;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/storage.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/services/database_service.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/services/tutorial_service.dart';
import 'package:fufu_dessert2/widgets/level_up_screen.dart';

class GameProvider with ChangeNotifier {
  static const int gridWidth = 7;
  static const int gridHeight = 9;
  
  List<List<GridDessert?>> _grid = List.generate(
    gridHeight,
    (_) => List.generate(gridWidth, (_) => null),
  );
  
  int _coins = 100;
  int _score = 0;
  int _shopLevel = 1;
  int _nextDessertId = 1;
  BuildContext? _currentContext;
  final math.Random _random = math.Random();
  Timer? _autoSaveTimer;
  
  // Store open/close state management
  bool _isStoreOpen = true;
  DateTime? _lastStoreToggleTime;
  final int _storeToggleCooldownSeconds = 0;
  final int _maxClosureTimeMinutes = 5;
  DateTime? _storeClosedTime;
  
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
  
  // Store state getters
  bool get isStoreOpen => _isStoreOpen;
  bool get canToggleStore {
    if (_lastStoreToggleTime == null) return true;
    return DateTime.now().difference(_lastStoreToggleTime!).inSeconds >= _storeToggleCooldownSeconds;
  }
  
  // Check if level up is ready (manual trigger available)
  bool get levelUpReady {
    return _shopLevel < levelRequirements.length && _score >= levelRequirements[_shopLevel];
  }
  
  // Manual level up method (triggered by UI button)
  void levelUp() {
    if (levelUpReady) {
      _performLevelUp();
    }
  }
  
  // Toggle store open/close state
  void toggleStore() {
    if (!canToggleStore) return;
    
    _isStoreOpen = !_isStoreOpen;
    _lastStoreToggleTime = DateTime.now();
    
    if (_isStoreOpen) {
      // Opening store
      _storeClosedTime = null;
      AudioService().playSoundEffect(SoundEffect.buttonPress);
    } else {
      // Closing store
      _storeClosedTime = DateTime.now();
      AudioService().playSoundEffect(SoundEffect.buttonPress);
    }
    
    notifyListeners();
  }
  
  // Check if store should be force-reopened due to max closure time
  void _checkForcedReopening() {
    if (!_isStoreOpen && _storeClosedTime != null) {
      final closureTime = DateTime.now().difference(_storeClosedTime!);
      if (closureTime.inMinutes >= _maxClosureTimeMinutes) {
        _isStoreOpen = true;
        _storeClosedTime = null;
        notifyListeners();
      }
    }
  }
  
  // Set context for tutorials
  void setContext(BuildContext context) {
    _currentContext = context;
  }
  Storage get storage => _storage;
  bool get isSellMode => _isSellMode;
  List<Point<int>> get selectedForSale => _selectedForSale;
  List<Point<int>> get selectedCells => _selectedCells;
  int? get selectedLevel => _selectedLevel;

  // Get level requirements (centralized to avoid duplication)
  List<int> get levelRequirements => [
    0, 800, 2200, 4300, 7200, 11000, 15800, 21700, 28800, 37200,
    47400, 59000, 72200, 87100, 103800, 122400, 143000, 165700, 190600, 217800,
    247400, 279500, 314200, 351600, 391800, 435000, 481300, 530800, 583600, 639800,
  ];

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
      _checkForcedReopening();
    });
  }

  bool _isGridEmpty() {
    return _grid.every((row) => row.every((cell) => cell == null));
  }

  void _fillRandomSpaces(int count) {
    if (count <= 0) return; // MEMORY OPTIMIZATION: Early exit
    
    final emptySpaces = <Point<int>>[];
    
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (_grid[y][x] == null) {
          emptySpaces.add(Point(x, y));
        }
      }
    }
    
    if (emptySpaces.isEmpty) return; // MEMORY OPTIMIZATION: Early exit
    
    emptySpaces.shuffle(_random);
    final spacesToFill = math.min(count, emptySpaces.length);
    
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

  /// Generate random dessert level with improved balanced probabilities
  /// Reduced bottleneck at mid-tier ingredients for smoother progression
  int _generateWeightedRandomLevel() {
    final roll = _random.nextInt(1000); // 0-999 for more precise control
    
    // Ultra rare high levels (3% total) - IMPROVED BALANCE
    if (roll < 1) return 10;      // 0.1% chance (1/1000) - Honey (unchanged)
    if (roll < 5) return 9;       // 0.4% chance (4/1000) - Cream (4x increase)
    if (roll < 15) return 8;      // 1.0% chance (10/1000) - Vanilla (5x increase)
    if (roll < 30) return 7;      // 1.5% chance (15/1000) - Strawberries (15x increase)
    
    // Rare mid-high levels (7% total) - SIGNIFICANTLY IMPROVED
    if (roll < 60) return 6;      // 3.0% chance (30/1000) - Chocolate (3x increase)
    if (roll < 100) return 5;     // 4.0% chance (40/1000) - Eggs (2.7x increase)
    
    // Uncommon mid levels (25% total) - MUCH MORE ACCESSIBLE
    if (roll < 200) return 4;     // 10.0% chance (100/1000) - Butter (1.7x increase)
    if (roll < 350) return 3;     // 15.0% chance (150/1000) - Milk (2.5x increase)
    
    // Common low levels (65% total) - STILL DOMINANT BUT BALANCED
    if (roll < 650) return 2;     // 30.0% chance (300/1000) - Sugar (reduced from 42.5%)
    return 1;                     // 35.0% chance (350/1000) - Flour (reduced from 42.5%)
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
    
    // Play bubble click sound when tapping on a dessert
    if (dessert != null) {
      AudioService().playSoundEffect(SoundEffect.bubbleClick);
    }
    
    if (dessert == null) {
      // Empty cell - generate random dessert at random locations
      _fillRandomSpaces(1);
      
      // Play bubble click sound effect
      AudioService().playSoundEffect(SoundEffect.bubbleClick);
      
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
        Future.delayed(const Duration(milliseconds: 50), () {
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
    final nextLevel = math.min(_selectedLevel! + 1, 10);
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
      final bonusDessertsToPlace = math.min(dessertsToCreate - 1, emptySpaces.length);
      
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
        // totalCreated would be bonusDessertsToPlace + 1
      }
    }
    
    // Award score points for merging achievement (1.5x XP)
    final xpEarned = (newDessert.baseValue * 1.5).round();
    _score += xpEarned;
    
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
    
    // Play bubble click sound when tapping on a dessert in sell mode
    AudioService().playSoundEffect(SoundEffect.bubbleClick);
    
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
    // Check if player qualifies for level up
    if (_shopLevel < levelRequirements.length) {
      final requiredScore = levelRequirements[_shopLevel];
      
      if (_score >= requiredScore) {
        _performLevelUp();
      }
    }
  }
  
  // Automatic level up method
  void _performLevelUp() {
    if (_shopLevel < levelRequirements.length && _score >= levelRequirements[_shopLevel]) {
      final oldLevel = _shopLevel;
      _shopLevel++;
      
      // Progressive coin rewards: 100, 150, 200, 250, 300, 350, 400, 450, 500, capped at 1000
      final coinReward = math.min(1000, 50 + _shopLevel * 50);
      _coins += coinReward;
      
      // Notify other providers about level change
      if (onShopLevelChanged != null) {
        onShopLevelChanged!(_shopLevel);
      }
      
      
      // Play level up sound effect
      AudioService().playSoundEffect(SoundEffect.levelUp);
      
      _checkForNewUnlocks(oldLevel, _shopLevel);
      
      // Show level up screen if context is available
      if (_currentContext != null) {
        debugPrint('🎬 GameProvider: Showing level up screen');
        _showLevelUpScreen(oldLevel, _shopLevel, coinReward);
      } else {
      }
      
      notifyListeners();
    }
  }

  // Show level up screen
  void _showLevelUpScreen(int oldLevel, int newLevel, int coinReward) {
    if (_currentContext != null) {
      Navigator.of(_currentContext!).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: LevelUpScreen(
                oldLevel: oldLevel,
                newLevel: newLevel,
                coinReward: coinReward,
                gameProvider: this,
                onDismiss: () {
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        ),
      );
    }
  }
  
  void _checkForNewUnlocks(int oldLevel, int newLevel) {
    // Determine if this is a major unlock requiring full-screen celebration
    bool isMajorUnlock = [3, 6, 8, 10].contains(newLevel);
    
    // Calculate unlock details
    Map<String, dynamic> unlockData = _getUnlockData(newLevel);
    
    if (isMajorUnlock) {
      // Major Unlocks - Full-screen animation with showcase
      
      // TODO: Trigger full-screen celebration animation
      _triggerMajorUnlockCelebration(unlockData);
    } else {
      // Minor Unlocks - Notification banner
      
      // TODO: Trigger notification banner
      _triggerMinorUnlockNotification(unlockData);
    }
  }
  
  Map<String, dynamic> _getUnlockData(int level) {
    switch (level) {
      case 2:
        return {
          'title': 'First Recipe Unlocked!',
          'features': ['Cookies recipe', 'Crafting system'],
          'bonus': '50 coins + free ingredients',
        };
      case 3:
        return {
          'title': 'Furniture Store Opens!',
          'features': ['Furniture store', 'Simple recipes', 'Basic decorations'],
          'bonus': '100 coins + starter furniture pack',
        };
      case 4:
        return {
          'title': 'Master Chef Certification!',
          'features': ['3-ingredient recipes', 'Third table slot', 'Medium furniture'],
          'bonus': '150 coins + recipe book',
        };
      case 5:
        return {
          'title': 'Chocolate Unlocked!',
          'features': ['Chocolate ingredient', 'Premium furniture tier'],
          'bonus': '200 coins + chocolate starter pack',
        };
      case 6:
        return {
          'title': 'Interior Designer!',
          'features': ['Complex 4-ingredient recipes', 'Luxury furniture', 'Fourth table slot'],
          'bonus': '250 coins + designer furniture set',
        };
      case 7:
        return {
          'title': 'Advanced Recipes!',
          'features': ['Vanilla ingredient', 'Premium decorations'],
          'bonus': '300 coins + vanilla collection',
        };
      case 8:
        return {
          'title': 'Culinary Artist!',
          'features': ['Master recipes', 'Elite furniture', 'Fifth table slot'],
          'bonus': '400 coins + artist collection',
        };
      case 9:
        return {
          'title': 'Expert Chef!',
          'features': ['Honey ingredient', 'Expert recipes'],
          'bonus': '450 coins + honey collection',
        };
      case 10:
        return {
          'title': 'Dessert Empire!',
          'features': ['Ultimate recipes', 'Prestige furniture', 'Sixth table slot'],
          'bonus': '500 coins + empire starter pack',
        };
      default:
        return {
          'title': 'Level Up!',
          'features': ['New opportunities'],
          'bonus': '${50 + level * 25} coins',
        };
    }
  }
  
  void _triggerMajorUnlockCelebration(Map<String, dynamic> unlockData) {
    // TODO: Implement full-screen celebration animation
    // This would typically show:
    // - Full-screen overlay with celebration animation
    // - Achievement badge
    // - Feature showcase with tutorial popup
    // - Starter bonus distribution
  }
  
  void _triggerMinorUnlockNotification(Map<String, dynamic> unlockData) {
    // TODO: Implement notification banner
    // This would typically show:
    // - Top banner notification
    // - Shop highlight for new items
    // - Small coin bonus
  }

  void earnCoins(int amount) {
    final xpEarned = amount * 3;
    _coins += amount;
    _score += xpEarned; // Customer served: 3x XP
    _checkShopLevelUpgrade();
    
    // Play coin sound effect
    AudioService().playSoundEffect(SoundEffect.coin);
    
    notifyListeners();
  }
  
  // Apply penalty for customer timeout
  void applyCustomerTimeoutPenalty(int patienceRemaining) {
    int penalty = _calculateTimeoutPenalty(patienceRemaining);
    
    // Apply level-based penalty scaling
    if (_shopLevel <= 5) {
      penalty = (penalty * 0.5).round(); // 50% reduced for early game
    } else if (_shopLevel >= 16) {
      penalty = (penalty * 1.25).round(); // 25% increased for late game
    }
    
    // Apply closed store bonus (50% reduced penalties)
    if (!_isStoreOpen) {
      penalty = (penalty * 0.5).round();
    }
    
    // Apply penalty with minimum balance protection
    _coins = math.max(10, _coins - penalty);
    
    // Play negative audio feedback
    AudioService().playSoundEffect(SoundEffect.buttonPress); // Placeholder - could add angry customer sound
    
    notifyListeners();
  }
  
  // Calculate penalty amount based on patience remaining
  int _calculateTimeoutPenalty(int patienceRemaining) {
    if (patienceRemaining <= 5) return 50;      // Furious
    if (patienceRemaining <= 15) return 30;     // Angry
    if (patienceRemaining <= 30) return 15;     // Disappointed
    return 5;                                   // Mildly upset
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
  
  // Serve dessert from grid to customer (this will generate coins)
  bool serveDessertFromStorage(int dessertLevel) {
    // Find and remove a dessert of the specified level from the grid
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        final cell = _grid[y][x];
        if (cell != null && cell.dessert.level == dessertLevel) {
          // Remove the dessert from grid
          _grid[y][x] = null;
          
          // Calculate payment based on dessert level
          final dessert = Dessert.getDessertByLevel(dessertLevel);
          final payment = dessert.baseValue;
          earnCoins(payment);
          
          notifyListeners();
          saveGameState();
          return true;
        }
      }
    }
    return false; // No dessert of that level found
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
    if (dessert == null) {
      return false;
    }


    // Check if we have all required ingredients in the grid
    final requiredIngredients = List<int>.from(dessert.requiredIngredients);
    List<String> foundIngredients = [];
    
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        final cell = _grid[row][col];
        if (cell != null) {
          final index = requiredIngredients.indexOf(cell.dessert.level);
          if (index != -1) {
            foundIngredients.add('${cell.dessert.name} (level ${cell.dessert.level}) at ($row,$col)');
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

    // Award score for successful crafting (2x XP + time bonus)
    _score += dessert.baseValue * 2; // Crafting success: Recipe value × 2 XP

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
    return CraftableDessert.getAvailableDesserts(availableIngredientLevels, _shopLevel);
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
      } else if (grid != null) {
        // Grid size mismatch - try to preserve as many items as possible
        // Silent migration from old grid size to new grid size
        _grid = List.generate(
          gridHeight,
          (_) => List.generate(gridWidth, (_) => null),
        );
        
        // Transfer items from old grid to new grid where possible
        int transferredItems = 0;
        for (int row = 0; row < math.min(grid.length, gridHeight); row++) {
          for (int col = 0; col < math.min(grid[row].length, gridWidth); col++) {
            if (grid[row][col] != null) {
              _grid[row][col] = grid[row][col];
              transferredItems++;
            }
          }
        }
        
        // Silently transferred $transferredItems items from old grid to new grid
        
        // Fill empty spaces with some new items if grid is too empty
        final emptySpaces = _countEmptySpaces();
        if (emptySpaces > (gridWidth * gridHeight * 0.8)) {
          _fillRandomSpaces(3); // Add fewer items since we preserved some
        }
      } else {
        // No saved grid - create new grid with initial items
        debugPrint('No saved grid found, creating new grid with current dimensions (${gridWidth}x${gridHeight})');
        _grid = List.generate(
          gridHeight,
          (_) => List.generate(gridWidth, (_) => null),
        );
        _fillRandomSpaces(5); // Fill with some initial desserts
      }
      
      // Check if level up is ready after loading state
      _checkShopLevelUpgrade();
      
      // Trigger shop level update to sync with other providers (like CustomerProvider)
      if (onShopLevelChanged != null) {
        onShopLevelChanged!(_shopLevel);
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
  
  int _countEmptySpaces() {
    int emptyCount = 0;
    for (int row = 0; row < gridHeight; row++) {
      for (int col = 0; col < gridWidth; col++) {
        if (_grid[row][col] == null) {
          emptyCount++;
        }
      }
    }
    return emptyCount;
  }

  // Experience and level methods for UI display
  int getShopExperience() {
    // Calculate current experience within the current level
    if (_shopLevel <= 1) return _score;
    
    // Get the XP requirement for current level (previous level's requirement)
    final currentLevelStartXP = levelRequirements[_shopLevel - 1];
    return _score - currentLevelStartXP;
  }
  
  int getRequiredExperience() {
    // Calculate required experience for next level
    if (_shopLevel >= levelRequirements.length) {
      return 1000; // Default for levels beyond our array
    }
    
    // Get XP needed for next level
    final nextLevelRequiredXP = levelRequirements[_shopLevel];
    final currentLevelStartXP = _shopLevel <= 1 ? 0 : levelRequirements[_shopLevel - 1];
    return nextLevelRequiredXP - currentLevelStartXP;
  }


  @override
  void dispose() {
    // MEMORY CLEANUP: Cancel all timers
    _autoSaveTimer?.cancel();
    _saveTimer?.cancel();
    
    // MEMORY CLEANUP: Clear collections
    _selectedCells.clear();
    _selectedForSale.clear();
    
    // MEMORY CLEANUP: Clear grid
    for (int i = 0; i < _grid.length; i++) {
      _grid[i].clear();
    }
    _grid.clear();
    
    // MEMORY CLEANUP: Null callbacks
    onShopLevelChanged = null;
    _currentContext = null;
    
    // Save state before disposal
    saveGameStateImmediate();
    
    super.dispose();
  }
}