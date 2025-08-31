import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/screens/tutorial_screen.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioService _audioService = AudioService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E6),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Colors.brown),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
        backgroundColor: const Color(0xFFFFE4E1),
        foregroundColor: Colors.brown[700],
        elevation: 0,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio Settings Section
                _buildSectionHeader('Audio & Sound', Icons.volume_up),
                _buildSettingsCard([
                  _buildSwitchTile(
                    'Music',
                    'Background music',
                    _audioService.isMusicEnabled,
                    (value) {
                      setState(() {
                        _audioService.setMusicEnabled(value);
                      });
                    },
                    Icons.music_note,
                  ),
                  _buildSwitchTile(
                    'Sound Effects',
                    'Button clicks and game sounds',
                    _audioService.isSfxEnabled,
                    (value) {
                      setState(() {
                        _audioService.setSfxEnabled(value);
                      });
                    },
                    Icons.volume_up,
                  ),
                  _buildSliderTile(
                    'Music Volume',
                    'Background music volume',
                    _audioService.musicVolume,
                    (value) {
                      setState(() {
                        _audioService.setMusicVolume(value);
                      });
                    },
                    Icons.music_note,
                  ),
                ]),

                const SizedBox(height: 24),

                // Gameplay Settings Section
                _buildSectionHeader('Gameplay', Icons.games),
                _buildSettingsCard([
                  _buildSwitchTile(
                    'Auto-Save',
                    'Automatically save game progress',
                    true, // Could be linked to game provider
                    (value) {
                      // TODO: Implement auto-save toggle
                    },
                    Icons.save,
                  ),
                  _buildSwitchTile(
                    'Show Animations',
                    'Micro-animations and effects',
                    true, // Could be linked to animation settings
                    (value) {
                      // TODO: Implement animation toggle
                    },
                    Icons.animation,
                  ),
                  _buildListTile(
                    'Difficulty',
                    'Normal',
                    Icons.sports_esports,
                    () => _showDifficultyDialog(),
                  ),
                ]),

                const SizedBox(height: 24),

                // Tutorial & Help Section
                _buildSectionHeader('Help & Tutorial', Icons.help),
                _buildSettingsCard([
                  _buildListTile(
                    'Tutorial',
                    'Learn how to play the game',
                    Icons.school,
                    () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TutorialScreen(),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    'Reset Tutorial',
                    'Show tutorial tips again',
                    Icons.refresh,
                    () => _showResetTutorialDialog(),
                  ),
                ]),

                const SizedBox(height: 24),

                // Game Data Section
                _buildSectionHeader('Game Data', Icons.data_usage),
                _buildSettingsCard([
                  _buildListTile(
                    'Game Stats',
                    'View your progress and achievements',
                    Icons.bar_chart,
                    () => _showStatsDialog(gameProvider),
                  ),
                  _buildListTile(
                    'Reset Progress',
                    'Start over with a fresh game',
                    Icons.restore,
                    () => _showResetGameDialog(gameProvider),
                  ),
                ]),

                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader('About', Icons.info),
                _buildSettingsCard([
                  _buildListTile(
                    'Game Version',
                    'v1.0.0',
                    Icons.info_outline,
                    null,
                  ),
                  _buildListTile(
                    'Credits',
                    'Made with Flutter',
                    Icons.favorite,
                    () => _showCreditsDialog(),
                  ),
                ]),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown[600], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown[600]),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown[600]),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.brown[600],
            divisions: 10,
            label: '${(value * 100).round()}%',
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown[600]),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Easy'),
              subtitle: const Text('Relaxed pace, more time for orders'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Normal'),
              subtitle: const Text('Standard game experience'),
              trailing: const Icon(Icons.check, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Hard'),
              subtitle: const Text('Fast-paced, challenging gameplay'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Tutorial'),
        content: const Text('This will show all tutorial tips again when you play. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tutorial reset! Tips will show again.')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Level: ${gameProvider.shopLevel}'),
            Text('Coins: ${gameProvider.coins}'),
            Text('Experience: ${gameProvider.getShopExperience()}/${gameProvider.getRequiredExperience()}'),
            const Text('Total Desserts Crafted: 0'), // TODO: Add tracking
            const Text('Total Orders Served: 0'), // TODO: Add tracking
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResetGameDialog(GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Game Progress'),
        content: const Text('This will permanently delete all your progress and start over. This cannot be undone!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmResetGame(gameProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset Game'),
          ),
        ],
      ),
    );
  }

  void _confirmResetGame(GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text('Type "RESET" to confirm you want to delete all progress:'),
        actions: [
          TextField(
            decoration: const InputDecoration(hintText: 'Type RESET here'),
            onSubmitted: (value) {
              if (value.toUpperCase() == 'RESET') {
                Navigator.pop(context);
                // TODO: Implement actual reset functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game reset! Starting fresh.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCreditsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Credits'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧁 Fufu Dessert Game'),
            Text(''),
            Text('Built with Flutter & Dart'),
            Text('UI/UX designed for mobile'),
            Text(''),
            Text('Thank you for playing!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}