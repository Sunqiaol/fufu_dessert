import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/models/furniture.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/widgets/merge_grid_widget.dart';
import 'package:fufu_dessert2/screens/crafting_screen.dart';
import 'package:fufu_dessert2/screens/tutorial_screen.dart';
import 'package:fufu_dessert2/screens/empty_view_screen.dart';
import 'package:fufu_dessert2/screens/isometric_cafe_view.dart';
import 'package:fufu_dessert2/services/tutorial_service.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';
import 'package:fufu_dessert2/widgets/floating_orders_widget.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _storageHintController;
  late Animation<double> _storageHintAnimation;

  // Track ingredients dropped on each customer for auto-crafting
  Map<String, List<int>> _customerIngredients = {};

  @override
  void initState() {
    super.initState();

    // Initialize storage hint animation
    _storageHintController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _storageHintAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _storageHintController, curve: Curves.easeInOut),
    );
    
    // Start subtle pulsing animation
    _storageHintController.repeat(reverse: true);
    
    // Start background music
    _startBackgroundMusic();
    
    // Check if this is the first time playing and show tutorial
    _checkFirstTimeUser();
    
    // Connect providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final cafeProvider = Provider.of<CafeProvider>(context, listen: false);
      
      // Customer payment callback
      customerProvider.onCustomerServedCallback = (payment, wasHappy) {
        gameProvider.earnCoins(payment);
      };
      
      // Shop level upgrade callback - update customer capacity
      gameProvider.onShopLevelChanged = (newLevel) {
        customerProvider.updateShopLevel(newLevel);
      };
      
      // Initialize customer provider with current game level
      customerProvider.updateShopLevel(gameProvider.shopLevel);
      
      // Fallback sync mechanism - CustomerProvider can check GameProvider's actual level
      customerProvider.getCurrentShopLevelCallback = () => gameProvider.shopLevel;
      
      // Connect store open/close state
      customerProvider.getIsStoreOpenCallback = () => gameProvider.isStoreOpen;
      
      // Connect customer timeout penalty system
      customerProvider.onCustomerTimeoutCallback = (patienceRemaining) {
        gameProvider.applyCustomerTimeoutPenalty(patienceRemaining);
      };
      
      // Connect furniture attraction and seating capacity to customer system with null safety
      customerProvider.getFurnitureAttraction = () {
        try {
          return cafeProvider.totalAttractionBonus;
        } catch (e) {
          debugPrint('Error getting furniture attraction: $e');
          return 0;
        }
      };
      customerProvider.getSeatingCapacity = () {
        try {
          return cafeProvider.totalSeatingCapacity;
        } catch (e) {
          debugPrint('Error getting seating capacity: $e');
          return 8; // Default capacity
        }
      };
      customerProvider.getSeatingFurniture = () {
        try {
          return cafeProvider.placedFurniture;
        } catch (e) {
          debugPrint('Error getting seating furniture: $e');
          return <PlacedFurniture>[];
        }
      };
      
      // Connect seating capacity change notifications
      cafeProvider.onSeatingCapacityChanged = () {
        customerProvider.updateSeatingCapacity();
      };
      
      // Connect merged dessert serving from storage
      customerProvider.serveDessertCallback = (int dessertLevel) {
        try {
          return gameProvider.serveDessertFromStorage(dessertLevel);
        } catch (e) {
          debugPrint('Error serving merged dessert from storage: $e');
          return false;
        }
      };
      
      // Connect crafted dessert serving from storage
      customerProvider.serveCraftedDessertCallback = (int dessertId) {
        try {
          return gameProvider.serveCraftedDessert(dessertId);
        } catch (e) {
          debugPrint('Error serving crafted dessert from storage: $e');
          return false;
        }
      };
      
      // Connect storage availability checks for auto-feeding crafted desserts only
      customerProvider.hasStorageCraftedItemCallback = (int dessertId) {
        try {
          return gameProvider.storage.hasCraftedDessert(dessertId);
        } catch (e) {
          debugPrint('Error checking storage for crafted dessert $dessertId: $e');
          return false;
        }
      };
      
      // Initialize customer provider with current shop level
      customerProvider.updateShopLevel(gameProvider.shopLevel);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set context for GameProvider once after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.setContext(context);
    });
  }
  
  void _startBackgroundMusic() async {
    try {
      final audioService = AudioService();
      await audioService.playBackgroundMusic();
    } catch (e) {
    }
  }

  void _checkFirstTimeUser() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      final hasSeenTutorial = false; // Always show first time tutorial
      if (!hasSeenTutorial && mounted) {
        _showFirstTimeTutorialDialog();
      }
    }
  }

  void _showFirstTimeTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Text('🎉', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome to Fufu Dessert!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ready to start your dessert café adventure?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'This game involves merging ingredients, crafting desserts, and serving customers. Would you like to see a quick tutorial?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Tutorial marked as seen
                Navigator.of(context).pop();
              },
              child: const Text('Skip Tutorial'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Tutorial marked as seen
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TutorialScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Tutorial'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _storageHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.gameBackground,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
            // Currency & Level Section
            Container(
              height: AppTheme.responsiveTopBarHeight(context),
              margin: EdgeInsets.fromLTRB(
                AppTheme.responsiveMargin(context),
                AppTheme.responsiveSpacing(context, base: 4), 
                AppTheme.responsiveMargin(context), 
                AppTheme.responsiveSpacing(context)
              ),
              child: _buildCurrencyLevelBar(context),
            ),
            
            // Floating Orders Display - 11% of screen height (compact but functional)
            Container(
              height: MediaQuery.of(context).size.height * 0.11, // Reduced to 11% to not block board
              margin: EdgeInsets.symmetric(
                horizontal: AppTheme.responsiveMargin(context), 
                vertical: AppTheme.responsiveSpacing(context, base: 3)
              ),
              child: Consumer2<CustomerProvider, GameProvider>(
                builder: (context, customerProvider, gameProvider, child) {
                  final orderingCustomers = customerProvider.getOrderingCustomers();
                  return FloatingOrdersWidget(
                    orderingCustomers: orderingCustomers,
                    onCustomerTap: (customer) => _showServeDialog(context, customer),
                    onItemDropped: (customer, dragData) => _handleItemDrop(context, customer, dragData, gameProvider, customerProvider),
                    customerIngredients: _customerIngredients,
                  );
                },
              ),
            ),
            
            // Main Content
            Expanded(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.responsiveMargin(context),
                  AppTheme.responsiveSpacing(context),
                  AppTheme.responsiveMargin(context),
                  AppTheme.responsiveSpacing(context, base: 4)
                ), // Responsive spacing system
                child: Column(
                  children: [
                    // Grid - takes most space
                    Expanded(
                      flex: 8,
                      child: const MergeGridWidget(),
                    ),

                    // Bottom controls area - compressed height
                    Flexible(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Craft Button - Full Width
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                AppTheme.responsiveMargin(context),
                                AppTheme.responsiveSpacing(context),
                                AppTheme.responsiveMargin(context),
                                AppTheme.responsiveSpacing(context, base: 4)
                              ),
                              child: CuteButton(
                                text: 'Craft',
                                icon: Icons.construction,
                                gradient: const LinearGradient(colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)]),
                                onPressed: () {
                                  AudioService().playSoundEffect(SoundEffect.buttonPress);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const CraftingScreen(),
                                    ),
                                  );
                                },
                                height: AppTheme.responsiveButtonHeight(context),
                              ),
                            ),

                            // Empty View Button
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                AppTheme.responsiveMargin(context),
                                AppTheme.responsiveSpacing(context),
                                AppTheme.responsiveMargin(context),
                                AppTheme.responsiveSpacing(context, base: 4)
                              ),
                              child: CuteButton(
                                text: 'Empty View',
                                icon: Icons.visibility,
                                gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                                onPressed: () {
                                  AudioService().playSoundEffect(SoundEffect.buttonPress);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const EmptyViewScreen(),
                                    ),
                                  );
                                },
                                height: AppTheme.responsiveButtonHeight(context),
                              ),
                            ),

                            // Cafe View Button
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                AppTheme.responsiveMargin(context),
                                AppTheme.responsiveSpacing(context),
                                AppTheme.responsiveMargin(context),
                                AppTheme.responsiveSpacing(context, base: 4)
                              ),
                              child: CuteButton(
                                text: 'Cafe View',
                                icon: Icons.store,
                                gradient: const LinearGradient(colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)]),
                                onPressed: () {
                                  AudioService().playSoundEffect(SoundEffect.buttonPress);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const IsometricCafeView(),
                                    ),
                                  );
                                },
                                height: AppTheme.responsiveButtonHeight(context),
                              ),
                            ),

                            // Selection Info
                            Consumer<GameProvider>(
                              builder: (context, gameProvider, child) {
                                if (gameProvider.isSellMode) {
                                  return Container(
                                    padding: EdgeInsets.fromLTRB(
                                      AppTheme.responsiveMargin(context),
                                      AppTheme.responsiveSpacing(context, base: 4),
                                      AppTheme.responsiveMargin(context),
                                      AppTheme.responsiveSpacing(context)
                                    ), // Responsive spacing
                                    child: const Text(
                                      '💰 Select ingredients to store!',
                                      style: TextStyle(fontSize: 10, color: Colors.green),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
                ),
              
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemDrop(BuildContext context, Customer customer, Map<String, dynamic> dragData, GameProvider gameProvider, CustomerProvider customerProvider) {
    // Check if this is a crafted dessert from storage
    if (dragData['type'] == 'crafted_dessert') {
      _serveCraftedDessertDirectly(context, customer, dragData, gameProvider, customerProvider);
      return;
    }
    
    // Handle grid desserts
    final draggedLevel = dragData['level'] as int;
    
    // Initialize customer ingredient list if not exists
    _customerIngredients[customer.id] ??= [];
    
    // Check if the dropped item matches the customer's order directly
    bool canServeDirectly = false;
    
    if (customer.orderType == OrderType.mergedDessert && customer.orderLevel != null) {
      canServeDirectly = draggedLevel == customer.orderLevel;
    }
    
    if (canServeDirectly) {
      // Direct serving for merged desserts from grid
      _serveDessertDirectly(context, customer, dragData, gameProvider, customerProvider);
    } else if (customer.orderType == OrderType.craftedDessert) {
      // Auto-crafting system for crafted desserts
      _handleIngredientDrop(context, customer, dragData, gameProvider, customerProvider);
    } else {
      // Item doesn't match customer's order
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${customer.name} doesn\'t want Level $draggedLevel dessert'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _serveDessertDirectly(BuildContext context, Customer customer, Map<String, dynamic> dragData, GameProvider gameProvider, CustomerProvider customerProvider) {
    final draggedLevel = dragData['level'] as int;
    final x = dragData['x'] as int;
    final y = dragData['y'] as int;
    
    // Remove the item from the grid
    final originalDessert = gameProvider.grid[y][x];
    gameProvider.grid[y][x] = null;
    gameProvider.notifyListeners(); // Update UI first
    
    // Check if the customer wants this dessert level
    bool canServe = false;
    if (customer.orderType == OrderType.mergedDessert && customer.orderLevel == draggedLevel) {
      canServe = true;
    }
    
    if (canServe) {
      // Use the new direct serving method
      final success = customerProvider.serveCustomerDirectly(customer.id, draggedLevel);
      
      if (success) {
        // Show success message (sound is already played by the customer provider)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Served ${customer.name} ${customer.emoji} with Level $draggedLevel dessert!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refill the grid space after successful serving
        gameProvider.generateRandomDessert();
      } else {
        // Put the item back if serving failed
        gameProvider.grid[y][x] = originalDessert;
        gameProvider.notifyListeners();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Could not serve this customer right now'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Put the item back if serving failed
      gameProvider.grid[y][x] = originalDessert;
      gameProvider.notifyListeners();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Could not serve this customer right now'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    // Save game state
    gameProvider.saveGameStateImmediate();
  }

  void _serveCraftedDessertDirectly(BuildContext context, Customer customer, Map<String, dynamic> dragData, GameProvider gameProvider, CustomerProvider customerProvider) {
    final dessertId = dragData['dessertId'] as int;
    final dessert = dragData['dessert'] as CraftableDessert;
    
    // Check if customer wants this specific crafted dessert
    bool canServe = false;
    if (customer.orderType == OrderType.craftedDessert && customer.orderCraftedDessertId == dessertId) {
      canServe = true;
    }
    
    if (canServe) {
      // Try to serve the crafted dessert from storage
      final success = customerProvider.serveCustomerFromStorage(customer.id);
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Served ${customer.name} ${customer.emoji} with ${dessert.name}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Could not serve this customer right now'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Customer doesn't want this dessert
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${customer.name} doesn\'t want ${dessert.name}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleIngredientDrop(BuildContext context, Customer customer, Map<String, dynamic> dragData, GameProvider gameProvider, CustomerProvider customerProvider) {
    final draggedLevel = dragData['level'] as int;
    final x = dragData['x'] as int;
    final y = dragData['y'] as int;
    
    
    // Add ingredient to this customer's collection
    _customerIngredients[customer.id]!.add(draggedLevel);
    
    
    // Remove the item from the grid and add new random item
    gameProvider.grid[y][x] = null;
    gameProvider.generateRandomDessert();
    gameProvider.notifyListeners();
    
    // Check if we have all ingredients for any craftable dessert that matches this customer's order
    CraftableDessert? craftableDessert;
    if (customer.orderCraftedDessertId != null) {
      craftableDessert = CraftableDessert.dessertRecipes.firstWhere(
        (recipe) => recipe.id == customer.orderCraftedDessertId,
        orElse: () => CraftableDessert.dessertRecipes.first,
      );
    }
    
    if (craftableDessert != null && _hasAllIngredients(_customerIngredients[customer.id]!, craftableDessert.requiredIngredients)) {
      // We have all ingredients! Auto-craft and serve
      _autoCraftAndServe(context, customer, craftableDessert, gameProvider, customerProvider);
    } else {
      // Show feedback about collected ingredient
      final dessert = Dessert.getDessertByLevel(draggedLevel);
      final collected = _customerIngredients[customer.id]!.length;
      final needed = craftableDessert?.requiredIngredients.length ?? 0;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📦 Collected ${dessert.name} for ${customer.name} ($collected/$needed ingredients)'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 1),
        ),
      );
    }
    
    // Save game state
    gameProvider.saveGameStateImmediate();
  }

  bool _hasAllIngredients(List<int> collectedIngredients, List<int> requiredIngredients) {
    
    // Create a copy of required ingredients to track what we still need
    List<int> remainingRequired = List.from(requiredIngredients);
    
    // Check each collected ingredient
    for (int ingredient in collectedIngredients) {
      remainingRequired.remove(ingredient);
    }
    
    
    // If no ingredients remain, we have everything
    return remainingRequired.isEmpty;
  }

  void _autoCraftAndServe(BuildContext context, Customer customer, CraftableDessert craftableDessert, GameProvider gameProvider, CustomerProvider customerProvider) {
    // Get collected ingredients before clearing
    final collectedIngredients = _customerIngredients[customer.id] ?? [];
    
    // Clear the customer's ingredient collection
    _customerIngredients[customer.id] = [];
    
    // Since crafting now takes from grid directly, we need to place ingredients back in grid temporarily
    // Find empty spots and place ingredients, then craft
    List<Map<String, int>> placedIngredients = [];
    
    for (final ingredientLevel in collectedIngredients) {
      // Find an empty spot in the grid
      bool placed = false;
      for (int row = 0; row < 10 && !placed; row++) {
        for (int col = 0; col < 7 && !placed; col++) {
          if (gameProvider.grid[row][col] == null) {
            // Create a temporary grid dessert
            final dessert = Dessert.getDessertByLevel(ingredientLevel);
            gameProvider.grid[row][col] = GridDessert(
              id: DateTime.now().millisecondsSinceEpoch + col + row * 7, // Unique temporary ID
              dessert: dessert,
              gridX: col,
              gridY: row,
            );
            placedIngredients.add({'row': row, 'col': col, 'level': ingredientLevel});
            placed = true;
          }
        }
      }
    }
    
    
    // Now craft the dessert (this will remove ingredients from grid)
    final success = gameProvider.craftDessert(craftableDessert.id);
    
    
    if (success) {
      // Try to serve the crafted dessert
      final serveSuccess = customerProvider.serveCustomerFromStorage(customer.id);
      
      if (serveSuccess) {
        // Success! Play sound and show message
        AudioService().playSoundEffect(SoundEffect.craft);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Auto-crafted and served ${craftableDessert.name} ${craftableDessert.emoji} to ${customer.name}!'),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Crafting succeeded but serving failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Crafted ${craftableDessert.name} but couldn\'t serve ${customer.name}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Crafting failed - put ingredients back
      for (final placed in placedIngredients) {
        gameProvider.grid[placed['row']!][placed['col']!] = null;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to craft dessert'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    gameProvider.notifyListeners();
  }

  void _showServeDialog(BuildContext context, customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Serve ${customer.name} ${customer.emoji}'),
          content: Text('They want: ${customer.getOrderDescription()}\nSelect what to serve:'),
          actions: List.generate(10, (index) {
            final level = index + 1;
            return TextButton(
              onPressed: () {
                Provider.of<CustomerProvider>(context, listen: false)
                    .serveCustomer(customer.id, level);
                Navigator.of(context).pop();
              },
              child: Text('Level $level'),
            );
          }),
        );
      },
    );
  }

  Widget _buildCurrencyLevelBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsivePadding(context, small: 8, large: 12), 
        vertical: AppTheme.responsivePadding(context, small: 4, large: 6)
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gold/Coins
          Expanded(
            flex: 3,
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) => _buildCurrencyItem(
                context,
                Icons.monetization_on,
                '${gameProvider.coins}',
                Colors.amber,
                'Gold'
              ),
            ),
          ),
          
          // Level with Progress Bar
          Expanded(
            flex: 4,
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                return _buildLevelProgress(
                  context,
                  gameProvider,
                  gameProvider.shopLevel,
                  gameProvider.getShopExperience(), 
                  gameProvider.getRequiredExperience()
                );
              },
            ),
          ),
          
          // Hearts/Energy (Customer capacity)
          Expanded(
            flex: 3,
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) => _buildCurrencyItem(
                context,
                Icons.favorite,
                '${customerProvider.customers.length}/${customerProvider.maxCustomers}',
                Colors.pink,
                'Customers'
              ),
            ),
          ),
          
          // Store Open/Close Toggle
          Expanded(
            flex: 3,
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: gameProvider.canToggleStore ? gameProvider.toggleStore : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gameProvider.isStoreOpen 
                          ? [Colors.green.shade600, Colors.green.shade800]
                          : [Colors.red.shade600, Colors.red.shade800],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gameProvider.canToggleStore ? Colors.white : Colors.grey,
                        width: gameProvider.canToggleStore ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (gameProvider.isStoreOpen ? Colors.green : Colors.red).withValues(alpha: gameProvider.canToggleStore ? 0.6 : 0.3),
                          blurRadius: gameProvider.canToggleStore ? 8 : 4,
                          spreadRadius: gameProvider.canToggleStore ? 2 : 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          gameProvider.isStoreOpen ? Icons.store : Icons.lock,
                          color: gameProvider.canToggleStore ? Colors.white : Colors.grey.shade300,
                          size: 18,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          gameProvider.isStoreOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            color: gameProvider.canToggleStore ? Colors.white : Colors.grey.shade300,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyItem(BuildContext context, IconData icon, String value, Color color, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsivePadding(context, small: 6, large: 8), 
        vertical: AppTheme.responsivePadding(context, small: 4, large: 6)
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppTheme.responsiveFontSize(context, 20)),
          SizedBox(height: AppTheme.responsiveSpacing(context, base: 2)),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: AppTheme.responsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(BuildContext context, GameProvider gameProvider, int level, int currentExp, int requiredExp) {
    // Normal level progress display
    double progress = requiredExp > 0 ? currentExp / requiredExp : 0.0;
    
    return GestureDetector(
      onTap: () => _showXpProgressDialog(context, gameProvider),
      child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsivePadding(context, small: 6, large: 8), 
        vertical: AppTheme.responsivePadding(context, small: 4, large: 6)
      ),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, color: Colors.blue, size: AppTheme.responsiveFontSize(context, 18)),
              SizedBox(width: 4),
              Text(
                'Lv.$level',
                style: TextStyle(
                  fontSize: AppTheme.responsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.withOpacity(0.9),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.responsiveSpacing(context, base: 2)),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.blue.withOpacity(0.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(Colors.blue.withOpacity(0.7)),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showXpProgressDialog(BuildContext context, GameProvider gameProvider) {
    final currentXp = gameProvider.getShopExperience();
    final requiredXp = gameProvider.getRequiredExperience();
    final progress = requiredXp > 0 ? currentXp / requiredXp : 1.0;
    final isMaxLevel = gameProvider.shopLevel >= gameProvider.levelRequirements.length;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.store, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Café Level ${gameProvider.shopLevel}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMaxLevel) ...[
                const Text(
                  '🎉 Maximum Level Reached!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Experience: ${gameProvider.score}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ] else ...[
                Text(
                  'Progress to Level ${gameProvider.shopLevel + 1}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'XP: $currentXp / $requiredXp',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}% complete',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 Earn XP by:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text('• Serving customers (3x coins earned)', style: TextStyle(fontSize: 12)),
                const Text('• Merging desserts (1.5x dessert value)', style: TextStyle(fontSize: 12)),
                const Text('• Crafting desserts (2x dessert value)', style: TextStyle(fontSize: 12)),
              ],
            ],
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

}