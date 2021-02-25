// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "core_patch.dart";

@pragma("vm:entry-point")
class _Double implements double {
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  factory _Double.fromInteger(int value) native "Double_doubleFromInteger";

  @pragma("vm:recognized", "asm-intrinsic")
  int get hashCode native "Double_hashCode";
  @pragma("vm:recognized", "asm-intrinsic")
  int get _identityHashCode native "Double_hashCode";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator +(num other) {
    return _add(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  double _add(double other) native "Double_add";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator -(num other) {
    return _sub(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  double _sub(double other) native "Double_sub";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator *(num other) {
    return _mul(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  double _mul(double other) native "Double_mul";

  int operator ~/(num other) {
    return _trunc_div(other.toDouble());
  }

  @pragma("vm:non-nullable-result-type")
  int _trunc_div(double other) native "Double_trunc_div";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator /(num other) {
    return _div(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  double _div(double other) native "Double_div";

  double operator %(num other) {
    return _modulo(other.toDouble());
  }

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  double _modulo(double other) native "Double_modulo";

  double remainder(num other) {
    return _remainder(other.toDouble());
  }

  double _remainder(double other) native "Double_remainder";

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  double operator -() native "Double_flipSignBit";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator ==(Object other) {
    return (other is num) && _equal(other.toDouble());
  }

  @pragma("vm:exact-result-type", bool)
  bool _equal(double other) native "Double_equal";
  @pragma("vm:exact-result-type", bool)
  bool _equalToInteger(int other) native "Double_equalToInteger";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator <(num other) {
    return other > this;
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator >(num other) {
    return _greaterThan(other.toDouble());
  }

  @pragma("vm:exact-result-type", bool)
  bool _greaterThan(double other) native "Double_greaterThan";

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator >=(num other) {
    return (this == other) || (this > other);
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator <=(num other) {
    return (this == other) || (this < other);
  }

  double _addFromInteger(int other) {
    return new _Double.fromInteger(other)._add(this);
  }

  double _subFromInteger(int other) {
    return new _Double.fromInteger(other)._sub(this);
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Double")
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

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  bool get isNegative native "Double_getIsNegative";
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  bool get isInfinite native "Double_getIsInfinite";
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
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

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  double roundToDouble() native "Double_round";
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  double floorToDouble() native "Double_floor";
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  double ceilToDouble() native "Double_ceil";
  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  double truncateToDouble() native "Double_truncate";

  num clamp(num lowerLimit, num upperLimit) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (lowerLimit == null) {
      throw new ArgumentError.notNull("lowerLimit");
    }
    if (upperLimit == null) {
      throw new ArgumentError.notNull("upperLimit");
    }
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw new ArgumentError(lowerLimit);
    }
    if (lowerLimit.isNaN) return lowerLimit;
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:non-nullable-result-type")
  int toInt() native "Double_toInt";

  double toDouble() {
    return this;
  }

  static const int CACHE_SIZE_LOG2 = 3;
  static const int CACHE_LENGTH = 1 << (CACHE_SIZE_LOG2 + 1);
  static const int CACHE_MASK = CACHE_LENGTH - 1;
  // Each key (double) followed by its toString result.
  static final List _cache = new List.filled(CACHE_LENGTH, null);
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

    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (fractionDigits == null) {
      throw new ArgumentError.notNull("fractionDigits");
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

  String toStringAsExponential([int? fractionDigits]) {
    // See ECMAScript-262, 15.7.4.6 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 7.
    if (fractionDigits != null) {
      if (fractionDigits < 0 || fractionDigits > 20) {
        throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
      }
    }

    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

    // The dart function prints the shortest representation when fractionDigits
    // equals null. The native function wants -1 instead.
    fractionDigits = (fractionDigits == null) ? -1 : fractionDigits;

    return _toStringAsExponential(fractionDigits);
  }

  String _toStringAsExponential(int fractionDigits)
      native "Double_toStringAsExponential";

  String toStringAsPrecision(int precision) {
    // See ECMAScript-262, 15.7.4.7 for details.

    if (precision == null) {
      throw new ArgumentError.notNull("precision");
    }
    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 8.
    if (precision < 1 || precision > 21) {
      throw new RangeError.range(precision, 1, 21, "precision");
    }

    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

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
      } else if (other is int) {
        // Compare as integers as it is more precise if the integer value is
        // outside of MIN_EXACT_INT_TO_DOUBLE..MAX_EXACT_INT_TO_DOUBLE range.
        const int MAX_EXACT_INT_TO_DOUBLE = 9007199254740992; // 2^53.
        const int MIN_EXACT_INT_TO_DOUBLE = -MAX_EXACT_INT_TO_DOUBLE;
        if ((MIN_EXACT_INT_TO_DOUBLE <= other) &&
            (other <= MAX_EXACT_INT_TO_DOUBLE)) {
          return EQUAL;
        }
        const bool limitIntsTo64Bits = ((1 << 64) == 0);
        if (limitIntsTo64Bits) {
          // With integers limited to 64 bits, double.toInt() clamps
          // double value to fit into the MIN_INT64..MAX_INT64 range.
          // MAX_INT64 is not precisely representable as double, so
          // integers near MAX_INT64 compare as equal to (MAX_INT64 + 1) when
          // represented as doubles.
          // There is no similar problem with MIN_INT64 as it is precisely
          // representable as double.
          const double maxInt64Plus1AsDouble = 9223372036854775808.0;
          if (this >= maxInt64Plus1AsDouble) {
            return GREATER;
          }
        }
        return toInt().compareTo(other);
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
