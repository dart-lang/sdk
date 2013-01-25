// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

/**
 * The super interceptor class for [JSInt] and [JSDouble]. The compiler
 * recognizes this class as an interceptor, and changes references to
 * [:this:] to actually use the receiver of the method, which is
 * generated as an extra argument added to each member.
 */
class JSNumber {
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

  num remainder(num b) {
    checkNull(b); // TODO(ngeoffray): This is not specified but co19 tests it.
    if (b is! num) throw new ArgumentError(b);
    return JS('num', r'# % #', this, b);
  }

  num abs() => JS('num', r'Math.abs(#)', this);

  int toInt() {
    if (isNaN) throw new UnsupportedError('NaN');
    if (isInfinite) throw new UnsupportedError('Infinity');
    num truncated = truncate();
    return JS('bool', r'# == -0.0', truncated) ? 0 : truncated;
  }

  num ceil() => JS('num', r'Math.ceil(#)', this);

  num floor() => JS('num', r'Math.floor(#)', this);

  bool get isInfinite {
    return JS('bool', r'# == Infinity', this)
      || JS('bool', r'# == -Infinity', this);
  }

  num round() {
    if (this < 0) {
      return JS('num', r'-Math.round(-#)', this);
    } else {
      return JS('num', r'Math.round(#)', this);
    }
  }

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

  double toDouble() => this;

  num truncate() => this < 0 ? ceil() : floor();

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
      return JS('String', r'String(#)', this);
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

  num operator ~/(num other) {
    if (other is !num) throw new ArgumentError(other);
    return (JS('num', r'# / #', this, other)).truncate();
  }

  // TODO(ngeoffray): Move the bit operations below to [JSInt] and
  // make them take an int. Because this will make operations slower,
  // we define these methods on number for now but we need to decide
  // the grain at which we do the type checks.

  num operator <<(num other) {
    if (other is !num) throw new ArgumentError(other);
    if (JS('num', '#', other) < 0) throw new ArgumentError(other);
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    if (JS('bool', r'# > 31', other)) return 0;
    return JS('num', r'(# << #) >>> 0', this, other);
  }

  num operator >>(num other) {
    if (other is !num) throw new ArgumentError(other);
    if (JS('num', '#', other) < 0) throw new ArgumentError(other);
    if (JS('num', '#', this) > 0) {
      // JavaScript only looks at the last 5 bits of the shift-amount. In JS
      // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
      // computation when that happens.
      if (JS('bool', r'# > 31', other)) return 0;
      // Given that 'a' is positive we must not use '>>'. Otherwise a number
      // that has the 31st bit set would be treated as negative and shift in
      // ones.
      return JS('num', r'# >>> #', this, other);
    }
    // For negative numbers we just clamp the shift-by amount. 'a' could be
    // negative but not have its 31st bit set. The ">>" would then shift in
    // 0s instead of 1s. Therefore we cannot simply return 0xFFFFFFFF.
    if (JS('num', '#', other) > 31) other = 31;
    return JS('num', r'(# >> #) >>> 0', this, other);
  }

  num operator &(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', r'(# & #) >>> 0', this, other);    
  }

  num operator |(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', r'(# | #) >>> 0', this, other);    
  }

  num operator ^(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', r'(# ^ #) >>> 0', this, other);    
  }

  bool operator <(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# < #', this, other);
  }

  bool operator >(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# > #', this, other);
  }

  bool operator <=(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# <= #', this, other);
  }

  bool operator >=(num other) {
    if (other is !num) throw new ArgumentError(other);
    return JS('num', '# >= #', this, other);
  }
}

class JSInt extends JSNumber {
  const JSInt();

  bool get isEven => (this & 1) == 0;

  bool get isOdd => (this & 1) == 1;

  Type get runtimeType => int;

  int operator ~() => JS('int', r'(~#) >>> 0', this);
}

class JSDouble extends JSNumber {
  const JSDouble();
  Type get runtimeType => double;
}
