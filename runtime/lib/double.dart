// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Double implements double {
  factory _Double.fromInteger(int value)
      native "Double_doubleFromInteger";
  int hashCode() {
    try {
      return toInt();
    } on FormatException catch (e) {
      return 0;
    }
  }
  double operator +(num other) {
    return _add(other.toDouble());
  }
  double _add(double other) native "Double_add";

  double operator -(num other) {
    return _sub(other.toDouble());
  }
  double _sub(double other) native "Double_sub";

  double operator *(num other) {
    return _mul(other.toDouble());
  }
  double _mul(double other) native "Double_mul";

  double operator ~/(num other) {
    return _trunc_div(other.toDouble());
  }
  double _trunc_div(double other) native "Double_trunc_div";

  double operator /(num other) {
    return _div(other.toDouble());
  }
  double _div(double other) native "Double_div";

  double operator %(num other) {
    return _modulo(other.toDouble());
  }
  double _modulo(double other) native "Double_modulo";

  double remainder(num other) {
    return _remainder(other.toDouble());
  }
  double _remainder(double other) native "Double_remainder";
  double operator -() {
    if (this == 0.0) {
      // -0.0 is canonicalized by the VM's parser, therefore no cycles.
      return isNegative() ? 0.0 : -0.0;
    }
    return 0.0 - this;
  }
  bool operator ==(other) {
    if (!(other is num)) return false;
    return _equal(other.toDouble());
  }
  bool _equal(double other)native "Double_equal";
  bool _equalToInteger(int other) native "Double_equalToInteger";
  bool operator <(num other) {
    return other > this;
  }
  bool operator >(num other) {
    return _greaterThan(other.toDouble());
  }
  bool _greaterThan(double other) native "Double_greaterThan";
  bool operator >=(num other) {
    return (this == other) ||  (this > other);
  }
  bool operator <=(num other) {
    return (this == other) ||  (this < other);
  }
  double _addFromInteger(int other) {
    return new _Double.fromInteger(other) + this;
  }
  double _subFromInteger(int other) {
    return new _Double.fromInteger(other) - this;
  }
  double _mulFromInteger(int other) {
    return new _Double.fromInteger(other) * this;
  }
  double _truncDivFromInteger(int other) {
    return new _Double.fromInteger(other) ~/ this;
  }
  double _moduloFromInteger(int other) {
    return new _Double.fromInteger(other) % this;
  }
  double _remainderFromInteger(int other) {
    return new _Double.fromInteger(other).remainder(this);
  }
  bool _greaterThanFromInteger(int other)
      native "Double_greaterThanFromInteger";

  bool isNegative() native "Double_isNegative";
  bool isInfinite() native "Double_isInfinite";
  bool isNaN() native "Double_isNaN";

  double abs() {
    // Handle negative 0.0.
    if (this == 0.0) return 0.0;
    return this < 0.0 ? -this : this;
  }

  double round() native "Double_round";
  double floor() native "Double_floor";
  double ceil () native "Double_ceil";
  double truncate() native "Double_truncate";
  int toInt() native "Double_toInt";
  double toDouble() { return this; }

  double pow(num exponent) {
    if (exponent == 0) {
      return 1.0;  // ECMA-262 15.8.2.13
    }
    // Throw NullPointerException if exponent is null.
    double doubleExponent = exponent.toDouble();
    if (isNaN() || exponent.isNaN()) {
      return double.NAN;
    }
    return _pow(doubleExponent);
  }
  double _pow(double exponent) native "Double_pow";

  String toStringAsFixed(int fractionDigits) {
    // See ECMAScript-262, 15.7.4.5 for details.

    // Step 2.
    if (fractionDigits < 0 || fractionDigits > 20) {
      // TODO(antonm): should be proper RangeError or Dart counterpart.
      throw "Range error";
    }

    // Step 3.
    double x = this;

    // Step 4.
    if (isNaN()) return "NaN";

    // Step 5 and 6 skipped. Will be dealt with by native function.

    // Step 7.
    if (x >= 1e21 || x <= -1e21) {
      return x.toString();
    }

    return _toStringAsFixed(fractionDigits);
  }
  String _toStringAsFixed(int fractionDigits) native "Double_toStringAsFixed";

  String toStringAsExponential(int fractionDigits) {
    // See ECMAScript-262, 15.7.4.6 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 7.
    if (fractionDigits !== null &&
        (fractionDigits < 0 || fractionDigits > 20)) {
      // TODO(antonm): should be proper RangeError or Dart counterpart.
      throw "Range error";
    }

    if (isNaN()) return "NaN";
    if (this == double.INFINITY) return "Infinity";
    if (this == -double.INFINITY) return "-Infinity";

    // The dart function prints the shortest representation when fractionDigits
    // equals null. The native function wants -1 instead.
    fractionDigits = (fractionDigits === null) ? -1 : fractionDigits;

    return _toStringAsExponential(fractionDigits);
  }
  String _toStringAsExponential(int fractionDigits)
      native "Double_toStringAsExponential";

  String toStringAsPrecision(int precision) {
    // See ECMAScript-262, 15.7.4.7 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 8.
    if (precision < 1 || precision > 21) {
      // TODO(antonm): should be proper RangeError or Dart counterpart.
      throw "Range error";
    }

    if (isNaN()) return "NaN";
    if (this == double.INFINITY) return "Infinity";
    if (this == -double.INFINITY) return "-Infinity";

    return _toStringAsPrecision(precision);
  }
  String _toStringAsPrecision(int fractionDigits)
      native "Double_toStringAsPrecision";

  String toRadixString(int radix) {
    return toInt().toRadixString(radix);
  }

  // Order is: NaN > Infinity > ... > 0.0 > -0.0 > ... > -Infinity.
  int compareTo(Comparable other) {
    final int EQUAL = 0, LESS = -1, GREATER = 1;
    if (this < other) {
      return LESS;
    } else if (this > other) {
      return GREATER;
    } else if (this == other) {
      if (this == 0.0) {
        bool thisIsNegative = isNegative();
        bool otherIsNegative = other.isNegative();
        if (thisIsNegative == otherIsNegative) {
          return EQUAL;
        }
        return thisIsNegative ? LESS : GREATER;
      } else {
        return EQUAL;
      }
    } else if (isNaN()) {
      return other.isNaN() ? EQUAL : GREATER;
    } else {
      // Other is NaN.
      return LESS;
    }
  }
}
