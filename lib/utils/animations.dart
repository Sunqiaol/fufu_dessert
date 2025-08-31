import 'package:flutter/material.dart';

class GameAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 400);
  static const Duration longDuration = Duration(milliseconds: 600);

  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounce = Curves.bounceOut;
  static const Curve elastic = Curves.elasticOut;

  static Widget slideInFromBottom(Widget child, {Duration? duration}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration ?? mediumDuration,
      curve: easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value * 100),
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget scaleIn(Widget child, {Duration? duration}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? shortDuration,
      curve: bounce,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget fadeIn(Widget child, {Duration? duration}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration ?? mediumDuration,
      curve: easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget pulseAnimation(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.2),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      onEnd: () {
        // Loop the animation
      },
      child: child,
    );
  }

  static Widget mergeAnimation({
    required Widget child,
    required bool isAnimating,
    required VoidCallback onComplete,
  }) {
    if (!isAnimating) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.3),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      onEnd: onComplete,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.5),
                  blurRadius: value * 20,
                  spreadRadius: value * 5,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget coinAnimation({
    required Widget child,
    required bool isAnimating,
    required int coinAmount,
  }) {
    if (!isAnimating) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: -20,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -value * 50),
                child: Opacity(
                  opacity: 1.0 - value,
                  child: Text(
                    '+$coinAmount💰',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class StaggeredAnimationBuilder extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration itemDuration;
  final Curve curve;

  const StaggeredAnimationBuilder({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 100),
    this.itemDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: itemDuration,
          curve: curve,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }
}