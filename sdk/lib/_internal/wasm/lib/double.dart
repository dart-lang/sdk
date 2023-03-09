// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class double {
  @patch
  static double parse(String source,
      [@deprecated double onError(String source)?]) {
    double? result = tryParse(source);
    if (result == null) {
      if (onError == null) {
        throw FormatException('Invalid double $source');
      } else {
        return onError(source);
      }
    }
    return result;
  }

  @patch
  static double? tryParse(String source) {
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - [+/-]NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do allow leading or trailing whitespace.
    double result = JS<double>(r"""s => {
      const jsSource = stringFromDartString(s);
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(jsSource)) {
        return NaN;
      }
      return parseFloat(jsSource);
    }""", source);
    if (result.isNaN) {
      String trimmed = source.trim();
      if (!(trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN')) {
        return null;
      }
    }
    return result;
  }

  /// Wasm i64.trunc_sat_f64_s instruction
  external int _toInt();

  /// Wasm f64.copysign instruction
  external double _copysign(double other);
}

@pragma("wasm:entry-point")
final class _BoxedDouble extends double {
  // A boxed double contains an unboxed double.
  @pragma("wasm:entry-point")
  double value = 0.0;

  /// Dummy factory to silence error about missing superclass constructor.
  external factory _BoxedDouble();

  static const int _mantissaBits = 52;
  static const int _exponentBits = 11;
  static const int _exponentBias = 1023;
  static const int _signMask = 0x8000000000000000;
  static const int _exponentMask = 0x7FF0000000000000;
  static const int _mantissaMask = 0x000FFFFFFFFFFFFF;

  int get hashCode => _doubleHashCode(this);
  int get _identityHashCode => _doubleHashCode(this);

  static int _doubleHashCode(double value) {
    const int maxInt = 0x7FFFFFFFFFFFFFFF;
    int intValue = value._toInt();
    if (intValue.toDouble() == value && intValue != maxInt) {
      return _BoxedInt._intHashCode(intValue);
    }
    int bits = doubleToIntBits(value);
    return (bits ^ (bits >>> 32)) & 0x3FFFFFFF;
  }

  @pragma("wasm:prefer-inline")
  double operator +(num other) => this + other.toDouble(); // Intrinsic +
  @pragma("wasm:prefer-inline")
  double operator -(num other) => this - other.toDouble(); // Intrinsic -
  @pragma("wasm:prefer-inline")
  double operator *(num other) => this * other.toDouble(); // Intrinsic *
  @pragma("wasm:prefer-inline")
  double operator /(num other) => this / other.toDouble(); // Intrinsic /

  @pragma("wasm:prefer-inline")
  int operator ~/(num other) {
    return _truncDiv(this, other.toDouble());
  }

  static int _truncDiv(double a, double b) {
    return (a / b).toInt();
  }

  @pragma("wasm:prefer-inline")
  double operator %(num other) {
    return _modulo(this, other.toDouble());
  }

  static double _modulo(double a, double b) {
    double rem = a - (a / b).truncateToDouble() * b;
    if (rem == 0.0) return 0.0;
    if (rem < 0.0) {
      if (b < 0.0) {
        return rem - b;
      } else {
        return rem + b;
      }
    }
    return rem;
  }

  @pragma("wasm:prefer-inline")
  double remainder(num other) {
    return _remainder(this, other.toDouble());
  }

  static double _remainder(double a, double b) {
    return a - (a / b).truncateToDouble() * b;
  }

  external double operator -();

  @pragma("wasm:prefer-inline")
  bool operator ==(Object other) {
    return other is double
        ? this == other // Intrinsic ==
        : other is int
            ? this == other.toDouble() // Intrinsic ==
            : false;
  }

  @pragma("wasm:prefer-inline")
  bool operator <(num other) => this < other.toDouble(); // Intrinsic <
  @pragma("wasm:prefer-inline")
  bool operator >(num other) => this > other.toDouble(); // Intrinsic >
  @pragma("wasm:prefer-inline")
  bool operator >=(num other) => this >= other.toDouble(); // Intrinsic >=
  @pragma("wasm:prefer-inline")
  bool operator <=(num other) => this <= other.toDouble(); // Intrinsic <=

  @pragma("wasm:prefer-inline")
  bool get isNegative {
    // Sign bit set, not NaN
    int bits = doubleToIntBits(this);
    return (bits ^ _signMask)._le_u(_exponentMask);
  }

  @pragma("wasm:prefer-inline")
  bool get isInfinite {
    // Exponent at max, mantissa zero
    int bits = doubleToIntBits(this);
    return (bits & (_exponentMask | _mantissaMask)) == _exponentMask;
  }

  @pragma("wasm:prefer-inline")
  bool get isNaN {
    // Exponent at max, mantissa nonzero
    int bits = doubleToIntBits(this);
    return (bits & (_exponentMask | _mantissaMask)) > _exponentMask;
  }

  @pragma("wasm:prefer-inline")
  bool get isFinite {
    // Exponent not at max
    int bits = doubleToIntBits(this);
    return (bits & _exponentMask) != _exponentMask;
  }

  @pragma("wasm:prefer-inline")
  double abs() {
    return _copysign(0.0);
  }

  @pragma("wasm:prefer-inline")
  double get sign {
    if (this > 0.0) return 1.0;
    if (this < 0.0) return -1.0;
    return this; // +/-0.0 or NaN.
  }

  @pragma("wasm:prefer-inline")
  int round() => roundToDouble().toInt();
  @pragma("wasm:prefer-inline")
  int floor() => floorToDouble().toInt();
  @pragma("wasm:prefer-inline")
  int ceil() => ceilToDouble().toInt();
  @pragma("wasm:prefer-inline")
  int truncate() => truncateToDouble().toInt();

  @pragma("wasm:prefer-inline")
  double roundToDouble() {
    return _roundToDouble(this);
  }

  static double _roundToDouble(final double d) {
    final int bits = doubleToIntBits(d);
    final int exponent = (bits >> _mantissaBits) & ((1 << _exponentBits) - 1);

    if (exponent < _exponentBias) {
      // The exponent is less than 0, which means the absolute value of the
      // number is less than 1.
      return (d * 2.0).truncateToDouble();
    }

    if (exponent >= _exponentBias + _mantissaBits) {
      // The exponent is so big that the number is already an integer,
      // or it is +/- infinity or NaN.
      return d;
    }

    // Add 0.5 to the absolute value of the number and truncate the result.
    final int shift = (_exponentBias + _mantissaBits - 1) - exponent;
    final int adjust = (1)._shl(shift);
    final int mask = (-2)._shl(shift);
    final int rounded = (bits + adjust) & mask;
    return intBitsToDouble(rounded);
  }

  external double floorToDouble();
  external double ceilToDouble();
  external double truncateToDouble();

  num clamp(num lowerLimit, num upperLimit) {
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw new ArgumentError(lowerLimit);
    }
    if (lowerLimit.isNaN) return lowerLimit;
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  @pragma("wasm:prefer-inline")
  int toInt() {
    if (!isFinite) {
      throw UnsupportedError("Infinity or NaN toInt");
    }
    return _toInt();
  }

  @pragma("wasm:prefer-inline")
  double toDouble() {
    return this;
  }

  static const int CACHE_SIZE_LOG2 = 3;
  static const int CACHE_LENGTH = 1 << (CACHE_SIZE_LOG2 + 1);
  static const int CACHE_MASK = CACHE_LENGTH - 1;
  // Each key (double) followed by its toString result.
  static final List _cache = new List.filled(CACHE_LENGTH, null);
  static int _cacheEvictIndex = 0;

  String toString() {
    // TODO(koda): Consider starting at most recently inserted.
    for (int i = 0; i < CACHE_LENGTH; i += 2) {
      // Need 'identical' to handle negative zero, etc.
      if (identical(_cache[i], this)) {
        return _cache[i + 1];
      }
    }
    // TODO(koda): Consider optimizing all small integral values.
    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";
    if (this == 0) {
      if (isNegative) {
        return "-0.0";
      } else {
        return "0.0";
      }
    }
    String result = JS<String>("v => stringToDartString(v.toString())", value);
    if (this % 1.0 == 0.0 && result.indexOf('e') == -1) {
      result = '$result.0';
    }
    // Replace the least recently inserted entry.
    _cache[_cacheEvictIndex] = this;
    _cache[_cacheEvictIndex + 1] = result;
    _cacheEvictIndex = (_cacheEvictIndex + 2) & CACHE_MASK;
    return result;
  }

  String toStringAsFixed(int fractionDigits) {
    // See ECMAScript-262, 15.7.4.5 for details.

    // Step 2.
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
    }

    // Step 3.
    double x = this;

    // Step 4.
    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

    // Step 5 and 6 skipped. Will be dealt with by native function.

    // Step 7.
    if (x >= 1e21 || x <= -1e21) {
      return x.toString();
    }

    String result = _toStringAsFixed(fractionDigits);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String _toStringAsFixed(int fractionDigits) => JS<String>(
      "(d, digits) => stringToDartString(d.toFixed(digits))",
      value,
      fractionDigits.toDouble());

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

    String result = _toStringAsExponential(fractionDigits);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String _toStringAsExponential(int? fractionDigits) {
    if (fractionDigits == null) {
      return JS<String>("d => stringToDartString(d.toExponential())", value);
    } else {
      return JS<String>("(d, f) => stringToDartString(d.toExponential(f))",
          value, fractionDigits.toDouble());
    }
  }

  String toStringAsPrecision(int precision) {
    // See ECMAScript-262, 15.7.4.7 for details.

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

    String result = _toStringAsPrecision(precision);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String _toStringAsPrecision(int fractionDigits) => JS<String>(
      "(d, precision) => stringToDartString(d.toPrecision(precision))",
      value,
      fractionDigits.toDouble());

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
        return _toInt().compareTo(other);
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
