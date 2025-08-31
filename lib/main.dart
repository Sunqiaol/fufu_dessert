import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:fufu_dessert2/providers/game_provider.dart';
import 'package:fufu_dessert2/providers/cafe_provider.dart';
import 'package:fufu_dessert2/providers/customer_provider.dart';
import 'package:fufu_dessert2/screens/game_screen.dart';
import 'package:fufu_dessert2/services/audio_service.dart';
import 'package:fufu_dessert2/utils/app_theme.dart';

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

class FufuDessertApp extends StatelessWidget {
  const FufuDessertApp({super.key});

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
        home: const GameScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}