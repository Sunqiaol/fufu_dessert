import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _tutorialSeenKey = 'tutorial_seen';
  
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialSeenKey) ?? false;
  }
  
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialSeenKey, true);
  }
  
  static Future<void> resetTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialSeenKey);
  }
}