// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of fixnum;

/**
 * An immutable 32-bit signed integer, in the range [-2^31, 2^31 - 1].
 * Arithmetic operations may overflow in order to maintain this range.
 */
class int32 implements intx {

  /**
   * The maximum positive value attainable by an [int32], namely
   * 2147483647.
   */
  static const int32 MAX_VALUE = const int32._internal(0x7FFFFFFF);

  /**
   * The minimum positive value attainable by an [int32], namely
   * -2147483648.
   */
  static int32 MIN_VALUE = const int32._internal(0x80000000);

  /**
   * An [int32] constant equal to 0.
   */
  static int32 ZERO = const int32._internal(0);

  /**
   * An [int32] constant equal to 1.
   */
  static int32 ONE = const int32._internal(1);

  /**
   * An [int32] constant equal to 2.
   */
  static int32 TWO = const int32._internal(2);

  // Hex digit char codes
  static const int _CC_0 = 48; // '0'.charCodeAt(0)
  static const int _CC_9 = 57; // '9'.charCodeAt(0)
  static const int _CC_a = 97; // 'a'.charCodeAt(0)
  static const int _CC_z = 122; // 'z'.charCodeAt(0)
  static const int _CC_A = 65; // 'A'.charCodeAt(0)
  static const int _CC_Z = 90; // 'Z'.charCodeAt(0)

  static int _decodeHex(int c) {
    if (c >= _CC_0 && c <= _CC_9) {
      return c - _CC_0;
    } else if (c >= _CC_a && c <= _CC_z) {
      return c - _CC_a + 10;
    } else if (c >= _CC_A && c <= _CC_Z) {
      return c - _CC_A + 10;
    } else {
      return -1; // bad char code
    }
  }

  /**
   * Parses a [String] in a given [radix] between 2 and 16 and returns an
   * [int32].
   */
  // TODO(rice) - Make this faster by converting several digits at once.
  static int32 parseRadix(String s, int radix) {
    if ((radix <= 1) || (radix > 16)) {
      throw "Bad radix: $radix";
    }
    int32 x = ZERO;
    for (int i = 0; i < s.length; i++) {
      int c = s.charCodeAt(i);
      int digit = _decodeHex(c);
      if (digit < 0 || digit >= radix) {
        throw new Exception("Non-radix char code: $c");
      }
      x = (x * radix) + digit;
    }
    return x;
  }

  /**
   * Parses a decimal [String] and returns an [int32].
   */
  static int32 parseInt(String s) => new int32.fromInt(int.parse(s));

  /**
   * Parses a hexadecimal [String] and returns an [int32].
   */
  static int32 parseHex(String s) => parseRadix(s, 16);

  // Assumes i is <= 32-bit.
  static int _bitCount(int i) {
    // See "Hacker's Delight", section 5-1, "Counting 1-Bits".

    // The basic strategy is to use "divide and conquer" to
    // add pairs (then quads, etc.) of bits together to obtain
    // sub-counts.
    //
    // A straightforward approach would look like:
    //
    // i = (i & 0x55555555) + ((i >>  1) & 0x55555555);
    // i = (i & 0x33333333) + ((i >>  2) & 0x33333333);
    // i = (i & 0x0F0F0F0F) + ((i >>  4) & 0x0F0F0F0F);
    // i = (i & 0x00FF00FF) + ((i >>  8) & 0x00FF00FF);
    // i = (i & 0x0000FFFF) + ((i >> 16) & 0x0000FFFF);
    //
    // The code below removes unnecessary &'s and uses a
    // trick to remove one instruction in the first line.

    i -= ((i >> 1) & 0x55555555);
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
    i = ((i + (i >> 4)) & 0x0F0F0F0F);
    i += (i >> 8);
    i += (i >> 16);
    return (i & 0x0000003F);
  }

  // Assumes i is <= 32-bit
  static int _numberOfLeadingZeros(int i) {
    i |= i >> 1;
    i |= i >> 2;
    i |= i >> 4;
    i |= i >> 8;
    i |= i >> 16;
    return _bitCount(~i);
  }

  static int _numberOfTrailingZeros(int i) => _bitCount((i & -i) - 1);

  // The internal value, kept in the range [MIN_VALUE, MAX_VALUE].
  final int _i;

  const int32._internal(int i) : _i = i;

  /**
   * Constructs an [int32] from an [int].  Only the low 32 bits of the input
   * are used.
   */
  int32.fromInt(int i) : _i = (i & 0x7fffffff) - (i & 0x80000000);

  // Convert an [int] or [intx] to an [int32].  Note that an [int64]
  // will be truncated.
  int _convert(other) {
    if (other == null) {
      throw new ArgumentError(null);
    } else if (other is intx) {
      return other.toInt32()._i;
    } else if (other is int) {
      return other;
    } else {
      throw new Exception("Can't retrieve 32-bit int from $other");
    }
  }

  // The +, -, * , &, |, and ^ operaters deal with types as follows:
  //
  // int32 + int => int32
  // int32 + int32 => int32
  // int32 + int64 => int64
  //
  // The %, ~/ and remainder operators return an int32 even with an int64
  // argument, since the result cannot be greater than the value on the
  // left-hand side:
  //
  // int32 % int => int32
  // int32 % int32 => int32
  // int32 % int64 => int32

  intx operator +(other) {
    if (other is int64) {
      return this.toInt64() + other;
    }
    return new int32.fromInt(_i + _convert(other));
  }

  intx operator -(other) {
    if (other is int64) {
      return this.toInt64() - other;
    }
    return new int32.fromInt(_i - _convert(other));
  }

  int32 operator -() => new int32.fromInt(-_i);

  intx operator *(other) {
    if (other is int64) {
      return this.toInt64() * other;
    }
    // TODO(rice) - optimize
    return (this.toInt64() * other).toInt32();
  }

  int32 operator %(other) {
    if (other is int64) {
      // Result will be int32
      return (this.toInt64() % other).toInt32();
    }
    return new int32.fromInt(_i % _convert(other));
  }

  int32 operator ~/(other) {
    if (other is int64) {
      // Result will be int32
      return (this.toInt64() ~/ other).toInt32();
    }
    return new int32.fromInt(_i ~/ _convert(other));
  }

  int32 remainder(other) {
    if (other is int64) {
      // Result will be int32
      int64 t = this.toInt64();
      return (t - (t ~/ other) * other).toInt32();
    }
    return this - (this ~/ other) * other;
  }

  int32 operator &(other) {
    if (other is int64) {
      return (this.toInt64() & other).toInt32();
    }
    return new int32.fromInt(_i & _convert(other));
  }

  int32 operator |(other) {
    if (other is int64) {
      return (this.toInt64() | other).toInt32();
    }
    return new int32.fromInt(_i | _convert(other));
  }

  int32 operator ^(other) {
    if (other is int64) {
      return (this.toInt64() ^ other).toInt32();
    }
    return new int32.fromInt(_i ^ _convert(other));
  }

  int32 operator ~() => new int32.fromInt(~_i);

  int32 operator <<(int n) {
    if (n < 0) {
      throw new ArgumentError("$n");
    }
    n &= 31;
    return new int32.fromInt(_i << n);
  }

  int32 operator >>(int n) {
    if (n < 0) {
      throw new ArgumentError("$n");
    }
    n &= 31;
    int value;
    if (_i >= 0) {
      value = _i >> n;
    } else {
      value = (_i >> n) | (0xffffffff << (32 - n));
    }
    return new int32.fromInt(value);
  }

  int32 shiftRightUnsigned(int n) {
    if (n < 0) {
      throw new ArgumentError("$n");
    }
    n &= 31;
    int value;
    if (_i >= 0) {
      value = _i >> n;
    } else {
      value = (_i >> n) & ((1 << (32 - n)) - 1);
    }
    return new int32.fromInt(value);
  }

  /**
   * Returns [true] if this [int32] has the same numeric value as the
   * given object.  The argument may be an [int] or an [intx].
   */
  bool operator ==(other) {
    if (other == null) {
      return false;
    }
    if (other is int64) {
      return this.toInt64() == other;
    }
    return _i == _convert(other);
  }

  int compareTo(Comparable other) {
    if (other is int64) {
      return this.toInt64().compareTo(other);
    }
    return _i.compareTo(_convert(other));
  }

  bool operator <(other) {
    if (other is int64) {
      return this.toInt64() < other;
    }
    return _i < _convert(other);
  }

  bool operator <=(other) {
    if (other is int64) {
      return this.toInt64() < other;
    }
    return _i <= _convert(other);
  }

  bool operator >(other) {
    if (other is int64) {
      return this.toInt64() < other;
    }
    return _i > _convert(other);
  }

  bool operator >=(other) {
    if (other is int64) {
      return this.toInt64() < other;
    }
    return _i >= _convert(other);
  }

  bool get isEven => (_i & 0x1) == 0;
  bool get isMaxValue => _i == 2147483647;
  bool get isMinValue => _i == -2147483648;
  bool get isNegative => _i < 0;
  bool get isOdd => (_i & 0x1) == 1;
  bool get isZero => _i == 0;

  int get hashCode => _i;

  int32 abs() => _i < 0 ? new int32.fromInt(-_i) : this;

  int numberOfLeadingZeros() => _numberOfLeadingZeros(_i);
  int numberOfTrailingZeros() => _numberOfTrailingZeros(_i);

  List<int> toBytes() {
    List<int> result = new List<int>(4);
    result[0] = _i & 0xff;
    result[1] = (_i >> 8) & 0xff;
    result[2] = (_i >> 16) & 0xff;
    result[3] = (_i >> 24) & 0xff;
    return result;
  }

  int toInt() => _i;
  int32 toInt32() => this;
  int64 toInt64() => new int64.fromInt(_i);

  String toString() => _i.toString();
  String toHexString() => _i.toRadixString(16);
  String toRadixString(int radix) => _i.toRadixString(radix);
}
