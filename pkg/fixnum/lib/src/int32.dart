// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of fixnum;

/**
 * An immutable 32-bit signed integer, in the range [-2^31, 2^31 - 1].
 * Arithmetic operations may overflow in order to maintain this range.
 */
class Int32 implements IntX {

  /**
   * The maximum positive value attainable by an [Int32], namely
   * 2147483647.
   */
  static const Int32 MAX_VALUE = const Int32._internal(0x7FFFFFFF);

  /**
   * The minimum positive value attainable by an [Int32], namely
   * -2147483648.
   */
  static const Int32 MIN_VALUE = const Int32._internal(-0x80000000);

  /**
   * An [Int32] constant equal to 0.
   */
  static const Int32 ZERO = const Int32._internal(0);

  /**
   * An [Int32] constant equal to 1.
   */
  static const Int32 ONE = const Int32._internal(1);

  /**
   * An [Int32] constant equal to 2.
   */
  static const Int32 TWO = const Int32._internal(2);

  // Hex digit char codes
  static const int _CC_0 = 48; // '0'.codeUnitAt(0)
  static const int _CC_9 = 57; // '9'.codeUnitAt(0)
  static const int _CC_a = 97; // 'a'.codeUnitAt(0)
  static const int _CC_z = 122; // 'z'.codeUnitAt(0)
  static const int _CC_A = 65; // 'A'.codeUnitAt(0)
  static const int _CC_Z = 90; // 'Z'.codeUnitAt(0)

  static int _decodeDigit(int c) {
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
   * [Int32].
   */
  // TODO(rice) - Make this faster by converting several digits at once.
  static Int32 parseRadix(String s, int radix) {
    if ((radix <= 1) || (radix > 16)) {
      throw new ArgumentError("Bad radix: $radix");
    }
    Int32 x = ZERO;
    for (int i = 0; i < s.length; i++) {
      int c = s.codeUnitAt(i);
      int digit = _decodeDigit(c);
      if (digit < 0 || digit >= radix) {
        throw new FormatException("Non-radix code unit: $c");
      }
      x = (x * radix) + digit;
    }
    return x;
  }

  /**
   * Parses a decimal [String] and returns an [Int32].
   */
  static Int32 parseInt(String s) => new Int32(int.parse(s));

  /**
   * Parses a hexadecimal [String] and returns an [Int32].
   */
  static Int32 parseHex(String s) => parseRadix(s, 16);

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

  const Int32._internal(int i) : _i = i;

  /**
   * Constructs an [Int32] from an [int].  Only the low 32 bits of the input
   * are used.
   */
  Int32([int i=0]) : _i = (i & 0x7fffffff) - (i & 0x80000000);

  // Returns the [int] representation of the specified value. Throws
  // [ArgumentError] for non-integer arguments.
  int _toInt(val) {
    if (val is Int32) {
      return val._i;
    } else if (val is int) {
      return val;
    }
    throw new ArgumentError(val);
  }

  // The +, -, * , &, |, and ^ operaters deal with types as follows:
  //
  // Int32 + int => Int32
  // Int32 + Int32 => Int32
  // Int32 + Int64 => Int64
  //
  // The %, ~/ and remainder operators return an Int32 even with an Int64
  // argument, since the result cannot be greater than the value on the
  // left-hand side:
  //
  // Int32 % int => Int32
  // Int32 % Int32 => Int32
  // Int32 % Int64 => Int32

  IntX operator +(other) {
    if (other is Int64) {
      return this.toInt64() + other;
    }
    return new Int32(_i + _toInt(other));
  }

  IntX operator -(other) {
    if (other is Int64) {
      return this.toInt64() - other;
    }
    return new Int32(_i - _toInt(other));
  }

  Int32 operator -() => new Int32(-_i);

  IntX operator *(other) {
    if (other is Int64) {
      return this.toInt64() * other;
    }
    // TODO(rice) - optimize
    return (this.toInt64() * other).toInt32();
  }

  Int32 operator %(other) {
    if (other is Int64) {
      // Result will be Int32
      return (this.toInt64() % other).toInt32();
    }
    return new Int32(_i % _toInt(other));
  }

  Int32 operator ~/(other) {
    if (other is Int64) {
      return (this.toInt64() ~/ other).toInt32();
    }
    return new Int32(_i ~/ _toInt(other));
  }

  Int32 remainder(other) {
    if (other is Int64) {
      Int64 t = this.toInt64();
      return (t - (t ~/ other) * other).toInt32();
    }
    return this - (this ~/ other) * other;
  }

  Int32 operator &(other) {
    if (other is Int64) {
      return (this.toInt64() & other).toInt32();
    }
    return new Int32(_i & _toInt(other));
  }

  Int32 operator |(other) {
    if (other is Int64) {
      return (this.toInt64() | other).toInt32();
    }
    return new Int32(_i | _toInt(other));
  }

  Int32 operator ^(other) {
    if (other is Int64) {
      return (this.toInt64() ^ other).toInt32();
    }
    return new Int32(_i ^ _toInt(other));
  }

  Int32 operator ~() => new Int32(~_i);

  Int32 operator <<(int n) {
    if (n < 0) {
      throw new ArgumentError(n);
    }
    n &= 31;
    return new Int32(_i << n);
  }

  Int32 operator >>(int n) {
    if (n < 0) {
      throw new ArgumentError(n);
    }
    n &= 31;
    int value;
    if (_i >= 0) {
      value = _i >> n;
    } else {
      value = (_i >> n) | (0xffffffff << (32 - n));
    }
    return new Int32(value);
  }

  Int32 shiftRightUnsigned(int n) {
    if (n < 0) {
      throw new ArgumentError(n);
    }
    n &= 31;
    int value;
    if (_i >= 0) {
      value = _i >> n;
    } else {
      value = (_i >> n) & ((1 << (32 - n)) - 1);
    }
    return new Int32(value);
  }

  /**
   * Returns [true] if this [Int32] has the same numeric value as the
   * given object.  The argument may be an [int] or an [IntX].
   */
  bool operator ==(other) {
    if (other is Int32) {
      return _i == other._i;
    } else if (other is Int64) {
      return this.toInt64() == other;
    } else if (other is int) {
      return _i == other;
    }
    return false;
  }

  int compareTo(Comparable other) {
    if (other is Int64) {
      return this.toInt64().compareTo(other);
    }
    return _i.compareTo(_toInt(other));
  }

  bool operator <(other) {
    if (other is Int64) {
      return this.toInt64() < other;
    }
    return _i < _toInt(other);
  }

  bool operator <=(other) {
    if (other is Int64) {
      return this.toInt64() <= other;
    }
    return _i <= _toInt(other);
  }

  bool operator >(other) {
    if (other is Int64) {
      return this.toInt64() > other;
    }
    return _i > _toInt(other);
  }

  bool operator >=(other) {
    if (other is Int64) {
      return this.toInt64() >= other;
    }
    return _i >= _toInt(other);
  }

  bool get isEven => (_i & 0x1) == 0;
  bool get isMaxValue => _i == 2147483647;
  bool get isMinValue => _i == -2147483648;
  bool get isNegative => _i < 0;
  bool get isOdd => (_i & 0x1) == 1;
  bool get isZero => _i == 0;
  int get bitLength => _i.bitLength;

  int get hashCode => _i;

  Int32 abs() => _i < 0 ? new Int32(-_i) : this;

  Int32 clamp(lowerLimit, upperLimit) {
    if (this < lowerLimit) {
      if (lowerLimit is IntX) return lowerLimit.toInt32();
      if (lowerLimit is int) return new Int32(lowerLimit);
      throw new ArgumentError(lowerLimit);
    } else if (this > upperLimit) {
      if (upperLimit is IntX) return upperLimit.toInt32();
      if (upperLimit is int) return new Int32(upperLimit);
      throw new ArgumentError(upperLimit);
    }
    return this;
  }

  int numberOfLeadingZeros() => _numberOfLeadingZeros(_i);
  int numberOfTrailingZeros() => _numberOfTrailingZeros(_i);

  Int32 toSigned(int width) {
    if (width < 1 || width > 32) throw new ArgumentError(width);
    return new Int32(_i.toSigned(width));
  }

  Int32 toUnsigned(int width) {
    if (width < 0 || width > 32) throw new ArgumentError(width);
    return new Int32(_i.toUnsigned(width));
  }

  List<int> toBytes() {
    List<int> result = new List<int>(4);
    result[0] = _i & 0xff;
    result[1] = (_i >> 8) & 0xff;
    result[2] = (_i >> 16) & 0xff;
    result[3] = (_i >> 24) & 0xff;
    return result;
  }

  double toDouble() => _i.toDouble();
  int toInt() => _i;
  Int32 toInt32() => this;
  Int64 toInt64() => new Int64(_i);

  String toString() => _i.toString();
  String toHexString() => _i.toRadixString(16);
  String toRadixString(int radix) => _i.toRadixString(radix);
}
