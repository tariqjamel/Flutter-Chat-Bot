import 'dart:math';
import 'package:flutter/material.dart';
import '../styles.dart';

class AnimatedOrb extends StatelessWidget {
  final AnimationController controller;
  final bool isListening;
  final bool isGenerating;

  const AnimatedOrb({
    super.key,
    required this.controller,
    required this.isListening,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glows
          _buildPulseCircle(1.0, 0, AppStyles.primaryColor.withOpacity(0.1)),
          _buildPulseCircle(0.8, 1, AppStyles.accentColor.withOpacity(0.15)),
          _buildPulseCircle(0.6, 2, AppStyles.primaryColor.withOpacity(0.2)),

          // The Core Orb
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppStyles.primaryColor, AppStyles.accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppStyles.primaryColor.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Icon(
                  isListening ? Icons.graphic_eq_rounded : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 50,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCircle(double scaleFactor, int delay, Color color) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double animationValue = sin((controller.value + delay * 0.3) * pi * 2) * 0.1 + 1.0;
        return Transform.scale(
          scale: scaleFactor * (isGenerating || isListening ? animationValue : 1.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        );
      },
    );
  }
}
