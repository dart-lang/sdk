// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class MathNatives {
  static double cos(num d) native;
  static double sin(num d) native;
  static double tan(num d) native;
  static double acos(num d) native;
  static double asin(num d) native;
  static double atan(num d) native;
  static double atan2(num a, num b) native;
  static double sqrt(num d) native;
  static double exp(num d) native;
  static double log(num d) native;
  static double pow(num d1, num d2) native;
  static double random() native;
  static int parseInt(String str) native;
  static double parseDouble(String str) native;

  static BadNumberFormatException _newBadNumberFormat(x) native {
    return new BadNumberFormatException(x);
  }
}
