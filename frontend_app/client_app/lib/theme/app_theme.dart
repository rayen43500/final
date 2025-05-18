import 'package:flutter/material.dart';

class AppTheme {
  // Nouvelles couleurs pour BIN FLOW
  static const Color primaryColor = Color(0xFF3F51B5);     // Bleu indigo
  static const Color primaryColorLight = Color(0xFF7986CB); // Bleu indigo clair
  static const Color primaryColorDark = Color(0xFF303F9F);  // Bleu indigo foncé
  
  // Accent orange pour contraste
  static const Color accentColor = Color(0xFFFF9800);       // Orange
  static const Color accentColorLight = Color(0xFFFFB74D);  // Orange clair
  
  // Couleurs secondaires
  static const Color secondaryColor = Color(0xFFF5F5F5);    // Gris très clair
  
  // Couleurs complémentaires
  static const Color successColor = Color(0xFF4CAF50);      // Vert
  static const Color warningColor = Color(0xFFFFC107);      // Jaune
  static const Color errorColor = Color(0xFFF44336);        // Rouge
  static const Color infoColor = Color(0xFF2196F3);         // Bleu
  
  // Couleurs de texte
  static const Color textColor = Color(0xFF212121);         // Noir presque
  static const Color lightTextColor = Color(0xFF757575);    // Gris
  static const Color ultraLightTextColor = Color(0xFFBDBDBD); // Gris clair
  
  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFFFFFFF);   // Blanc
  static const Color surfaceColor = Color(0xFFFFFFFF);      // Blanc
  static const Color scaffoldBackgroundColor = Color(0xFFFAFAFA); // Blanc cassé
  
  // Couleurs de carte
  static const Color cardColor = Color(0xFFFFFFFF);         // Blanc
  static const Color dividerColor = Color(0xFFE0E0E0);      // Gris clair
  
  // Statut des produits
  static const Color outOfStockColor = Color(0xFFF44336);   // Rouge
  static const Color lowStockColor = Color(0xFFFFC107);     // Jaune
  static const Color inStockColor = Color(0xFF4CAF50);      // Vert
  
  // Nouvelles couleurs pour catégories
  static const Color categoryBlue = Color(0xFF2196F3);      // Bleu
  static const Color categoryGreen = Color(0xFF4CAF50);     // Vert
  static const Color categoryPurple = Color(0xFF9C27B0);    // Violet
  static const Color categoryOrange = Color(0xFFFF9800);    // Orange
  static const Color categoryRed = Color(0xFFF44336);       // Rouge
  static const Color categoryTeal = Color(0xFF009688);      // Turquoise
  static const Color categoryPink = Color(0xFFE91E63);      // Rose
  static const Color categoryIndigo = Color(0xFF3F51B5);    // Indigo
  
  // Rayons
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 20.0;
  
  // Élévations
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;
  static const double elevationXLarge = 8.0;
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Logo BIN FLOW
  static Widget buildLogo({double height = 40, bool showText = true}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radiusSmall),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: Image.asset(
        'assets/images/bin_flow_logo.png',
        height: height,
      ),
    );
  }
  
  // Styles de texte améliorés
  static TextStyle get headingStyle => const TextStyle(
    fontFamily: 'serif',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 0.3,
  );
  
  static TextStyle get subheadingStyle => const TextStyle(
    fontFamily: 'serif',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleStyle => const TextStyle(
    fontFamily: 'serif',
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
  
  static TextStyle get smallTextStyle => const TextStyle(
    fontSize: 13,
    color: lightTextColor,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    color: lightTextColor,
    fontWeight: FontWeight.w400,
  );
  
  // Décoration pour les champs de texte
  static InputDecoration textFieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
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
  
  // Style pour les boutons primaires
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    elevation: 1,
    shadowColor: primaryColor.withOpacity(0.4),
  );
  
  // Thème clair amélioré
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'serif',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      buttonTheme: ButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: elevationSmall,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          shadowColor: primaryColor.withOpacity(0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: lightTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: lightTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
        headlineMedium: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: TextStyle(fontSize: 15, color: textColor, letterSpacing: 0.2),
        bodyMedium: TextStyle(fontSize: 13, color: lightTextColor, fontWeight: FontWeight.w500),
        bodySmall: TextStyle(fontSize: 12, color: lightTextColor, fontWeight: FontWeight.w400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryColor,
        disabledColor: dividerColor,
        selectedColor: primaryColorLight,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        brightness: Brightness.light,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 24,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(
        color: lightTextColor,
        size: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        circularTrackColor: secondaryColor,
      ),
    );
  }
} 