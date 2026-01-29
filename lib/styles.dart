import 'package:flutter/material.dart';

class AppStyles {
  // Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color accentColor = Color(0xFF8B5CF6);  // Violet
  static const Color backgroundColor = Colors.black;
  static const Color surfaceColor = Color(0xFF1E293B);   // Slate 800
  static const Color glassColor = Color(0x33FFFFFF);     // White with 20% opacity
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFF94A3B8); // Slate 400

  // Glassmorphism Style
  static BoxDecoration glassDecoration({double blur = 10.0, double radius = 16.0}) {
    return BoxDecoration(
      color: glassColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    color: textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Outfit', // We'll fall back to default if not available
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textColor,
    fontSize: 16,
    fontFamily: 'Outfit',
  );

  static const TextStyle secondaryStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
    fontFamily: 'Outfit',
  );
}
