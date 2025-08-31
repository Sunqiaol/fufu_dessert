import 'package:flutter/material.dart';

class GameConstants {
  // Grid Configuration
  static const int gridWidth = 7;
  static const int gridHeight = 9;
  static const double gridCellSize = 60.0;
  static const double gridPadding = 16.0;
  
  // Game Balance
  static const int initialCoins = 100;
  static const int maxCustomers = 6;
  static const int customerSpawnInterval = 8; // seconds
  static const int basePatienceTime = 30; // seconds
  
  // UI Colors
  static const Color primaryColor = Color(0xFFE91E63);
  static const Color secondaryColor = Color(0xFFFFB6C1);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF8F4E6);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Game Messages
  static const Map<String, String> messages = {
    'merge_success': '✨ Merged successfully!',
    'customer_happy': '😊 Customer is happy!',
    'customer_angry': '😠 Customer left angry!',
    'level_up': '🎉 Level up!',
    'not_enough_coins': '💰 Not enough coins!',
    'furniture_placed': '🛋️ Furniture placed!',
    'furniture_upgraded': '⬆️ Furniture upgraded!',
  };
  
  // Tutorial Messages
  static const List<String> tutorialSteps = [
    '🧁 Welcome to Fufu Dessert!',
    '📱 Tap three same desserts to merge them',
    '👥 Serve customers to earn coins',
    '🏪 Use the café tab to manage your shop',
    '🛋️ Place furniture to attract customers',
    '📈 Level up to unlock new features!',
  ];
  
  // Achievement Thresholds
  static const Map<String, int> achievements = {
    'first_merge': 1,
    'master_merger': 100,
    'coin_collector': 1000,
    'customer_service': 50,
    'cafe_decorator': 10,
    'dessert_master': 1000000,
  };
}

class GameSounds {
  static const String merge = 'sounds/merge.wav';
  static const String coin = 'sounds/coin.wav';
  static const String customerEnter = 'sounds/bell.wav';
  static const String customerLeave = 'sounds/door.wav';
  static const String levelUp = 'sounds/levelup.wav';
  static const String click = 'sounds/click.wav';
}

class GameTexts {
  static const String appTitle = '🧁 Fufu Dessert';
  static const String mergeTab = 'Merge';
  static const String cafeTab = 'Café';
  
  static String coins(int amount) => '$amount';
  static String score(int amount) => '$amount';
  static String level(int level) => 'Level $level';
  static String customers(int current, int max) => '$current/$max';
  
  static String dessertInfo(String name, int level, int value) => 
      '$name (Lv.$level)\nValue: $value coins';
  
  static String customerOrder(String name, int level) => 
      '$name wants a Level $level dessert';
  
  static String furnitureInfo(String name, int level, int attraction) =>
      '$name (Lv.$level)\nAttraction: +$attraction';
}