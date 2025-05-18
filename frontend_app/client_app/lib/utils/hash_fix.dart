import 'package:flutter/foundation.dart';

// This class provides a replacement for the deprecated hashValues function
class HashFix {
  static int hashValues(Object a, Object b) {
    return Object.hash(a, b);
  }
  
  static int hashList(List<Object?> values) {
    return Object.hashAll(values);
  }
} 