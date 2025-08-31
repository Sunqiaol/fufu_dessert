import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/models/furniture.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/widgets/customer_widget.dart';
import 'package:fufu_dessert2/screens/crafting_screen.dart';
import 'package:fufu_dessert2/screens/settings_screen.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';

class CafeViewWidget extends StatelessWidget {
  const CafeViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<CafeProvider, CustomerProvider, GameProvider>(
      builder: (context, cafeProvider, customerProvider, gameProvider, child) {
        return Stack(
          children: [
            // Cafe grid - now takes full screen
            Positioned.fill(
              child: Center(
                child: Container(
                  width: CafeProvider.gridSize * CafeProvider.cellSize,
                  height: CafeProvider.gridSize * CafeProvider.cellSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF8B4513), width: 3), // Darker brown border
                    gradient: _createCafeFloorPattern(),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Checkered tile pattern overlay
                      CustomPaint(
                        size: Size(
                          CafeProvider.gridSize * CafeProvider.cellSize,
                          CafeProvider.gridSize * CafeProvider.cellSize,
                        ),
                        painter: CafeFloorPainter(),
                      ),
                      
                      // Mouse and touch handling
                      MouseRegion(
                    onHover: (event) {
                      if (cafeProvider.isDragging) {
                        cafeProvider.updateDragPreview(
                          event.localPosition.dx,
                          event.localPosition.dy,
                        );
                      }
                    },
                    child: Listener(
                      onPointerMove: (event) {
                        if (cafeProvider.isDragging) {
                          cafeProvider.updateDragPreview(
                            event.localPosition.dx,
                            event.localPosition.dy,
                          );
                        }
                      },
                      onPointerUp: (event) {
                        if (cafeProvider.isDragging) {
                          cafeProvider.finishDragging();
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          if (cafeProvider.isDragging) {
                            cafeProvider.finishDragging();
                          }
                        },
                        child: Stack(
                        children: [
                          // Grid lines (optional, for debug)
                          if (cafeProvider.isInEditMode)
                            CustomPaint(
                              size: Size(
                                CafeProvider.gridSize * CafeProvider.cellSize,
                                CafeProvider.gridSize * CafeProvider.cellSize,
                              ),
                              painter: GridPainter(),
                            ),
                          
                          // Yellow preview when dragging
                          if (cafeProvider.previewX != null && cafeProvider.previewY != null)
                            Positioned(
                              left: cafeProvider.previewX! * CafeProvider.cellSize,
                              top: cafeProvider.previewY! * CafeProvider.cellSize,
                              child: Container(
                                width: cafeProvider.previewWidth! * CafeProvider.cellSize,
                                height: cafeProvider.previewHeight! * CafeProvider.cellSize,
                                decoration: BoxDecoration(
                                  color: cafeProvider.previewValid 
                                    ? Colors.yellow.withOpacity(0.5)
                                    : Colors.red.withOpacity(0.5),
                                  border: Border.all(
                                    color: cafeProvider.previewValid ? Colors.yellow : Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          
                          // Customers
                          ...customerProvider.customers.map((customer) {
                            return CustomerWidget(
                              customer: customer,
                              onTap: () {
                                // Handle customer tap - serve from storage
                                if (customer.state == CustomerState.ordering) {
                                  final success = customerProvider.serveCustomerFromStorage(customer.id);
                                  
                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '✅ Served ${customer.name}! They wanted: ${customer.getOrderDescription()}',
                                        ),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '❌ Cannot serve ${customer.name}! They want: ${customer.getOrderDescription()}. Check your storage!',
                                        ),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } else {
                                  // Customer is not ordering
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${customer.name} is ${customer.state.name}. Wait for them to order!',
                                      ),
                                      backgroundColor: Colors.blue,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            );
                          }),
                          
                          // Placed furniture
                          ...cafeProvider.placedFurniture.map((furniture) {
                            return SimpleFurnitureWidget(
                              furniture: furniture,
                              isSelected: cafeProvider.selectedFurniture?.id == furniture.id,
                              isInEditMode: cafeProvider.isInEditMode,
                              onTap: () {
                                if (cafeProvider.isInEditMode) {
                                  cafeProvider.selectFurniture(furniture.id);
                                  // Show upgrade dialog if furniture can be upgraded
                                  if (cafeProvider.canUpgradeFurniture(furniture.id)) {
                                    _showUpgradeDialog(context, furniture, gameProvider, cafeProvider);
                                  }
                                }
                              },
                              shouldBounce: furniture.justPlaced ?? false,
                              onDragStart: () {
                                if (cafeProvider.isInEditMode) {
                                  cafeProvider.startDragging(furniture.id);
                                }
                              },
                              onDragUpdate: (globalPosition) {
                                // Convert global position to local position relative to cafe container
                                final RenderBox cafeBox = context.findRenderObject() as RenderBox;
                                final localPosition = cafeBox.globalToLocal(globalPosition);
                                cafeProvider.updateDragPreview(localPosition.dx, localPosition.dy);
                              },
                              onDragEnd: () {
                                cafeProvider.finishDragging();
                              },
                            );
                          }),
                        ],
                        ),
                      ),
                    ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Floating bottom control bar
            _buildFloatingControlBar(context, cafeProvider, gameProvider),
          ],
        );
      },
    );
  }

  // Create a warm wood-like floor gradient
  LinearGradient _createCafeFloorPattern() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFDEB887), // Burlywood
        Color(0xFFD2B48C), // Tan
        Color(0xFFBC9A6A), // Darker tan
        Color(0xFFA0522D), // Sienna
      ],
      stops: [0.0, 0.3, 0.7, 1.0],
    );
  }

  Widget _buildFloatingControlBar(BuildContext context, CafeProvider cafeProvider, GameProvider gameProvider) {
    return Positioned(
      bottom: AppTheme.responsiveSpacing(context, base: 20),
      left: AppTheme.responsiveMargin(context),
      right: AppTheme.responsiveMargin(context),
      child: Container(
        height: AppTheme.responsiveButtonHeight(context) + 16,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFAF0), // Floral white
              Color(0xFFFFF8DC), // Cornsilk
              Color(0xFFFFE4E1), // Misty rose
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Show sell button instead of buy when in edit mode and furniture is selected
            if (cafeProvider.isInEditMode && cafeProvider.selectedFurniture != null)
              _buildPillButton(
                context: context,
                emoji: '💰',
                label: 'Sell',
                color: const Color(0xFFFF5722), // Red/orange for sell
                onPressed: () => _sellSelectedFurniture(context, gameProvider, cafeProvider),
              )
            else
              _buildPillButton(
                context: context,
                emoji: '🛒',
                label: 'Buy',
                color: const Color(0xFFFF8C42), // Softer orange
                onPressed: () => _showFurnitureShop(context, gameProvider, cafeProvider),
              ),
            _buildPillButton(
              context: context,
              emoji: cafeProvider.isInEditMode ? '✅' : '✏️',
              label: cafeProvider.isInEditMode ? 'Done' : 'Edit',
              color: cafeProvider.isInEditMode 
                ? const Color(0xFF4CAF50) // Softer green
                : const Color(0xFF2196F3), // Softer blue
              onPressed: cafeProvider.toggleEditMode,
            ),
            _buildPillButton(
              context: context,
              emoji: '🎂',
              label: 'Craft',
              color: const Color(0xFFE91E63), // Softer pink
              onPressed: () {
                AudioService().playSoundEffect(SoundEffect.buttonPress);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CraftingScreen(),
                  ),
                );
              },
            ),
            _buildPillButton(
              context: context,
              emoji: '⚙️',
              label: 'Settings',
              color: const Color(0xFF607D8B), // Softer gray
              onPressed: () {
                AudioService().playSoundEffect(SoundEffect.buttonPress);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required BuildContext context,
    required String emoji,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.responsiveSpacing(context, base: 8),
          vertical: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(25),
            splashColor: color.withOpacity(0.3),
            highlightColor: color.withOpacity(0.1),
            child: Container(
              height: AppTheme.responsiveButtonHeight(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.85),
                    color,
                    color.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: AppTheme.responsiveFontSize(context, 18),
                    ),
                  ),
                  SizedBox(width: AppTheme.responsiveSpacing(context, base: 4)),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: AppTheme.responsiveFontSize(context, 14),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(0.5, 0.5),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFurnitureShop(BuildContext context, GameProvider gameProvider, CafeProvider cafeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.store, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Furniture Shop'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${gameProvider.coins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Consumer<GameProvider>(
              builder: (context, gp, child) {
                final availableFurniture = _getAvailableFurniture(gp.shopLevel);
                
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableFurniture.length,
                  itemBuilder: (context, index) {
                    final furniture = availableFurniture[index];
                    final canAfford = gp.coins >= furniture.price;
                    final levelMet = gp.shopLevel >= furniture.level;
                    
                    // Check table restrictions
                    bool canBuyTable = true;
                    String? tableRestriction;
                    if (furniture.type == FurnitureType.table || furniture.type == FurnitureType.seating) {
                      final currentTables = cafeProvider.tableCount;
                      final maxTables = cafeProvider.getMaxTablesForLevel(gp.shopLevel);
                      if (currentTables >= maxTables) {
                        canBuyTable = false;
                        tableRestriction = 'Max tables reached';
                      }
                    }
                    
                    final canBuy = canAfford && levelMet && canBuyTable;
                    
                    return Card(
                      elevation: canBuy ? 4 : 1,
                      color: canBuy ? null : Colors.grey[300],
                      child: InkWell(
                        onTap: canBuy ? () {
                          _buyFurniture(context, furniture, gp, cafeProvider);
                        } : null,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Furniture emoji
                              Text(
                                furniture.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 8),
                              
                              // Furniture name
                              Text(
                                furniture.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: canBuy ? Colors.black : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              
                              // Price
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: canAfford ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${furniture.price} coins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Seating capacity (for tables)
                              if (furniture.seatingCapacity > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${furniture.seatingCapacity} seats',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              
                              // Level requirement
                              if (furniture.level > 1)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: levelMet ? Colors.blue : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Level ${furniture.level}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              
                              // Table restriction warning
                              if (tableRestriction != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tableRestriction,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              
                              // Attraction bonus
                              const SizedBox(height: 4),
                              Text(
                                '+${furniture.attractionBonus} attraction',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<Furniture> _getAvailableFurniture(int shopLevel) {
    // Return furniture that can be unlocked at current level or below
    return Furniture.furnitureItems
        .where((furniture) => furniture.level <= shopLevel + 2) // Show 2 levels ahead
        .toList();
  }

  void _buyFurniture(BuildContext context, Furniture furniture, GameProvider gameProvider, CafeProvider cafeProvider) {
    // Check table purchase restrictions
    if (furniture.type == FurnitureType.table || furniture.type == FurnitureType.seating) {
      final currentTables = cafeProvider.tableCount;
      final maxTables = cafeProvider.getMaxTablesForLevel(gameProvider.shopLevel);
      
      if (currentTables >= maxTables) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum tables reached! Need level ${((currentTables - 2) * 3) + 4} to buy more tables.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    if (gameProvider.coins >= furniture.price && gameProvider.shopLevel >= furniture.level) {
      // Deduct coins
      gameProvider.spendCoins(furniture.price);
      
      // Add furniture to cafe (find empty spot)
      _placeFurnitureInEmptySpot(cafeProvider, furniture);
      
      // Show success message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${furniture.name} purchased! 🎉'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showUpgradeDialog(BuildContext context, PlacedFurniture furniture, GameProvider gameProvider, CafeProvider cafeProvider) {
    final upgradeFurniture = cafeProvider.getUpgradeFurniture(furniture.id);
    if (upgradeFurniture == null) return;
    
    final canAfford = gameProvider.coins >= furniture.furniture.upgradePrice;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upgrade ${furniture.furniture.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current: ${furniture.furniture.emoji} ${furniture.furniture.name}'),
              Text('Capacity: ${furniture.furniture.seatingCapacity} people'),
              const SizedBox(height: 10),
              Text('Upgrade to: ${upgradeFurniture.emoji} ${upgradeFurniture.name}'),
              Text('New Capacity: ${upgradeFurniture.seatingCapacity} people'),
              Text('Attraction: ${upgradeFurniture.attractionBonus} (+${upgradeFurniture.attractionBonus - furniture.furniture.attractionBonus})'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: canAfford ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cost: ${furniture.furniture.upgradePrice} coins',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: canAfford ? () {
                gameProvider.spendCoins(furniture.furniture.upgradePrice);
                cafeProvider.upgradeFurniture(furniture.id, upgradeFurniture);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upgraded to ${upgradeFurniture.name}! +${upgradeFurniture.seatingCapacity - furniture.furniture.seatingCapacity} seats'),
                    backgroundColor: Colors.green,
                  ),
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }

  void _sellSelectedFurniture(BuildContext context, GameProvider gameProvider, CafeProvider cafeProvider) {
    final selectedFurniture = cafeProvider.selectedFurniture;
    if (selectedFurniture == null) return;
    
    final sellPrice = (selectedFurniture.furniture.price * 0.5).round();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sell ${selectedFurniture.furniture.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${selectedFurniture.furniture.emoji} ${selectedFurniture.furniture.name}'),
              const SizedBox(height: 10),
              Text('Original Price: ${selectedFurniture.furniture.price} coins'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You\'ll receive: $sellPrice coins (50%)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to sell this furniture?',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final actualSellPrice = cafeProvider.sellFurniture(selectedFurniture.id);
                gameProvider.earnCoins(actualSellPrice);
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sold ${selectedFurniture.furniture.name} for $actualSellPrice coins!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                AudioService().playSoundEffect(SoundEffect.coin);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sell', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _placeFurnitureInEmptySpot(CafeProvider cafeProvider, Furniture furniture) {
    // Try to find an empty spot in the cafe
    for (int y = 0; y < 15; y++) {  // Try various positions
      for (int x = 0; x < 15; x++) {
        final worldX = x * 0.5;
        final worldY = y * 0.5;
        
        // Check if this position is valid
        final gridX = (worldX / 0.5).round();
        final gridY = (worldY / 0.5).round();
        final width = (furniture.width / 0.5).round();
        final height = (furniture.height / 0.5).round();
        
        if (cafeProvider.isValidPosition(gridX, gridY, width, height, '')) {
          // Found a valid spot, place the furniture
          final placedFurniture = PlacedFurniture(
            id: 'furniture_${DateTime.now().millisecondsSinceEpoch}',
            furniture: furniture,
            x: worldX,
            y: worldY,
            justPlaced: true,
          );
          
          cafeProvider.addNewFurniture(placedFurniture);
          
          // Reset bounce flag after animation
          Future.delayed(const Duration(milliseconds: 600), () {
            final index = cafeProvider.placedFurniture.indexWhere((f) => f.id == placedFurniture.id);
            if (index != -1) {
              cafeProvider.placedFurniture[index] = placedFurniture.copyWith(justPlaced: false);
              cafeProvider.notifyListeners();
            }
          });
          
          return;
        }
      }
    }
  }
}

// Extension to add helper methods to CafeProvider
extension CafeProviderExtensions on CafeProvider {
  bool isValidPosition(int gridX, int gridY, int width, int height, String excludeId) {
    return isValidPositionPublic(gridX, gridY, width, height, excludeId);
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (int i = 0; i <= CafeProvider.gridSize; i++) {
      final x = i * CafeProvider.cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= CafeProvider.gridSize; i++) {
      final y = i * CafeProvider.cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SimpleFurnitureWidget extends StatelessWidget {
  final PlacedFurniture furniture;
  final bool isSelected;
  final bool isInEditMode;
  final bool shouldBounce;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final Function(Offset)? onDragUpdate;
  final VoidCallback? onDragEnd;

  // Cache common gradients for performance
  static final Map<String, Gradient> _gradientCache = <String, Gradient>{};
  
  static Gradient _getGradient(String key, List<Color> colors) {
    return _gradientCache.putIfAbsent(key, () => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ));
  }

  const SimpleFurnitureWidget({
    super.key,
    required this.furniture,
    required this.isSelected,
    required this.isInEditMode,
    this.shouldBounce = false,
    required this.onTap,
    required this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: furniture.x * (CafeProvider.cellSize / 0.5), // Convert world to pixels (0.5 scale system)
      top: furniture.y * (CafeProvider.cellSize / 0.5),  // Convert world to pixels (0.5 scale system)
      child: BounceAnimation(
        shouldBounce: shouldBounce,
        child: GestureDetector(
            onTap: onTap,
            onPanStart: (details) {
              if (isInEditMode && isSelected) {
                onDragStart();
                print('Started dragging furniture: ${furniture.id}');
              }
            },
            onPanUpdate: (details) {
              if (isInEditMode && isSelected && onDragUpdate != null) {
                print('Pan update: ${details.globalPosition}');
                onDragUpdate!(details.globalPosition);
              }
            },
            onPanEnd: (details) {
              if (isInEditMode && isSelected && onDragEnd != null) {
                print('Pan ended');
                onDragEnd!();
              }
            },
            child: Container(
              width: furniture.furniture.width * (CafeProvider.cellSize / 0.5),
              height: furniture.furniture.height * (CafeProvider.cellSize / 0.5),
              child: Consumer<CustomerProvider>(
                builder: (context, customerProvider, child) {
                  // Calculate table occupancy with null safety
                  final isSeatingFurniture = furniture.furniture.seatingCapacity > 0;
                  int occupancy = 0;
                  
                  try {
                    if (isSeatingFurniture && customerProvider.customers.isNotEmpty) {
                      occupancy = customerProvider.customers.where((c) => 
                        c.assignedTableId == furniture.id
                      ).length;
                    }
                  } catch (e) {
                    debugPrint('Error calculating table occupancy: $e');
                    occupancy = 0;
                  }
                  
                  return _buildIsometricFurniture(context, customerProvider, isSeatingFurniture, occupancy);
                },
              ),
        ),
      )),
    );
  }

  Widget _buildIsometricFurniture(BuildContext context, CustomerProvider customerProvider, bool isSeatingFurniture, int occupancy) {
    // Cache expensive calculations
    final borderRadius = BorderRadius.circular(12);
    final selectedBorder = isSelected && isInEditMode 
        ? Border.all(color: Colors.yellow, width: 3)
        : null;
    
    return Stack(
      children: [
        // Main isometric furniture body
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: selectedBorder,
          ),
          child: Stack(
            children: [
              // Furniture base/shadow
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.only(top: 4, left: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              // Main furniture body
              Container(
                margin: const EdgeInsets.only(bottom: 4, right: 4),
                decoration: BoxDecoration(
                  gradient: _getFurnitureGradient(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getFurnitureBorderColor(),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Furniture details/pattern
                    _buildFurnitureDetails(),
                    
                    // Customers sitting (if seating furniture)
                    if (isSeatingFurniture && occupancy > 0)
                      ..._buildSittingCustomers(occupancy),
                  ],
                ),
              ),
              
              // Furniture label
              if (furniture.furniture.width >= 1.0)
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      furniture.furniture.name,
                      style: const TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Table occupancy indicator
        if (isSeatingFurniture)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: occupancy == 0 
                  ? Colors.green.withOpacity(0.9)
                  : occupancy >= furniture.furniture.seatingCapacity
                    ? Colors.red.withOpacity(0.9) 
                    : Colors.orange.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Text(
                '$occupancy/${furniture.furniture.seatingCapacity}',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  LinearGradient _getFurnitureGradient() {
    final furnitureType = furniture.furniture.name.toLowerCase();
    
    if (furnitureType.contains('table')) {
      // Table gradient - warm wood tones
      return _getGradient('table', const [
        Color(0xFFD2B48C), // Tan
        Color(0xFFA0522D), // Sienna
        Color(0xFF8B4513), // Saddle brown
      ]) as LinearGradient;
    } else if (furnitureType.contains('chair')) {
      // Chair gradient - fabric colors
      return _getGradient('chair', const [
        Color(0xFFDDA0DD), // Plum
        Color(0xFFBA55D3), // Medium orchid
        Color(0xFF9370DB), // Medium purple
      ]) as LinearGradient;
    } else if (furnitureType.contains('register')) {
      // Register gradient - metallic
      return _getGradient('register', const [
        Color(0xFFE6E6FA), // Lavender
        Color(0xFFD3D3D3), // Light gray
        Color(0xFFA9A9A9), // Dark gray
      ]) as LinearGradient;
    } else {
      // Default furniture gradient - don't cache as colors are dynamic
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          furniture.furniture.color.withOpacity(0.8),
          furniture.furniture.color,
          furniture.furniture.color.withOpacity(0.6),
        ],
      );
    }
  }

  Color _getFurnitureBorderColor() {
    final furnitureType = furniture.furniture.name.toLowerCase();
    
    if (furnitureType.contains('table')) {
      return const Color(0xFF654321); // Dark brown
    } else if (furnitureType.contains('chair')) {
      return const Color(0xFF4B0082); // Indigo
    } else if (furnitureType.contains('register')) {
      return const Color(0xFF708090); // Slate gray
    } else {
      return Colors.brown[600] ?? Colors.brown;
    }
  }

  Widget _buildFurnitureDetails() {
    final furnitureType = furniture.furniture.name.toLowerCase();
    
    if (furnitureType.contains('table')) {
      return _buildTableDetails();
    } else if (furnitureType.contains('chair')) {
      return _buildChairDetails();
    } else if (furnitureType.contains('register')) {
      return _buildRegisterDetails();
    } else {
      return _buildDefaultDetails();
    }
  }

  Widget _buildTableDetails() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5DEB3).withOpacity(0.6), // Wheat color for table surface
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDEB887), width: 1), // Burlywood border
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFF5DEB3).withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Center(
          child: Icon(
            Icons.table_restaurant,
            color: Color(0xFF8B4513),
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildChairDetails() {
    return Container(
      margin: const EdgeInsets.all(6),
      child: Column(
        children: [
          // Chair back
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDDA0DD).withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: const Color(0xFF9370DB), width: 1),
              ),
            ),
          ),
          // Chair seat
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFBA55D3).withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF8B008B), width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.chair,
                  color: Color(0xFF4B0082),
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterDetails() {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Register screen
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF000000).withOpacity(0.8),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF696969), width: 1),
              ),
              child: const Center(
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Register base
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFD3D3D3).withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF808080), width: 1),
              ),
              child: const Center(
                child: Icon(
                  Icons.point_of_sale,
                  color: Color(0xFF2F4F4F),
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultDetails() {
    // Special case for basic display case - use custom image
    if (furniture.furniture.id == 'display_case_1') {
      return Container(
        margin: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: Image.asset(
                'assets/images/Display_1.jpg',
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to emoji if image fails to load
                  return Container(
                    width: 100,
                    height: 50, // 2:1 aspect ratio
                    color: furniture.furniture.color.withValues(alpha: 0.3),
                    child: Center(
                      child: Text(
                        furniture.furniture.emoji,
                        style: TextStyle(
                          fontSize: (furniture.furniture.width * 12).clamp(12, 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }
    
    // Default emoji display for other furniture
    return Center(
      child: Text(
        furniture.furniture.emoji,
        style: TextStyle(
          fontSize: (furniture.furniture.width * 12).clamp(12, 24),
        ),
      ),
    );
  }

  List<Widget> _buildSittingCustomers(int occupancy) {
    List<Widget> customers = [];
    final tableSize = furniture.furniture.seatingCapacity;
    
    for (int i = 0; i < occupancy; i++) {
      // Position customers around the table
      double xOffset = 0.0;
      double yOffset = 0.0;
      
      if (tableSize == 2) {
        // 2-person table: customers sit opposite
        xOffset = i == 0 ? 0.2 : 0.8;
        yOffset = 0.5;
      } else if (tableSize == 4) {
        // 4-person table: customers sit on all sides
        switch (i) {
          case 0: xOffset = 0.5; yOffset = 0.1; break; // Top
          case 1: xOffset = 0.9; yOffset = 0.5; break; // Right
          case 2: xOffset = 0.5; yOffset = 0.9; break; // Bottom
          case 3: xOffset = 0.1; yOffset = 0.5; break; // Left
        }
      } else {
        // Default positioning for other table sizes
        xOffset = (i % 2 == 0) ? 0.3 : 0.7;
        yOffset = (i < 2) ? 0.3 : 0.7;
      }
      
      customers.add(
        Positioned(
          left: (furniture.furniture.width * (CafeProvider.cellSize / 0.5)) * xOffset - 8,
          top: (furniture.furniture.height * (CafeProvider.cellSize / 0.5)) * yOffset - 8,
          child: _buildAnimatedCustomer(i),
        ),
      );
    }
    
    return customers;
  }

  Widget _buildAnimatedCustomer(int customerIndex) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.8, end: 1.1),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getCustomerColor(customerIndex),
                  _getCustomerColor(customerIndex).withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 12,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Color _getCustomerColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}

// Custom painter for cafe floor checkered tile pattern
class CafeFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 40.0; // Size of each tile
    
    // Create paint objects for different tile colors
    final paint1 = Paint()
      ..color = const Color(0xFFF5DEB3).withOpacity(0.3) // Wheat - lighter tile
      ..style = PaintingStyle.fill;
      
    final paint2 = Paint()
      ..color = const Color(0xFFDEB887).withOpacity(0.4) // Burlywood - darker tile  
      ..style = PaintingStyle.fill;
      
    final groutPaint = Paint()
      ..color = const Color(0xFFA0522D).withOpacity(0.1) // Sienna - grout lines
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Calculate number of tiles
    final tilesX = (size.width / tileSize).ceil();
    final tilesY = (size.height / tileSize).ceil();

    // Draw checkered pattern
    for (int x = 0; x < tilesX; x++) {
      for (int y = 0; y < tilesY; y++) {
        final rect = Rect.fromLTWH(
          x * tileSize,
          y * tileSize,
          tileSize,
          tileSize,
        );

        // Alternate between two tile colors in checkerboard pattern
        final paint = (x + y) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(rect, paint);
        
        // Add subtle wood grain texture within each tile
        _drawWoodGrain(canvas, rect, paint);
        
        // Draw grout lines
        canvas.drawRect(rect, groutPaint);
      }
    }
  }
  
  void _drawWoodGrain(Canvas canvas, Rect rect, Paint basePaint) {
    final grainPaint = Paint()
      ..color = basePaint.color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw subtle horizontal wood grain lines
    final grainLines = 3;
    for (int i = 1; i <= grainLines; i++) {
      final y = rect.top + (rect.height * i) / (grainLines + 1);
      canvas.drawLine(
        Offset(rect.left + 2, y),
        Offset(rect.right - 2, y),
        grainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

