import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/models/craftable_dessert.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/screens/match_game_screen.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';

class CraftingScreen extends StatefulWidget {
  const CraftingScreen({super.key});

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen> {
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E6),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.cookie, color: Colors.brown),
            SizedBox(width: 8),
            Text('Dessert Crafting'),
          ],
        ),
        backgroundColor: const Color(0xFFFFE4E1),
        foregroundColor: Colors.brown[700],
        elevation: 0,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          try {
            final availableDessertsToShow = CraftableDessert.getAvailableRecipes(gameProvider.shopLevel);
            
            if (availableDessertsToShow.isEmpty) {
              return _buildNoRecipesAvailable();
            }
            
            return Column(
              children: [
                // Crafting Instructions Header
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade100, Colors.red.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '👩‍🍳 Dessert Kitchen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Combine your stored ingredients to create delicious desserts! Desserts are worth more coins than individual ingredients.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.brown,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Dessert Recipes List
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: availableDessertsToShow.length,
                      itemBuilder: (context, index) {
                        final dessert = availableDessertsToShow[index];
                        final canCraft = gameProvider.canCraftDessert(dessert.id);
                        final missingIngredients = gameProvider.getMissingIngredients(dessert.id);
                        
                        return _buildDessertRecipeCard(
                          context,
                          dessert,
                          canCraft,
                          missingIngredients,
                          gameProvider,
                        );
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Game'),
        backgroundColor: Colors.brown[600],
      ),
    );
  }

  Widget _buildNoRecipesAvailable() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cookie_outlined,
            size: 80,
            color: Colors.brown,
          ),
          SizedBox(height: 24),
          Text(
            'No Recipes Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Collect ingredients by playing the merge game to unlock dessert recipes!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDessertRecipeCard(
    BuildContext context,
    CraftableDessert dessert,
    bool canCraft,
    List<int> missingIngredients,
    GameProvider gameProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: canCraft
              ? [
                  dessert.color.withOpacity(0.1),
                  dessert.color.withOpacity(0.05),
                  Colors.white,
                ]
              : [
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canCraft ? dessert.color.withOpacity(0.5) : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: canCraft 
                ? dessert.color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
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
            // Dessert Header
            Row(
              children: [
                // Dessert Emoji
                Container(
                  width: 60,
                  height: 60,
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
                          color: canCraft ? Colors.brown[800] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        dessert.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: canCraft ? Colors.brown[600] : Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Current storage amount
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Text(
                          '📦 In Storage: ${gameProvider.storage.getDessertQuantity(dessert.id)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
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
                          '💰 ${dessert.baseValue} coins',
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
            
            // Recipe Ingredients
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
                final hasIngredient = gameProvider.storage.hasEnough(ingredientLevel);
                final quantity = gameProvider.storage.getQuantity(ingredientLevel);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasIngredient 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasIngredient ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ingredient.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ingredient.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: hasIngredient ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                      if (hasIngredient) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($quantity)',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Craft Options - Quick Craft or Mini-Game
            if (canCraft)
              Column(
                children: [
                  // Quick Craft Button (1 item)
                  SparkleAnimation(
                    isAnimating: _isAnimating,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isAnimating = true);
                          AudioService().playSoundEffect(SoundEffect.craft);
                          final success = gameProvider.craftDessert(dessert.id);
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            if (mounted) setState(() => _isAnimating = false);
                          });
                          if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🎉 Quick crafted 1x ${dessert.name}! Added to storage.',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '❌ Failed to craft ${dessert.name}. Check your ingredients.',
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.flash_on),
                      label: const Text('Quick Craft (1x)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  )),
                  
                  const SizedBox(height: 8),
                  
                  // Mini-Game Button (5-20 items based on performance)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AudioService().playSoundEffect(SoundEffect.buttonPress);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MatchGameScreen(
                              dessertToCraft: dessert,
                              shopLevel: gameProvider.shopLevel,
                              onIngredientConsume: () {
                                // Consume ingredients regardless of game outcome
                                final consumed = gameProvider.consumeIngredientsForMatchGame(dessert.id);
                                if (!consumed) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('❌ Ingredients no longer available.'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              onGameComplete: (rewardCount) {
                                // Add crafted desserts to storage based on game performance
                                // Ingredients are already consumed by onIngredientConsume
                                if (rewardCount > 0) {
                                  gameProvider.storage.addCraftedDessert(dessert.id, quantity: rewardCount);
                                  // Play craft sound effect
                                  AudioService().playSoundEffect(SoundEffect.craft);
                                  // Save game state (this will automatically notify listeners)
                                  gameProvider.saveGameState();
                                }
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      rewardCount > 0 
                                        ? '🎮 连连看 Complete! Crafted ${rewardCount}x ${dessert.name}!'
                                        : '🎮 连连看 Complete! Better luck next time.',
                                    ),
                                    backgroundColor: rewardCount >= 15 
                                      ? Colors.purple 
                                      : rewardCount > 0 
                                        ? Colors.blue 
                                        : Colors.orange,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.games),
                      label: const Text('连连看 Challenge (5-20x)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Info text
                  const Text(
                    '💡 Play 连连看 to earn more desserts!\nReward depends on completion speed & accuracy.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.brown,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📋 Missing Ingredients:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: missingIngredients.map((level) {
                        final ingredient = Dessert.getDessertByLevel(level);
                        return Text(
                          '${ingredient.emoji} ${ingredient.name}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
            'Error Loading Recipes',
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
}