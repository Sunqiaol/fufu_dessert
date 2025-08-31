import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E6),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory, color: Colors.brown),
            SizedBox(width: 8),
            Text('Storage'),
          ],
        ),
        backgroundColor: const Color(0xFFFFE4E1),
        foregroundColor: Colors.brown[700],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.cake),
              text: 'Merged Desserts',
            ),
            Tab(
              icon: Icon(Icons.cookie),
              text: 'Crafted Desserts',
            ),
          ],
          labelColor: Colors.brown,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.brown,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Merged Desserts Tab
          _buildMergedDessertsTab(),
          
          // Crafted Desserts Tab  
          _buildCraftedDessertsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Game'),
        backgroundColor: Colors.brown[600],
      ),
    );
  }

  Widget _buildMergedDessertsTab() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        try {
          final storage = gameProvider.storage;
          final availableLevels = storage.getAvailableLevels();
          
          if (availableLevels.isEmpty) {
            return _buildEmptyMergedDesserts();
          }
          
          return Column(
            children: [
              // Storage Stats Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.brown.shade100, Colors.orange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Total Items
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.inventory, size: 32, color: Colors.brown[600]),
                          const SizedBox(height: 4),
                          Text(
                            '${storage.getTotalItems()}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[700],
                            ),
                          ),
                          Text(
                            'Total Items',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.brown[300],
                    ),
                    
                    // Unique Types
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.category, size: 32, color: Colors.brown[600]),
                          const SizedBox(height: 4),
                          Text(
                            '${availableLevels.length}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[700],
                            ),
                          ),
                          Text(
                            'Types',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.brown[300],
                    ),
                    
                    // Estimated Value
                    Expanded(
                      child: Column(
                        children: [
                          Icon(Icons.attach_money, size: 32, color: Colors.brown[600]),
                          const SizedBox(height: 4),
                          Text(
                            '${_calculateTotalValue(storage)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown[700],
                            ),
                          ),
                          Text(
                            'Total Value',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Storage Items Grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: availableLevels.length,
                    itemBuilder: (context, index) {
                      final level = availableLevels[index];
                      final dessert = Dessert.getDessertByLevel(level);
                      final quantity = storage.getQuantity(level);
                      
                      return _buildStorageItemCard(dessert, quantity);
                    },
                  ),
                ),
              ),
            ],
          );
        } catch (e) {
          return _buildErrorState(e.toString());
        }
      },
    );
  }

  Widget _buildCraftedDessertsTab() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        try {
          final storage = gameProvider.storage;
          final availableDessertIds = storage.getAvailableDessertIds();
          
          if (availableDessertIds.isEmpty) {
            return _buildEmptyCraftedDesserts();
          }
          
          return Container(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: availableDessertIds.length,
              itemBuilder: (context, index) {
                final dessertId = availableDessertIds[index];
                final dessert = CraftableDessert.getDessertById(dessertId);
                final quantity = storage.getDessertQuantity(dessertId);
                
                if (dessert == null) return const SizedBox();
                
                return _buildDessertStorageDetailCard(dessert, quantity, gameProvider);
              },
            ),
          );
        } catch (e) {
          return _buildErrorState(e.toString());
        }
      },
    );
  }

  Widget _buildEmptyMergedDesserts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Merged Desserts Stored!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.brown[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              children: [
                Text(
                  '💡 How to Store Merged Desserts:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Go to the Merge Grid tab\\n'
                  '2. Click "Sell Mode" button\\n'
                  '3. Select merged desserts to store\\n'
                  '4. Click "Store" button',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCraftedDesserts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cookie_outlined,
            size: 80,
            color: Colors.brown[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No Crafted Desserts!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.brown[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Column(
              children: [
                Text(
                  '👩‍🍳 How to Craft Desserts:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Collect ingredients from the merge grid\\n'
                  '2. Go to "Craft Desserts" section\\n'
                  '3. Select a recipe you can make\\n'
                  '4. Craft and serve to customers!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDessertStorageCard(CraftableDessert dessert, int quantity) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dessert.color.withOpacity(0.1),
            dessert.color.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dessert.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: dessert.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dessert Emoji with glow effect
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    dessert.color.withOpacity(0.3),
                    dessert.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  dessert.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Dessert Name
            Text(
              dessert.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Value
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💰${dessert.baseValue}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Quantity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'x$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItemCard(Dessert dessert, int quantity) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dessert.color.withOpacity(0.1),
            dessert.color.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dessert.color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: dessert.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dessert Emoji with glow effect
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    dessert.color.withOpacity(0.3),
                    dessert.color.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  dessert.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Dessert Name
            Text(
              dessert.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),
            
            // Level and Value
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: dessert.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lv.${dessert.level}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: dessert.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '💰${dessert.baseValue}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Quantity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'x$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          const Text(
            'Error Loading Storage',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateTotalValue(storage) {
    try {
      int totalValue = 0;
      for (final level in storage.getAvailableLevels()) {
        final dessert = Dessert.getDessertByLevel(level);
        final quantity = storage.getQuantity(level);
        totalValue += (dessert.baseValue * quantity).round();
      }
      return totalValue;
    } catch (e) {
      return 0;
    }
  }

  // New detailed card layout matching crafting page
  Widget _buildDessertStorageDetailCard(CraftableDessert dessert, int quantity, GameProvider gameProvider) {
    return Draggable<Map<String, dynamic>>(
      data: {
        'type': 'crafted_dessert',
        'dessertId': dessert.id,
        'dessert': dessert,
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 0.8,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dessert.color.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dessert.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    dessert.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            dessert.color.withOpacity(0.1),
            dessert.color.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dessert.color.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: dessert.color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Dessert Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        dessert.color.withOpacity(0.3),
                        dessert.color.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: dessert.color.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      dessert.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Dessert Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dessert.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                      Text(
                        dessert.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.brown[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Quantity badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          '📦 Quantity: $quantity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '💰 ${dessert.baseValue} coins each',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Recipe Ingredients (for reference)
            const Text(
              'Recipe:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dessert.requiredIngredients.map((ingredientLevel) {
                final ingredient = Dessert.getDessertByLevel(ingredientLevel);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ingredient.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        'Lv.${ingredient.level}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              dessert.color.withOpacity(0.1),
              dessert.color.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dessert.color.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: dessert.color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Dessert Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          dessert.color.withOpacity(0.3),
                          dessert.color.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: dessert.color.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dessert.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Dessert Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dessert.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown[800],
                          ),
                        ),
                        Text(
                          dessert.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Quantity badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            '📦 Quantity: $quantity',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '💰 ${dessert.baseValue} coins each',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Recipe Ingredients (for reference)
              const Text(
                'Recipe:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dessert.requiredIngredients.map((ingredientLevel) {
                  final ingredient = Dessert.getDessertByLevel(ingredientLevel);
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ingredient.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          'Lv.${ingredient.level}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}