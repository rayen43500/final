import 'package:flutter/material.dart';

class AppStyle {
  // Couleurs éco-responsables naturelles
  static const Color primaryColor = Color(0xFF7D9D6C); // Vert olive naturel
  static const Color secondaryColor = Color(0xFFCA9E67); // Beige doré
  static const Color tertiaryColor = Color(0xFF6D9A8F); // Vert d'eau
  static const Color errorColor = Color(0xFFCB8E6E); // Terracotta

  static const Color backgroundColor = Color(0xFFF8F7F2); // Ivoire naturel
  static const Color cardColor = Color(0xFFFFFEFC); // Blanc naturel
  static const Color dividerColor = Color(0xFFE7E5DF); // Beige très clair

  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF4A4942); // Gris anthracite
  static const Color textSecondaryColor = Color(0xFF7F7D76); // Taupe
  static const Color textLightColor = Color(0xFFF8F7F2); // Blanc cassé

  // Couleurs d'état
  static const Color successColor = Color(0xFF8FB573); // Vert sauge
  static const Color warningColor = Color(0xFFD8B96A); // Ocre doré
  static const Color infoColor = Color(0xFF829CA7); // Bleu gris

  // Rayons
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 20.0;

  // Élévations
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Styles de texte
  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: 0.3,
  );
  
  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 15,
    color: textPrimaryColor,
    letterSpacing: 0.2,
  );

  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    color: textSecondaryColor,
    fontWeight: FontWeight.w400,
  );

  // Logo BIN FLOW
  static Widget buildLogo({double height = 40, bool showText = true}) {
    return Image.asset(
      'assets/images/bin_flow_logo.png',
      height: height,
    );
  }

  // Décoration de carte avec ombre douce
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMedium),
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
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: backgroundColor,
      labelStyle: const TextStyle(
        color: textSecondaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // Style pour les boutons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textLightColor,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: elevationSmall,
  );

  // Style pour les boutons secondaires
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: textLightColor,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: elevationSmall,
  );

  // Thème global
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
        onBackground: textPrimaryColor,
        onSurface: textPrimaryColor,
        onPrimary: textLightColor,
        onSecondary: textLightColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textLightColor,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
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
          color: textPrimaryColor,
        ),
        bodySmall: captionStyle,
      ),
      useMaterial3: true,
    );
  }
} 