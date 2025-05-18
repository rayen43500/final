import 'package:flutter/material.dart';
import 'hash_fix.dart';

// Cette classe remplace la fonctionnalité de GoogleFontsVariant
class CustomFontsVariant {
  final FontWeight fontWeight;
  final FontStyle fontStyle;

  const CustomFontsVariant({
    this.fontWeight = FontWeight.w400,
    this.fontStyle = FontStyle.normal,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CustomFontsVariant &&
        other.fontWeight == fontWeight &&
        other.fontStyle == fontStyle;
  }

  @override
  int get hashCode => HashFix.hashValues(fontWeight, fontStyle);
} 