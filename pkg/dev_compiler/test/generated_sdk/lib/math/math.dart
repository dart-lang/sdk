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
import 'dart:_foreign_helper' show JS;
import 'dart:_js_helper' show patch, checkNum;

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
double atan2(num a, num b)
  => JS('double', r'Math.atan2(#, #)', checkNum(a), checkNum(b));

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
num pow(num x, num exponent) {
  checkNum(x);
  checkNum(exponent);
  return JS('num', r'Math.pow(#, #)', x, exponent);
}

/**
 * Converts [x] to a double and returns the sine of the value.
 *
 * If [x] is not a finite number, the result is NaN.
 */
double sin(num x)
  => JS('double', r'Math.sin(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the cosine of the value.
 *
 * If [x] is not a finite number, the result is NaN.
 */
double cos(num x)
  => JS('double', r'Math.cos(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the tangent of the value.
 *
 * The tangent function is equivalent to [:sin(x)/cos(x):] and may be
 * infinite (positive or negative) when [:cos(x):] is equal to zero.
 * If [x] is not a finite number, the result is NaN.
 */
double tan(num x)
  => JS('double', r'Math.tan(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the arc cosine of the value.
 *
 * Returns a value in the range -PI..PI, or NaN if [x] is outside
 * the range -1..1.
 */
double acos(num x)
  => JS('double', r'Math.acos(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the arc sine of the value.
 * Returns a value in the range -PI..PI, or  NaN if [x] is outside
 * the range -1..1.
 */
double asin(num x)
  => JS('double', r'Math.asin(#)', checkNum(x));

/**
 * Converts [x] to a dobule and returns the arc tangent of the vlaue.
 * Returns a value in the range -PI/2..PI/2, or NaN if [x] is NaN.
 */
double atan(num x)
  => JS('double', r'Math.atan(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the positive square root of the value.
 *
 * Returns -0.0 if [x] is -0.0, and NaN if [x] is otherwise negative or NaN.
 */
double sqrt(num x)
  => JS('double', r'Math.sqrt(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the natural exponent, [E],
 * to the power [x].
 * Returns NaN if [x] is NaN.
 */
double exp(num x)
  => JS('double', r'Math.exp(#)', checkNum(x));

/**
 * Converts [x] to a double and returns the natural logarithm of the value.
 * Returns negative infinity if [x] is equal to zero.
 * Returns NaN if [x] is NaN or less than zero.
 */
double log(num x)
  => JS('double', r'Math.log(#)', checkNum(x));

const int _POW2_32 = 0x100000000;
class _JSRandom implements Random {
  // The Dart2JS implementation of Random doesn't use a seed.
  const _JSRandom();

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new RangeError("max must be in range 0 < max ≤ 2^32, was $max");
    }
    return JS("int", "(Math.random() * #) >>> 0", max);
  }

  /**
   * Generates a positive random floating point value uniformly distributed on
   * the range from 0.0, inclusive, to 1.0, exclusive.
   */
  double nextDouble() => JS("double", "Math.random()");

  /**
   * Generates a random boolean value.
   */
  bool nextBool() => JS("bool", "Math.random() < 0.5");
}
class _Random implements Random {
  // Constants used by the algorithm or masking.
  static const double _POW2_53_D = 1.0 * (0x20000000000000);
  static const double _POW2_27_D = 1.0 * (1 << 27);
  static const int _MASK32 = 0xFFFFFFFF;

  // State comprised of two unsigned 32 bit integers.
  int _lo = 0;
  int _hi = 0;

  // Implements:
  //   uint64_t hash = 0;
  //   do {
  //      hash = hash * 1037 ^ mix64((uint64_t)seed);
  //      seed >>= 64;
  //   } while (seed != 0 && seed != -1);  // Limits for pos/neg seed.
  //   if (hash == 0) {
  //     hash = 0x5A17;
  //   }
  //   _lo = hash & _MASK_32;
  //   _hi = hash >> 32;
  // and then does four _nextState calls to shuffle bits around.
  _Random(int seed) {
    int empty_seed = 0;
    if (seed < 0) {
      empty_seed = -1;
    }
    do {
      int low = seed & _MASK32;
      seed = (seed - low) ~/ _POW2_32;
      int high = seed & _MASK32;
      seed = (seed - high) ~/ _POW2_32;

      // Thomas Wang's 64-bit mix function.
      // http://www.concentric.net/~Ttwang/tech/inthash.htm
      // via. http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm

      // key = ~key + (key << 21);
      int tmplow = low << 21;
      int tmphigh = (high << 21) | (low >> 11);
      tmplow = (~low & _MASK32) + tmplow;
      low = tmplow & _MASK32;
      high = (~high + tmphigh + ((tmplow - low) ~/ 0x100000000)) & _MASK32;
      // key = key ^ (key >> 24).
      tmphigh = high >> 24;
      tmplow = (low >> 24) | (high << 8);
      low ^= tmplow;
      high ^= tmphigh;
      // key = key * 265
      tmplow = low * 265;
      low = tmplow & _MASK32;
      high = (high * 265 + (tmplow - low) ~/ 0x100000000) & _MASK32;
      // key = key ^ (key >> 14);
      tmphigh = high >> 14;
      tmplow = (low >> 14) | (high << 18);
      low ^= tmplow;
      high ^= tmphigh;
      // key = key * 21
      tmplow = low * 21;
      low = tmplow & _MASK32;
      high = (high * 21 + (tmplow - low) ~/ 0x100000000) & _MASK32;
      // key = key ^ (key >> 28).
      tmphigh = high >> 28;
      tmplow = (low >> 28) | (high << 4);
      low ^= tmplow;
      high ^= tmphigh;
      // key = key + (key << 31);
      tmplow = low << 31;
      tmphigh = (high << 31) | (low >> 1);
      tmplow += low;
      low = tmplow & _MASK32;
      high = (high + tmphigh + (tmplow - low) ~/ 0x100000000) & _MASK32;
      // Mix end.

      // seed = seed * 1037 ^ key;
      tmplow = _lo * 1037;
      _lo = tmplow & _MASK32;
      _hi = (_hi * 1037 + (tmplow - _lo) ~/ 0x100000000) & _MASK32;
      _lo ^= low;
      _hi ^= high;
    } while (seed != empty_seed);

    if (_hi == 0 && _lo == 0) {
      _lo = 0x5A17;
    }
    _nextState();
    _nextState();
    _nextState();
    _nextState();
  }

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A (0xFFFFDA61) is selected from "Numerical Recipes 3rd
  // Edition" p.348 B1.

  // Implements:
  //   var state = (A * _lo + _hi) & _MASK_64;
  //   _lo = state & _MASK_32;
  //   _hi = state >> 32;
  void _nextState() {
    // Simulate (0xFFFFDA61 * lo + hi) without overflowing 53 bits.
    int tmpHi = 0xFFFF0000 * _lo;  // At most 48 bits of significant result.
    int tmpHiLo = tmpHi & _MASK32;             // Get the lower 32 bits.
    int tmpHiHi = tmpHi - tmpHiLo;            // And just the upper 32 bits.
    int tmpLo = 0xDA61 * _lo;
    int tmpLoLo = tmpLo & _MASK32;
    int tmpLoHi = tmpLo - tmpLoLo;

    int newLo = tmpLoLo + tmpHiLo + _hi;
    _lo = newLo & _MASK32;
    int newLoHi = newLo - _lo;
    _hi = ((tmpLoHi + tmpHiHi + newLoHi) ~/ _POW2_32) & _MASK32;
    assert(_lo < _POW2_32);
    assert(_hi < _POW2_32);
  }

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new RangeError("max must be in range 0 < max ≤ 2^32, was $max");
    }
    if ((max & (max - 1)) == 0) {
      // Fast case for powers of two.
      _nextState();
      return _lo & (max - 1);
    }

    int rnd32;
    int result;
    do {
      _nextState();
      rnd32 = _lo;
      result = rnd32.remainder(max); // % max;
    } while ((rnd32 - result + max) >= _POW2_32);
    return result;
  }

  double nextDouble() {
    _nextState();
    int bits26 = _lo & ((1 << 26) - 1);
    _nextState();
    int bits27 = _lo & ((1 << 27) - 1);
    return (bits26 * _POW2_27_D + bits27) / _POW2_53_D;
  }

  bool nextBool() {
    _nextState();
    return (_lo & 1) == 0;
  }
}