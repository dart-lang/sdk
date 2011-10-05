// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MathNatives {
  static int parseInt(String str) {
    if (str is !String) {
      throw "Wrong argument";
    }
    return _parseInt(str);
  }
  static double parseDouble(String str) {
    if (str is !String) {
      throw "Wrong argument";
    }
    return _parseDouble(str);
  }
  static double sqrt(num value) {
    return _sqrt(_asDouble(value));
  }
  static double sin(num value) {
    return _sin(_asDouble(value));
  }
  static double cos(num value) {
    return _cos(_asDouble(value));
  }
  static double tan(num value) {
    return _tan(_asDouble(value));
  }
  static double acos(num value) {
    return _acos(_asDouble(value));
  }
  static double asin(num value) {
    return _asin(_asDouble(value));
  }
  static double atan(num value) {
    return _atan(_asDouble(value));
  }
  static double atan2(num a, num b) {
    return _atan2(_asDouble(a), _asDouble(b));
  }
  static double exp(num value) {
    return _exp(_asDouble(value));
  }
  static double log(num value) {
    return _log(_asDouble(value));
  }
  static num pow(num value, num exponent) {
    if (exponent is int) {
      return value.pow(exponent);
    }
    // Double.pow will call exponent.toDouble().
    return _asDouble(value).pow(exponent);
  }
  static double random() {
    return _random();
  }
  static double _asDouble(num value) {
    double result = value.toDouble();
    if (result is !double) {
      throw "Wrong argument";
    }
    return result;
  }
  static double _random() native "MathNatives_random";
  static double _sqrt(double value) native "MathNatives_sqrt";
  static double _sin(double value) native "MathNatives_sin";
  static double _cos(double value) native "MathNatives_cos";
  static double _tan(double value) native "MathNatives_tan";
  static double _acos(double value) native "MathNatives_acos";
  static double _asin(double value) native "MathNatives_asin";
  static double _atan(double value) native "MathNatives_atan";
  static double _atan2(double a, double b) native "MathNatives_2atan";
  static double _exp(double value) native "MathNatives_exp";
  static double _log(double value) native "MathNatives_log";
  static int _parseInt(String str) native "MathNatives_parseInt";
  static double _parseDouble(String str) native "MathNatives_parseDouble";
}
