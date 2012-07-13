// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A part of the dart:math library.

/**
 * Base of the natural logarithms.
 */
final double E = 2.718281828459045;

/**
 * Natural logarithm of 10.
 */
final double LN10 =  2.302585092994046;

/**
 * Natural logarithm of 2.
 */
final double LN2 =  0.6931471805599453;

/**
 * Base-2 logarithm of E.
 */
final double LOG2E = 1.4426950408889634;

/**
 * Base-10 logarithm of E.
 */
final double LOG10E = 0.4342944819032518;

/**
 * The PI constant.
 */
final double PI = 3.1415926535897932;

/**
 * Square root of 1/2.
 */
final double SQRT1_2 = 0.7071067811865476;

/**
 * Square root of 2.
 */
final double SQRT2 = 1.4142135623730951;

/**
 * Parses a [String] representation of an [int], and returns
 * an [int]. Throws a [BadNumberFormatException] if [str]
 * cannot be parsed as an [int].
 */
external int parseInt(String str);

/**
 * Parses a [String] representation of a [double], and returns
 * a [double]. Throws a [BadNumberFormatException] if [str] cannot
 * be parsed as a [double].
 */
external double parseDouble(String str);

num min(num a, num b) {
  int c = a.compareTo(b);
  if (c == 0) return a;
  if (c < 0) {
    if ((b is double) && b.isNaN()) return b;
    return a;
  }
  if ((a is double) && a.isNaN()) return a;
  return b;
}

num max(num a, num b) {
  // NaNs are handled correctly since the compareTo function always considers
  // them to be bigger than any other operand.
  return (a.compareTo(b) < 0) ? b : a;
}

/**
 * Returns the arc tangent of [a]/[b] with sign according to quadrant.
 */
external double atan2(num a, num b);

/**
 * If the [exponent] is an integer the result is of the same type as [x].
 * Otherwise it is a [double].
 */
external num pow(num x, num exponent);

external double sin(num x);
external double cos(num x);
external double tan(num x);
external double acos(num x);
external double asin(num x);
external double atan(num x);
external double sqrt(num x);
external double exp(num x);
external double log(num x);
