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
int parseInt(String str) => MathNatives.parseInt(str);

/**
 * Parses a [String] representation of a [double], and returns
 * a [double]. Throws a [BadNumberFormatException] if [str] cannot
 * be parsed as a [double].
 */
double parseDouble(String str) => MathNatives.parseDouble(str);

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
double atan2(num a, num b) => MathNatives.atan2(a, b);

/**
 * If the [exponent] is an integer the result is of the same type as [x].
 * Otherwise it is a [double].
 */
num pow(num x, num exponent) => MathNatives.pow(x, exponent);

double sin(num x) => MathNatives.sin(x);
double cos(num x) => MathNatives.cos(x);
double tan(num x) => MathNatives.tan(x);
double acos(num x) => MathNatives.acos(x);
double asin(num x) => MathNatives.asin(x);
double atan(num x) => MathNatives.atan(x);
double sqrt(num x) => MathNatives.sqrt(x);
double exp(num x) => MathNatives.exp(x);
double log(num x) => MathNatives.log(x);
