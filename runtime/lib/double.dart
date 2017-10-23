// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

class _Double implements double {
  factory _Double.fromInteger(int value) native "Double_doubleFromInteger";

  int get hashCode native "Double_hashCode";
  int get _identityHashCode native "Double_hashCode";

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

  int operator ~/(num other) {
    return _trunc_div(other.toDouble());
  }

  int _trunc_div(double other) native "Double_trunc_div";

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

  double operator -() native "Double_flipSignBit";

  bool operator ==(other) {
    if (!(other is num)) return false;
    return _equal(other.toDouble());
  }

  bool _equal(double other) native "Double_equal";
  bool _equalToInteger(int other) native "Double_equalToInteger";
  bool operator <(num other) {
    return other > this;
  }

  bool operator >(num other) {
    return _greaterThan(other.toDouble());
  }

  bool _greaterThan(double other) native "Double_greaterThan";
  bool operator >=(num other) {
    return (this == other) || (this > other);
  }

  bool operator <=(num other) {
    return (this == other) || (this < other);
  }

  double _addFromInteger(int other) {
    return new _Double.fromInteger(other)._add(this);
  }

  double _subFromInteger(int other) {
    return new _Double.fromInteger(other)._sub(this);
  }

  double _mulFromInteger(int other) {
    return new _Double.fromInteger(other)._mul(this);
  }

  int _truncDivFromInteger(int other) {
    return new _Double.fromInteger(other)._trunc_div(this);
  }

  double _moduloFromInteger(int other) {
    return new _Double.fromInteger(other)._modulo(this);
  }

  double _remainderFromInteger(int other) {
    return new _Double.fromInteger(other)._remainder(this);
  }

  bool _greaterThanFromInteger(int other)
      native "Double_greaterThanFromInteger";

  bool get isNegative native "Double_getIsNegative";
  bool get isInfinite native "Double_getIsInfinite";
  bool get isNaN native "Double_getIsNaN";
  bool get isFinite => !isInfinite && !isNaN; // Can be optimized.

  double abs() {
    // Handle negative 0.0.
    if (this == 0.0) return 0.0;
    return this < 0.0 ? -this : this;
  }

  double get sign {
    if (this > 0.0) return 1.0;
    if (this < 0.0) return -1.0;
    return this; // +/-0.0 or NaN.
  }

  int round() => roundToDouble().toInt();
  int floor() => floorToDouble().toInt();
  int ceil() => ceilToDouble().toInt();
  int truncate() => truncateToDouble().toInt();

  double roundToDouble() native "Double_round";
  double floorToDouble() native "Double_floor";
  double ceilToDouble() native "Double_ceil";
  double truncateToDouble() native "Double_truncate";

  num clamp(num lowerLimit, num upperLimit) {
    if (lowerLimit is! num) {
      throw new ArgumentError.value(lowerLimit, "lowerLimit", "not a number");
    }
    if (upperLimit is! num) {
      throw new ArgumentError.value(upperLimit, "upperLimit", "not a number");
    }

    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw new ArgumentError(lowerLimit);
    }
    if (lowerLimit.isNaN) return lowerLimit;
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  int toInt() native "Double_toInt";
  num _toBigintOrDouble() {
    return this;
  }

  double toDouble() {
    return this;
  }

  static const int CACHE_SIZE_LOG2 = 3;
  static const int CACHE_LENGTH = 1 << (CACHE_SIZE_LOG2 + 1);
  static const int CACHE_MASK = CACHE_LENGTH - 1;
  // Each key (double) followed by its toString result.
  static final List _cache = new List(CACHE_LENGTH);
  static int _cacheEvictIndex = 0;

  String _toString() native "Double_toString";

  String toString() {
    // TODO(koda): Consider starting at most recently inserted.
    for (int i = 0; i < CACHE_LENGTH; i += 2) {
      // Need 'identical' to handle negative zero, etc.
      if (identical(_cache[i], this)) {
        return _cache[i + 1];
      }
    }
    // TODO(koda): Consider optimizing all small integral values.
    if (identical(0.0, this)) {
      return "0.0";
    }
    String result = _toString();
    // Replace the least recently inserted entry.
    _cache[_cacheEvictIndex] = this;
    _cache[_cacheEvictIndex + 1] = result;
    _cacheEvictIndex = (_cacheEvictIndex + 2) & CACHE_MASK;
    return result;
  }

  String toStringAsFixed(int fractionDigits) {
    // See ECMAScript-262, 15.7.4.5 for details.

    if (fractionDigits is! int) {
      throw new ArgumentError.value(
          fractionDigits, "fractionDigits", "not an integer");
    }
    // Step 2.
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
    }

    // Step 3.
    double x = this;

    // Step 4.
    if (isNaN) return "NaN";

    // Step 5 and 6 skipped. Will be dealt with by native function.

    // Step 7.
    if (x >= 1e21 || x <= -1e21) {
      return x.toString();
    }

    return _toStringAsFixed(fractionDigits);
  }

  String _toStringAsFixed(int fractionDigits) native "Double_toStringAsFixed";

  String toStringAsExponential([int fractionDigits]) {
    // See ECMAScript-262, 15.7.4.6 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 7.
    if (fractionDigits != null) {
      if (fractionDigits is! int) {
        throw new ArgumentError.value(
            fractionDigits, "fractionDigits", "not an integer");
      }
      if (fractionDigits < 0 || fractionDigits > 20) {
        throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
      }
    }

    if (isNaN) return "NaN";
    if (this == double.INFINITY) return "Infinity";
    if (this == -double.INFINITY) return "-Infinity";

    // The dart function prints the shortest representation when fractionDigits
    // equals null. The native function wants -1 instead.
    fractionDigits = (fractionDigits == null) ? -1 : fractionDigits;

    return _toStringAsExponential(fractionDigits);
  }

  String _toStringAsExponential(int fractionDigits)
      native "Double_toStringAsExponential";

  String toStringAsPrecision(int precision) {
    // See ECMAScript-262, 15.7.4.7 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    if (precision is! int) {
      throw new ArgumentError.value(precision, "precision", "not an integer");
    }
    // Step 8.
    if (precision < 1 || precision > 21) {
      throw new RangeError.range(precision, 1, 21, "precision");
    }

    if (isNaN) return "NaN";
    if (this == double.INFINITY) return "Infinity";
    if (this == -double.INFINITY) return "-Infinity";

    return _toStringAsPrecision(precision);
  }

  String _toStringAsPrecision(int fractionDigits)
      native "Double_toStringAsPrecision";

  // Order is: NaN > Infinity > ... > 0.0 > -0.0 > ... > -Infinity.
  int compareTo(num other) {
    const int EQUAL = 0, LESS = -1, GREATER = 1;
    if (this < other) {
      return LESS;
    } else if (this > other) {
      return GREATER;
    } else if (this == other) {
      if (this == 0.0) {
        bool thisIsNegative = isNegative;
        bool otherIsNegative = other.isNegative;
        if (thisIsNegative == otherIsNegative) {
          return EQUAL;
        }
        return thisIsNegative ? LESS : GREATER;
      } else {
        return EQUAL;
      }
    } else if (isNaN) {
      return other.isNaN ? EQUAL : GREATER;
    } else {
      // Other is NaN.
      return LESS;
    }
  }
}
