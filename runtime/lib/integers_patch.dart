// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of int.

patch class int {

  static bool is64Bit() => 1 << 32 is _Smi;

  static int _tryParseSmi(String str, int first, int last) {
    assert(first <= last);
    var ix = first;
    var sign = 1;
    var c = str.codeUnitAt(ix);
    // Check for leading '+' or '-'.
    if ((c == 0x2b) || (c == 0x2d)) {
      ix++;
      sign = 0x2c - c;  // -1 for '-', +1 for '+'.
      if (ix > last) {
        return null;  // Empty.
      }
    }
    int smiLimit = is64Bit() ? 18 : 9;
    if ((last - ix) >= smiLimit) {
      return null;  // May not fit into a Smi.
    }
    var result = 0;
    for (int i = ix; i <= last; i++) {
      var c = str.codeUnitAt(i) - 0x30;
      if ((c > 9) || (c < 0)) {
        return null;
      }
      result = result * 10 + c;
    }
    return sign * result;
  }

  static int _tryParseSmiWhitespace(String str) {
    int first = str._firstNonWhitespace();
    if (first < str.length) {
      int last = str._lastNonWhitespace();
      int res = _tryParseSmi(str, first, last);
      if (res != null) return res;
    }
    return _native_parse(str);
  }

  static int _parse(String str) {
    int res = _tryParseSmi(str, 0, str.length - 1);
    if (res != null) return res;
    return _tryParseSmiWhitespace(str);
  }

  static int _native_parse(String str) native "Integer_parse";

  static int _throwFormatException(String source, int position) {
    throw new FormatException("", source, position);
  }

  /* patch */ static int parse(String source,
                               { int radix,
                                 int onError(String str) }) {
    if (radix == null) {
      int result;
      if (source.isNotEmpty) result = _parse(source);
      if (result == null) {
        if (onError == null) {
          throw new FormatException("", source);
        }
        return onError(source);
      }
      return result;
    }
    return _slowParse(source, radix, onError);
  }

  /* patch */ const factory int.fromEnvironment(String name,
                                                {int defaultValue})
      native "Integer_fromEnvironment";

  static int _slowParse(String source, int radix, int onError(String str)) {
    if (source is! String) throw new ArgumentError(source);
    if (radix is! int) throw new ArgumentError("Radix is not an integer");
    if (radix < 2 || radix > 36) {
      throw new RangeError("Radix $radix not in range 2..36");
    }
    // Remove leading and trailing white space.
    int start = source._firstNonWhitespace();
    int i = start;
    if (onError == null) onError = (source) {
      throw new FormatException("Invalid radix-$radix number", source, i);
    };
    if (start == source.length) return onError(source);
    int end = source._lastNonWhitespace() + 1;

    bool negative = false;
    int result = 0;

    // The value 99 is used to represent a non-digit. It is too large to be
    // a digit value in any of the used bases.
    const NA = 99;
    const List<int> digits = const <int>[
      00, 01, 02, 03, 04, 05, 06, 07, 08, 09, NA, NA, NA, NA, NA, NA,  // 0x30
      NA, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,  // 0x40
      25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, NA, NA, NA, NA, NA,  // 0x50
      NA, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,  // 0x60
      25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, NA, NA, NA, NA, NA,  // 0x70
    ];

    int code = source.codeUnitAt(i);
    if (code == 0x2d || code == 0x2b) { // Starts with a plus or minus-sign.
      negative = (code == 0x2d);
      i++;
      if (i == end) return onError(source);
      code = source.codeUnitAt(i);
    }
    do {
      if (code < 0x30 || code > 0x7f) return onError(source);
      int digit = digits[code - 0x30];
      if (digit >= radix) return onError(source);
      result = result * radix + digit;
      i++;
      if (i == end) break;
      code = source.codeUnitAt(i);
    } while (true);
    return negative ? -result : result;
  }
}
