// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of double.

patch class double {

  static double _nativeParse(String str,
                             int start, int end) native "Double_parse";

  static double _tryParseDouble(var str, var start, var end) {
    assert(start < end);
    const int _DOT = 0x2e;    // '.'
    const int _ZERO = 0x30;   // '0'
    const int _MINUS = 0x2d;  // '-'
    const int _N = 0x4e;      // 'N'
    const int _a = 0x61;      // 'a'
    const int _I = 0x49;      // 'I'
    const int _e = 0x65;      // 'e'
    int exponent = 0;
    // Set to non-zero if a digit is seen. Avoids accepting ".".
    bool digitsSeen = false;
    // Added to exponent for each digit. Set to -1 when seeing '.'.
    int exponentDelta = 0;
    double doubleValue = 0.0;
    double sign = 1.0;
    int firstChar = str.codeUnitAt(start);
    if (firstChar == _MINUS) {
      sign = -1.0;
      start++;
      if (start == end) return null;
      firstChar = str.codeUnitAt(start);
    }
    if (firstChar == _I) {
      if (end == start + 8 && str.startsWith("nfinity", start + 1)) {
        return sign * double.INFINITY;
      }
      return null;
    }
    if (firstChar == _N) {
      if (end == start + 3 &&
          str.codeUnitAt(start + 1) == _a &&
          str.codeUnitAt(start + 2) == _N) {
        return double.NAN;
      }
      return null;
    }

    int firstDigit = firstChar ^ _ZERO;
    if (firstDigit <= 9) {
      start++;
      doubleValue = firstDigit.toDouble();
      digitsSeen = true;
    }
    for (int i = start; i < end; i++) {
      int c = str.codeUnitAt(i);
      int digit = c ^ _ZERO;  // '0'-'9' characters are now 0-9 integers.
      if (digit <= 9) {
        doubleValue = 10.0 * doubleValue + digit;
        // Doubles at or above this value (2**53) might have lost precission.
        const double MAX_EXACT_DOUBLE = 9007199254740992.0;
        if (doubleValue >= MAX_EXACT_DOUBLE) return null;
        exponent += exponentDelta;
        digitsSeen = true;
      } else if (c == _DOT && exponentDelta == 0) {
        exponentDelta = -1;
      } else if ((c | 0x20) == _e) {
        i++;
        if (i == end) return null;
        // int._tryParseSmi treats its end argument as inclusive.
        int expPart = int._tryParseSmi(str, i, end - 1);
        if (expPart == null) return null;
        exponent += expPart;
        break;
      } else {
        return null;
      }
    }
    if (!digitsSeen) return null;  // No digits.
    if (exponent == 0) return sign * doubleValue;
    // Powers of 10 up to 10^22 are representable as doubles.
    // Powers of 10 above that are only approximate due to lack of precission.
    const P10 = const [
                            1.0,  /*  0 */
                           10.0,
                          100.0,
                         1000.0,
                        10000.0,
                       100000.0,  /*  5 */
                      1000000.0,
                     10000000.0,
                    100000000.0,
                   1000000000.0,
                  10000000000.0,  /* 10 */
                 100000000000.0,
                1000000000000.0,
               10000000000000.0,
              100000000000000.0,
             1000000000000000.0,  /*  15 */
            10000000000000000.0,
           100000000000000000.0,
          1000000000000000000.0,
         10000000000000000000.0,
        100000000000000000000.0,  /*  20 */
       1000000000000000000000.0,
      10000000000000000000000.0,
    ];
    if (exponent < 0) {
      int negExponent = -exponent;
      if (negExponent >= P10.length) return null;
      return sign * (doubleValue / P10[negExponent]);
    }
    if (exponent > P10.length) return null;
    return sign * (doubleValue * P10[exponent]);
  }

  static double _parse(var str) {
    int len = str.length;
    int start = str._firstNonWhitespace();
    if (start == len) return null;  // All whitespace.
    int end = str._lastNonWhitespace() + 1;
    assert(start < end);
    var result = _tryParseDouble(str, start, end);
    if (result != null) return result;
    return _nativeParse(str, start, end);
  }

  /* patch */ static double parse(String str,
                                  [double onError(String str)]) {
    var result = _parse(str);
    if (result == null) {
      if (onError == null) throw new FormatException("Invalid double", str);
      return onError(str);
    }
    return result;
  }
}
