import 'package:flutter/material.dart';

class AppTheme {
  // Nouvelles couleurs pour BIN FLOW
  static const Color primaryColor = Color(0xFF3F51B5);     // Bleu indigo
  static const Color primaryColorLight = Color(0xFF7986CB); // Bleu indigo clair
  static const Color primaryColorDark = Color(0xFF303F9F);  // Bleu indigo foncé
  
  // Accent orange pour contraste
  static const Color accentColor = Color(0xFFFF9800);       // Orange
  static const Color accentColorLight = Color(0xFFFFB74D);  // Orange clair
  
  static const Color secondaryColor = Color(0xFFF5F5F5);    // Gris très clair
  static const Color successColor = Color(0xFF4CAF50);      // Vert
  static const Color warningColor = Color(0xFFFFC107);      // Jaune
  static const Color errorColor = Color(0xFFF44336);        // Rouge
  static const Color infoColor = Color(0xFF2196F3);         // Bleu
  static const Color textColor = Color(0xFF212121);         // Noir presque
  static const Color lightTextColor = Color(0xFF757575);    // Gris
  static const Color backgroundColor = Color(0xFFFFFFFF);   // Blanc
  static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA); // Blanc cassé
  
  // Styles de texte simplifiés (sans Google Fonts)
  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 0.3,
  );
  
  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.1,
  );
  
  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 15,
    color: textColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    color: lightTextColor,
    fontWeight: FontWeight.w400,
  );
  
  // Style pour les boutons
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 1,
  );

  // Style pour les boutons secondaires
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    foregroundColor: textColor,
    backgroundColor: secondaryColor,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 1,
  );

  // Style pour les boutons outline
  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  // Thème global simplifié
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        background: scaffoldBackgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingStyle.copyWith(color: Colors.white, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlineButtonStyle,
      ),
    );
  }
} 