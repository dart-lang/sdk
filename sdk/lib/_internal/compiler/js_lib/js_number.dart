// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

/**
 * The super interceptor class for [JSInt] and [JSDouble]. The compiler
 * recognizes this class as an interceptor, and changes references to
 * [:this:] to actually use the receiver of the method, which is
 * generated as an extra argument added to each member.
 *
 * Note that none of the methods here delegate to a method defined on JSInt or
 * JSDouble.  This is exploited in [tryComputeConstantInterceptor].
 */
class JSNumber extends Interceptor implements num {
  const JSNumber();

  int compareTo(num b) {
    if (b is! num) throw new ArgumentError(b);
    if (this < b) {
      return -1;
    } else if (this > b) {
      return 1;
    } else if (this == b) {
      if (this == 0) {
        bool bIsNegative = b.isNegative;
        if (isNegative == bIsNegative) return 0;
        if (isNegative) return -1;
        return 1;
      }
      return 0;
    } else if (isNaN) {
      if (b.isNaN) {
        return 0;
      }
      return 1;
    } else {
      return -1;
    }
  }

  bool get isNegative => (this == 0) ? (1 / this) < 0 : this < 0;

  bool get isNaN => JS('bool', r'isNaN(#)', this);

  bool get isInfinite {
    return JS('bool', r'# == Infinity', this)
        || JS('bool', r'# == -Infinity', this);
  }

  bool get isFinite => JS('bool', r'isFinite(#)', this);

  num remainder(num b) {
    checkNull(b); // TODO(ngeoffray): This is not specified but co19 tests it.
    if (b is! num) throw new ArgumentError(b);
    return JS('num', r'# % #', this, b);
  }

  num abs() => JS('num', r'Math.abs(#)', this);

  num get sign => this > 0 ? 1 : this < 0 ? -1 : this;

  static const int _MIN_INT32 = -0x80000000;
  static const int _MAX_INT32 = 0x7FFFFFFF;

  int toInt() {
    if (this >= _MIN_INT32 && this <= _MAX_INT32) {
      return JS('int', '# | 0', this);
    }
    if (JS('bool', r'isFinite(#)', this)) {
      return JS('int', r'# + 0', truncateToDouble());  // Converts -0.0 to +0.0.
    }
    // This is either NaN, Infinity or -Infinity.
    throw new UnsupportedError(JS("String", "''+#", this));
  }

  int truncate() => toInt();
  int ceil() => ceilToDouble().toInt();
  int floor() => floorToDouble().toInt();
  int round() => roundToDouble().toInt();

  double ceilToDouble() => JS('num', r'Math.ceil(#)', this);

  double floorToDouble() => JS('num', r'Math.floor(#)', this);

  double roundToDouble() {
    if (this < 0) {
      return JS('num', r'-Math.round(-#)', this);
    } else {
      return JS('num', r'Math.round(#)', this);
    }
  }

  double truncateToDouble() => this < 0 ? ceilToDouble() : floorToDouble();

  num clamp(lowerLimit, upperLimit) {
    if (lowerLimit is! num) throw new ArgumentError(lowerLimit);
    if (upperLimit is! num) throw new ArgumentError(upperLimit);
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw new ArgumentError(lowerLimit);
    }
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  // The return type is intentionally omitted to avoid type checker warnings
  // from assigning JSNumber to double.
  toDouble() => this;

  String toStringAsFixed(int fractionDigits) {
    checkNum(fractionDigits);
    // TODO(floitsch): fractionDigits must be an integer.
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw new RangeError(fractionDigits);
    }
    String result = JS('String', r'#.toFixed(#)', this, fractionDigits);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toStringAsExponential([int fractionDigits]) {
    String result;
    if (fractionDigits != null) {
      // TODO(floitsch): fractionDigits must be an integer.
      checkNum(fractionDigits);
      if (fractionDigits < 0 || fractionDigits > 20) {
        throw new RangeError(fractionDigits);
      }
      result = JS('String', r'#.toExponential(#)', this, fractionDigits);
    } else {
      result = JS('String', r'#.toExponential()', this);
    }
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toStringAsPrecision(int precision) {
    // TODO(floitsch): precision must be an integer.
    checkNum(precision);
    if (precision < 1 || precision > 21) {
      throw new RangeError(precision);
    }
    String result = JS('String', r'#.toPrecision(#)',
                       this, precision);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toRadixString(int radix) {
    checkNum(radix);
    if (radix < 2 || radix > 36) throw new RangeError(radix);
    return JS('String', r'#.toString(#)', this, radix);
  }

  // Note: if you change this, also change the function [S].
  String toString() {
    if (this == 0 && JS('bool', '(1 / #) < 0', this)) {
      return '-0.0';
    } else {
      return JS('String', r'"" + (#)', this);
    }
  }

  int get hashCode => JS('int', '# & 0x1FFFFFFF', this);

  num operator -() => JS('num', r'-#', this);

  num operator +(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# + #', this, other);
  }

  num operator -(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# - #', this, other);
  }

  num operator /(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# / #', this, other);
  }

  num operator *(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# * #', this, other);
  }

  num operator %(num other) {
    if (other is !num) throw new ArgumentError(other);
    // Euclidean Modulo.
    num result = JS('num', r'# % #', this, other);
    if (result == 0) return 0;  // Make sure we don't return -0.0.
    if (result > 0) return result;
    if (JS('num', '#', other) < 0) {
      return result - JS('num', '#', other);
    } else {
      return result + JS('num', '#', other);
    }
  }

  bool _isInt32(value) => JS('bool', '(# | 0) === #', value, value);

  num operator ~/(num other) {
    if (false) _tdivFast(other); // Ensure resolution.
    if (_isInt32(this) && _isInt32(other) && 0 != other && -1 != other) {
      return JS('num', r'(# / #) | 0', this, other);
    } else {
      return _tdivSlow(other);
    }
  }

  num _tdivFast(num other) {
    return _isInt32(this)
        ? JS('num', r'(# / #) | 0', this, other)
        : (JS('num', r'# / #', this, other)).toInt();
  }

  num _tdivSlow(num other) {
    if (other is !num) throw new ArgumentError(other);
    return (JS('num', r'# / #', this, other)).toInt();
  }

  // TODO(ngeoffray): Move the bit operations below to [JSInt] and
  // make them take an int. Because this will make operations slower,
  // we define these methods on number for now but we need to decide
  // the grain at which we do the type checks.

  num operator <<(num other) {
    if (other is !num) throw new ArgumentError(other);
    if (JS('num', '#', other) < 0) throw new ArgumentError(other);
    return _shlPositive(other);
  }

  num _shlPositive(num other) {
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    return JS('bool', r'# > 31', other)
        ? 0
        : JS('JSUInt32', r'(# << #) >>> 0', this, other);
  }

  num operator >>(num other) {
    if (false) _shrReceiverPositive(other);
    if (other is !num) throw new ArgumentError(other);
    if (JS('num', '#', other) < 0) throw new ArgumentError(other);
    return _shrOtherPositive(other);
  }

  num _shrOtherPositive(num other) {
    return JS('num', '#', this) > 0
        ? _shrBothPositive(other)
        // For negative numbers we just clamp the shift-by amount.
        // `this` could be negative but not have its 31st bit set.
        // The ">>" would then shift in 0s instead of 1s. Therefore
        // we cannot simply return 0xFFFFFFFF.
        : JS('JSUInt32', r'(# >> #) >>> 0', this, other > 31 ? 31 : other);
  }

  num _shrReceiverPositive(num other) {
    if (JS('num', '#', other) < 0) throw new ArgumentError(other);
    return _shrBothPositive(other);
  }

  num _shrBothPositive(num other) {
    return JS('bool', r'# > 31', other)
        // JavaScript only looks at the last 5 bits of the shift-amount. In JS
        // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
        // computation when that happens.
        ? 0
        // Given that `this` is positive we must not use '>>'. Otherwise a
        // number that has the 31st bit set would be treated as negative and
        // shift in ones.
        : JS('JSUInt32', r'# >>> #', this, other);
  }

  num operator &(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('JSUInt32', r'(# & #) >>> 0', this, other);
  }

  num operator |(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('JSUInt32', r'(# | #) >>> 0', this, other);
  }

  num operator ^(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('JSUInt32', r'(# ^ #) >>> 0', this, other);
  }

  bool operator <(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('bool', '# < #', this, other);
  }

  bool operator >(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('bool', '# > #', this, other);
  }

  bool operator <=(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('bool', '# <= #', this, other);
  }

  bool operator >=(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('bool', '# >= #', this, other);
  }

  Type get runtimeType => num;
}

/**
 * The interceptor class for [int]s.
 *
 * This class implements double since in JavaScript all numbers are doubles, so
 * while we want to treat `2.0` as an integer for some operations, its
 * interceptor should answer `true` to `is double`.
 */
class JSInt extends JSNumber implements int, double {
  const JSInt();

  bool get isEven => (this & 1) == 0;

  bool get isOdd => (this & 1) == 1;

  int toUnsigned(int width) {
    return this & ((1 << width) - 1);
  }

  int toSigned(int width) {
    int signMask = 1 << (width - 1);
    return (this & (signMask - 1)) - (this & signMask);
  }

  int get bitLength {
    int nonneg = this < 0 ? -this - 1 : this;
    if (nonneg >= 0x100000000) {
      nonneg = nonneg ~/ 0x100000000;
      return _bitCount(_spread(nonneg)) + 32;
    }
    return _bitCount(_spread(nonneg));
  }

  // Assumes i is <= 32-bit and unsigned.
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

    i = _shru(i, 0) - (_shru(i, 1) & 0x55555555);
    i = (i & 0x33333333) + (_shru(i, 2) & 0x33333333);
    i = 0x0F0F0F0F & (i + _shru(i, 4));
    i += _shru(i, 8);
    i += _shru(i, 16);
    return (i & 0x0000003F);
  }

  static _shru(int value, int shift) => JS('int', '# >>> #', value, shift);
  static _shrs(int value, int shift) => JS('int', '# >> #', value, shift);
  static _ors(int a, int b) => JS('int', '# | #', a, b);

  // Assumes i is <= 32-bit
  static int _spread(int i) {
    i = _ors(i, _shrs(i, 1));
    i = _ors(i, _shrs(i, 2));
    i = _ors(i, _shrs(i, 4));
    i = _ors(i, _shrs(i, 8));
    i = _shru(_ors(i, _shrs(i, 16)), 0);
    return i;
  }

  Type get runtimeType => int;

  int operator ~() => JS('JSUInt32', r'(~#) >>> 0', this);
}

class JSDouble extends JSNumber implements double {
  const JSDouble();
  Type get runtimeType => double;
}

class JSPositiveInt extends JSInt {}
class JSUInt32 extends JSPositiveInt {}
class JSUInt31 extends JSUInt32 {}
