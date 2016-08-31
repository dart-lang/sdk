// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._interceptors;

/**
 * The implementation of Dart's int & double methods.
 * These are made available as extension methods on `Number` in JS.
 */
@JsPeerInterface(name: 'Number')
class JSNumber extends Interceptor implements int, double {
  const JSNumber();

  int compareTo(num b) {
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
    return JS('bool', r'# == (1/0)', this)
        || JS('bool', r'# == (-1/0)', this);
  }

  bool get isFinite => JS('bool', r'isFinite(#)', this);

  JSNumber remainder(num b) {
    if (b is! num) throw argumentErrorValue(b);
    return JS('num', r'# % #', this, b);
  }

  JSNumber abs() => JS('num', r'Math.abs(#)', this);

  JSNumber get sign => this > 0 ? 1 : this < 0 ? -1 : this;

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
    throw new UnsupportedError(JS("String", '"" + #', this));
  }

  int truncate() => toInt();

  int ceil() => ceilToDouble().toInt();

  int floor() => floorToDouble().toInt();

  int round() {
    if (this > 0) {
      // This path excludes the special cases -0.0, NaN and -Infinity, leaving
      // only +Infinity, for which a direct test is faster than [isFinite].
      if (JS('bool', r'# !== (1/0)', this)) {
        return JS('int', r'Math.round(#)', this);
      }
    } else if (JS('bool', '# > (-1/0)', this)) {
      // This test excludes NaN and -Infinity, leaving only -0.0.
      //
      // Subtraction from zero rather than negation forces -0.0 to 0.0 so code
      // inside Math.round and code to handle result never sees -0.0, which on
      // some JavaScript VMs can be a slow path.
      return JS('int', r'0 - Math.round(0 - #)', this);
    }
    // This is either NaN, Infinity or -Infinity.
    throw new UnsupportedError(JS("String", '"" + #', this));
  }

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

  num clamp(num lowerLimit, num upperLimit) {
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw argumentErrorValue(lowerLimit);
    }
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  double toDouble() => this;

  String toStringAsFixed(int fractionDigits) {
    checkInt(fractionDigits);
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
    }
    String result = JS('String', r'#.toFixed(#)', this, fractionDigits);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toStringAsExponential([int fractionDigits]) {
    String result;
    if (fractionDigits != null) {
      checkInt(fractionDigits);
      if (fractionDigits < 0 || fractionDigits > 20) {
        throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
      }
      result = JS('String', r'#.toExponential(#)', this, fractionDigits);
    } else {
      result = JS('String', r'#.toExponential()', this);
    }
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toStringAsPrecision(int precision) {
    checkInt(precision);
    if (precision < 1 || precision > 21) {
      throw new RangeError.range(precision, 1, 21, "precision");
    }
    String result = JS('String', r'#.toPrecision(#)',
                       this, precision);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toRadixString(int radix) {
    checkInt(radix);
    if (radix < 2 || radix > 36) {
      throw new RangeError.range(radix, 2, 36, "radix");
    }
    String result = JS('String', r'#.toString(#)', this, radix);
    const int rightParenCode = 0x29;
    if (result.codeUnitAt(result.length - 1) != rightParenCode) {
      return result;
    }
    return _handleIEtoString(result);
  }

  static String _handleIEtoString(String result) {
    // Result is probably IE's untraditional format for large numbers,
    // e.g., "8.0000000000008(e+15)" for 0x8000000000000800.toString(16).
    var match = JS('List|Null',
                   r'/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(#)',
                   result);
    if (match == null) {
      // Then we don't know how to handle it at all.
      throw new UnsupportedError("Unexpected toString result: $result");
    }
    result = JS('String', '#', match[1]);
    int exponent = JS("int", "+#", match[3]);
    if (match[2] != null) {
      result = JS('String', '# + #', result, match[2]);
      exponent -= JS('int', '#.length', match[2]);
    }
    return result + "0" * exponent;
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

  JSNumber operator -() => JS('num', r'-#', this);

  JSNumber operator +(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('num', '# + #', this, other);
  }

  JSNumber operator -(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('num', '# - #', this, other);
  }

  double operator /(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('num', '# / #', this, other);
  }

  JSNumber operator *(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('num', '# * #', this, other);
  }

  JSNumber operator %(num other) {
    if (other is !num) throw argumentErrorValue(other);
    // Euclidean Modulo.
    num result = JS('num', r'# % #', this, other);
    if (result == 0) return (0 as JSNumber);  // Make sure we don't return -0.0.
    if (result > 0) return result;
    if (JS('num', '#', other) < 0) {
      return result - JS('num', '#', other);
    } else {
      return result + JS('num', '#', other);
    }
  }

  bool _isInt32(value) => JS('bool', '(# | 0) === #', value, value);

  int operator ~/(num other) {
    if (_isInt32(this) && _isInt32(other) && 0 != other && -1 != other) {
      return JS('int', r'(# / #) | 0', this, other);
    } else {
      return _tdivSlow(other);
    }
  }

  int _tdivSlow(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return (JS('num', r'# / #', this, other)).toInt();
  }

  // TODO(ngeoffray): Move the bit operations below to [JSInt] and
  // make them take an int. Because this will make operations slower,
  // we define these methods on number for now but we need to decide
  // the grain at which we do the type checks.

  int operator <<(num other) {
    if (other is !num) throw argumentErrorValue(other);
    if (JS('num', '#', other) < 0) throw argumentErrorValue(other);
    return _shlPositive(other);
  }

  int _shlPositive(num other) {
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    return JS('bool', r'# > 31', other)
        ? 0
        : JS('int', r'(# << #) >>> 0', this, other);
  }

  int operator >>(num other) {
    if (other is !num) throw argumentErrorValue(other);
    if (JS('num', '#', other) < 0) throw argumentErrorValue(other);
    return _shrOtherPositive(other);
  }

  int _shrOtherPositive(num other) {
    return JS('num', '#', this) > 0
        ? _shrBothPositive(other)
        // For negative numbers we just clamp the shift-by amount.
        // `this` could be negative but not have its 31st bit set.
        // The ">>" would then shift in 0s instead of 1s. Therefore
        // we cannot simply return 0xFFFFFFFF.
        : JS('int', r'(# >> #) >>> 0', this, other > 31 ? 31 : other);
  }

  int _shrBothPositive(num other) {
    return JS('bool', r'# > 31', other)
        // JavaScript only looks at the last 5 bits of the shift-amount. In JS
        // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
        // computation when that happens.
        ? 0
        // Given that `this` is positive we must not use '>>'. Otherwise a
        // number that has the 31st bit set would be treated as negative and
        // shift in ones.
        : JS('int', r'# >>> #', this, other);
  }

  int operator &(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('int', r'(# & #) >>> 0', this, other);
  }

  int operator |(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('int', r'(# | #) >>> 0', this, other);
  }

  int operator ^(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('int', r'(# ^ #) >>> 0', this, other);
  }

  bool operator <(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('bool', '# < #', this, other);
  }

  bool operator >(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('bool', '# > #', this, other);
  }

  bool operator <=(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('bool', '# <= #', this, other);
  }

  bool operator >=(num other) {
    if (other is !num) throw argumentErrorValue(other);
    return JS('bool', '# >= #', this, other);
  }

  // int members.
  // TODO(jmesserly): all numbers will have these in dynamic dispatch.
  // We can fix by checking it at dispatch time but we'd need to structure them
  // differently.

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
    int b = this;
    if (b < 0 || b > m) {
      b %= m;
    }
    int r = 1;
    while (e > 0) {
      if (e.isOdd) {
        r = (r * b) % m;
      }
      e ~/= 2;
      b = (b * b) % m;
    }
    return r;
  }

  // If inv is false, returns gcd(x, y).
  // If inv is true and gcd(x, y) = 1, returns d, so that c*x + d*y = 1.
  // If inv is true and gcd(x, y) != 1, throws Exception("Not coprime").
  static int _binaryGcd(int x, int y, bool inv) {
    int s = 1;
    if (!inv) {
      while (x.isEven && y.isEven) {
        x ~/= 2;
        y ~/= 2;
        s *= 2;
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
    int a = 1,
        b = 0,
        c = 0,
        d = 1;
    do {
      while (u.isEven) {
        u ~/= 2;
        if (ac) {
          if (!a.isEven || !b.isEven) {
            a += y;
            b -= x;
          }
          a ~/= 2;
        } else if (!b.isEven) {
          b -= x;
        }
        b ~/= 2;
      }
      while (v.isEven) {
        v ~/= 2;
        if (ac) {
          if (!c.isEven || !d.isEven) {
            c += y;
            d -= x;
          }
          c ~/= 2;
        } else if (!d.isEven) {
          d -= x;
        }
        d ~/= 2;
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
    if (!inv) return s*v;
    if (v != 1) throw new Exception("Not coprime");
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
    return _binaryGcd(x, y, false);
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

  static int _shru(int value, int shift) => JS('int', '# >>> #', value, shift);
  static int _shrs(int value, int shift) => JS('int', '# >> #', value, shift);
  static int _ors(int a, int b) => JS('int', '# | #', a, b);

  // Assumes i is <= 32-bit
  static int _spread(int i) {
    i = _ors(i, _shrs(i, 1));
    i = _ors(i, _shrs(i, 2));
    i = _ors(i, _shrs(i, 4));
    i = _ors(i, _shrs(i, 8));
    i = _shru(_ors(i, _shrs(i, 16)), 0);
    return i;
  }

  int operator ~() => JS('int', r'(~#) >>> 0', this);
}
