import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs éco-responsables et naturelles
  static const Color primaryColor = Color(0xFF7D9D6C); // Vert olive naturel
  static const Color secondaryColor = Color(0xFFF3F1EC); // Beige clair naturel
  static const Color accentColor = Color(0xFFCA9E67); // Beige doré
  static const Color backgroundColor = Color(0xFFF8F7F2); // Ivoire naturel
  
  // Couleurs de texte
  static const Color darkTextColor = Color(0xFF4A4942); // Gris anthracite
  static const Color lightTextColor = Color(0xFF7F7D76); // Taupe
  static const Color whiteTextColor = Color(0xFFF8F7F2); // Blanc cassé
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF8FB573); // Vert sauge
  static const Color errorColor = Color(0xFFCB8E6E); // Terracotta
  static const Color warningColor = Color(0xFFD8B96A); // Ocre doré
  static const Color infoColor = Color(0xFF829CA7); // Bleu gris
  
  // Couleurs de carte
  static const Color cardColor = Color(0xFFFFFEFC); // Blanc naturel
  static const Color cardShadowColor = Color(0x1A4A4942); // Ombre douce
  
  // Logo BIN FLOW
  static Widget buildLogo({double height = 40, bool showText = true}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: Image.asset(
        'assets/images/bin_flow_logo.svg',
        height: height,
      ),
    );
  }
  
  // Styles de texte
  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: darkTextColor,
    letterSpacing: 0.3,
  );
  
  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: darkTextColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: darkTextColor,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 15,
    color: darkTextColor,
    letterSpacing: 0.2,
  );

  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    color: lightTextColor,
    fontWeight: FontWeight.w400,
  );

  // Décoration de carte avec ombre douce
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Décoration pour les champs de texte
  static InputDecoration textFieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: secondaryColor,
      labelStyle: const TextStyle(
        color: lightTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // Style pour les boutons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: whiteTextColor,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    elevation: 1.0,
  );

  // Style pour les boutons secondaires
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: darkTextColor,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    elevation: 1.0,
  );

  // Thème global
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        tertiary: warningColor,
        error: errorColor,
        background: backgroundColor,
        surface: Colors.white,
        onBackground: darkTextColor,
        onSurface: darkTextColor,
        onPrimary: whiteTextColor,
        onSecondary: darkTextColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: whiteTextColor,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      textTheme: TextTheme(
        headlineLarge: headingStyle,
        headlineMedium: subheadingStyle,
        titleLarge: titleStyle,
        bodyLarge: bodyStyle,
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: darkTextColor,
        ),
        bodySmall: captionStyle,
      ),
      useMaterial3: true,
    );
  }
} 