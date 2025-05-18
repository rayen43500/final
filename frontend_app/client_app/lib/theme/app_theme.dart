import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Nouvelle palette de couleurs éco-responsables et naturelles
  static const Color primaryColor = Color(0xFF7D9D6C);     // Vert olive naturel
  static const Color primaryColorLight = Color(0xFFA1B78F); // Vert olive clair
  static const Color primaryColorDark = Color(0xFF5A7347);  // Vert olive foncé
  
  // Accent doré pour un look naturel et artisanal
  static const Color accentColor = Color(0xFFCA9E67);       // Beige doré
  static const Color accentColorLight = Color(0xFFE2C9A1);  // Beige doré clair
  
  // Couleurs secondaires
  static const Color secondaryColor = Color(0xFFF3F1EC);    // Beige clair naturel
  
  // Couleurs complémentaires
  static const Color successColor = Color(0xFF8FB573);      // Vert sauge
  static const Color warningColor = Color(0xFFD8B96A);      // Ocre doré
  static const Color errorColor = Color(0xFFCB8E6E);        // Terracotta
  static const Color infoColor = Color(0xFF829CA7);         // Bleu gris
  
  // Couleurs de texte
  static const Color textColor = Color(0xFF4A4942);         // Gris anthracite
  static const Color lightTextColor = Color(0xFF7F7D76);    // Taupe
  static const Color ultraLightTextColor = Color(0xFFB0ACA2); // Taupe clair
  
  // Couleurs de fond
  static const Color backgroundColor = Color(0xFFFFFEFC);   // Blanc naturel
  static const Color surfaceColor = Color(0xFFFFFEFC);      // Blanc naturel
  static const Color scaffoldBackgroundColor = Color(0xFFF8F7F2); // Ivoire naturel
  
  // Couleurs de carte
  static const Color cardColor = Color(0xFFFFFEFC);         // Blanc naturel
  static const Color dividerColor = Color(0xFFE7E5DF);      // Beige très clair
  
  // Statut des produits
  static const Color outOfStockColor = Color(0xFFCB8E6E);   // Terracotta
  static const Color lowStockColor = Color(0xFFD8B96A);     // Ocre doré
  static const Color inStockColor = Color(0xFF8FB573);      // Vert sauge
  
  // Nouvelles couleurs pour catégories
  static const Color categoryBlue = Color(0xFF829CA7);      // Bleu gris
  static const Color categoryGreen = Color(0xFF8FB573);     // Vert sauge
  static const Color categoryPurple = Color(0xFF9A8D9F);    // Lavande
  static const Color categoryOrange = Color(0xFFD2A76C);    // Orange doré
  static const Color categoryRed = Color(0xFFCB8E6E);       // Terracotta
  static const Color categoryTeal = Color(0xFF6D9A8F);      // Vert d'eau
  static const Color categoryPink = Color(0xFFCEA5A5);      // Rose poudré
  static const Color categoryIndigo = Color(0xFF7C8CA5);    // Bleu indigo
  
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
  static TextStyle get headingStyle => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: 0.3,
  );
  
  static TextStyle get subheadingStyle => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get titleStyle => GoogleFonts.playfairDisplay(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.1,
  );
  
  static TextStyle get subtitleStyle => GoogleFonts.raleway(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static TextStyle get bodyStyle => GoogleFonts.raleway(
    fontSize: 15,
    color: textColor,
    letterSpacing: 0.2,
  );
  
  static TextStyle get smallTextStyle => GoogleFonts.raleway(
    fontSize: 13,
    color: lightTextColor,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle get captionStyle => GoogleFonts.raleway(
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
      labelStyle: GoogleFonts.raleway(
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
    textStyle: GoogleFonts.raleway(
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
        titleTextStyle: GoogleFonts.playfairDisplay(
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
          textStyle: GoogleFonts.raleway(
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
          textStyle: GoogleFonts.raleway(
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
          textStyle: GoogleFonts.raleway(
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
        hintStyle: GoogleFonts.raleway(
          color: lightTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.raleway(
          color: lightTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: headingStyle,
        headlineMedium: subheadingStyle,
        titleLarge: titleStyle,
        titleMedium: subtitleStyle,
        bodyLarge: bodyStyle,
        bodyMedium: smallTextStyle,
        bodySmall: captionStyle,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryColor,
        disabledColor: dividerColor,
        selectedColor: primaryColorLight,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.raleway(
          fontSize: 13,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.raleway(
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
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.raleway(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.raleway(
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