// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of fixnum;

/**
 * An immutable 64-bit signed integer, in the range [-2^63, 2^63 - 1].
 * Arithmetic operations may overflow in order to maintain this range.
 */
class int64 implements intx {

  // A 64-bit integer is represented internally as three non-negative
  // integers, storing the 22 low, 22 middle, and 20 high bits of the
  // 64-bit value.  _l (low) and _m (middle) are in the range
  // [0, 2^22 - 1] and _h (high) is in the range [0, 2^20 - 1].
  int _l, _m, _h;

  // Note: instances of int64 are immutable outside of this library,
  // therefore we may return a reference to an existing instance.
  // We take care to perform mutation only on internally-generated
  // instances before they are exposed to external code.

  // Note: several functions require _BITS == 22 -- do not change this value.
  static const int _BITS = 22;
  static const int _BITS01 = 44; // 2 * _BITS
  static const int _BITS2 = 20; // 64 - _BITS01
  static const int _MASK = 4194303; // (1 << _BITS) - 1
  static const int _MASK_2 = 1048575; // (1 << _BITS2) - 1
  static const int _SIGN_BIT = 19; // _BITS2 - 1
  static const int _SIGN_BIT_VALUE = 524288; // 1 << _SIGN_BIT

  // Cached constants
  static int64 _MAX_VALUE;
  static int64 _MIN_VALUE;
  static int64 _ZERO;
  static int64 _ONE;
  static int64 _TWO;

  // Precompute the radix strings for MIN_VALUE to avoid the problem
  // of overflow of -MIN_VALUE.
  static List<String> _minValues = const <String>[
      null, null,
      "-1000000000000000000000000000000000000000000000000000000000000000", // 2
      "-2021110011022210012102010021220101220222", // base 3
      "-20000000000000000000000000000000", // base 4
      "-1104332401304422434310311213", // base 5
      "-1540241003031030222122212", // base 6
      "-22341010611245052052301", // base 7
      "-1000000000000000000000", // base 8
      "-67404283172107811828", // base 9
      "-9223372036854775808", // base 10
      "-1728002635214590698", // base 11
      "-41A792678515120368", // base 12
      "-10B269549075433C38", // base 13
      "-4340724C6C71DC7A8", // base 14
      "-160E2AD3246366808", // base 15
      "-8000000000000000" // base 16
  ];

  // The remainder of the last divide operation.
  static int64 _remainder;

  /**
   * The maximum positive value attainable by an [int64], namely
   * 9,223,372,036,854,775,807.
   */
  static int64 get MAX_VALUE {
    if (_MAX_VALUE == null) {
      _MAX_VALUE = new int64._bits(_MASK, _MASK, _MASK_2 >> 1);
    }
    return _MAX_VALUE;
  }

  /**
   * The minimum positive value attainable by an [int64], namely
   * -9,223,372,036,854,775,808.
   */
  static int64 get MIN_VALUE {
    if (_MIN_VALUE == null) {
      _MIN_VALUE = new int64._bits(0, 0, _SIGN_BIT_VALUE);
    }
    return _MIN_VALUE;
  }

  /**
   * An [int64] constant equal to 0.
   */
  static int64 get ZERO {
    if (_ZERO == null) {
      _ZERO = new int64();
    }
    return _ZERO;
  }

  /**
   * An [int64] constant equal to 1.
   */
  static int64 get ONE {
    if (_ONE == null) {
      _ONE = new int64._bits(1, 0, 0);
    }
    return _ONE;
  }

  /**
   * An [int64] constant equal to 2.
   */
  static int64 get TWO {
    if (_TWO == null) {
      _TWO = new int64._bits(2, 0, 0);
    }
    return _TWO;
  }

  /**
   * Parses a [String] in a given [radix] between 2 and 16 and returns an
   * [int64].
   */
  // TODO(rice) - make this faster by converting several digits at once.
  static int64 parseRadix(String s, int radix) {
    if ((radix <= 1) || (radix > 16)) {
      throw "Bad radix: $radix";
    }
    int64 x = ZERO;
    int i = 0;
    bool negative = false;
    if (s[0] == '-') {
      negative = true;
      i++;
    }
    for (; i < s.length; i++) {
      int c = s.charCodeAt(i);
      int digit = int32._decodeHex(c);
      if (digit < 0 || digit >= radix) {
        throw new Exception("Non-radix char code: $c");
      }
      x = (x * radix) + digit;
    }
    return negative ? -x : x;
  }

  /**
   * Parses a decimal [String] and returns an [int64].
   */
  static int64 parseInt(String s) => parseRadix(s, 10);

  /**
   * Parses a hexadecimal [String] and returns an [int64].
   */
  static int64 parseHex(String s) => parseRadix(s, 16);

  //
  // Public constructors
  //

  /**
   * Constructs an [int64] equal to 0.
   */
  int64() : _l = 0, _m = 0, _h = 0;

  /**
   * Constructs an [int64] with a given [int] value.
   */
  int64.fromInt(int value) {
    bool negative = false;
    if (value < 0) {
      negative = true;
      value = -value - 1;
    }
    if (_haveBigInts) {
      _l = value & _MASK;
      _m = (value >> _BITS) & _MASK;
      _h = (value >> _BITS01) & _MASK_2;
    } else {
      // Avoid using bitwise operations that coerce their input to 32 bits.
      _h = value ~/ 17592186044416; // 2^44
      value -= _h * 17592186044416;
      _m = value ~/ 4194304; // 2^22
      value -= _m * 4194304;
      _l = value;
    }

    if (negative) {
      _l = ~_l & _MASK;
      _m = ~_m & _MASK;
      _h = ~_h & _MASK_2;
    }
  }

  factory int64.fromBytes(List<int> bytes) {
    int top = bytes[7] & 0xff;
    top <<= 8;
    top |= bytes[6] & 0xff;
    top <<= 8;
    top |= bytes[5] & 0xff;
    top <<= 8;
    top |= bytes[4] & 0xff;

    int bottom = bytes[3] & 0xff;
    bottom <<= 8;
    bottom |= bytes[2] & 0xff;
    bottom <<= 8;
    bottom |= bytes[1] & 0xff;
    bottom <<= 8;
    bottom |= bytes[0] & 0xff;

    return new int64.fromInts(top, bottom);
  }

  factory int64.fromBytesBigEndian(List<int> bytes) {
    int top = bytes[0] & 0xff;
    top <<= 8;
    top |= bytes[1] & 0xff;
    top <<= 8;
    top |= bytes[2] & 0xff;
    top <<= 8;
    top |= bytes[3] & 0xff;

    int bottom = bytes[4] & 0xff;
    bottom <<= 8;
    bottom |= bytes[5] & 0xff;
    bottom <<= 8;
    bottom |= bytes[6] & 0xff;
    bottom <<= 8;
    bottom |= bytes[7] & 0xff;

    return new int64.fromInts(top, bottom);
 }

  /**
   * Constructs an [int64] from a pair of 32-bit integers having the value
   * [:((top & 0xffffffff) << 32) | (bottom & 0xffffffff):].
   */
  int64.fromInts(int top, int bottom) {
    top &= 0xffffffff;
    bottom &= 0xffffffff;
    _l = bottom & _MASK;
    _m = ((top & 0xfff) << 10) | ((bottom >> _BITS) & 0x3ff);
    _h = (top >> 12) & _MASK_2;
  }

  int64 _promote(other) {
    if (other == null) {
      throw new ArgumentError(null);
    } else if (other is intx) {
      other = other.toInt64();
    } else if (other is int) {
      other = new int64.fromInt(other);
    }
    if (other is !int64) {
      throw new Exception("Can't promote $other to int64");
    }
    return other;
  }

  int64 operator +(other) {
    int64 o = _promote(other);
    int sum0 = _l + o._l;
    int sum1 = _m + o._m + _shiftRight(sum0, _BITS);
    int sum2 = _h + o._h + _shiftRight(sum1, _BITS);

    int64 result = new int64._bits(sum0 & _MASK, sum1 & _MASK, sum2 & _MASK_2);
    return result;
  }

  int64 operator -(other) {
    int64 o = _promote(other);

    int sum0 = _l - o._l;
    int sum1 = _m - o._m + _shiftRight(sum0, _BITS);
    int sum2 = _h - o._h + _shiftRight(sum1, _BITS);

    int64 result = new int64._bits(sum0 & _MASK, sum1 & _MASK, sum2 & _MASK_2);
    return result;
  }

  int64 operator -() {
    // Like 0 - this.
    int sum0 = -_l;
    int sum1 = -_m + _shiftRight(sum0, _BITS);
    int sum2 = -_h + _shiftRight(sum1, _BITS);

    return new int64._bits(sum0 & _MASK, sum1 & _MASK, sum2 & _MASK_2);
  }

  int64 operator *(other) {
    int64 o = _promote(other);
    // Grab 13-bit chunks.
    int a0 = _l & 0x1fff;
    int a1 = (_l >> 13) | ((_m & 0xf) << 9);
    int a2 = (_m >> 4) & 0x1fff;
    int a3 = (_m >> 17) | ((_h & 0xff) << 5);
    int a4 = (_h & 0xfff00) >> 8;

    int b0 = o._l & 0x1fff;
    int b1 = (o._l >> 13) | ((o._m & 0xf) << 9);
    int b2 = (o._m >> 4) & 0x1fff;
    int b3 = (o._m >> 17) | ((o._h & 0xff) << 5);
    int b4 = (o._h & 0xfff00) >> 8;

    // Compute partial products.
    // Optimization: if b is small, avoid multiplying by parts that are 0.
    int p0 = a0 * b0; // << 0
    int p1 = a1 * b0; // << 13
    int p2 = a2 * b0; // << 26
    int p3 = a3 * b0; // << 39
    int p4 = a4 * b0; // << 52

    if (b1 != 0) {
      p1 += a0 * b1;
      p2 += a1 * b1;
      p3 += a2 * b1;
      p4 += a3 * b1;
    }
    if (b2 != 0) {
      p2 += a0 * b2;
      p3 += a1 * b2;
      p4 += a2 * b2;
    }
    if (b3 != 0) {
      p3 += a0 * b3;
      p4 += a1 * b3;
    }
    if (b4 != 0) {
      p4 += a0 * b4;
    }

    // Accumulate into 22-bit chunks:
    // .........................................c10|...................c00|
    // |....................|..................xxxx|xxxxxxxxxxxxxxxxxxxxxx| p0
    // |....................|......................|......................|
    // |....................|...................c11|......c01.............|
    // |....................|....xxxxxxxxxxxxxxxxxx|xxxxxxxxx.............| p1
    // |....................|......................|......................|
    // |.................c22|...............c12....|......................|
    // |..........xxxxxxxxxx|xxxxxxxxxxxxxxxxxx....|......................| p2
    // |....................|......................|......................|
    // |.................c23|..c13.................|......................|
    // |xxxxxxxxxxxxxxxxxxxx|xxxxx.................|......................| p3
    // |....................|......................|......................|
    // |.........c24........|......................|......................|
    // |xxxxxxxxxxxx........|......................|......................| p4

    int c00 = p0 & 0x3fffff;
    int c01 = (p1 & 0x1ff) << 13;
    int c0 = c00 + c01;

    int c10 = p0 >> 22;
    int c11 = p1 >> 9;
    int c12 = (p2 & 0x3ffff) << 4;
    int c13 = (p3 & 0x1f) << 17;
    int c1 = c10 + c11 + c12 + c13;

    int c22 = p2 >> 18;
    int c23 = p3 >> 5;
    int c24 = (p4 & 0xfff) << 8;
    int c2 = c22 + c23 + c24;

    // Propagate high bits from c0 -> c1, c1 -> c2.
    c1 += c0 >> _BITS;
    c0 &= _MASK;
    c2 += c1 >> _BITS;
    c1 &= _MASK;
    c2 &= _MASK_2;

    return new int64._bits(c0, c1, c2);
  }

  int64 operator %(other) {
    if (other.isZero) {
      throw new IntegerDivisionByZeroException();
    }
    if (this.isZero) {
      return ZERO;
    }
    int64 o = _promote(other).abs();
    _divMod(this, o, true);
    return _remainder < 0 ? (_remainder + o) : _remainder;
  }

  int64 operator ~/(other) => _divMod(this, _promote(other), false);

  // int64 remainder(other) => this - (this ~/ other) * other;
  int64 remainder(other) {
    if (other.isZero) {
      throw new IntegerDivisionByZeroException();
    }
    int64 o = _promote(other).abs();
    _divMod(this, o, true);
    return _remainder;
  }

  int64 operator &(other) {
    int64 o = _promote(other);
    int a0 = _l & o._l;
    int a1 = _m & o._m;
    int a2 = _h & o._h;
    return new int64._bits(a0, a1, a2);
  }

  int64 operator |(other) {
    int64 o = _promote(other);
    int a0 = _l | o._l;
    int a1 = _m | o._m;
    int a2 = _h | o._h;
    return new int64._bits(a0, a1, a2);
  }

  int64 operator ^(other) {
    int64 o = _promote(other);
    int a0 = _l ^ o._l;
    int a1 = _m ^ o._m;
    int a2 = _h ^ o._h;
    return new int64._bits(a0, a1, a2);
  }

  int64 operator ~() {
    var result = new int64._bits((~_l) & _MASK, (~_m) & _MASK, (~_h) & _MASK_2);
    return result;
  }

  int64 operator <<(int n) {
    if (n < 0) {
      throw new ArgumentError("$n");
    }
    n &= 63;

    int res0, res1, res2;
    if (n < _BITS) {
      res0 = _l << n;
      res1 = (_m << n) | (_l >> (_BITS - n));
      res2 = (_h << n) | (_m >> (_BITS - n));
    } else if (n < _BITS01) {
      res0 = 0;
      res1 = _l << (n - _BITS);
      res2 = (_m << (n - _BITS)) | (_l >> (_BITS01 - n));
    } else {
      res0 = 0;
      res1 = 0;
      res2 = _l << (n - _BITS01);
    }

    return new int64._bits(res0 & _MASK, res1 & _MASK, res2 & _MASK_2);
  }

  int64 operator >>(int n) {
    if (n < 0) {
      throw new ArgumentError("$n");
    }
    n &= 63;

    int res0, res1, res2;

    // Sign extend h(a).
    int a2 = _h;
    bool negative = (a2 & _SIGN_BIT_VALUE) != 0;
    if (negative) {
      a2 += 0x3 << _BITS2; // add extra one bits on the left
    }

    if (n < _BITS) {
      res2 = _shiftRight(a2, n);
      if (negative) {
        res2 |= _MASK_2 & ~(_MASK_2 >> n);
      }
      res1 = _shiftRight(_m, n) | (a2 << (_BITS - n));
      res0 = _shiftRight(_l, n) | (_m << (_BITS - n));
    } else if (n < _BITS01) {
      res2 = negative ? _MASK_2 : 0;
      res1 = _shiftRight(a2, n - _BITS);
      if (negative) {
        res1 |= _MASK & ~(_MASK >> (n - _BITS));
      }
      res0 = _shiftRight(_m, n - _BITS) | (a2 << (_BITS01 - n));
    } else {
      res2 = negative ? _MASK_2 : 0;
      res1 = negative ? _MASK : 0;
      res0 = _shiftRight(a2, n - _BITS01);
      if (negative) {
        res0 |= _MASK & ~(_MASK >> (n - _BITS01));
      }
    }

    return new int64._bits(res0 & _MASK, res1 & _MASK, res2 & _MASK_2);
  }

  int64 shiftRightUnsigned(int n) {
    if (n < 0) {
      throw new ArgumentError("$n");
    }
    n &= 63;

    int res0, res1, res2;
    int a2 = _h & _MASK_2; // Ensure a2 is positive.
    if (n < _BITS) {
      res2 = a2 >> n;
      res1 = (_m >> n) | (a2 << (_BITS - n));
      res0 = (_l >> n) | (_m << (_BITS - n));
    } else if (n < _BITS01) {
      res2 = 0;
      res1 = a2 >> (n - _BITS);
      res0 = (_m >> (n - _BITS)) | (_h << (_BITS01 - n));
    } else {
      res2 = 0;
      res1 = 0;
      res0 = a2 >> (n - _BITS01);
    }

    return new int64._bits(res0 & _MASK, res1 & _MASK, res2 & _MASK_2);
  }

  /**
   * Returns [true] if this [int64] has the same numeric value as the
   * given object.  The argument may be an [int] or an [intx].
   */
  bool operator ==(other) {
    if (other == null) {
      return false;
    }
    int64 o = _promote(other);
    return _l == o._l && _m == o._m && _h == o._h;
  }

  int compareTo(Comparable other) {
    int64 o = _promote(other);
    int signa = _h >> (_BITS2 - 1);
    int signb = o._h >> (_BITS2 - 1);
    if (signa != signb) {
      return signa == 0 ? 1 : -1;
    }
    if (_h > o._h) {
      return 1;
    } else if (_h < o._h) {
      return -1;
    }
    if (_m > o._m) {
      return 1;
    } else if (_m < o._m) {
      return -1;
    }
    if (_l > o._l) {
      return 1;
    } else if (_l < o._l) {
      return -1;
    }
    return 0;
  }

  bool operator <(other) {
    return this.compareTo(other) < 0;
  }

  bool operator <=(other) {
    return this.compareTo(other) <= 0;
  }

  bool operator >(other) {
    return this.compareTo(other) > 0;
  }

  bool operator >=(other) {
    return this.compareTo(other) >= 0;
  }

  bool get isEven => (_l & 0x1) == 0;
  bool get isMaxValue => (_h == _MASK_2 >> 1) && _m == _MASK && _l == _MASK;
  bool get isMinValue => _h == _SIGN_BIT_VALUE && _m == 0 && _l == 0;
  bool get isNegative => (_h >> (_BITS2 - 1)) != 0;
  bool get isOdd => (_l & 0x1) == 1;
  bool get isZero => _h == 0 && _m == 0 && _l == 0;

  /**
   * Returns a hash code based on all the bits of this [int64].
   */
  int get hashCode {
    int bottom = ((_m & 0x3ff) << _BITS) | _l;
    int top = (_h << 12) | ((_m >> 10) & 0xfff);
    return bottom ^ top;
  }

  int64 abs() {
    return this < 0 ? -this : this;
  }

  /**
   * Returns the number of leading zeros in this [int64] as an [int]
   * between 0 and 64.
   */
  int numberOfLeadingZeros() {
    int b2 = int32._numberOfLeadingZeros(_h);
    if (b2 == 32) {
      int b1 = int32._numberOfLeadingZeros(_m);
      if (b1 == 32) {
        return int32._numberOfLeadingZeros(_l) + 32;
      } else {
        return b1 + _BITS2 - (32 - _BITS);
      }
    } else {
      return b2 - (32 - _BITS2);
    }
  }

  /**
   * Returns the number of trailing zeros in this [int64] as an [int]
   * between 0 and 64.
   */
  int numberOfTrailingZeros() {
    int zeros = int32._numberOfTrailingZeros(_l);
    if (zeros < 32) {
      return zeros;
    }

    zeros = int32._numberOfTrailingZeros(_m);
    if (zeros < 32) {
      return _BITS + zeros;
    }

    zeros = int32._numberOfTrailingZeros(_h);
    if (zeros < 32) {
      return _BITS01 + zeros;
    }
    // All zeros
    return 64;
  }

  List<int> toBytes() {
    List<int> result = new List<int>(8);
    result[0] = _l & 0xff;
    result[1] = (_l >> 8) & 0xff;
    result[2] = ((_m << 6) & 0xfc) | ((_l >> 16) & 0x3f);
    result[3] = (_m >> 2) & 0xff;
    result[4] = (_m >> 10) & 0xff;
    result[5] = ((_h << 4) & 0xf0) | ((_m >> 18) & 0xf);
    result[6] = (_h >> 4) & 0xff;
    result[7] = (_h >> 12) & 0xff;
    return result;
  }

  int toInt() {
    int l = _l;
    int m = _m;
    int h = _h;
    bool negative = false;
    if ((_h & _SIGN_BIT_VALUE) != 0) {
      l = ~_l & _MASK;
      m = ~_m & _MASK;
      h = ~_h & _MASK_2;
      negative = true;
    }

    int result;
    if (_haveBigInts) {
      result = (h << _BITS01) | (m << _BITS) | l;
    } else {
      result = (h * 17592186044416) + (m * 4194304) + l;
    }
    return negative ? -result - 1 : result;
  }

  /**
   * Returns an [int32] containing the low 32 bits of this [int64].
   */
  int32 toInt32() {
    return new int32.fromInt(((_m & 0x3ff) << _BITS) | _l);
  }

  /**
   * Returns [this].
   */
  int64 toInt64() => this;

  /**
   * Returns the value of this [int64] as a decimal [String].
   */
  // TODO(rice) - Make this faster by converting several digits at once.
  String toString() {
    int64 a = this;
    if (a.isZero) {
      return "0";
    }
    if (a.isMinValue) {
      return "-9223372036854775808";
    }

    String result = "";
    bool negative = false;
    if (a.isNegative) {
      negative = true;
      a = -a;
    }

    int64 ten = new int64._bits(10, 0, 0);
    while (!a.isZero) {
      a = _divMod(a, ten, true);
      result = "${_remainder._l}$result";
    }
    if (negative) {
      result = "-$result";
    }
    return result;
  }

  // TODO(rice) - Make this faster by avoiding arithmetic.
  String toHexString() {
    int64 x = new int64._copy(this);
    if (isZero) {
      return "0";
    }
    String hexStr = "";
    int64 digit_f = new int64.fromInt(0xf);
    while (!x.isZero) {
      int digit = x._l & 0xf;
      hexStr = "${_hexDigit(digit)}$hexStr";
      x = x.shiftRightUnsigned(4);
    }
    return hexStr;
  }

  String toRadixString(int radix) {
    if ((radix <= 1) || (radix > 16)) {
      throw "Bad radix: $radix";
    }
    int64 a = this;
    if (a.isZero) {
      return "0";
    }
    if (a.isMinValue) {
      return _minValues[radix];
    }

    String result = "";
    bool negative = false;
    if (a.isNegative) {
      negative = true;
      a = -a;
    }

    int64 r = new int64._bits(radix, 0, 0);
    while (!a.isZero) {
      a = _divMod(a, r, true);
      result = "${_hexDigit(_remainder._l)}$result";
    }
    return negative ? "-$result" : result;
  }

  String toDebugString() {
    return "int64[_l=$_l, _m=$_m, _h=$_h]";
  }

  /**
   * Constructs an [int64] with a given bitwise representation.  No validation
   * is performed.
   */
  int64._bits(int this._l, int this._m, int this._h);

  /**
   * Constructs an [int64] with the same value as an existing [int64].
   */
  int64._copy(int64 other) {
    _l = other._l;
    _m = other._m;
    _h = other._h;
  }

  // Determine whether the platform supports ints greater than 2^53
  // without loss of precision.
  static bool _haveBigIntsCached = null;

  static bool get _haveBigInts {
    if (_haveBigIntsCached == null) {
      var x = 9007199254740992;
      // Defeat compile-time constant folding.
      if (2 + 2 != 4) {
        x = 0;
      }
      var y = x + 1;
      var same = y == x;
      _haveBigIntsCached = !same;
    }
    return _haveBigIntsCached;
  }

  String _hexDigit(int digit) => "0123456789ABCDEF"[digit];

  // Implementation of '~/' and '%'.

  // Note: mutates [this].
  void _negate() {
    int neg0 = (~_l + 1) & _MASK;
    int neg1 = (~_m + (neg0 == 0 ? 1 : 0)) & _MASK;
    int neg2 = (~_h + ((neg0 == 0 && neg1 == 0) ? 1 : 0)) & _MASK_2;

    _l = neg0;
    _m = neg1;
    _h = neg2;
  }

  // Note: mutates [this].
  void _setBit(int bit) {
    if (bit < _BITS) {
      _l |= 0x1 << bit;
    } else if (bit < _BITS01) {
      _m |= 0x1 << (bit - _BITS);
    } else {
      _h |= 0x1 << (bit - _BITS01);
    }
  }

  // Note: mutates [this].
  void _toShru1() {
    int a2 = _h;
    int a1 = _m;
    int a0 = _l;

    _h = a2 >> 1;
    _m = (a1 >> 1) | ((a2 & 0x1) << (_BITS - 1));
    _l = (a0 >> 1) | ((a1 & 0x1) << (_BITS - 1));
  }

  // Work around dart2js bugs with negative arguments to '>>' operator.
  static int _shiftRight(int x, int n) {
    if (x >= 0) {
      return x >> n;
    } else {
      int shifted = x >> n;
      if (shifted >= 0x80000000) {
        shifted -= 4294967296;
      }
      return shifted;
    }
  }

  /**
   * Attempt to subtract b from a if a >= b:
   *
   * if (a >= b) {
   *   a -= b;
   *   return true;
   * } else {
   *   return false;
   * }
   */
  // Note: mutates [a].
  static bool _trialSubtract(int64 a, int64 b) {
    // Early exit.
    int sum2 = a._h - b._h;
    if (sum2 < 0) {
      return false;
    }

    int sum0 = a._l - b._l;
    int sum1 = a._m - b._m + _shiftRight(sum0, _BITS);
    sum2 += _shiftRight(sum1, _BITS);

    if (sum2 < 0) {
      return false;
    }

    a._l = sum0 & _MASK;
    a._m = sum1 & _MASK;
    a._h = sum2 & _MASK_2;

    return true;
  }

  // Note: mutates [a] via _trialSubtract.
  static int64 _divModHelper(int64 a, int64 b,
      bool negative, bool aIsNegative, bool aIsMinValue,
      bool computeRemainder) {
    // Align the leading one bits of a and b by shifting b left.
    int shift = b.numberOfLeadingZeros() - a.numberOfLeadingZeros();
    int64 bshift = b << shift;

    // Quotient must be a new instance since we mutate it.
    int64 quotient = new int64();
    while (shift >= 0) {
      bool gte = _trialSubtract(a, bshift);
      if (gte) {
        quotient._setBit(shift);
        if (a.isZero) {
          break;
        }
      }

      bshift._toShru1();
      shift--;
    }

    if (negative) {
      quotient._negate();
    }

    if (computeRemainder) {
      if (aIsNegative) {
        _remainder = -a;
        if (aIsMinValue) {
          _remainder = _remainder - ONE;
        }
      } else {
        _remainder = a;
      }
    }

    return quotient;
  }

  int64 _divModByMinValue(bool computeRemainder) {
    // MIN_VALUE / MIN_VALUE == 1, remainder = 0
    // (x != MIN_VALUE) / MIN_VALUE == 0, remainder == x
    if (isMinValue) {
      if (computeRemainder) {
        _remainder = ZERO;
      }
      return ONE;
    }
    if (computeRemainder) {
      _remainder = this;
    }
    return ZERO;
  }

  /**
   * this &= ((1L << bits) - 1)
   */
  // Note: mutates [this].
  int64 _maskRight(int bits) {
    int b0, b1, b2;
    if (bits <= _BITS) {
      b0 = _l & ((1 << bits) - 1);
      b1 = b2 = 0;
    } else if (bits <= _BITS01) {
      b0 = _l;
      b1 = _m & ((1 << (bits - _BITS)) - 1);
      b2 = 0;
    } else {
      b0 = _l;
      b1 = _m;
      b2 = _h & ((1 << (bits - _BITS01)) - 1);
    }

    _l = b0;
    _m = b1;
    _h = b2;
  }

  int64 _divModByShift(int64 a, int bpower, bool negative, bool aIsCopy,
      bool aIsNegative, bool computeRemainder) {
    int64 c = a >> bpower;
    if (negative) {
      c._negate();
    }

    if (computeRemainder) {
      if (!aIsCopy) {
        a = new int64._copy(a);
      }
      a._maskRight(bpower);
      if (aIsNegative) {
        a._negate();
      }
      _remainder = a;
    }
    return c;
  }

  /**
   * Return the exact log base 2 of this, or -1 if this is not a power of two.
   */
  int _powerOfTwo() {
    // Power of two or 0.
    int l = _l;
    if ((l & (l - 1)) != 0) {
      return -1;
    }
    int m = _m;
    if ((m & (m - 1)) != 0) {
      return -1;
    }
    int h = _h;
    if ((h & (h - 1)) != 0) {
      return -1;
    }
    if (h == 0 && m == 0 && l == 0) {
      return -1;
    }
    if (h == 0 && m == 0 && l != 0) {
      return int32._numberOfTrailingZeros(l);
    }
    if (h == 0 && m != 0 && l == 0) {
      return int32._numberOfTrailingZeros(m) + _BITS;
    }
    if (h != 0 && m == 0 && l == 0) {
      return int32._numberOfTrailingZeros(h) + _BITS01;
    }

    return -1;
  }

  int64 _divMod(int64 a, int64 b, bool computeRemainder) {
    if (b.isZero) {
      throw new IntegerDivisionByZeroException();
    }
    if (a.isZero) {
      if (computeRemainder) {
        _remainder = ZERO;
      }
      return ZERO;
    }
    // MIN_VALUE / MIN_VALUE = 1, anything other a / MIN_VALUE is 0.
    if (b.isMinValue) {
      return a._divModByMinValue(computeRemainder);
    }
    // Normalize b to abs(b), keeping track of the parity in 'negative'.
    // We can do this because we have already ensured that b != MIN_VALUE.
    bool negative = false;
    if (b.isNegative) {
      b = -b;
      negative = !negative;
    }
    // If b == 2^n, bpower will be n, otherwise it will be -1.
    int bpower = b._powerOfTwo();

    // True if the original value of a is negative.
    bool aIsNegative = false;
    // True if the original value of a is int64.MIN_VALUE.
    bool aIsMinValue = false;

    /*
     * Normalize a to a positive value, keeping track of the sign change in
     * 'negative' (which tracks the sign of both a and b and is used to
     * determine the sign of the quotient) and 'aIsNegative' (which is used to
     * determine the sign of the remainder).
     *
     * For all values of a except MIN_VALUE, we can just negate a and modify
     * negative and aIsNegative appropriately. When a == MIN_VALUE, negation is
     * not possible without overflowing 64 bits, so instead of computing
     * abs(MIN_VALUE) / abs(b) we compute (abs(MIN_VALUE) - 1) / abs(b). The
     * only circumstance under which these quotients differ is when b is a power
     * of two, which will divide abs(MIN_VALUE) == 2^64 exactly. In this case,
     * we can get the proper result by shifting MIN_VALUE in unsigned fashion.
     *
     * We make a single copy of a before the first operation that needs to
     * modify its value.
     */
    bool aIsCopy = false;
    if (a.isMinValue) {
      aIsMinValue = true;
      aIsNegative = true;
      // If b is not a power of two, treat -a as MAX_VALUE (instead of the
      // actual value (MAX_VALUE + 1)).
      if (bpower == -1) {
        a = new int64._copy(MAX_VALUE);
        aIsCopy = true;
        negative = !negative;
      } else {
        // Signed shift of MIN_VALUE produces the right answer.
        int64 c = a >> bpower;
        if (negative) {
          c._negate();
        }
        if (computeRemainder) {
          _remainder = ZERO;
        }
        return c;
      }
    } else if (a.isNegative) {
      aIsNegative = true;
      a = -a;
      aIsCopy = true;
      negative = !negative;
    }

    // Now both a and b are non-negative.
    // If b is a power of two, just shift.
    if (bpower != -1) {
      return _divModByShift(a, bpower, negative, aIsCopy, aIsNegative,
        computeRemainder);
    }

    // If a < b, the quotient is 0 and the remainder is a.
    if (a < b) {
      if (computeRemainder) {
        if (aIsNegative) {
          _remainder = -a;
        } else {
          _remainder = aIsCopy ? a : new int64._copy(a);
        }
      }
      return ZERO;
    }

    // Generate the quotient using bit-at-a-time long division.
    return _divModHelper(aIsCopy ? a : new int64._copy(a), b, negative,
        aIsNegative, aIsMinValue, computeRemainder);
  }
}
