// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Mathematical constants and functions, plus a random number generator.
 */
library dart.math;

part "jenkins_smi_hash.dart";
part "point.dart";
part "random.dart";
part "rectangle.dart";

/**
 * Base of the natural logarithms.
 *
 * Typically written as "e".
 */
const double E = 2.718281828459045;

/**
 * Natural logarithm of 10.
 */
const double LN10 =  2.302585092994046;

/**
 * Natural logarithm of 2.
 */
const double LN2 =  0.6931471805599453;

/**
 * Base-2 logarithm of [E].
 */
const double LOG2E = 1.4426950408889634;

/**
 * Base-10 logarithm of [E].
 */
const double LOG10E = 0.4342944819032518;

/**
 * The PI constant.
 */
const double PI = 3.1415926535897932;

/**
 * Square root of 1/2.
 */
const double SQRT1_2 = 0.7071067811865476;

/**
 * Square root of 2.
 */
const double SQRT2 = 1.4142135623730951;

/**
  * Returns the lesser of two numbers.
  *
  * Returns NaN if either argument is NaN.
  * The lesser of [:-0.0:] and [:0.0:] is [:-0.0:].
  * If the arguments are otherwise equal (including int and doubles with the
  * same mathematical value) then it is unspecified which of the two arguments
  * is returned.
  */
num min(num a, num b) {
  // These partially redundant type checks improve code quality for dart2js.
  // Most of the improvement is at call sites from the inferred non-null num
  // return type.
  if (a is! num) throw new ArgumentError(a);
  if (b is! num) throw new ArgumentError(b);

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
    if (a == 0 && b.isNegative || b.isNaN) return b;
    return a;
  }
  return a;
}

/**
  * Returns the larger of two numbers.
  *
  * Returns NaN if either argument is NaN.
  * The larger of [:-0.0:] and [:0.0:] is [:0.0:]. If the arguments are
  * otherwise equal (including int and doubles with the same mathematical value)
  * then it is unspecified which of the two arguments is returned.
  */
num max(num a, num b) {
  // These partially redundant type checks improve code quality for dart2js.
  // Most of the improvement is at call sites from the inferred non-null num
  // return type.
  if (a is! num) throw new ArgumentError(a);
  if (b is! num) throw new ArgumentError(b);

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
    if (b.isNaN) return b;
    return a;
  }
  // max(-0.0, 0) must return 0.
  if (b == 0 && a.isNegative) return b;
  return a;
}

/**
 * A variant of [atan].
 *
 * Converts both arguments to doubles.
 *
 * Returns the angle between the positive x-axis and the vector ([b],[a]).
 * The result, in radians, is in the range -PI..PI.
 *
 * If [b] is positive, this is the same as [:atan(b/a):].
 *
 * The result is negative when [a] is negative (including when [a] is the
 * double -0.0).
 *
 * If [a] is equal to zero, the vector ([b],[a]) is considered parallel to
 * the x-axis, even if [b] is also equal to zero. The sign of [b] determines
 * the direction of the vector along the x-axis.
 *
 * Returns NaN if either argument is NaN.
 */
external double atan2(num a, num b);

/**
 * Returns [x] to the power of [exponent].
 *
 * If [x] is an [int] and [exponent] is a non-negative [int], the result is
 * an [int], otherwise both arguments are converted to doubles first, and the
 * result is a [double].
 *
 * For integers, the power is always equal to the mathematical result of `x` to
 * the power `exponent`, only limited by the available memory.
 *
 * For doubles, `pow(x, y)` handles edge cases as follows:
 *
 * - if `y` is zero (0.0 or -0.0), the result is always 1.0.
 * - if `x` is 1.0, the result is always 1.0.
 * - otherwise, if either `x` or `y` is NaN then the result is NaN.
 * - if `x` is negative (but not -0.0) and `y` is a finite non-integer, the
 *   result is NaN.
 * - if `x` is Infinity and `y` is negative, the result is 0.0.
 * - if `x` is Infinity and `y` is positive, the result is Infinity.
 * - if `x` is 0.0 and `y` is negative, the result is Infinity.
 * - if `x` is 0.0 and `y` is positive, the result is 0.0.
 * - if `x` is -Infinity or -0.0 and `y` is an odd integer, then the result is
 *   `-pow(-x ,y)`.
 * - if `x` is -Infinity or -0.0 and `y` is not an odd integer, then the result
 *   is the same as `pow(-x , y)`.
 * - if `y` is Infinity and the absolute value of `x` is less than 1, the
 *   result is 0.0.
 * - if `y` is Infinity and `x` is -1, the result is 1.0.
 * - if `y` is Infinity and the absolute value of `x` is greater than 1,
 *   the result is Infinity.
 * - if `y` is -Infinity, the result is `1/pow(x, Infinity)`.
 *
 * This corresponds to the `pow` function defined in the IEEE Standard 754-2008.
 *
 * Notice that an [int] result cannot overflow, but a [double] result might
 * be [double.INFINITY].
 */
external num pow(num x, num exponent);

/**
 * Converts [x] to a double and returns the sine of the value.
 *
 * If [x] is not a finite number, the result is NaN.
 */
external double sin(num x);

/**
 * Converts [x] to a double and returns the cosine of the value.
 *
 * If [x] is not a finite number, the result is NaN.
 */
external double cos(num x);

/**
 * Converts [x] to a double and returns the tangent of the value.
 *
 * The tangent function is equivalent to [:sin(x)/cos(x):] and may be
 * infinite (positive or negative) when [:cos(x):] is equal to zero.
 * If [x] is not a finite number, the result is NaN.
 */
external double tan(num x);

/**
 * Converts [x] to a double and returns the arc cosine of the value.
 *
 * Returns a value in the range -PI..PI, or NaN if [x] is outside
 * the range -1..1.
 */
external double acos(num x);

/**
 * Converts [x] to a double and returns the arc sine of the value.
 * Returns a value in the range -PI..PI, or  NaN if [x] is outside
 * the range -1..1.
 */
external double asin(num x);

/**
 * Converts [x] to a dobule and returns the arc tangent of the vlaue.
 * Returns a value in the range -PI/2..PI/2, or NaN if [x] is NaN.
 */
external double atan(num x);

/**
 * Converts [x] to a double and returns the positive square root of the value.
 *
 * Returns -0.0 if [x] is -0.0, and NaN if [x] is otherwise negative or NaN.
 */
external double sqrt(num x);

/**
 * Converts [x] to a double and returns the natural exponent, [E],
 * to the power [x].
 * Returns NaN if [x] is NaN.
 */
external double exp(num x);

/**
 * Converts [x] to a double and returns the natural logarithm of the value.
 * Returns negative infinity if [x] is equal to zero.
 * Returns NaN if [x] is NaN or less than zero.
 */
external double log(num x);
