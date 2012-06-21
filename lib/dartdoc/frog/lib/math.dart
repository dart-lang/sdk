// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

class Math native 'Math' {
  /**
   * Base of the natural logarithms.
   */
  static final double E = 2.718281828459045;

  /**
   * Natural logarithm of 10.
   */
  static final double LN10 =  2.302585092994046;

  /**
   * Natural logarithm of 2.
   */
  static final double LN2 =  0.6931471805599453;

  /**
   * Base-2 logarithm of E.
   */
  static final double LOG2E = 1.4426950408889634;

  /**
   * Base-10 logarithm of E.
   */
  static final double LOG10E = 0.4342944819032518;

  /**
   * The PI constant.
   */
  static final double PI = 3.1415926535897932;

  /**
   * Square root of 1/2.
   */
  static final double SQRT1_2 = 0.7071067811865476;

  /**
   * Square root of 2.
   */
  static final double SQRT2 = 1.4142135623730951;

  /**
   * Parses a [String] representation of an [int], and returns
   * an [int]. Throws a [BadNumberFormatException] if [str]
   * cannot be parsed as an [int].
   */
  static int parseInt(String str) native '''
  var match = /^\\s*[+-]?(?:(0[xX][abcdefABCDEF0-9]+)|\\d+)\\s*\$/.exec(str);
  if (!match) \$throw(new BadNumberFormatException(str));
  var isHex = !!match[1];
  var ret = parseInt(str, isHex ? 16 : 10);
  if (isNaN(ret)) \$throw(new BadNumberFormatException(str));
  return ret;''' { throw new BadNumberFormatException(""); }

  /**
   * Parses a [String] representation of a [double], and returns
   * a [double]. Throws a [BadNumberFormatException] if [str] cannot
   * be parsed as a [double].
   */
  static double parseDouble(String str) native '''var ret = parseFloat(str);
  if (isNaN(ret) && str != 'NaN') \$throw(new BadNumberFormatException(str));
  return ret;''' { throw new BadNumberFormatException(""); }

  static num min(num a, num b) native '''if (a == b) return a;
  if (a < b) {
    if (isNaN(b)) return b;
    else return a;
  }
  if (isNaN(a)) return a;
  else return b;''';

  static num max(num a, num b) native 'return (a >= b) ? a : b;';

  /**
   * Returns the arc tangent of [a]/[b] with sign according to quadrant.
   */
  static double atan2(num a, num b) native;

  /**
   * If the [exponent] is an integer the result is of the same type as [x].
   * Otherwise it is a [double].
   */
  static num pow(num x, num exponent) native;

  /**
   * Returns a random double greater than or equal to 0.0 and less
   * than 1.0.
   */
  static double random() native;

  static double sin(num x) native;
  static double cos(num x) native;
  static double tan(num x) native;
  static double acos(num x) native;
  static double asin(num x) native;
  static double atan(num x) native;
  static double sqrt(num x) native;
  static double exp(num x) native;
  static double log(num x) native;
}
