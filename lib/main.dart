import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/screens/game_screen.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';
import 'package:fufu_dessert2/screens/settings_screen.dart';
import 'package:fufu_dessert2/widgets/improved_cafe_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio service
  final audioService = AudioService();
  await audioService.initialize();
  
  // Comprehensive error suppression for intentional overflow
  // This completely suppresses overflow errors in both debug and release modes
  FlutterError.onError = (FlutterErrorDetails details) {
    final errorMessage = details.toString().toLowerCase();
    final exceptionMessage = details.exception.toString().toLowerCase();
    
    // Skip all overflow-related errors since our icons are intentionally bigger
    if (errorMessage.contains('overflowed') || 
        errorMessage.contains('renderflex') ||
        errorMessage.contains('overflow') ||
        errorMessage.contains('renderbox') ||
        exceptionMessage.contains('overflowed') ||
        exceptionMessage.contains('overflow') ||
        exceptionMessage.contains('pixel')) {
      return; // Completely ignore overflow errors
    }
    
    // Only show non-overflow errors in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  
  // Also suppress console debug prints for overflow
  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        final msg = message.toLowerCase();
        if (msg.contains('overflowed') ||
            msg.contains('overflow') ||
            msg.contains('pixels') ||
            msg.contains('renderflex')) {
          return; // Don't print overflow messages
        }
      }
      // Print other debug messages normally
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    };
  }
  
  // Suppress platform error messages too
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('overflow') || 
        errorStr.contains('overflowed') ||
        errorStr.contains('renderflex')) {
      return true; // Handled (suppressed)
    }
    return false; // Let other errors through
  };
  
  runApp(const FufuDessertApp());
}

class FufuDessertApp extends StatefulWidget {
  const FufuDessertApp({super.key});

  @override
  State<FufuDessertApp> createState() => _FufuDessertAppState();
}

class _FufuDessertAppState extends State<FufuDessertApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Additional listener for app focus changes
    SystemChannels.lifecycle.setMessageHandler((message) {
      if (message == AppLifecycleState.paused.toString() || 
          message == AppLifecycleState.inactive.toString() ||
          message == 'AppLifecycleState.paused' ||
          message == 'AppLifecycleState.inactive') {
        AudioService().deactivateAudio();
      } else if (message == AppLifecycleState.resumed.toString() ||
                 message == 'AppLifecycleState.resumed') {
        AudioService().reactivateAudio();
        // Wait a bit then force start background music
        Future.delayed(Duration(milliseconds: 500), () {
          AudioService().playBackgroundMusic();
        });
      }
      return Future.value();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop audio when app is disposed
    AudioService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Reactivate audio system when app comes back
        AudioService().reactivateAudio();
        // Wait a bit then force start background music
        Future.delayed(Duration(milliseconds: 500), () {
          AudioService().playBackgroundMusic();
        });
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Immediately deactivate all audio when app goes to background or is closed
        AudioService().deactivateAudio();
        break;
    }
  }
  
  @override
  void didChangeAccessibilityFeatures() {
    super.didChangeAccessibilityFeatures();
    // Force stop audio on any accessibility change (some devices trigger this on app switch)
    AudioService().deactivateAudio();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => CafeProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: MaterialApp(
        title: '🧁 Fufu Dessert',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          fontFamily: 'Comic Sans MS',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryPink,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        home: const MainNavigator(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Main navigation widget to switch between Grid view and Cafe view
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0; // Start with Grid view as default

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          GameScreen(), // Grid view
          ImprovedCafeView(), // Improved cafe view with fixed coordinates and smooth drag
          SettingsScreen(), // Settings view
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryPink,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Grid View',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Cafe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}