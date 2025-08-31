import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/models/furniture.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';

class FurnitureWidget extends StatelessWidget {
  final PlacedFurniture furniture;
  final bool isSelected;
  final VoidCallback onTap;

  const FurnitureWidget({
    super.key,
    required this.furniture,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cafeProvider = Provider.of<CafeProvider>(context, listen: false);
    
    return Positioned(
      left: furniture.x * CafeProvider.cellSize,
      top: furniture.y * CafeProvider.cellSize,
      child: (isSelected && cafeProvider.isInEditMode) ? Draggable<PlacedFurniture>(
        data: furniture,
        feedback: _buildFurnitureContainer(isDragging: true),
        childWhenDragging: _buildFurnitureContainer(isGhost: true),
        onDragStarted: () {
          cafeProvider.startDragging(furniture.id);
        },
        onDragEnd: (details) {
          cafeProvider.finishDragging();
        },
        child: GestureDetector(
          onTap: onTap,
          child: _buildFurnitureContainer(),
        ),
      ) : GestureDetector(
        onTap: onTap,
        child: _buildFurnitureContainer(),
      ),
    );
  }

  Widget _buildFurnitureContainer({bool isDragging = false, bool isGhost = false}) {
    return Transform.rotate(
          angle: furniture.rotation,
          child: Container(
            width: furniture.furniture.width * CafeProvider.cellSize,
            height: furniture.furniture.height * CafeProvider.cellSize,
            decoration: BoxDecoration(
              color: isGhost 
                ? furniture.furniture.color.withValues(alpha: 0.3)
                : furniture.furniture.color.withValues(alpha: 0.8),
              border: isDragging
                ? Border.all(color: Colors.green, width: 3)
                : isSelected 
                  ? Border.all(color: Colors.yellow, width: 3)
                  : Border.all(color: Colors.brown[300]!, width: 1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isDragging ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main furniture display
                Center(
                  child: _buildFurnitureDisplay(),
                ),
                
                // Upgrade indicator
                if (furniture.furniture.canUpgrade)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 12,
                        color: Colors.black,
                      ),
                    ),
                  ),
                
                // Level indicator
                if (furniture.furniture.level > 1)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'L${furniture.furniture.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Attraction bonus indicator
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${furniture.furniture.attractionBonus}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFurnitureDisplay() {
    // Special case for basic display case - use custom image
    if (furniture.furniture.id == 'display_case_1') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/images/Display_1.jpg',
          width: furniture.furniture.width * CafeProvider.cellSize * 0.9,
          height: furniture.furniture.height * CafeProvider.cellSize * 0.9,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to emoji if image fails to load
            return _buildDefaultFurnitureDisplay();
          },
        ),
      );
    }
    
    // Default display for other furniture
    return _buildDefaultFurnitureDisplay();
  }

  Widget _buildDefaultFurnitureDisplay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          furniture.furniture.emoji,
          style: TextStyle(
            fontSize: furniture.furniture.width * 24,
          ),
        ),
        if (furniture.furniture.width >= 1.0)
          Text(
            furniture.furniture.name,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}