// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of int.

patch class int {

  /* patch */ const factory int.fromEnvironment(String name,
                                                {int defaultValue})
      native "Integer_fromEnvironment";

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
    var smiLimit = is64Bit() ? 18 : 9;
    if ((last - ix) >= smiLimit) {
      return null;  // May not fit into a Smi.
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

  /* patch */ static int parse(String source,
                               { int radix,
                                 int onError(String str) }) {
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

  static int _parse(String source, int radix, onError) {
    int end = source._lastNonWhitespace() + 1;
    if (end == 0) {
      return _throwFormatException(onError, source, source.length, radix);
    }
    int start = source._firstNonWhitespace();

    int first = source.codeUnitAt(start);
    int sign = 1;
    if (first == 0x2b /* + */ || first == 0x2d /* - */) {
      sign = 0x2c - first;  // -1 if '-', +1 if '+'.
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

  static int _throwFormatException(onError, source, index, radix) {
    if (onError != null) return onError(source);
    if (radix == null) {
      throw new FormatException("Invalid number", source, index);
    }
    throw new FormatException("Invalid radix-$radix number", source, index);
  }

  static int _parseRadix(String source, int radix,
                         int start, int end, int sign) {
    int tableIndex = (radix - 2) * 4 + (int.is64Bit() ? 2 : 0);
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
    _Smi multiplier = _PARSE_LIMITS[tableIndex + 1];
    int blockEnd = start + blockSize;
    do {
      _Smi smi = _parseBlock(source, radix, start, blockEnd);
      if (smi == null) return null;
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
  // 32-bit limit/multiplier at (radix - 2)*4, 64-bit limit at (radix-2)*4+1
  static const _PARSE_LIMITS = const [
    30, 1073741824,  62, 4611686018427387904,  /* radix: 2 */
    18,  387420489,  39, 4052555153018976267,
    15, 1073741824,  30, 1152921504606846976,
    12,  244140625,  26, 1490116119384765625,  /* radix: 5 */
    11,  362797056,  23,  789730223053602816,
    10,  282475249,  22, 3909821048582988049,
    10, 1073741824,  20, 1152921504606846976,
     9,  387420489,  19, 1350851717672992089,
     9, 1000000000,  18, 1000000000000000000,  /* radix: 10 */
     8,  214358881,  17,  505447028499293771,
     8,  429981696,  17, 2218611106740436992,
     8,  815730721,  16,  665416609183179841,
     7,  105413504,  16, 2177953337809371136,
     7,  170859375,  15,  437893890380859375,   /* radix: 15 */
     7,  268435456,  15, 1152921504606846976,
     7,  410338673,  15, 2862423051509815793,
     7,  612220032,  14,  374813367582081024,
     7,  893871739,  14,  799006685782884121,
     6,   64000000,  14, 1638400000000000000,  /* radix: 20 */
     6,   85766121,  14, 3243919932521508681,
     6,  113379904,  13,  282810057883082752,
     6,  148035889,  13,  504036361936467383,
     6,  191102976,  13,  876488338465357824,
     6,  244140625,  13, 1490116119384765625,  /* radix: 25 */
     6,  308915776,  13, 2481152873203736576,
     6,  387420489,  13, 4052555153018976267,
     6,  481890304,  12,  232218265089212416,
     6,  594823321,  12,  353814783205469041,
     6,  729000000,  12,  531441000000000000,  /* radix: 30 */
     6,  887503681,  12,  787662783788549761,
     6, 1073741824,  12, 1152921504606846976,
     5,   39135393,  12, 1667889514952984961,
     5,   45435424,  12, 2386420683693101056,
     5,   52521875,  12, 3379220508056640625,  /* radix: 35 */
     5,   60466176,  11,  131621703842267136,
  ];
}
