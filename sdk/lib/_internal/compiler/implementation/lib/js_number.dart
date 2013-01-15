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

  String toString() {
    if (this == 0 && JS('bool', '(1 / #) < 0', this)) {
      return '-0.0';
    } else {
      return JS('String', r'String(#)', this);
    }
  }

  int get hashCode => this & 0x1FFFFFFF;

  num operator -() => JS('num', r'-#', this);
}

class JSInt extends JSNumber {
  const JSInt();

  bool get isEven => (this & 1) == 0;

  bool get isOdd => (this & 1) == 1;

  Type get runtimeType => int;

  int operator ~() => JS('num', r'(~#) >>> 0', this);
}

class JSDouble extends JSNumber {
  const JSDouble();
  Type get runtimeType => double;
}
