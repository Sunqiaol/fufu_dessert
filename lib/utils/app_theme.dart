import 'package:flutter/material.dart';
import 'dart:math' as math;

class AppTheme {
  // Cute pastel color palette
  static const Color primaryPink = Color(0xFFFFB6C1);
  static const Color primaryPeach = Color(0xFFFFDAB9);
  static const Color primaryLavender = Color(0xFFE6E6FA);
  static const Color primaryMint = Color(0xFFF0FFFF);
  static const Color primaryCream = Color(0xFFFFFDD0);
  
  // Accent colors
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentRose = Color(0xFFFF69B4);
  static const Color accentPurple = Color(0xFF9370DB);
  static const Color accentGreen = Color(0xFF98FB98);
  static const Color accentOrange = Color(0xFFFFB347);
  
  // Background gradients
  static const LinearGradient gameBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8DC), // Cornsilk
      Color(0xFFFFF5EE), // Seashell
      Color(0xFFFFE4E1), // Misty rose
    ],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFFFFAFA), // Snow
    ],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFB6C1), // Light pink
      Color(0xFFFF69B4), // Hot pink
    ],
  );
  
  static const LinearGradient greenButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF98FB98), // Pale green
      Color(0xFF90EE90), // Light green
    ],
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA500), // Orange
    ],
  );

  // Text styles
  static const TextStyle titleText = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Color(0xFF8B4513), // Saddle brown
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2,
        color: Colors.white,
      ),
    ],
  );
  
  static const TextStyle subtitleText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFFA0522D), // Sienna
  );
  
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: Color(0xFF8B4513), // Saddle brown
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2,
        color: Colors.black26,
      ),
    ],
  );

  // Box decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get buttonDecoration => BoxDecoration(
    gradient: buttonGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration get goldButtonDecoration => BoxDecoration(
    gradient: goldGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration get greenButtonDecoration => BoxDecoration(
    gradient: greenButtonGradient,
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Helper method for sparkle effect colors
  static List<Color> get sparkleColors => [
    accentGold,
    accentRose,
    accentPurple,
    accentGreen,
    accentOrange,
  ];

  // Responsive design utilities
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  static bool isSmallScreen(BuildContext context) => screenWidth(context) < 360;
  static bool isLargeScreen(BuildContext context) => screenWidth(context) > 600;
  static bool isTallScreen(BuildContext context) => screenHeight(context) > 800;
  
  // Responsive padding - reduced values
  static double responsivePadding(BuildContext context, {double small = 4.0, double large = 8.0}) {
    return isSmallScreen(context) ? small : large;
  }
  
  // New responsive spacing system for better mobile scaling
  static double responsiveSpacing(BuildContext context, {double base = 8.0}) {
    final width = screenWidth(context);
    if (width < 350) return base * 0.6; // Very small screens - 4.8px
    if (width < 400) return base * 0.75; // Small screens - 6px  
    if (width < 600) return base * 1.0; // Normal mobile - 8px
    return base * 1.25; // Large screens - 10px
  }
  
  static double responsiveMargin(BuildContext context, {double base = 12.0}) {
    final width = screenWidth(context);
    if (width < 350) return base * 0.5; // Very small screens - 6px
    if (width < 400) return base * 0.67; // Small screens - 8px
    if (width < 600) return base * 1.0; // Normal mobile - 12px
    return base * 1.33; // Large screens - 16px
  }
  
  // Responsive font sizes
  static double responsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) {
      return baseSize * 0.9;
    } else if (isLargeScreen(context)) {
      return baseSize * 1.1;
    }
    return baseSize;
  }
  
  // Responsive button height
  static double responsiveButtonHeight(BuildContext context) {
    if (isSmallScreen(context)) {
      return 40.0;
    } else if (isLargeScreen(context)) {
      return 60.0;
    }
    return 50.0;
  }
  
  // Responsive grid item size
  static double responsiveGridItemSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Account for padding
    final itemsPerRow = isSmallScreen(context) ? 4 : (isLargeScreen(context) ? 6 : 5);
    return (availableWidth / itemsPerRow) - 8; // Account for spacing
  }

  // Percentage-based responsive utilities
  static double percentWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }
  
  static double percentHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }
  
  // Responsive top bar height (6-8% of screen height - smaller)
  static double responsiveTopBarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (isSmallScreen(context) ? 0.06 : 0.08); // 6-8% of screen
  }
  
  // Responsive floating orders height (6-8% of screen height - smaller)
  static double responsiveFloatingOrdersHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (isSmallScreen(context) ? 0.06 : 0.08); // 6-8% of screen
  }
  
  // Responsive tab bar height (4-5% of screen height - smaller)
  static double responsiveTabBarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (isSmallScreen(context) ? 0.04 : 0.05); // 4-5% of screen
  }
  
  // Responsive card width (25-35% of screen width)
  static double responsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (isSmallScreen(context) ? 0.25 : 0.3); // 25-30% of screen width
  }
}

// Cute animated button widget
class CuteButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final bool isDisabled;

  const CuteButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.gradient,
    this.width,
    this.height,
    this.isDisabled = false,
  });

  @override
  State<CuteButton> createState() => _CuteButtonState();
}

class _CuteButtonState extends State<CuteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isDisabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isDisabled) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (!widget.isDisabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height ?? AppTheme.responsiveButtonHeight(context),
              decoration: BoxDecoration(
                gradient: widget.isDisabled 
                    ? const LinearGradient(
                        colors: [Colors.grey, Colors.grey])
                    : (widget.gradient ?? AppTheme.buttonGradient),
                borderRadius: BorderRadius.circular(28), // More rounded for kawaii
                boxShadow: widget.isDisabled ? null : const [
                  BoxShadow(
                    color: Color(0x26000000), // Colors.black.withOpacity(0.15)
                    blurRadius: 6, // Reduced blur radius
                    offset: Offset(0, 3), // Reduced offset
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: AppTheme.responsiveFontSize(context, 20),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.text,
                          style: AppTheme.buttonText.copyWith(
                            fontSize: AppTheme.responsiveFontSize(context, 16),
                            color: widget.isDisabled ? Colors.grey[400] : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Sparkle animation widget for crafting effects
class SparkleAnimation extends StatefulWidget {
  final Widget child;
  final bool isAnimating;
  final Color sparkleColor;
  final int sparkleCount;
  
  const SparkleAnimation({
    super.key,
    required this.child,
    this.isAnimating = false,
    this.sparkleColor = Colors.amber,
    this.sparkleCount = 4, // Reduced from 8 to 4 for performance
  });

  @override
  State<SparkleAnimation> createState() => _SparkleAnimationState();
}

class _SparkleAnimationState extends State<SparkleAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _sparkleAnimations;
  late List<Animation<Offset>> _sparklePositions;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 800ms
      vsync: this,
    );

    // Create multiple sparkle animations with different timings and positions
    _sparkleAnimations = List.generate(widget.sparkleCount, (index) {
      final startTime = index * 0.1; // Stagger the animations
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(startTime, 1.0, curve: Curves.easeOutQuart),
        ),
      );
    });

    _sparklePositions = List.generate(widget.sparkleCount, (index) {
      final angle = (index * 2 * math.pi) / widget.sparkleCount;
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          50 * math.cos(angle),
          50 * math.sin(angle),
        ),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutQuart,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(SparkleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.forward();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        
        // Animated sparkles
        ...List.generate(widget.sparkleCount, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final sparkleValue = _sparkleAnimations[index].value;
              final position = _sparklePositions[index].value;
              
              if (sparkleValue == 0.0) return const SizedBox.shrink();
              
              return Transform.translate(
                offset: position,
                child: Opacity(
                  opacity: (1.0 - sparkleValue) * sparkleValue * 4, // Fade in and out
                  child: Transform.scale(
                    scale: sparkleValue,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.sparkleColor,
                            widget.sparkleColor.withOpacity(0.3),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.sparkleColor.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
        
        // Central glow effect
        if (widget.isAnimating)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.sparkleColor.withOpacity(0.3 * _controller.value),
                      blurRadius: 20 * _controller.value,
                      spreadRadius: 5 * _controller.value,
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// Bounce animation widget for furniture placement  
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final bool shouldBounce;
  final Duration duration;
  
  const BounceAnimation({
    super.key,
    required this.child,
    this.shouldBounce = false,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(BounceAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldBounce && !oldWidget.shouldBounce) {
      _controller.forward().then((_) {
        if (mounted) {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

