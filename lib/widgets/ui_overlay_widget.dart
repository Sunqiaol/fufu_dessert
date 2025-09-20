import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';
import 'package:fufu_dessert2/services/audio_service.dart';

class UIOverlayWidget extends StatelessWidget {
  const UIOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.responsivePadding(context, small: 4, large: 6), 
            vertical: AppTheme.responsivePadding(context, small: 2, large: 4)
          ),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Money (Coins) - only rebuilds when coins change
              Expanded(
                flex: 2,
                child: Consumer<GameProvider>(
                  builder: (context, gameProvider, child) => _buildCompactStat(
                    context,
                    Icons.monetization_on,
                    '${gameProvider.coins}',
                    Colors.amber,
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
              
              // Shop Level - only rebuilds when level changes
              Expanded(
                child: Consumer<GameProvider>(
                  builder: (context, gameProvider, child) {
                    // Set context for tutorials
                    gameProvider.setContext(context);
                    
                    // Debug the exact state
                    
                    if (gameProvider.levelUpReady) {
                      return GestureDetector(
                        onTap: () {
                          AudioService().playSoundEffect(SoundEffect.levelUp);
                          gameProvider.levelUp();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.responsivePadding(context, small: 3, large: 5), 
                            vertical: AppTheme.responsivePadding(context, small: 2, large: 3)
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star, 
                                color: Colors.white, 
                                size: AppTheme.responsiveFontSize(context, 16)
                              ),
                              SizedBox(width: AppTheme.responsivePadding(context, small: 2, large: 3)),
                              Text(
                                'LEVEL UP!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTheme.responsiveFontSize(context, 12),
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return _buildClickableLevelStat(context, gameProvider);
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 4),
              
              // People in Store - only rebuilds when customers change
              Expanded(
                flex: 2,
                child: Consumer<CustomerProvider>(
                  builder: (context, customerProvider, child) => _buildCompactStat(
                    context,
                    Icons.people,
                    '${customerProvider.customers.length}/${customerProvider.maxCustomers}',
                    Colors.green,
                  ),
                ),
              ),
              
              // Store Open/Close Toggle - Fourth slot
              Expanded(
                flex: 2,
                child: Consumer<GameProvider>(
                  builder: (context, gameProvider, child) => GestureDetector(
                    onTap: gameProvider.canToggleStore ? gameProvider.toggleStore : null,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.responsivePadding(context, small: 3, large: 5),
                        vertical: AppTheme.responsivePadding(context, small: 2, large: 3),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gameProvider.isStoreOpen 
                            ? [Colors.green, Colors.green.shade700]
                            : [Colors.red, Colors.red.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (gameProvider.isStoreOpen ? Colors.green : Colors.red).withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            gameProvider.isStoreOpen ? Icons.store : Icons.lock,
                            color: Colors.white,
                            size: AppTheme.responsiveFontSize(context, 14),
                          ),
                          SizedBox(width: AppTheme.responsivePadding(context, small: 1, large: 2)),
                          Text(
                            gameProvider.isStoreOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.responsiveFontSize(context, 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildCompactStat(BuildContext context, IconData icon, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.responsivePadding(context, small: 3, large: 5), 
        vertical: AppTheme.responsivePadding(context, small: 2, large: 3)
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppTheme.responsiveFontSize(context, 16)),
          SizedBox(width: AppTheme.responsivePadding(context, small: 2, large: 3)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.responsiveFontSize(context, 11),
                fontWeight: FontWeight.bold,
                color: color,
                shadows: [
                  Shadow(
                    offset: const Offset(0.5, 0.5),
                    blurRadius: 1,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableLevelStat(BuildContext context, GameProvider gameProvider) {
    return GestureDetector(
      onTap: () => _showXpProgressDialog(context, gameProvider),
      child: _buildCompactStat(
        context,
        Icons.store,
        'Lv.${gameProvider.shopLevel}',
        Colors.blue,
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
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