import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/services/database_service.dart';
import 'package:fufu_dessert2/screens/tutorial_screen.dart';
import 'package:fufu_dessert2/screens/settings_screen.dart';
import 'package:fufu_dessert2/services/tutorial_service.dart';
import 'package:fufu_dessert2/models/customer.dart';
import 'package:fufu_dessert2/models/dessert.dart';
import 'package:fufu_dessert2/screens/storage_screen.dart';
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
                color: Colors.black.withOpacity(0.1),
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
                  builder: (context, gameProvider, child) => _buildCompactStat(
                    context,
                    Icons.store,
                    'Lv.${gameProvider.shopLevel}',
                    Colors.blue,
                  ),
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
              
              // Menu button for additional info - static, no rebuilds
              Consumer2<GameProvider, CustomerProvider>(
                builder: (context, gameProvider, customerProvider, child) => IconButton(
                  onPressed: () => _showStatsMenu(context, gameProvider, customerProvider),
                  icon: Icon(Icons.more_vert, size: AppTheme.responsiveFontSize(context, 18)),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: const EdgeInsets.all(4),
                  tooltip: 'More Stats',
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.8),
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

  void _showStatsDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue),
              SizedBox(width: 8),
              Text('Game Stats'),
            ],
          ),
          content: Consumer2<CafeProvider, CustomerProvider>(
            builder: (context, cafeProvider, customerProvider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatRow('Total Coins', '${gameProvider.coins}'),
                  _buildStatRow('Current Score', '${gameProvider.score}'),
                  _buildStatRow('Shop Level', '${gameProvider.shopLevel}'),
                  const Divider(),
                  const Text('🪑 Café Capacity', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildStatRow('Seating Capacity', '${cafeProvider.totalSeatingCapacity ?? 8} people'),
                  _buildStatRow('Current Customers', '${customerProvider.customers.length}'),
                  _buildStatRow('Tables Placed', '${cafeProvider.tableCount ?? 2}'),
                  _buildStatRow('Max Tables (Level ${gameProvider.shopLevel ?? 1})', '${cafeProvider.getMaxTablesForLevel(gameProvider.shopLevel ?? 1)}'),
                  _buildStatRow('Next Table Unlock', 'Level ${(((cafeProvider.tableCount ?? 2) - 2) * 3) + 4}'),
                  const Divider(),
                  _buildStatRow('Attraction Bonus', '+${cafeProvider.totalAttractionBonus ?? 0}'),
                  const Divider(),
                  const Text('👥 Customer Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  _buildStatRow('Entering', '${customerProvider.customers.where((c) => c.state == CustomerState.entering).length}'),
                  _buildStatRow('Browsing', '${customerProvider.customers.where((c) => c.state == CustomerState.browsing).length}'),
                  _buildStatRow('Ordering', '${customerProvider.customers.where((c) => c.state == CustomerState.ordering).length}'),
                  _buildStatRow('Eating (Seated)', '${customerProvider.customers.where((c) => c.state == CustomerState.eating).length}'),
                  _buildStatRow('Leaving', '${customerProvider.customers.where((c) => c.state == CustomerState.leaving).length}'),
                ],
              );
            },
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.purple),
                title: const Text('Music & Sound'),
                subtitle: const Text('Toggle game audio'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAudioSettingsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('Tutorial'),
                subtitle: const Text('Learn how to play the game'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TutorialScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text('Reset Game'),
                subtitle: const Text('⚠️ This will delete all progress!'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showResetConfirmDialog(context);
                },
              ),
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

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Game'),
          content: const Text(
            'Are you sure you want to reset your game? '
            'This will delete all progress and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Get providers
                  final gameProvider = Provider.of<GameProvider>(context, listen: false);
                  final cafeProvider = Provider.of<CafeProvider>(context, listen: false);
                  final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                  
                  // Clear database first
                  final db = DatabaseService();
                  await db.clearAllData();
                  
                  // Reset all provider states to initial values
                  await gameProvider.resetToInitialState();
                  await cafeProvider.resetToInitialState();
                  customerProvider.removeAllCustomers();
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Game completely reset! Starting fresh... 🎮✨'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error resetting game: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showStorageDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.inventory, color: Colors.brown),
              SizedBox(width: 8),
              Text('Ingredient Storage'),
            ],
          ),
          content: Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              try {
                final storage = gameProvider.storage;
                final availableLevels = storage.getAvailableLevels();
              
              if (availableLevels.isEmpty) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Storage is empty!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Store ingredients from the merge grid by using sell mode.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              }
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Items: ${storage.getTotalItems()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Available Ingredients:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        children: availableLevels.map((level) {
                          final dessert = Dessert.getDessertByLevel(level);
                          final quantity = storage.getQuantity(level);
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: dessert.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: dessert.color.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  dessert.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dessert.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Level ${dessert.level} • Value: ${dessert.baseValue}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x$quantity',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Text(
                      '💡 Tip: Serve these ingredients directly to ordering customers in the café!',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              );
              } catch (e) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading storage',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }
            },
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

  void _showAudioSettingsDialog(BuildContext context) {
    final audioService = AudioService();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.volume_up, color: Colors.purple),
                  SizedBox(width: 8),
                  Text('Music & Sound Settings'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      audioService.isMusicEnabled ? Icons.music_note : Icons.music_off,
                      color: audioService.isMusicEnabled ? Colors.green : Colors.red,
                    ),
                    title: const Text('Background Music'),
                    subtitle: Text(audioService.isMusicEnabled ? 'Enabled' : 'Disabled'),
                    trailing: Switch(
                      value: audioService.isMusicEnabled,
                      onChanged: (value) async {
                        await audioService.setMusicEnabled(value);
                        if (value) {
                          await audioService.playBackgroundMusic();
                        } else {
                          await audioService.stopBackgroundMusic();
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      audioService.isSfxEnabled ? Icons.volume_up : Icons.volume_off,
                      color: audioService.isSfxEnabled ? Colors.green : Colors.red,
                    ),
                    title: const Text('Sound Effects'),
                    subtitle: Text(audioService.isSfxEnabled ? 'Enabled' : 'Disabled'),
                    trailing: Switch(
                      value: audioService.isSfxEnabled,
                      onChanged: (value) async {
                        await audioService.setSfxEnabled(value);
                        if (value) {
                          audioService.playSoundEffect(SoundEffect.buttonPress);
                        }
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🎵 Note: Audio may require internet connection for some sounds',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
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
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showStatsMenu(BuildContext context, GameProvider gameProvider, CustomerProvider customerProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '📊 Game Stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColoredStatRow('💰 Money', '${gameProvider.coins}', Colors.amber),
              _buildColoredStatRow('⭐ Score', '${gameProvider.score}', Colors.purple),
              _buildColoredStatRow('🏪 Shop Level', 'Lv.${gameProvider.shopLevel}', Colors.blue),
              _buildColoredStatRow('👥 Customers', '${customerProvider.customers.length}/${customerProvider.maxCustomers}', Colors.green),
              Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  try {
                    final count = gameProvider.storage.getTotalItems();
                    return _buildColoredStatRow('📦 Storage', '$count items', Colors.brown);
                  } catch (e) {
                    return _buildColoredStatRow('📦 Storage', '? items', Colors.brown);
                  }
                },
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StorageScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory, size: 16),
                  label: const Text('Storage'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Settings'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildColoredStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: color)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}