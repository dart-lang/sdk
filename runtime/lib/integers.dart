// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

// This marker interface represents 64-bit integers in the compiler for type
// propagation and range analysis.  It is implemented by _Smi and _Mint.
abstract class _int64 implements int {}

abstract class _IntegerImplementation implements int {
  num operator +(num other) {
    var result = other._addFromInteger(this);
    if (result != null) return result;
    final _IntegerImplementation otherAsIntImpl = other;
    return otherAsIntImpl._toBigint()._addFromInteger(this);
  }

  num operator -(num other) {
    var result = other._subFromInteger(this);
    if (result != null) return result;
    final _IntegerImplementation otherAsIntImpl = other;
    return otherAsIntImpl._toBigint()._subFromInteger(this);
  }

  num operator *(num other) {
    var result = other._mulFromInteger(this);
    if (result != null) return result;
    final _IntegerImplementation otherAsIntImpl = other;
    return otherAsIntImpl._toBigint()._mulFromInteger(this);
  }

  int operator ~/(num other) {
    if ((other is int) && (other == 0)) {
      throw const IntegerDivisionByZeroException();
    }
    var result = other._truncDivFromInteger(this);
    if (result != null) return result;
    final _IntegerImplementation otherAsIntImpl = other;
    return otherAsIntImpl._toBigint()._truncDivFromInteger(this);
  }

  double operator /(num other) {
    return this.toDouble() / other.toDouble();
  }

  num operator %(num other) {
    if ((other is int) && (other == 0)) {
      throw const IntegerDivisionByZeroException();
    }
    var result = other._moduloFromInteger(this);
    if (result != null) return result;
    final _IntegerImplementation otherAsIntImpl = other;
    return otherAsIntImpl._toBigint()._moduloFromInteger(this);
  }

  int operator -() {
    return 0 - this;
  }

  int operator &(int other) {
    var result = other._bitAndFromInteger(this);
    if (result != null) return result;
    return other._toBigint()._bitAndFromInteger(this);
  }

  int operator |(int other) {
    var result = other._bitOrFromInteger(this);
    if (result != null) return result;
    return other._toBigint()._bitOrFromInteger(this);
  }

  int operator ^(int other) {
    var result = other._bitXorFromInteger(this);
    if (result != null) return result;
    return other._toBigint()._bitXorFromInteger(this);
  }

  num remainder(num other) {
    return other._remainderFromInteger(this);
  }

  int _bitAndFromSmi(_Smi other) native "Integer_bitAndFromInteger";
  int _bitAndFromInteger(int other) native "Integer_bitAndFromInteger";
  int _bitOrFromInteger(int other) native "Integer_bitOrFromInteger";
  int _bitXorFromInteger(int other) native "Integer_bitXorFromInteger";
  int _addFromInteger(int other) native "Integer_addFromInteger";
  int _subFromInteger(int other) native "Integer_subFromInteger";
  int _mulFromInteger(int other) native "Integer_mulFromInteger";
  int _truncDivFromInteger(int other) native "Integer_truncDivFromInteger";
  int _moduloFromInteger(int other) native "Integer_moduloFromInteger";
  int _remainderFromInteger(int other) {
    return other - (other ~/ this) * this;
  }

  int operator >>(int other) {
    var result = other._shrFromInt(this);
    if (result != null) return result;
    return other._toBigint()._shrFromInt(this);
  }

  int operator <<(int other) {
    var result = other._shlFromInt(this);
    if (result != null) return result;
    return other._toBigint()._shlFromInt(this);
  }

  bool operator <(num other) {
    return other > this;
  }

  bool operator >(num other) {
    return other._greaterThanFromInteger(this);
  }

  bool operator >=(num other) {
    return (this == other) || (this > other);
  }

  bool operator <=(num other) {
    return (this == other) || (this < other);
  }

  bool _greaterThanFromInteger(int other)
      native "Integer_greaterThanFromInteger";

  bool operator ==(other) {
    if (other is num) {
      return other._equalToInteger(this);
    }
    return false;
  }

  bool _equalToInteger(int other) native "Integer_equalToInteger";
  int abs() {
    return this < 0 ? -this : this;
  }

  int get sign {
    return (this > 0) ? 1 : (this < 0) ? -1 : 0;
  }

  bool get isEven => ((this & 1) == 0);
  bool get isOdd => !isEven;
  bool get isNaN => false;
  bool get isNegative => this < 0;
  bool get isInfinite => false;
  bool get isFinite => true;

  int toUnsigned(int width) {
    return this & ((1 << width) - 1);
  }

  int toSigned(int width) {
    // The value of binary number weights each bit by a power of two.  The
    // twos-complement value weights the sign bit negatively.  We compute the
    // value of the negative weighting by isolating the sign bit with the
    // correct power of two weighting and subtracting it from the value of the
    // lower bits.
    int signMask = 1 << (width - 1);
    return (this & (signMask - 1)) - (this & signMask);
  }

  int compareTo(num other) {
    const int EQUAL = 0, LESS = -1, GREATER = 1;
    if (other is double) {
      const int MAX_EXACT_INT_TO_DOUBLE = 9007199254740992; // 2^53.
      const int MIN_EXACT_INT_TO_DOUBLE = -MAX_EXACT_INT_TO_DOUBLE;
      double d = other;
      if (d.isInfinite) {
        return d == double.NEGATIVE_INFINITY ? GREATER : LESS;
      }
      if (d.isNaN) {
        return LESS;
      }
      if (MIN_EXACT_INT_TO_DOUBLE <= this && this <= MAX_EXACT_INT_TO_DOUBLE) {
        // Let the double implementation deal with -0.0.
        return -(d.compareTo(this.toDouble()));
      } else {
        // If abs(other) > MAX_EXACT_INT_TO_DOUBLE, then other has an integer
        // value (no bits below the decimal point).
        other = d.toInt();
      }
    }
    if (this < other) {
      return LESS;
    } else if (this > other) {
      return GREATER;
    } else {
      return EQUAL;
    }
  }

  int round() {
    return this;
  }

  int floor() {
    return this;
  }

  int ceil() {
    return this;
  }

  int truncate() {
    return this;
  }

  double roundToDouble() {
    return this.toDouble();
  }

  double floorToDouble() {
    return this.toDouble();
  }

  double ceilToDouble() {
    return this.toDouble();
  }

  double truncateToDouble() {
    return this.toDouble();
  }

  num clamp(num lowerLimit, num upperLimit) {
    if (lowerLimit is! num) {
      throw new ArgumentError.value(lowerLimit, "lowerLimit", "not a number");
    }
    if (upperLimit is! num) {
      throw new ArgumentError.value(upperLimit, "upperLimit", "not a number");
    }

    // Special case for integers.
    if (lowerLimit is int && upperLimit is int && lowerLimit <= upperLimit) {
      if (this < lowerLimit) return lowerLimit;
      if (this > upperLimit) return upperLimit;
      return this;
    }
    // Generic case involving doubles, and invalid integer ranges.
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw new ArgumentError(lowerLimit);
    }
    if (lowerLimit.isNaN) return lowerLimit;
    // Note that we don't need to care for -0.0 for the lower limit.
    if (this < lowerLimit) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  int toInt() {
    return this;
  }

  double toDouble() {
    return new _Double.fromInteger(this);
  }

  _Bigint _toBigint() {
    return new _Bigint._fromInt(this);
  }

  num _toBigintOrDouble() {
    return _toBigint();
  }

  String toStringAsFixed(int fractionDigits) {
    return this.toDouble().toStringAsFixed(fractionDigits);
  }

  String toStringAsExponential([int fractionDigits]) {
    return this.toDouble().toStringAsExponential(fractionDigits);
  }

  String toStringAsPrecision(int precision) {
    return this.toDouble().toStringAsPrecision(precision);
  }

  static const _digits = "0123456789abcdefghijklmnopqrstuvwxyz";

  String toRadixString(int radix) {
    if (radix < 2 || 36 < radix) {
      throw new RangeError.range(radix, 2, 36, "radix");
    }
    if (radix & (radix - 1) == 0) {
      return _toPow2String(radix);
    }
    if (radix == 10) return this.toString();
    final bool isNegative = this < 0;
    int value = isNegative ? -this : this;
    List temp = new List();
    do {
      int digit = value % radix;
      value ~/= radix;
      temp.add(_digits.codeUnitAt(digit));
    } while (value > 0);
    if (isNegative) temp.add(0x2d); // '-'.

    _OneByteString string = _OneByteString._allocate(temp.length);
    for (int i = 0, j = temp.length; j > 0; i++) {
      string._setAt(i, temp[--j]);
    }
    return string;
  }

  String _toPow2String(int radix) {
    int value = this;
    if (value == 0) return "0";
    assert(radix & (radix - 1) == 0);
    var negative = value < 0;
    var bitsPerDigit = radix.bitLength - 1;
    var length = 0;
    if (negative) {
      value = -value;
      length = 1;
    }
    // Integer division, rounding up, to find number of _digits.
    length += (value.bitLength + bitsPerDigit - 1) ~/ bitsPerDigit;
    _OneByteString string = _OneByteString._allocate(length);
    string._setAt(0, 0x2d); // '-'. Is overwritten if not negative.
    var mask = radix - 1;
    do {
      string._setAt(--length, _digits.codeUnitAt(value & mask));
      value >>= bitsPerDigit;
    } while (value > 0);
    return string;
  }

  // Returns pow(this, e) % m.
  int modPow(int e, int m) {
    if (e is! int) {
      throw new ArgumentError.value(e, "exponent", "not an integer");
    }
    if (m is! int) {
      throw new ArgumentError.value(m, "modulus", "not an integer");
    }
    if (e < 0) throw new RangeError.range(e, 0, null, "exponent");
    if (m <= 0) throw new RangeError.range(m, 1, null, "modulus");
    if (e == 0) return 1;
    if (e is _Bigint || m is _Bigint) {
      return _toBigint().modPow(e, m);
    }
    int b = this;
    if (b < 0 || b > m) {
      b %= m;
    }
    int r = 1;
    while (e > 0) {
      if (e.isOdd) {
        r = (r * b) % m;
      }
      e >>= 1;
      b = (b * b) % m;
    }
    return r;
  }

  // If inv is false, returns gcd(x, y).
  // If inv is true and gcd(x, y) = 1, returns d, so that c*x + d*y = 1.
  // If inv is true and gcd(x, y) != 1, throws Exception("Not coprime").
  static int _binaryGcd(int x, int y, bool inv) {
    int s = 0;
    if (!inv) {
      while (x.isEven && y.isEven) {
        x >>= 1;
        y >>= 1;
        s++;
      }
      if (y.isOdd) {
        var t = x;
        x = y;
        y = t;
      }
    }
    final bool ac = x.isEven;
    int u = x;
    int v = y;
    int a = 1, b = 0, c = 0, d = 1;
    do {
      while (u.isEven) {
        u >>= 1;
        if (ac) {
          if (!a.isEven || !b.isEven) {
            a += y;
            b -= x;
          }
          a >>= 1;
        } else if (!b.isEven) {
          b -= x;
        }
        b >>= 1;
      }
      while (v.isEven) {
        v >>= 1;
        if (ac) {
          if (!c.isEven || !d.isEven) {
            c += y;
            d -= x;
          }
          c >>= 1;
        } else if (!d.isEven) {
          d -= x;
        }
        d >>= 1;
      }
      if (u >= v) {
        u -= v;
        if (ac) a -= c;
        b -= d;
      } else {
        v -= u;
        if (ac) c -= a;
        d -= b;
      }
    } while (u != 0);
    if (!inv) return v << s;
    if (v != 1) {
      throw new Exception("Not coprime");
    }
    if (d < 0) {
      d += x;
      if (d < 0) d += x;
    } else if (d > x) {
      d -= x;
      if (d > x) d -= x;
    }
    return d;
  }

  // Returns 1/this % m, with m > 0.
  int modInverse(int m) {
    if (m is! int) {
      throw new ArgumentError.value(m, "modulus", "not an integer");
    }
    if (m <= 0) throw new RangeError.range(m, 1, null, "modulus");
    if (m == 1) return 0;
    if (m is _Bigint) {
      return _toBigint().modInverse(m);
    }
    int t = this;
    if ((t < 0) || (t >= m)) t %= m;
    if (t == 1) return 1;
    if ((t == 0) || (t.isEven && m.isEven)) {
      throw new Exception("Not coprime");
    }
    return _binaryGcd(m, t, true);
  }

  // Returns gcd of abs(this) and abs(other).
  int gcd(int other) {
    if (other is! int) {
      throw new ArgumentError.value(other, "other", "not an integer");
    }
    int x = this.abs();
    int y = other.abs();
    if (x == 0) return y;
    if (y == 0) return x;
    if ((x == 1) || (y == 1)) return 1;
    if (y is _Bigint) {
      return x._toBigint().gcd(y);
    }
    return _binaryGcd(x, y, false);
  }
}

class _Smi extends _IntegerImplementation implements _int64 {
  factory _Smi._uninstantiable() {
    throw new UnsupportedError("_Smi can only be allocated by the VM");
  }
  int get hashCode => this;
  int get _identityHashCode => this;
  int operator ~() native "Smi_bitNegate";
  int get bitLength native "Smi_bitLength";

  int operator &(int other) => other._bitAndFromSmi(this);

  int _bitAndFromSmi(_Smi other) native "Smi_bitAndFromSmi";
  int _shrFromInt(int other) native "Smi_shrFromInt";
  int _shlFromInt(int other) native "Smi_shlFromInt";

  /**
   * The digits of '00', '01', ... '99' as a single array.
   *
   * Get the digits of `n`, with `0 <= n < 100`, as
   * `_digitTable[n * 2]` and `_digitTable[n * 2 + 1]`.
   */
  static const _digitTable = const [
    0x30, 0x30, 0x30, 0x31, 0x30, 0x32, 0x30, 0x33, //
    0x30, 0x34, 0x30, 0x35, 0x30, 0x36, 0x30, 0x37, //
    0x30, 0x38, 0x30, 0x39, 0x31, 0x30, 0x31, 0x31, //
    0x31, 0x32, 0x31, 0x33, 0x31, 0x34, 0x31, 0x35, //
    0x31, 0x36, 0x31, 0x37, 0x31, 0x38, 0x31, 0x39, //
    0x32, 0x30, 0x32, 0x31, 0x32, 0x32, 0x32, 0x33, //
    0x32, 0x34, 0x32, 0x35, 0x32, 0x36, 0x32, 0x37, //
    0x32, 0x38, 0x32, 0x39, 0x33, 0x30, 0x33, 0x31, //
    0x33, 0x32, 0x33, 0x33, 0x33, 0x34, 0x33, 0x35, //
    0x33, 0x36, 0x33, 0x37, 0x33, 0x38, 0x33, 0x39, //
    0x34, 0x30, 0x34, 0x31, 0x34, 0x32, 0x34, 0x33, //
    0x34, 0x34, 0x34, 0x35, 0x34, 0x36, 0x34, 0x37, //
    0x34, 0x38, 0x34, 0x39, 0x35, 0x30, 0x35, 0x31, //
    0x35, 0x32, 0x35, 0x33, 0x35, 0x34, 0x35, 0x35, //
    0x35, 0x36, 0x35, 0x37, 0x35, 0x38, 0x35, 0x39, //
    0x36, 0x30, 0x36, 0x31, 0x36, 0x32, 0x36, 0x33, //
    0x36, 0x34, 0x36, 0x35, 0x36, 0x36, 0x36, 0x37, //
    0x36, 0x38, 0x36, 0x39, 0x37, 0x30, 0x37, 0x31, //
    0x37, 0x32, 0x37, 0x33, 0x37, 0x34, 0x37, 0x35, //
    0x37, 0x36, 0x37, 0x37, 0x37, 0x38, 0x37, 0x39, //
    0x38, 0x30, 0x38, 0x31, 0x38, 0x32, 0x38, 0x33, //
    0x38, 0x34, 0x38, 0x35, 0x38, 0x36, 0x38, 0x37, //
    0x38, 0x38, 0x38, 0x39, 0x39, 0x30, 0x39, 0x31, //
    0x39, 0x32, 0x39, 0x33, 0x39, 0x34, 0x39, 0x35, //
    0x39, 0x36, 0x39, 0x37, 0x39, 0x38, 0x39, 0x39, //
  ];

  /**
   * Result of int.toString for -99, -98, ..., 98, 99.
   */
  static const _smallLookupTable = const [
    "-99", "-98", "-97", "-96", "-95", "-94", "-93", "-92", "-91", "-90", //
    "-89", "-88", "-87", "-86", "-85", "-84", "-83", "-82", "-81", "-80", //
    "-79", "-78", "-77", "-76", "-75", "-74", "-73", "-72", "-71", "-70", //
    "-69", "-68", "-67", "-66", "-65", "-64", "-63", "-62", "-61", "-60", //
    "-59", "-58", "-57", "-56", "-55", "-54", "-53", "-52", "-51", "-50", //
    "-49", "-48", "-47", "-46", "-45", "-44", "-43", "-42", "-41", "-40", //
    "-39", "-38", "-37", "-36", "-35", "-34", "-33", "-32", "-31", "-30", //
    "-29", "-28", "-27", "-26", "-25", "-24", "-23", "-22", "-21", "-20", //
    "-19", "-18", "-17", "-16", "-15", "-14", "-13", "-12", "-11", "-10", //
    "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "0", //
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", //
    "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", //
    "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", //
    "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", //
    "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", //
    "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", //
    "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", //
    "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", //
    "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", //
    "91", "92", "93", "94", "95", "96", "97", "98", "99" //
  ];

  // Powers of 10 above 1000000 are indistinguishable by eye.
  static const int _POW_10_7 = 10000000;
  static const int _POW_10_8 = 100000000;
  static const int _POW_10_9 = 1000000000;

  // Find the number of decimal digits in a positive smi.
  // Never called with numbers < 100. These are handled before calling.
  static int _positiveBase10Length(var smi) {
    // A positive smi has length <= 19 if 63-bit,  <=10 if 31-bit.
    // Avoid comparing a 31-bit smi to a non-smi.
    if (smi < 1000) return 3;
    if (smi < 10000) return 4;
    if (smi < _POW_10_7) {
      if (smi < 100000) return 5;
      if (smi < 1000000) return 6;
      return 7;
    }
    if (smi < _POW_10_8) return 8;
    if (smi < _POW_10_9) return 9;
    smi = smi ~/ _POW_10_9;
    // Handle numbers < 100 before calling recursively.
    if (smi < 10) return 10;
    if (smi < 100) return 11;
    return 9 + _positiveBase10Length(smi);
  }

  String toString() {
    if (this < 100 && this > -100) return _smallLookupTable[this + 99];
    if (this < 0) return _negativeToString(this);
    // Inspired by Andrei Alexandrescu: "Three Optimization Tips for C++"
    // Avoid expensive remainder operation by doing it on more than
    // one digit at a time.
    const int DIGIT_ZERO = 0x30;
    int length = _positiveBase10Length(this);
    _OneByteString result = _OneByteString._allocate(length);
    int index = length - 1;
    var smi = this;
    do {
      // Two digits at a time.
      var twoDigits = smi.remainder(100);
      smi = smi ~/ 100;
      int digitIndex = twoDigits * 2;
      result._setAt(index, _digitTable[digitIndex + 1]);
      result._setAt(index - 1, _digitTable[digitIndex]);
      index -= 2;
    } while (smi >= 100);
    if (smi < 10) {
      // Character code for '0'.
      result._setAt(index, DIGIT_ZERO + smi);
    } else {
      // No remainder for this case.
      int digitIndex = smi * 2;
      result._setAt(index, _digitTable[digitIndex + 1]);
      result._setAt(index - 1, _digitTable[digitIndex]);
    }
    return result;
  }

  // Find the number of decimal digits in a negative smi.
  // Never called with numbers > -100. These are handled before calling.
  static int _negativeBase10Length(var negSmi) {
    // A negative smi has length <= 19 if 63-bit, <=10 if 31-bit.
    // Avoid comparing a 31-bit smi to a non-smi.
    if (negSmi > -1000) return 3;
    if (negSmi > -10000) return 4;
    if (negSmi > -_POW_10_7) {
      if (negSmi > -100000) return 5;
      if (negSmi > -1000000) return 6;
      return 7;
    }
    if (negSmi > -_POW_10_8) return 8;
    if (negSmi > -_POW_10_9) return 9;
    negSmi = negSmi ~/ _POW_10_9;
    // Handle numbers > -100 before calling recursively.
    if (negSmi > -10) return 10;
    if (negSmi > -100) return 11;
    return 9 + _negativeBase10Length(negSmi);
  }

  // Convert a negative smi to a string.
  // Doesn't negate the smi to avoid negating the most negative smi, which
  // would become a non-smi.
  static String _negativeToString(int negSmi) {
    // Character code for '-'
    const int MINUS_SIGN = 0x2d;
    // Character code for '0'.
    const int DIGIT_ZERO = 0x30;
    if (negSmi > -10) {
      return _OneByteString._allocate(2)
        .._setAt(0, MINUS_SIGN)
        .._setAt(1, DIGIT_ZERO - negSmi);
    }
    if (negSmi > -100) {
      int digitIndex = 2 * -negSmi;
      return _OneByteString._allocate(3)
        .._setAt(0, MINUS_SIGN)
        .._setAt(1, _digitTable[digitIndex])
        .._setAt(2, _digitTable[digitIndex + 1]);
    }
    // Number of digits, not including minus.
    int digitCount = _negativeBase10Length(negSmi);
    _OneByteString result = _OneByteString._allocate(digitCount + 1);
    result._setAt(0, MINUS_SIGN); // '-'.
    int index = digitCount;
    do {
      var twoDigits = negSmi.remainder(100);
      negSmi = negSmi ~/ 100;
      int digitIndex = -twoDigits * 2;
      result._setAt(index, _digitTable[digitIndex + 1]);
      result._setAt(index - 1, _digitTable[digitIndex]);
      index -= 2;
    } while (negSmi <= -100);
    if (negSmi > -10) {
      result._setAt(index, DIGIT_ZERO - negSmi);
    } else {
      // No remainder necessary for this case.
      int digitIndex = -negSmi * 2;
      result._setAt(index, _digitTable[digitIndex + 1]);
      result._setAt(index - 1, _digitTable[digitIndex]);
    }
    return result;
  }
}

// Represents integers that cannot be represented by Smi but fit into 64bits.
class _Mint extends _IntegerImplementation implements _int64 {
  factory _Mint._uninstantiable() {
    throw new UnsupportedError("_Mint can only be allocated by the VM");
  }
  int get hashCode => this;
  int get _identityHashCode => this;
  int operator ~() native "Mint_bitNegate";
  int get bitLength native "Mint_bitLength";

  int _bitAndFromSmi(_Smi other) => _bitAndFromInteger(other);

  // Shift by mint exceeds range that can be handled by the VM.
  int _shrFromInt(int other) {
    if (other < 0) {
      return -1;
    } else {
      return 0;
    }
  }

  int _shlFromInt(int other) native "Mint_shlFromInt";
}
