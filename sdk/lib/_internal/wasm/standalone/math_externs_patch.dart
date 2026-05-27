// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_error_utils";
import 'dart:_embedder' as embedder;
import "dart:_internal" show patch;
import "dart:_wasm";

@patch
double atan2(num a, num b) => embedder
    .mathAtan2(
      WasmF64.fromDouble(a.toDouble()),
      WasmF64.fromDouble(b.toDouble()),
    )
    .toDouble();
@patch
double sin(num radians) =>
    embedder.mathSin(WasmF64.fromDouble(radians.toDouble())).toDouble();
@patch
double cos(num radians) =>
    embedder.mathCos(WasmF64.fromDouble(radians.toDouble())).toDouble();
@patch
double tan(num radians) =>
    embedder.mathTan(WasmF64.fromDouble(radians.toDouble())).toDouble();
@patch
double acos(num x) =>
    embedder.mathAcos(WasmF64.fromDouble(x.toDouble())).toDouble();
@patch
double asin(num x) =>
    embedder.mathAsin(WasmF64.fromDouble(x.toDouble())).toDouble();
@patch
double atan(num x) =>
    embedder.mathAtan(WasmF64.fromDouble(x.toDouble())).toDouble();
@patch
double sqrt(num x) => x.toDouble().sqrt();
@patch
double exp(num x) =>
    embedder.mathExp(WasmF64.fromDouble(x.toDouble())).toDouble();
@patch
double log(num x) =>
    embedder.mathLog(WasmF64.fromDouble(x.toDouble())).toDouble();

double _doublePow(double base, double exponent) => embedder
    .mathPow(
      WasmF64.fromDouble(base.toDouble()),
      WasmF64.fromDouble(exponent.toDouble()),
    )
    .toDouble();

@patch
class _Random {
  @patch
  static int _initialSeed() => embedder.randomInt().toInt();
}

class _SecureRandom implements Random {
  _SecureRandom() {
    // Throw early in constructor if entropy source is not hooked up.
    _getBytes(1);
  }

  // Return count bytes of entropy as an integer; count <= 8.
  int _getBytes(int count) {
    final random = embedder.randomIntSecure().toInt();
    return random.toUnsigned(64);
  }

  int nextInt(int max) {
    RangeErrorUtils.checkValueInInterval(
      max,
      1,
      _POW2_32,
      "max",
      "Must be positive and <= 2^32",
    );
    final byteCount =
        ((max - 1).bitLength + 7) >> 3; // Divide number of bits by 8, round up.
    if (byteCount == 0) {
      return 0; // Not random if max == 1.
    }
    var rnd;
    var result;
    do {
      rnd = _getBytes(byteCount);
      result = rnd % max;
    } while ((rnd - result + max) > (1 << (byteCount << 3)));
    return result;
  }

  double nextDouble() {
    return (_getBytes(7) >> 3) / _POW2_53_D;
  }

  bool nextBool() {
    return _getBytes(1).isEven;
  }

  // Constants used by the algorithm.
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);
}
