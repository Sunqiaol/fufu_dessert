import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';

class MergeGridWidget extends StatelessWidget {
  const MergeGridWidget({super.key});
  
  // Cache expensive decorations
  static final Map<String, BoxDecoration> _cellDecorationCache = {};
  
  BoxDecoration _getCachedCellDecoration(GameProvider gameProvider, GridDessert? gridDessert, int x, int y) {
    // Create cache key based on cell state and position for variety
    final bool isEmpty = gridDessert == null;
    final bool isSelected = gameProvider.isSelected(x, y);
    final int colorVariant = (x + y) % 3; // Create 3 different pastel variants
    final String key = '${isEmpty}_${isSelected}_$colorVariant';
    
    return _cellDecorationCache[key] ??= BoxDecoration(
      gradient: isEmpty
          ? _getEmptyGradient(colorVariant)
          : _getFilledGradient(colorVariant),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isSelected 
            ? const Color(0xFFFF69B4) // Hot pink for selected
            : _getBorderColor(colorVariant),
        width: isSelected ? 3.0 : 2.0, // Slightly thicker borders
      ),
      boxShadow: isSelected
          ? [
              const BoxShadow(
                color: Color(0x66FF69B4), // Stronger glow when selected
                blurRadius: 12,
                offset: Offset(0, 6),
                spreadRadius: 2,
              ),
            ]
          : [
              const BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6, // Slightly softer shadow
                offset: Offset(0, 3),
              ),
            ],
    );
  }
  
  // Beautiful pastel gradients for empty cells
  static LinearGradient _getEmptyGradient(int variant) {
    switch (variant) {
      case 0: // Mint cream
        return const LinearGradient(
          colors: [Color(0xFFF0FFF4), Color(0xFFE6FFFA)], // Mint to light mint
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1: // Light pink cream  
        return const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)], // Lavender blush to misty rose
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2: // Vanilla cream
        return const LinearGradient(
          colors: [Color(0xFFFFFAF0), Color(0xFFFDF5E6)], // Floral white to old lace
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return _getEmptyGradient(0);
    }
  }
  
  // Beautiful pastel gradients for filled cells
  static LinearGradient _getFilledGradient(int variant) {
    switch (variant) {
      case 0: // Light mint
        return const LinearGradient(
          colors: [Color(0xFFE6FFFA), Color(0xFFB2F5EA)], // Light mint to pale turquoise
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1: // Soft pink
        return const LinearGradient(
          colors: [Color(0xFFFFE4E1), Color(0xFFFFCDD2)], // Misty rose to pink
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2: // Warm cream
        return const LinearGradient(
          colors: [Color(0xFFFDF5E6), Color(0xFFFAEBD7)], // Old lace to antique white
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return _getFilledGradient(0);
    }
  }
  
  // Matching border colors for each variant
  static Color _getBorderColor(int variant) {
    switch (variant) {
      case 0: return const Color(0xFFB2F5EA); // Mint border
      case 1: return const Color(0xFFFFB6C1); // Pink border
      case 2: return const Color(0xFFDDD6C7); // Cream border
      default: return const Color(0xFFFFB6C1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, CustomerProvider>(
      builder: (context, gameProvider, customerProvider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF8E7), // Cream
                const Color(0xFFFFE4E1), // Misty rose
                const Color(0xFFFFFAFA), // Snow white
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFB6C1), // Light pink
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate cell size based on available space (7x10 grid)
              final availableWidth = constraints.maxWidth - (6 * 2); // 6 gaps of 2px each (7-1)
              final availableHeight = constraints.maxHeight - (9 * 2); // 9 gaps of 2px each (10-1)
              final cellWidth = availableWidth / 7;
              final cellHeight = availableHeight / 10;
              // Prioritize width to fill horizontal space better, but cap by height if needed
              final cellSize = cellWidth <= cellHeight * 1.2 ? cellWidth : cellHeight;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0), // Minimal horizontal padding
                child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: GameProvider.gridWidth,
                        crossAxisSpacing: 2, // Reduced spacing for bigger dessert items
                        mainAxisSpacing: 2,  // Reduced spacing for bigger dessert items
                        childAspectRatio: 1.0,
                      ),
                      itemCount: GameProvider.gridWidth * GameProvider.gridHeight,
                      itemBuilder: (context, index) {
                        final x = index % GameProvider.gridWidth;
                        final y = index ~/ GameProvider.gridWidth;
                        final gridDessert = gameProvider.grid[y][x];

                        return Container(
                          decoration: _getCachedCellDecoration(gameProvider, gridDessert, x, y),
                          child: gridDessert != null
                              ? _buildFilledCell(context, gameProvider, customerProvider, gridDessert, cellSize)
                              : _buildEmptyCell(gameProvider, x, y, cellSize),
                        );
                      },
                    ),
                  );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilledCell(BuildContext context, GameProvider gameProvider, CustomerProvider customerProvider, GridDessert gridDessert, double cellSize) {
    return Draggable<Map<String, dynamic>>(
      data: {
        'type': 'grid_dessert',
        'level': gridDessert.dessert.level,
        'x': gridDessert.gridX,
        'y': gridDessert.gridY,
        'dessert': gridDessert,
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: Container(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gridDessert.dessert.color.withOpacity(0.8),
                  gridDessert.dessert.color.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                gridDessert.dessert.emoji,
                style: TextStyle(
                  fontSize: cellSize * 0.4,
                  shadows: [
                    Shadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildDessertContent(gridDessert, customerProvider, cellSize),
      ),
      child: GestureDetector(
        onTap: () => gameProvider.selectCell(gridDessert.gridX, gridDessert.gridY),
        child: _buildDessertContent(gridDessert, customerProvider, cellSize),
      ),
    );
  }

  Widget _buildDessertContent(GridDessert gridDessert, CustomerProvider customerProvider, double cellSize) {
    // Check if any customer wants this dessert
    final bool isWantedByCustomer = customerProvider.isAnyCustomerWantingLevel(gridDessert.dessert.level);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main dessert display
        Center(
          child: Container(
            padding: EdgeInsets.all(cellSize * 0.05),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  gridDessert.dessert.color.withOpacity(0.4),
                  gridDessert.dessert.color.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Transform.scale(
              scale: 1.4,
              child: Text(
                gridDessert.dessert.emoji,
                style: TextStyle(
                  fontSize: (cellSize * 0.7).clamp(28, 55),
                  shadows: [
                    Shadow(
                      color: gridDessert.dessert.color.withOpacity(0.8),
                      blurRadius: 4,
                      offset: const Offset(1.5, 1.5),
                    ),
                    Shadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 2,
                      offset: const Offset(-1, -1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Level badge (top-left)
        if (cellSize > 30)
          Positioned(
            top: cellSize * 0.02,
            left: cellSize * 0.02,
            child: Container(
              constraints: BoxConstraints(
                minWidth: cellSize * 0.2, 
                minHeight: cellSize * 0.15,
                maxWidth: cellSize * 0.3,
                maxHeight: cellSize * 0.25,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: cellSize * 0.02, 
                vertical: cellSize * 0.01
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(cellSize * 0.08),
                border: Border.all(color: gridDessert.dessert.color, width: 0.5),
              ),
              child: FittedBox(
                child: Text(
                  '${gridDessert.dessert.level}',
                  style: TextStyle(
                    fontSize: (cellSize * 0.12).clamp(8, 16),
                    fontWeight: FontWeight.bold,
                    color: gridDessert.dessert.color,
                  ),
                ),
              ),
            ),
          ),
        
        // Value badge (bottom-right)
        if (cellSize > 30)
          Positioned(
            bottom: cellSize * 0.02,
            right: cellSize * 0.02,
            child: Container(
              constraints: BoxConstraints(
                minWidth: cellSize * 0.15, 
                minHeight: cellSize * 0.12,
                maxWidth: cellSize * 0.25,
                maxHeight: cellSize * 0.2,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: cellSize * 0.015, 
                vertical: cellSize * 0.01
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(cellSize * 0.06),
              ),
              child: FittedBox(
                child: Text(
                  '${gridDessert.dessert.baseValue}',
                  style: TextStyle(
                    fontSize: (cellSize * 0.1).clamp(6, 12),
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ),
          ),
        
        // Customer want hint icon (top-right with pulsing animation)
        if (isWantedByCustomer)
          Positioned(
            top: cellSize * 0.02,
            right: cellSize * 0.02,
            child: _PulsingHintIcon(cellSize: cellSize),
          ),
      ],
    );
  }

  Widget _buildEmptyCell(GameProvider gameProvider, int x, int y, double cellSize) {
    return GestureDetector(
      onTap: () => gameProvider.selectCell(x, y),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: MergeGridWidget._getEmptyGradient((x + y) % 3),
          border: Border.all(
            color: Colors.pink.withOpacity(0.4),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sparkle icon with subtle glow effect
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.pink.withOpacity(0.7),
                  size: (cellSize * 0.3).clamp(16, 28),
                ),
              ),
              SizedBox(height: cellSize * 0.01),
              // Small "+" symbol below sparkle
              Icon(
                Icons.add,
                color: Colors.pink.withOpacity(0.5),
                size: (cellSize * 0.12).clamp(8, 14),
              ),
            ],
          ),
        ),
      ),
    );
  }


}

class _PulsingHintIcon extends StatefulWidget {
  final double cellSize;
  
  const _PulsingHintIcon({required this.cellSize});
  
  @override
  State<_PulsingHintIcon> createState() => _PulsingHintIconState();
}

class _PulsingHintIconState extends State<_PulsingHintIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Start the repeating animation
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.cellSize * 0.25,
              height: widget.cellSize * 0.25,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.orange,
                    Colors.deepOrange,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: widget.cellSize * 0.12,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}