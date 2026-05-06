// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder' as embedder;
import "dart:_internal" show doubleToIntBits, intBitsToDouble, patch;
import 'dart:_string';
import 'dart:_wasm';

@patch
class BoxedDouble {
  @patch
  String toString() {
    return JSStringImpl.fromRefUnchecked(
      embedder.f64ToString(WasmF64.fromDouble(value)),
    );
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
    embedder.f64ToFixed(
      WasmF64.fromDouble(this),
      WasmI32.fromInt(fractionDigits),
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
            ? embedder.f64ToExponential(WasmF64.fromDouble(this))
            : embedder.f64ToExponentialWithFractionDigits(
                WasmF64.fromDouble(this),
                WasmI32.fromInt(fractionDigits),
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
        embedder.f64ToPrecision(
          WasmF64.fromDouble(this),
          WasmI32.fromInt(fractionDigits),
        ),
      );
}
