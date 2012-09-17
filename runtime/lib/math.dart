// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MathNatives {
  static num pow(num value, num exponent) {
    if (exponent is int) {
      return value.pow(exponent);
    }
    // Double.pow will call exponent.toDouble().
    return value.toDouble().pow(exponent);
  }
  static double random() => _random();
  static double sqrt(num value) => _sqrt(value.toDouble());
  static double sin(num value) => _sin(value.toDouble());
  static double cos(num value) => _cos(value.toDouble());
  static double tan(num value) => _tan(value.toDouble());
  static double acos(num value) => _acos(value.toDouble());
  static double asin(num value) => _asin(value.toDouble());
  static double atan(num value) => _atan(value.toDouble());
  static double atan2(num a, num b) => _atan2(a.toDouble(), b.toDouble());
  static double exp(num value) => _exp(value.toDouble());
  static double log(num value) => _log(value.toDouble());

  static double _random() native "MathNatives_random";
  static double _sqrt(double value) native "MathNatives_sqrt";
  static double _sin(double value) native "MathNatives_sin";
  static double _cos(double value) native "MathNatives_cos";
  static double _tan(double value) native "MathNatives_tan";
  static double _acos(double value) native "MathNatives_acos";
  static double _asin(double value) native "MathNatives_asin";
  static double _atan(double value) native "MathNatives_atan";
  static double _atan2(double a, double b) native "MathNatives_atan2";
  static double _exp(double value) native "MathNatives_exp";
  static double _log(double value) native "MathNatives_log";
}
