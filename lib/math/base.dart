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
 * Parses a [String] representation of an [int], and returns an [int]. Throws a
 * [FormatException] if [str] cannot be parsed as an [int].
 */
int parseInt(String str) => MathNatives.parseInt(str);

/**
 * Parses a [String] representation of a [double], and returns a [double].
 * Throws a [FormatException] if [str] cannot be parsed as a [double].
 */
double parseDouble(String str) => MathNatives.parseDouble(str);

/**
  * Returns the minimum of two numbers. If either argument is NaN returns NaN.
  * The minimum of [:-0.0:] and [:0.0:] is [:-0.0:]. If both arguments are
  * equal (int and doubles with the same mathematical value are equal) then
  * it is unspecified which of the two arguments is returned.
  */
num min(num a, num b) {
  if (a is num) {
    // TODO(floitsch): merge this if into the previous one, once dart2js
    // correctly propagates types for logical ands.
    if (b is num) {
      if (a > b) return b;
      if (a < b) return a;
      if (b is double) {
        // Special case for NaN and -0.0. If one argument is NaN return NaN.
        // [min] must also distinguish between -0.0 and 0.0.
        if (a is double) {
          if (a == 0.0) {
            // a is either 0.0 or -0.0. b is either 0.0, -0.0 or NaN.
            // The following returns -0.0 if either a or b is -0.0, and it
            // returns NaN if b is NaN.
            return (a + b) * a * b;
          }
        }
        // Check for NaN and b == -0.0.
        if (a == 0 && b.isNegative() || b.isNan()) return b;
        return a;
      }
      return a;
    }
    throw new IllegalArgumentException(b);
  }
  throw new IllegalArgumentException(a);
}

/**
  * Returns the maximum of two numbers. If either argument is NaN returns NaN.
  * The maximum of [:-0.0:] and [:0.0:] is [:0.0:]. If both arguments are
  * equal (int and doubles with the same mathematical value are equal) then
  * it is unspecified which of the two arguments is returned.
  */
num max(num a, num b) {
  if (a is num) {
    // TODO(floitsch): merge this if into the previous one, once dart2js
    // correctly propagates types for logical ands.
    if (b is num) {
      if (a > b) return a;
      if (a < b) return b;
      if (b is double) {
        // Special case for NaN and -0.0. If one argument is NaN return NaN.
        // [max] must also distinguish between -0.0 and 0.0.
        if (a is double) {
          if (a == 0.0) {
            // a is either 0.0 or -0.0. b is either 0.0, -0.0, or NaN.
            // The following returns 0.0 if either a or b is 0.0, and it
            // returns NaN if b is NaN.
            return a + b;
          }
        }
        // Check for NaN.
        if (b.isNaN()) return b;
        return a;
      }
      // max(-0.0, 0) must return 0.
      if (b == 0 && a.isNegative()) return b;
      return a;
    }
    throw new IllegalArgumentException(b);
  }
  throw new IllegalArgumentException(a);
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
