// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

/// VM implementation of int.
@patch
class int {
  @patch
  const factory int.fromEnvironment(String name, {int defaultValue})
      native "Integer_fromEnvironment";

  _Bigint _toBigint();
  int _shrFromInt(int other);
  int _shlFromInt(int other);
  int _bitAndFromSmi(_Smi other);
  int _bitAndFromInteger(int other);
  int _bitOrFromInteger(int other);
  int _bitXorFromInteger(int other);

  static int _tryParseSmi(String str, int first, int last) {
    assert(first <= last);
    var ix = first;
    var sign = 1;
    var c = str.codeUnitAt(ix);
    // Check for leading '+' or '-'.
    if ((c == 0x2b) || (c == 0x2d)) {
      ix++;
      sign = 0x2c - c; // -1 for '-', +1 for '+'.
      if (ix > last) {
        return null; // Empty.
      }
    }
    var smiLimit = 9;
    if ((last - ix) >= smiLimit) {
      return null; // May not fit into a Smi.
    }
    var result = 0;
    for (int i = ix; i <= last; i++) {
      var c = 0x30 ^ str.codeUnitAt(i);
      if (9 < c) {
        return null;
      }
      result = 10 * result + c;
    }
    return sign * result;
  }

  @patch
  static int parse(String source, {int radix, int onError(String source)}) {
    if (source == null) throw new ArgumentError("The source must not be null");
    if (source.isEmpty) return _throwFormatException(onError, source, 0, radix);
    if (radix == null || radix == 10) {
      // Try parsing immediately, without trimming whitespace.
      int result = _tryParseSmi(source, 0, source.length - 1);
      if (result != null) return result;
    } else if (radix < 2 || radix > 36) {
      throw new RangeError("Radix $radix not in range 2..36");
    }
    // Split here so improve odds of parse being inlined and the checks omitted.
    return _parse(source, radix, onError);
  }

  static int _parse(_StringBase source, int radix, onError) {
    int end = source._lastNonWhitespace() + 1;
    if (end == 0) {
      return _throwFormatException(onError, source, source.length, radix);
    }
    int start = source._firstNonWhitespace();

    int first = source.codeUnitAt(start);
    int sign = 1;
    if (first == 0x2b /* + */ || first == 0x2d /* - */) {
      sign = 0x2c - first; // -1 if '-', +1 if '+'.
      start++;
      if (start == end) {
        return _throwFormatException(onError, source, end, radix);
      }
      first = source.codeUnitAt(start);
    }
    if (radix == null) {
      // check for 0x prefix.
      int index = start;
      if (first == 0x30 /* 0 */) {
        index++;
        if (index == end) return 0;
        first = source.codeUnitAt(index);
        if ((first | 0x20) == 0x78 /* x */) {
          index++;
          if (index == end) {
            return _throwFormatException(onError, source, index, null);
          }
          int result = _parseRadix(source, 16, index, end, sign);
          if (result == null) {
            return _throwFormatException(onError, source, null, null);
          }
          return result;
        }
      }
      radix = 10;
    }
    int result = _parseRadix(source, radix, start, end, sign);
    if (result == null) {
      return _throwFormatException(onError, source, null, radix);
    }
    return result;
  }

  @patch
  static int tryParse(String source, {int radix}) {
    if (source == null) throw new ArgumentError("The source must not be null");
    if (source.isEmpty) return null;
    if (radix == null || radix == 10) {
      // Try parsing immediately, without trimming whitespace.
      int result = _tryParseSmi(source, 0, source.length - 1);
      if (result != null) return result;
    } else if (radix < 2 || radix > 36) {
      throw new RangeError("Radix $radix not in range 2..36");
    }
    return _parse(source, radix, _kNull);
  }

  static Null _kNull(_) => null;

  static int _throwFormatException(onError, source, index, radix) {
    if (onError != null) return onError(source);
    if (radix == null) {
      throw new FormatException("Invalid number", source, index);
    }
    throw new FormatException("Invalid radix-$radix number", source, index);
  }

  static int _parseRadix(
      String source, int radix, int start, int end, int sign) {
    int tableIndex = (radix - 2) * 2;
    int blockSize = _PARSE_LIMITS[tableIndex];
    int length = end - start;
    if (length <= blockSize) {
      _Smi smi = _parseBlock(source, radix, start, end);
      if (smi != null) return sign * smi;
      return null;
    }

    // Often cheaper than: int smallBlockSize = length % blockSize;
    // because digit count generally tends towards smaller. rather
    // than larger.
    int smallBlockSize = length;
    while (smallBlockSize >= blockSize) smallBlockSize -= blockSize;
    int result = 0;
    if (smallBlockSize > 0) {
      int blockEnd = start + smallBlockSize;
      _Smi smi = _parseBlock(source, radix, start, blockEnd);
      if (smi == null) return null;
      result = sign * smi;
      start = blockEnd;
    }
    int multiplier = _PARSE_LIMITS[tableIndex + 1];
    int positiveOverflowLimit = 0;
    int negativeOverflowLimit = 0;
    if (_limitIntsTo64Bits) {
      tableIndex = tableIndex << 1; // Pre-multiply by 2 for simpler indexing.
      positiveOverflowLimit = _int64OverflowLimits[tableIndex];
      if (positiveOverflowLimit == 0) {
        positiveOverflowLimit =
            _initInt64OverflowLimits(tableIndex, multiplier);
      }
      negativeOverflowLimit = _int64OverflowLimits[tableIndex + 1];
    }
    int blockEnd = start + blockSize;
    do {
      _Smi smi = _parseBlock(source, radix, start, blockEnd);
      if (smi == null) return null;
      if (_limitIntsTo64Bits) {
        if (result >= positiveOverflowLimit) {
          if ((result > positiveOverflowLimit) ||
              (smi > _int64OverflowLimits[tableIndex + 2])) {
            if (radix == 16 &&
                !(result >= _int64UnsignedOverflowLimit &&
                    (result > _int64UnsignedOverflowLimit ||
                        smi > _int64UnsignedSmiOverflowLimit)) &&
                blockEnd + blockSize > end) {
              return (result * multiplier) + smi;
            }
            return null;
          }
        } else if (result <= negativeOverflowLimit) {
          if ((result < negativeOverflowLimit) ||
              (smi > _int64OverflowLimits[tableIndex + 3])) {
            return null;
          }
        }
      }
      result = (result * multiplier) + (sign * smi);
      start = blockEnd;
      blockEnd = start + blockSize;
    } while (blockEnd <= end);
    return result;
  }

  // Parse block of digits into a Smi.
  static _Smi _parseBlock(String source, int radix, int start, int end) {
    _Smi result = 0;
    if (radix <= 10) {
      for (int i = start; i < end; i++) {
        int digit = source.codeUnitAt(i) ^ 0x30;
        if (digit >= radix) return null;
        result = radix * result + digit;
      }
    } else {
      for (int i = start; i < end; i++) {
        int char = source.codeUnitAt(i);
        int digit = char ^ 0x30;
        if (digit > 9) {
          digit = (char | 0x20) - (0x61 - 10);
          if (digit < 10 || digit >= radix) return null;
        }
        result = radix * result + digit;
      }
    }
    return result;
  }

  // For each radix, 2-36, how many digits are guaranteed to fit in a smi,
  // and magnitude of such a block (radix ** digit-count).
  static const _PARSE_LIMITS = const [
    30, 1073741824, // radix: 2
    18, 387420489,
    15, 1073741824,
    12, 244140625, //  radix: 5
    11, 362797056,
    10, 282475249,
    10, 1073741824,
    9, 387420489,
    9, 1000000000, //  radix: 10
    8, 214358881,
    8, 429981696,
    8, 815730721,
    7, 105413504,
    7, 170859375, //    radix: 15
    7, 268435456,
    7, 410338673,
    7, 612220032,
    7, 893871739,
    6, 64000000, //    radix: 20
    6, 85766121,
    6, 113379904,
    6, 148035889,
    6, 191102976,
    6, 244140625, //   radix: 25
    6, 308915776,
    6, 387420489,
    6, 481890304,
    6, 594823321,
    6, 729000000, //    radix: 30
    6, 887503681,
    6, 1073741824,
    5, 39135393,
    5, 45435424,
    5, 52521875, //    radix: 35
    5, 60466176,
  ];

  /// Flag indicating if integers are limited by 64 bits
  /// (`--limit-ints-to-64-bits` mode is enabled).
  static const _limitIntsTo64Bits = ((1 << 64) == 0);

  static const _maxInt64 = 0x7fffffffffffffff;
  static const _minInt64 = -_maxInt64 - 1;

  static const _int64UnsignedOverflowLimit = 0xfffffffff;
  static const _int64UnsignedSmiOverflowLimit = 0xfffffff;

  /// In the `--limit-ints-to-64-bits` mode calculation of the expression
  ///
  ///   result = (result * multiplier) + (sign * smi)
  ///
  /// in `_parseRadix()` may overflow 64-bit integers. In such case,
  /// `int.parse()` should stop with an error.
  ///
  /// This table is lazily filled with int64 overflow limits for result and smi.
  /// For each multiplier from `_PARSE_LIMITS[tableIndex + 1]` this table
  /// contains
  ///
  /// * `[tableIndex*2]` = positive limit for result
  /// * `[tableIndex*2 + 1]` = negative limit for result
  /// * `[tableIndex*2 + 2]` = limit for smi if result is exactly at positive limit
  /// * `[tableIndex*2 + 3]` = limit for smi if result is exactly at negative limit
  static final Int64List _int64OverflowLimits =
      new Int64List(_PARSE_LIMITS.length * 2);

  static int _initInt64OverflowLimits(int tableIndex, int multiplier) {
    _int64OverflowLimits[tableIndex] = _maxInt64 ~/ multiplier;
    _int64OverflowLimits[tableIndex + 1] = _minInt64 ~/ multiplier;
    _int64OverflowLimits[tableIndex + 2] = _maxInt64.remainder(multiplier);
    _int64OverflowLimits[tableIndex + 3] = -(_minInt64.remainder(multiplier));
    return _int64OverflowLimits[tableIndex];
  }
}
