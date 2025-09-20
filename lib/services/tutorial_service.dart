import 'package:flutter/material.dart';
import 'package:fufu_dessert2/widgets/tutorial_overlay.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/services/database_service.dart';
import 'package:fufu_dessert2/services/audio_service.dart';

enum TutorialType {
  firstRecipe,      // Level 2
  furnitureShop,    // Level 3
  moreTables,       // Level 4
  premiumFurniture, // Level 5
  complexRecipes,   // Level 6
  luxuryFurniture,  // Level 7
  masterRecipes,    // Level 8
  eliteFurniture,   // Level 9
  ultimateMastery,  // Level 10
}

class TutorialService {
  static final TutorialService _instance = TutorialService._internal();
  factory TutorialService() => _instance;
  TutorialService._internal();

  // Track completed tutorials
  final Set<TutorialType> _completedTutorials = {};
  bool _tutorialsEnabled = true;

  Future<void> initialize() async {
    _tutorialsEnabled = true;
  }

  Future<void> setTutorialsEnabled(bool enabled) async {
    _tutorialsEnabled = enabled;
  }

  Future<void> markTutorialCompleted(TutorialType type) async {
    _completedTutorials.add(type);
  }

  bool isTutorialCompleted(TutorialType type) {
    return _completedTutorials.contains(type);
  }

  Future<void> resetTutorials() async {
    _completedTutorials.clear();
  }

  // Show level-up tutorial if not completed
  void showLevelUpTutorial(BuildContext context, int newLevel, GameProvider gameProvider) {
    debugPrint('🎓 Tutorial Service: showLevelUpTutorial called for level $newLevel');
    
    if (!_tutorialsEnabled) {
      debugPrint('🎓 Tutorial Service: Tutorials disabled, skipping');
      return;
    }

    final tutorialType = _getTutorialTypeForLevel(newLevel);
    debugPrint('🎓 Tutorial Service: Tutorial type for level $newLevel: $tutorialType');
    
    if (tutorialType == null) {
      debugPrint('🎓 Tutorial Service: No tutorial type found for level $newLevel');
      return;
    }
    
    if (isTutorialCompleted(tutorialType)) {
      debugPrint('🎓 Tutorial Service: Tutorial $tutorialType already completed');
      return;
    }

    debugPrint('🎓 Tutorial Service: Showing tutorial for $tutorialType');
    
    // Show celebration first, then tutorial
    Future.delayed(const Duration(milliseconds: 500), () {
      debugPrint('🎓 Tutorial Service: About to show level up celebration');
      _showLevelUpCelebration(context, newLevel, () {
        debugPrint('🎓 Tutorial Service: About to show tutorial overlay');
        _showTutorial(context, tutorialType, gameProvider);
      });
    });
  }

  TutorialType? _getTutorialTypeForLevel(int level) {
    switch (level) {
      case 2: return TutorialType.firstRecipe;
      case 3: return TutorialType.furnitureShop;
      case 4: return TutorialType.moreTables;
      case 5: return TutorialType.premiumFurniture;
      case 6: return TutorialType.complexRecipes;
      case 7: return TutorialType.luxuryFurniture;
      case 8: return TutorialType.masterRecipes;
      case 9: return TutorialType.eliteFurniture;
      case 10: return TutorialType.ultimateMastery;
      default: return null;
    }
  }

  void _showLevelUpCelebration(BuildContext context, int level, VoidCallback onComplete) {
    final celebrationData = _getLevelUpCelebration(level);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LevelUpCelebrationDialog(
        level: level,
        title: celebrationData['title']!,
        subtitle: celebrationData['subtitle']!,
        onComplete: onComplete,
      ),
    );
  }

  Map<String, String> _getLevelUpCelebration(int level) {
    switch (level) {
      case 2: return {
        'title': '🎊 CONGRATULATIONS! 🎊',
        'subtitle': 'Your dessert skills are improving!',
      };
      case 3: return {
        'title': '🛍️ SHOP UNLOCKED! 🛍️',
        'subtitle': 'Time to decorate your dessert shop!',
      };
      case 4: return {
        'title': '📈 EXPANDING BUSINESS! 📈',
        'subtitle': 'Your shop is growing popular!',
      };
      case 5: return {
        'title': '✨ LUXURY UNLOCKED! ✨',
        'subtitle': 'Your shop deserves the finer things!',
      };
      case 6: return {
        'title': '🎂 MASTER BAKER! 🎂',
        'subtitle': 'You\'re becoming a true dessert artist!',
      };
      case 7: return {
        'title': '🏆 LUXURY ESTABLISHMENT! 🏆',
        'subtitle': 'Your shop rivals the finest bakeries!',
      };
      case 8: return {
        'title': '🎓 CULINARY MASTER! 🎓',
        'subtitle': 'You\'ve achieved true mastery!',
      };
      case 9: return {
        'title': '🌟 ELITE ESTABLISHMENT! 🌟',
        'subtitle': 'Your shop is legendary!',
      };
      case 10: return {
        'title': '👑 DESSERT EMPIRE RULER! 👑',
        'subtitle': 'You have achieved the ultimate!',
      };
      default: return {
        'title': '🎉 LEVEL UP! 🎉',
        'subtitle': 'Keep growing your dessert empire!',
      };
    }
  }

  void _showTutorial(BuildContext context, TutorialType type, GameProvider gameProvider) {
    final steps = _getTutorialSteps(type, context, gameProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlay(
        steps: steps,
        onComplete: () {
          Navigator.of(context).pop();
          markTutorialCompleted(type);
        },
        onSkip: () {
          Navigator.of(context).pop();
          markTutorialCompleted(type);
        },
      ),
    );
  }

  List<TutorialStep> _getTutorialSteps(TutorialType type, BuildContext context, GameProvider gameProvider) {
    switch (type) {
      case TutorialType.firstRecipe:
        return [
          TutorialStep(
            id: 'recipe_intro',
            title: '🍪 Amazing! You\'ve learned your first recipe!',
            message: 'Tap the cookbook to see what you can craft!',
          ),
          TutorialStep(
            id: 'crafting_basics',
            title: '👨‍🍳 Combine Flour + Sugar to make delicious Cookies!',
            message: 'Crafted desserts are worth much more than merged ones!',
          ),
          TutorialStep(
            id: 'try_crafting',
            title: '✨ Try it now! Find Flour and Sugar in your grid!',
            message: 'Look for these ingredients and drag them together to craft!',
          ),
          TutorialStep(
            id: 'completion_reward',
            title: '🎊 Perfect! Cookies are worth 25 coins each!',
            message: 'Keep crafting to grow your dessert empire!',
          ),
        ];

      case TutorialType.furnitureShop:
        return [
          TutorialStep(
            id: 'store_intro',
            title: '🏪 A traveling merchant has arrived with furniture!',
            message: 'Open the settings menu and look for the furniture shop!',
          ),
          TutorialStep(
            id: 'attraction_system',
            title: '💝 Beautiful furniture attracts more customers!',
            message: 'Higher attraction = happier customers = more coins!',
          ),
          TutorialStep(
            id: 'first_purchase',
            title: '🌱 Start small! Plants cost 20 coins and add +2 attraction.',
            message: 'Even tiny improvements make a big difference!',
          ),
          TutorialStep(
            id: 'placement_tutorial',
            title: '🎯 Place furniture anywhere in your shop!',
            message: 'Enter edit mode and drag furniture to arrange your layout!',
          ),
          TutorialStep(
            id: 'new_recipe_butter',
            title: '🧈 Bonus: Butter is now available for new recipes!',
            message: 'Try making Pancakes with Flour + Milk!',
          ),
        ];

      case TutorialType.moreTables:
        return [
          TutorialStep(
            id: 'table_capacity',
            title: '🍽️ Success! You can now place a 3rd table!',
            message: 'More tables = more customers = more profit!',
          ),
          TutorialStep(
            id: 'ingredient_eggs',
            title: '🥚 Fresh eggs have arrived from the local farm!',
            message: 'This opens up many new recipe possibilities!',
          ),
          TutorialStep(
            id: 'recipe_complexity',
            title: '👩‍🍳 You can now craft recipes with 3 ingredients!',
            message: 'Try: Flour + Sugar + Milk = Simple Muffin (65 coins)!',
          ),
          TutorialStep(
            id: 'strategy_tip',
            title: '⏰ Pro tip: Serve your happiest customers first!',
            message: 'Green patience clocks give bonus coin rewards!',
          ),
        ];

      case TutorialType.premiumFurniture:
        return [
          TutorialStep(
            id: 'premium_access',
            title: '💎 Premium furniture is now available!',
            message: 'These items provide much higher attraction bonuses!',
          ),
          TutorialStep(
            id: 'chocolate_intro',
            title: '🍫 Sweet! Premium chocolate has been delivered!',
            message: 'This rare ingredient makes the most valuable desserts!',
          ),
          TutorialStep(
            id: 'investment_strategy',
            title: '📊 Premium costs more but attracts many more customers!',
            message: 'A 55-coin lamp gives +4 attraction vs +2 for basic items!',
          ),
          TutorialStep(
            id: 'hot_chocolate_recipe',
            title: '☕ New recipe: Hot Chocolate = 95 coins!',
            message: 'Premium ingredients = premium profits!',
          ),
        ];

      case TutorialType.complexRecipes:
        return [
          TutorialStep(
            id: 'table_expansion',
            title: '🏪 Your shop is booming! 4th table unlocked!',
            message: 'You can now serve even more hungry customers!',
          ),
          TutorialStep(
            id: 'strawberry_season',
            title: '🍓 It\'s strawberry season! Fresh berries available!',
            message: 'Perfect for pies, cakes, and summer treats!',
          ),
          TutorialStep(
            id: 'four_ingredient_mastery',
            title: '🧑‍🍳 You\'ve mastered 4-ingredient recipes!',
            message: 'Try Berry Pie: Flour + Butter + Strawberries + Sugar = 140 coins!',
          ),
          TutorialStep(
            id: 'match_game_evolution',
            title: '🎮 Crafting games are now more challenging but more rewarding!',
            message: 'Bigger grids mean bigger multiplier bonuses!',
          ),
        ];

      case TutorialType.luxuryFurniture:
        return [
          TutorialStep(
            id: 'luxury_tier',
            title: '🎨 Luxury furniture tier unlocked!',
            message: 'Grand paintings, grandfather clocks, and more await!',
          ),
          TutorialStep(
            id: 'vanilla_extract',
            title: '🌟 Premium vanilla extract has arrived!',
            message: 'The secret ingredient that makes desserts extraordinary!',
          ),
          TutorialStep(
            id: 'vanilla_specialties',
            title: '🧁 New specialty: Vanilla Cupcakes = 200 coins!',
            message: 'Vanilla makes everything taste better!',
          ),
          TutorialStep(
            id: 'attraction_milestone',
            title: '✨ Your shop\'s attraction is now truly impressive!',
            message: 'Customers are traveling from far and wide to visit!',
          ),
        ];

      case TutorialType.masterRecipes:
        return [
          TutorialStep(
            id: 'master_status',
            title: '👑 Master baker status achieved! 5th table unlocked!',
            message: 'Your empire continues to grow!',
          ),
          TutorialStep(
            id: 'cream_introduction',
            title: '🦄 Ultra-premium cream is now available!',
            message: 'Only master bakers can work with ingredients this fine!',
          ),
          TutorialStep(
            id: 'five_ingredient_complexity',
            title: '🎂 Master the art of 5-ingredient recipes!',
            message: 'Cream Cake: Flour + Sugar + Butter + Eggs + Cream = 280 coins!',
          ),
          TutorialStep(
            id: 'elite_match_games',
            title: '⚡ Master-level crafting games unlocked!',
            message: 'Higher difficulty, higher rewards - only for true experts!',
          ),
        ];

      case TutorialType.eliteFurniture:
        return [
          TutorialStep(
            id: 'elite_status',
            title: '💫 Elite furniture collection unlocked!',
            message: 'Grand pianos, chandeliers, and masterpieces await!',
          ),
          TutorialStep(
            id: 'golden_honey',
            title: '🍯 Liquid gold! Pure honey has arrived!',
            message: 'The rarest ingredient for your most special creations!',
          ),
          TutorialStep(
            id: 'honey_specialties',
            title: '🥞 Divine recipe: Honey Pancakes = 340 coins!',
            message: 'Sweet perfection that customers dream about!',
          ),
          TutorialStep(
            id: 'prestige_preparation',
            title: '⭐ You\'re approaching legendary status!',
            message: 'One more level until ultimate mastery!',
          ),
        ];

      case TutorialType.ultimateMastery:
        return [
          TutorialStep(
            id: 'ultimate_achievement',
            title: '🏰 Behold! Your 6-table dessert empire!',
            message: 'You rule the ultimate culinary kingdom!',
          ),
          TutorialStep(
            id: 'prestige_furniture',
            title: '🏛️ Prestige furniture collection unlocked!',
            message: 'Fountains, statues, and legendary displays!',
          ),
          TutorialStep(
            id: 'masters_recipes',
            title: '🏆 Ultimate recipe: Master\'s Delight = 500 coins!',
            message: 'Six premium ingredients in perfect harmony!',
          ),
          TutorialStep(
            id: 'royal_recipe',
            title: '👑 The legendary Royal Cake: ALL ingredients = 1,000 coins!',
            message: 'Only true masters can craft this masterpiece!',
          ),
          TutorialStep(
            id: 'endless_journey',
            title: '∞ Your journey continues! Keep perfecting your empire!',
            message: 'New challenges and rewards await the truly dedicated!',
          ),
        ];

      default:
        return [];
    }
  }

  // Manual tutorial showing (from settings or help menu)
  void showTutorialManually(BuildContext context, TutorialType type, GameProvider gameProvider) {
    _showTutorial(context, type, gameProvider);
  }
}

class _LevelUpCelebrationDialog extends StatefulWidget {
  final int level;
  final String title;
  final String subtitle;
  final VoidCallback onComplete;

  const _LevelUpCelebrationDialog({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.onComplete,
  });

  @override
  State<_LevelUpCelebrationDialog> createState() => _LevelUpCelebrationDialogState();
}

class _LevelUpCelebrationDialogState extends State<_LevelUpCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _scaleController.forward();
    _rotateController.repeat();

    // Play celebration sound
    AudioService().playSoundEffect(SoundEffect.levelUp);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE4E1),
                    Color(0xFFF8F4E6),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Level badge with rotation
                  AnimatedBuilder(
                    animation: _rotateAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value * 2 * 3.14159,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${widget.level}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.brown[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Continue button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onComplete();
                    },
                    icon: const Icon(Icons.school, size: 20),
                    label: const Text('Start Tutorial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}