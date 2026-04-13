// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show doubleToIntBits, intBitsToDouble, patch;
import 'dart:_js_helper' show JS;
import 'dart:_string';

@patch
class BoxedDouble {
  @patch
  String toString() {
    final int bits = doubleToIntBits(value);

    if (bits == doubleToIntBits(0.0)) return '0.0';
    if (bits == doubleToIntBits(-0.0)) return '-0.0';
    if (bits == doubleToIntBits(1.0)) return '1.0';
    if (bits == doubleToIntBits(-1.0)) return '-1.0';

    for (int i = 0; i < CACHE_LENGTH; i++) {
      // Special cases such as -0.0/0.0 and NaN are never inserted into the
      // cache.
      if (bits == _cacheKeys[i]) {
        return _cacheValues[i];
      }
    }
    if (isNaN) return "NaN";
    if (isInfinite) {
      if (isNegative) return "-Infinity";
      return "Infinity";
    }

    String result = JSStringImpl.fromRefUnchecked(
      JS<WasmExternRef?>(
        'Function.prototype.call.bind(Number.prototype.toString)',
        WasmF64.fromDouble(value),
      ),
    );
    if (this % 1.0 == 0.0 && result.indexOf('e') == -1) {
      result = '$result.0';
    }
    // Replace the least recently inserted entry.
    _cacheKeys[_cacheEvictIndex] = bits;
    _cacheValues[_cacheEvictIndex] = result;
    _cacheEvictIndex = (_cacheEvictIndex + 1) & CACHE_MASK;
    return result;
  }

  @patch
  String toStringAsFixed(int fractionDigits) {
    // See ECMAScript-262, 15.7.4.5 for details.

    // Step 2.
    // 0 <= fractionDigits <= 20
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      fractionDigits,
      20,
      "fractionDigits",
    );

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

  String _toStringAsFixed(int fractionDigits) => JSStringImpl.fromRefUnchecked(
    JS<WasmExternRef>(
      "(d, digits) => d.toFixed(digits)",
      value,
      fractionDigits.toDouble(),
    ),
  );

  @patch
  String toStringAsExponential([int? fractionDigits]) {
    // See ECMAScript-262, 15.7.4.6 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 7.
    if (fractionDigits != null) {
      // 0 <= fractionDigits <= 20
      RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
        fractionDigits,
        20,
        "fractionDigits",
      );
    }

    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

    String result = _toStringAsExponential(fractionDigits);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String _toStringAsExponential(int? fractionDigits) =>
      JSStringImpl.fromRefUnchecked(
        fractionDigits == null
            ? JS<WasmExternRef>("d => d.toExponential()", value)
            : JS<WasmExternRef>(
                "(d, f) => d.toExponential(f)",
                value,
                fractionDigits.toDouble(),
              ),
      );

  @patch
  String toStringAsPrecision(int precision) {
    // See ECMAScript-262, 15.7.4.7 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 8.
    RangeErrorUtils.checkValueInInterval(precision, 1, 21, "precision");

    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

    String result = _toStringAsPrecision(precision);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String _toStringAsPrecision(int fractionDigits) =>
      JSStringImpl.fromRefUnchecked(
        JS<WasmExternRef>(
          "(d, precision) => d.toPrecision(precision)",
          value,
          fractionDigits.toDouble(),
        ),
      );
}
