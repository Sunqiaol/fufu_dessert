import 'package:flutter/material.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'dart:async';
import 'dart:math';
import 'dart:math' as math;

class MatchGameScreen extends StatefulWidget {
  final CraftableDessert dessertToCraft;
  final Function(int rewardCount) onGameComplete;
  final VoidCallback onIngredientConsume;
  final int shopLevel;

  const MatchGameScreen({
    super.key,
    required this.dessertToCraft,
    required this.onGameComplete,
    required this.onIngredientConsume,
    required this.shopLevel,
  });

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> with TickerProviderStateMixin {
  late int gridSize;
  late int gameTimeSeconds;
  
  late List<List<int?>> gameGrid;
  late List<int> availableIngredients;
  late Timer gameTimer;
  late AnimationController _shakeController;
  
  late int timeRemaining;
  int score = 0;
  int matches = 0;
  late int targetMatches;
  bool gameActive = true;
  bool ingredientsConsumed = false;
  Point<int>? selectedCell;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _calculateDifficulty();
    _initializeGame();
    _startTimer();
  }
  
  void _calculateDifficulty() {
    // Progressive unlock system difficulty based on shop level
    if (widget.shopLevel <= 3) {
      // LEVELS 1-3: Learning Phase
      gridSize = 4; // 4×4 only
      gameTimeSeconds = 90; // 90 seconds (generous)
      // Available ingredients: Only levels 1-3 (Flour, Sugar, Milk)
    } else if (widget.shopLevel <= 5) {
      // LEVELS 4-5: Intermediate Phase  
      gridSize = (widget.shopLevel == 4) ? 4 : 5; // 4×4 to 5×5
      gameTimeSeconds = (widget.shopLevel == 4) ? 90 : 75; // 75-90 seconds
      // Available ingredients: Levels 1-4 (adds Butter)
    } else if (widget.shopLevel <= 7) {
      // LEVELS 6-7: Advanced Phase
      gridSize = (widget.shopLevel == 6) ? 5 : 6; // 5×5 to 6×6
      gameTimeSeconds = (widget.shopLevel == 6) ? 75 : 60; // 60-75 seconds  
      // Available ingredients: Levels 1-6 (adds Chocolate, Strawberries)
    } else if (widget.shopLevel <= 9) {
      // LEVELS 8-9: Expert Phase
      gridSize = (widget.shopLevel == 8) ? 6 : 7; // 6×6 to 7×7
      gameTimeSeconds = (widget.shopLevel == 8) ? 60 : 45; // 45-60 seconds
      // Available ingredients: Levels 1-8 (adds Vanilla, Cream)
    } else {
      // LEVEL 10+: Master Phase
      gridSize = 8; // 7×7 to 8×8 (max)
      gameTimeSeconds = 30; // 30-45 seconds (minimum)
      // Available ingredients: All levels 1-10
    }
    
    // Ensure grid size is reasonable for the number of ingredient types
    int ingredientCount = widget.dessertToCraft.requiredIngredients.length;
    int minGridSize = math.max(4, math.sqrt(ingredientCount * 4).ceil());
    gridSize = math.max(gridSize, minGridSize);
    
    // Set initial time and target matches
    timeRemaining = gameTimeSeconds;
    targetMatches = (gridSize * gridSize) ~/ 2;
    
    // Debug info: Match Game Difficulty: Grid ${gridSize}x$gridSize, Time: ${gameTimeSeconds}s, Ingredient levels: ${widget.dessertToCraft.requiredIngredients}
  }

  @override
  void dispose() {
    gameTimer.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _initializeGame() {
    // Get ingredients from the dessert recipe
    availableIngredients = List<int>.from(widget.dessertToCraft.requiredIngredients);
    
    // Determine maximum ingredient level based on shop level (progressive unlock)
    int maxIngredientLevel;
    if (widget.shopLevel <= 3) {
      maxIngredientLevel = 3; // Only Flour, Sugar, Milk
    } else if (widget.shopLevel <= 5) {
      maxIngredientLevel = 4; // Adds Butter
    } else if (widget.shopLevel <= 7) {
      maxIngredientLevel = 6; // Adds Chocolate, Strawberries
    } else if (widget.shopLevel <= 9) {
      maxIngredientLevel = 8; // Adds Vanilla, Cream
    } else {
      maxIngredientLevel = 10; // All ingredients
    }
    
    // Add more variety if needed (minimum 4 different types for good gameplay)
    while (availableIngredients.length < 4) {
      int newIngredient = Random().nextInt(maxIngredientLevel) + 1;
      if (!availableIngredients.contains(newIngredient)) {
        availableIngredients.add(newIngredient);
      }
    }
    
    // Remove any ingredients that exceed the shop level restriction
    availableIngredients = availableIngredients.where((level) => level <= maxIngredientLevel).toList();
    
    // Initialize grid with pairs of ingredients
    gameGrid = List.generate(gridSize, (i) => List.generate(gridSize, (j) => null));
    
    // Calculate total cells and ensure even number for pairs
    int totalCells = gridSize * gridSize;
    int pairCount = totalCells ~/ 2;
    
    // For odd total cells, reduce by 1 to keep pairs
    if (totalCells % 2 == 1) {
      totalCells--;
      pairCount = totalCells ~/ 2;
    }
    
    // Create pairs of ingredients
    List<int> allTiles = [];
    for (int i = 0; i < pairCount; i++) {
      int ingredient = availableIngredients[i % availableIngredients.length];
      allTiles.add(ingredient);
      allTiles.add(ingredient); // Add pair
    }
    
    // Fill remaining cells with null if odd grid size
    while (allTiles.length < gridSize * gridSize) {
      allTiles.add(0); // Use 0 to represent empty cells that will be set to null
    }
    
    // Shuffle and place
    allTiles.shuffle();
    int index = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (index < allTiles.length) {
          gameGrid[i][j] = allTiles[index] == 0 ? null : allTiles[index];
          index++;
        } else {
          gameGrid[i][j] = null; // Safety fallback
        }
      }
    }
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        timeRemaining--;
        if (timeRemaining <= 0) {
          _endGame();
        }
      });
    });
  }

  void _onCellTapped(int row, int col) {
    if (!gameActive || gameGrid[row][col] == null) return;
    
    AudioService().playSoundEffect(SoundEffect.buttonPress);
    
    final currentCell = Point(col, row);
    
    if (selectedCell == null) {
      // First selection
      setState(() {
        selectedCell = currentCell;
      });
    } else if (selectedCell!.x == col && selectedCell!.y == row) {
      // Deselect same cell
      setState(() {
        selectedCell = null;
      });
    } else {
      // Check for match
      final selectedValue = gameGrid[selectedCell!.y][selectedCell!.x];
      final currentValue = gameGrid[row][col];
      
      if (selectedValue == currentValue && _isValidPath(selectedCell!, currentCell)) {
        // Match found!
        AudioService().playSoundEffect(SoundEffect.coin);
        setState(() {
          gameGrid[selectedCell!.y][selectedCell!.x] = null;
          gameGrid[row][col] = null;
          selectedCell = null;
          matches++;
          score += 100;
        });
        
        // Check win condition
        if (_isGridEmpty()) {
          _endGame();
        }
      } else {
        // No match - shake animation
        _shakeController.forward().then((_) => _shakeController.reverse());
        setState(() {
          selectedCell = currentCell;
        });
      }
    }
  }

  bool _isValidPath(Point<int> start, Point<int> end) {
    // 连连看 rules: 两个转弯内可以消除 (can eliminate within two turns)
    
    // Direct line (0 turns)
    if (_hasDirectPath(start, end)) return true;
    
    // One turn path (1 turn)
    if (_hasOneCornerPath(start, end)) return true;
    
    // Two turn path (2 turns)
    if (_hasTwoCornerPath(start, end)) return true;
    
    return false;
  }

  bool _hasDirectPath(Point<int> start, Point<int> end) {
    if (start.x == end.x) {
      // Vertical path
      int minY = math.min(start.y, end.y);
      int maxY = math.max(start.y, end.y);
      for (int y = minY + 1; y < maxY; y++) {
        if (gameGrid[y][start.x] != null) return false;
      }
      return true;
    } else if (start.y == end.y) {
      // Horizontal path
      int minX = math.min(start.x, end.x);
      int maxX = math.max(start.x, end.x);
      for (int x = minX + 1; x < maxX; x++) {
        if (gameGrid[start.y][x] != null) return false;
      }
      return true;
    }
    return false;
  }

  bool _hasOneCornerPath(Point<int> start, Point<int> end) {
    // Try corner at (start.x, end.y)
    Point<int> corner1 = Point(start.x, end.y);
    if (gameGrid[corner1.y][corner1.x] == null && 
        _hasDirectPath(start, corner1) && 
        _hasDirectPath(corner1, end)) {
      return true;
    }
    
    // Try corner at (end.x, start.y)
    Point<int> corner2 = Point(end.x, start.y);
    if (gameGrid[corner2.y][corner2.x] == null && 
        _hasDirectPath(start, corner2) && 
        _hasDirectPath(corner2, end)) {
      return true;
    }
    
    return false;
  }

  bool _hasTwoCornerPath(Point<int> start, Point<int> end) {
    // Two turn path: start -> corner1 -> corner2 -> end
    // We need to find intermediate points that create valid 2-turn paths
    
    // Try all possible intermediate points along the same row as start
    for (int x = 0; x < gridSize; x++) {
      if (x == start.x) continue;
      Point<int> corner1 = Point(x, start.y);
      if (gameGrid[corner1.y][corner1.x] == null || corner1 == end) {
        // Check if we can go: start -> corner1 -> end with one more turn
        if (_hasDirectPath(start, corner1) && _hasOneCornerPath(corner1, end)) {
          return true;
        }
      }
    }
    
    // Try all possible intermediate points along the same column as start
    for (int y = 0; y < gridSize; y++) {
      if (y == start.y) continue;
      Point<int> corner1 = Point(start.x, y);
      if (gameGrid[corner1.y][corner1.x] == null || corner1 == end) {
        // Check if we can go: start -> corner1 -> end with one more turn
        if (_hasDirectPath(start, corner1) && _hasOneCornerPath(corner1, end)) {
          return true;
        }
      }
    }
    
    // Try paths through the border of the grid (extended area)
    // Check extended horizontal paths (row -1 and row gridSize)
    for (int y = -1; y <= gridSize; y += gridSize + 1) {
      for (int x = math.min(start.x, end.x); x <= math.max(start.x, end.x); x++) {
        Point<int> corner1 = Point(x, y);
        if (_canReachBorderPoint(start, corner1) && _canReachBorderPoint(corner1, end)) {
          return true;
        }
      }
    }
    
    // Check extended vertical paths (column -1 and column gridSize)
    for (int x = -1; x <= gridSize; x += gridSize + 1) {
      for (int y = math.min(start.y, end.y); y <= math.max(start.y, end.y); y++) {
        Point<int> corner1 = Point(x, y);
        if (_canReachBorderPoint(start, corner1) && _canReachBorderPoint(corner1, end)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  bool _canReachBorderPoint(Point<int> gridPoint, Point<int> borderPoint) {
    // Check if we can reach a border point (outside grid) from a grid point
    if (borderPoint.y == -1 || borderPoint.y == gridSize) {
      // Horizontal border - check vertical path to border
      if (borderPoint.x == gridPoint.x) {
        // Direct vertical path
        int minY = math.min(gridPoint.y, borderPoint.y < 0 ? -1 : gridSize);
        int maxY = math.max(gridPoint.y, borderPoint.y < 0 ? -1 : gridSize);
        for (int y = minY + 1; y < maxY; y++) {
          if (y >= 0 && y < gridSize && gameGrid[y][gridPoint.x] != null) {
            return false;
          }
        }
        return true;
      }
    }
    
    if (borderPoint.x == -1 || borderPoint.x == gridSize) {
      // Vertical border - check horizontal path to border
      if (borderPoint.y == gridPoint.y) {
        // Direct horizontal path
        int minX = math.min(gridPoint.x, borderPoint.x < 0 ? -1 : gridSize);
        int maxX = math.max(gridPoint.x, borderPoint.x < 0 ? -1 : gridSize);
        for (int x = minX + 1; x < maxX; x++) {
          if (x >= 0 && x < gridSize && gameGrid[gridPoint.y][x] != null) {
            return false;
          }
        }
        return true;
      }
    }
    
    return false;
  }

  bool _isGridEmpty() {
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (gameGrid[i][j] != null) return false;
      }
    }
    return true;
  }

  void _consumeIngredients() {
    if (!ingredientsConsumed) {
      ingredientsConsumed = true;
      widget.onIngredientConsume();
    }
  }

  void _endGame() {
    gameActive = false;
    gameTimer.cancel();
    
    // Consume ingredients first
    _consumeIngredients();
    
    // Calculate reward based on completion percentage (fixed max multiplier of 20x)
    const int maxReward = 20; // Fixed max multiplier
    int reward;
    
    // Performance-based rewards following the balanced system
    double completionRate = matches / targetMatches;
    
    if (_isGridEmpty()) {
      // 100% Clear: Max multiplier + 25% time bonus
      reward = maxReward;
      if (timeRemaining > gameTimeSeconds * 0.5) { // >50% time remaining
        reward = (reward * 1.25).round(); // +25% time bonus
      }
    } else if (completionRate >= 0.8) {
      // 80%+ Clear: 90% of max multiplier + 15% time bonus  
      reward = (maxReward * 0.9).round(); // 18x base
      if (timeRemaining > gameTimeSeconds * 0.3) { // >30% time remaining
        reward = (reward * 1.15).round(); // +15% time bonus
      }
    } else if (completionRate >= 0.6) {
      // 60%+ Clear: 70% of max multiplier + 5% time bonus
      reward = (maxReward * 0.7).round(); // 14x base
      if (timeRemaining > gameTimeSeconds * 0.1) { // >10% time remaining
        reward = (reward * 1.05).round(); // +5% time bonus
      }
    } else if (completionRate >= 0.4) {
      // 40%+ Clear: 50% of max multiplier
      reward = (maxReward * 0.5).round(); // 10x base
    } else {
      // <40% Clear: 30% of max multiplier
      reward = (maxReward * 0.3).round(); // 6x base
    }
    
    // Ensure reward stays within reasonable range
    reward = reward.clamp(5, 25); // Allow slightly above 20x with time bonuses
    
    widget.onGameComplete(reward);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Consume ingredients when user tries to exit
          _consumeIngredients();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.primaryCream,
        appBar: AppBar(
          title: Text('连连看 - ${widget.dessertToCraft.name} (${gridSize}x$gridSize)'),
          backgroundColor: AppTheme.primaryPeach,
          foregroundColor: Colors.brown[700],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Consume ingredients when user manually goes back
              _consumeIngredients();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: timeRemaining <= 30 ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${timeRemaining}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: gameActive ? _buildGameView() : _buildGameOverView(),
      ),
    );
  }

  Widget _buildGameView() {
    return Column(
      children: [
        // Game Stats
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Score', '$score', Colors.blue),
              _buildStatCard('Matches', '$matches/$targetMatches', Colors.green),
              _buildStatCard('Time', '${timeRemaining}s', timeRemaining <= 30 ? Colors.red : Colors.orange),
              _buildStatCard('Difficulty', _getDifficultyLabel(), _getDifficultyColor()),
            ],
          ),
        ),
        
        // Game Grid
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = sin(_shakeController.value * pi * 4) * 5;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ gridSize;
                      final col = index % gridSize;
                      
                      // Safety bounds check
                      if (row >= gameGrid.length || col >= gameGrid[0].length) {
                        return const SizedBox(); // Return empty widget for out-of-bounds
                      }
                      
                      final value = gameGrid[row][col];
                      final isSelected = selectedCell?.x == col && selectedCell?.y == row;
                      
                      return GestureDetector(
                        onTap: () => _onCellTapped(row, col),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: value == null 
                                ? Colors.transparent 
                                : isSelected 
                                    ? AppTheme.accentGold 
                                    : Colors.white,
                            border: value != null 
                                ? Border.all(
                                    color: isSelected ? AppTheme.accentGold : AppTheme.primaryPink.withValues(alpha: 0.5),
                                    width: isSelected ? 3 : 2,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: value != null ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: value != null 
                              ? Center(
                                  child: Text(
                                    Dessert.getDessertByLevel(value).emoji,
                                    style: TextStyle(
                                      fontSize: AppTheme.responsiveFontSize(context, 24),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            '🎯 连连看: Match identical ingredients within 2 turns!\n两个转弯内可以消除 • Earn more rewards by completing faster!',
            style: TextStyle(fontSize: 14, color: Colors.brown),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverView() {
    final isWin = _isGridEmpty();
    final completionPercent = (matches / targetMatches * 100).round();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWin ? '🎉 Perfect Match!' : '⏰ Time\'s Up!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Completion: $completionPercent%',
              style: const TextStyle(fontSize: 18, color: Colors.brown),
            ),
            const SizedBox(height: 16),
            Text(
              'Final Score: $score',
              style: const TextStyle(fontSize: 16, color: Colors.brown),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Ensure ingredients are consumed (should already be consumed in _endGame)
                _consumeIngredients();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Collect Rewards'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDifficultyLabel() {
    if (gridSize <= 4) return 'Easy';
    if (gridSize <= 5) return 'Medium';
    if (gridSize <= 6) return 'Hard';
    if (gridSize <= 7) return 'Expert';
    return 'Master';
  }
  
  Color _getDifficultyColor() {
    if (gridSize <= 4) return Colors.green;
    if (gridSize <= 5) return Colors.orange;
    if (gridSize <= 6) return Colors.red;
    if (gridSize <= 7) return Colors.purple;
    return Colors.black;
  }
}