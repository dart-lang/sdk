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
    if (isNaN) throw new FormatException('NaN');
    if (isInfinite) throw new FormatException('Infinity');
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

  double toDouble() => this;

  num truncate() => this < 0 ? ceil() : floor();

  String toStringAsFixed(int fractionDigits) {
    checkNum(fractionDigits);
    String result = JS('String', r'#.toFixed(#)', this, fractionDigits);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toStringAsExponential(int fractionDigits) {
    String result;
    if (fractionDigits != null) {
      checkNum(fractionDigits);
      result = JS('String', r'#.toExponential(#)', this, fractionDigits);
    } else {
      result = JS('String', r'#.toExponential()', this);
    }
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toStringAsPrecision(int fractionDigits) {
    checkNum(fractionDigits);
    String result = JS('String', r'#.toPrecision(#)',
                       this, fractionDigits);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  String toRadixString(int radix) {
    checkNum(radix);
    if (radix < 2 || radix > 36) throw new ArgumentError(radix);
    return JS('String', r'#.toString(#)', this, radix);
  }
}

class JSInt extends JSNumber {
  const JSInt();

  bool get isEven => (this & 1) == 0;

  bool get isOdd => (this & 1) == 1;
}

class JSDouble extends JSNumber {
  const JSDouble();
}
