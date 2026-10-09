// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_error_utils";
import "dart:_internal" show patch;
import "dart:js_interop";
import "dart:_js_types" show JSUint8ArrayImpl;
import "dart:_wasm";

@patch
double atan2(num a, num b) =>
    _atan2(a.toDouble().toWasmF64(), b.toDouble().toWasmF64()).toDouble();
@patch
double sin(num radians) => _sin(radians.toDouble().toWasmF64()).toDouble();
@patch
double cos(num radians) => _cos(radians.toDouble().toWasmF64()).toDouble();
@patch
double tan(num radians) => _tan(radians.toDouble().toWasmF64()).toDouble();
@patch
double acos(num x) => _acos(x.toDouble().toWasmF64()).toDouble();
@patch
double asin(num x) => _asin(x.toDouble().toWasmF64()).toDouble();
@patch
double atan(num x) => _atan(x.toDouble().toWasmF64()).toDouble();
@patch
double sqrt(num x) => x.toDouble().sqrt();
@patch
double exp(num x) => _exp(x.toDouble().toWasmF64()).toDouble();
@patch
double log(num x) => _log(x.toDouble().toWasmF64()).toDouble();

double _doublePow(double base, double exponent) =>
    _wasmDoublePow(base.toWasmF64(), exponent.toWasmF64()).toDouble();

@pragma("wasm:import", "Math.pow")
external WasmF64 _wasmDoublePow(WasmF64 base, WasmF64 exponent);
@pragma("wasm:import", "Math.atan2")
external WasmF64 _atan2(WasmF64 a, WasmF64 b);
@pragma("wasm:import", "Math.sin")
external WasmF64 _sin(WasmF64 x);
@pragma("wasm:import", "Math.cos")
external WasmF64 _cos(WasmF64 x);
@pragma("wasm:import", "Math.tan")
external WasmF64 _tan(WasmF64 x);
@pragma("wasm:import", "Math.acos")
external WasmF64 _acos(WasmF64 x);
@pragma("wasm:import", "Math.asin")
external WasmF64 _asin(WasmF64 x);
@pragma("wasm:import", "Math.atan")
external WasmF64 _atan(WasmF64 x);
@pragma("wasm:import", "Math.exp")
external WasmF64 _exp(WasmF64 x);
@pragma("wasm:import", "Math.log")
external WasmF64 _log(WasmF64 x);

@JS('crypto')
external _JSCrypto get _jsCryptoGetter;

final _JSCrypto _jsCrypto = _jsCryptoGetter;

extension type _JSCrypto._(JSObject _jsCrypto) implements JSObject {}

extension _JSCryptoGetRandomValues on _JSCrypto {
  @JS('getRandomValues')
  external void getRandomValues(JSUint8Array array);
}

@JS('Math')
external _JSMath get _jsMathGetter;

final _JSMath _jsMath = _jsMathGetter;

extension type _JSMath._(JSObject _jsMath) implements JSObject {}

extension _JSMathRandom on _JSMath {
  @JS('random')
  external double random();
}

@patch
class _Random {
  @patch
  static int _initialSeed() {
    final low = (_jsMath.random() * 4294967295.0).toInt();
    final high = (_jsMath.random() * 4294967295.0).toInt();
    return ((high << 32) | low);
  }
}

class _SecureRandom implements Random {
  final JSUint8ArrayImpl _buffer = JSUint8ArrayImpl(8);

  _SecureRandom() {
    // Throw early in constructor if entropy source is not hooked up.
    _getBytes(1);
  }

  // Return count bytes of entropy as an integer; count <= 8.
  int _getBytes(int count) {
    final JSUint8ArrayImpl bufferView = JSUint8ArrayImpl.view(
      _buffer.buffer,
      0,
      count,
    );

    final JSUint8Array bufferViewJS = bufferView.toJS;
    _jsCrypto.getRandomValues(bufferViewJS);

    int value = 0;
    for (int i = 0; i < count; i += 1) {
      value = (value << 8) | bufferView[i];
    }

    return value;
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
