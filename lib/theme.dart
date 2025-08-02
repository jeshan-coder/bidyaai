import 'package:flutter/material.dart';

// --- FONT SETUP COMPLETE ---
// Your pubspec.yaml is now configured, so this theme will correctly
// use the different weights of the Lexend font family.
// Remember to STOP and RESTART your app for the changes to take effect.

class AppTheme {
  // This is the custom MaterialColor that we created.
  static const MaterialColor primaryColor = MaterialColor(
    0xFF153764, // Your primary color
    <int, Color>{
      50: Color(0xFFE3E7ED),
      100: Color(0xFFB8C3D7),
      200: Color(0xFF899DBA),
      300: Color(0xFF5A789D),
      400: Color(0xFF375E87),
      500: Color(0xFF153764),
      600: Color(0xFF13345C),
      700: Color(0xFF102D52),
      800: Color(0xFF0E2748),
      900: Color(0xFF0A1A34),
    },
  );

  // Defined a default text color from the design.
  static const Color _textColor = Color(0xFF0F141A);

  // This is the main theme data for the app.
  static final ThemeData mainTheme = ThemeData(
    primarySwatch: primaryColor,
    fontFamily: 'Lexend',
    useMaterial3: true,
    // This merges our custom styles with Flutter's defaults for better consistency.
    textTheme: ThemeData.light().textTheme.copyWith(
      // For "Download Bidya AI"
      headlineSmall: const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w700, // Uses Lexend-Bold.ttf
        letterSpacing: -0.015,
        height: 1.25,
      ),
      // For AppBar Title "BidyaAI"
      titleLarge: const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w700, // Uses Lexend-Bold.ttf
        letterSpacing: -0.015,
        height: 1.25,
      ),
      // For the main body paragraph
      bodyLarge: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400, // Uses Lexend-Regular.ttf
        height: 1.5,
      ),
      // For "Downloading"
      bodyMedium: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500, // Uses Lexend-Medium.ttf
        height: 1.5,
      ),
      // For "50%"
      labelLarge: const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400, // Uses Lexend-Regular.ttf
        height: 1.5,
      ),
      // For bottom navigation items like "Home", "Chat"
      labelMedium: const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500, // Uses Lexend-Medium.ttf
        letterSpacing: 0.015,
        height: 1.5,
        color: Color(0xFF556F91), // Specific color for nav items
      ),
    ).apply( // This applies the default text color to all styles.
      bodyColor: _textColor,
      displayColor: _textColor,
    ),
  );
}
