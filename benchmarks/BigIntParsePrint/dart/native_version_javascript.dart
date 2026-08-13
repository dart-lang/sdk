// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library;

import 'dart:js_interop';

import 'native_version.dart';

const NativeBigIntMethods nativeBigInt = _Methods();

@JS('eval')
external JSAny? _eval(String s);

@JS('bigint_parse')
external JSBigInt _parse(String s);

@JS('bigint_toString')
external String _toStringMethod(JSBigInt o);

@JS('bigint_bitLength')
external int _bitLength(JSBigInt o);

@JS('bigint_isEven')
external bool _isEven(JSBigInt o);

@JS('bigint_add')
external JSBigInt _add(JSBigInt left, JSBigInt right);

@JS('bigint_shiftLeft')
external JSBigInt _shiftLeft(JSBigInt o, JSBigInt i);

@JS('bigint_shiftRight')
external JSBigInt _shiftRight(JSBigInt o, JSBigInt i);

@JS('bigint_subtract')
external JSBigInt _subtract(JSBigInt left, JSBigInt right);

@JS('bigint_fromInt')
external JSBigInt _fromInt(int i);

class _Methods implements NativeBigIntMethods<JSBigInt> {
  static bool _initialized = false;
  static bool _enabled = false;

  const _Methods();

  @override
  bool get enabled {
    if (!_initialized) {
      _initialize();
    }
    return _enabled;
  }

  void _initialize() {
    _initialized = true;
    try {
      _setup();
      _enabled = true;
    } catch (e) {
      // We get here if the JavaScript implementation does not have BigInt (or
      // run in a stand-alone JavaScript implementation without the right
      // 'preamble').
      //
      // Print so we can see what failed.
      print(e);
    }
  }

  @override
  JSBigInt parse(String string) => _parse(string);

  @override
  String toStringMethod(JSBigInt value) => _toStringMethod(value);

  @override
  JSBigInt fromInt(int i) => _fromInt(i);

  @override
  JSBigInt get one => _one;

  @override
  JSBigInt get eight => _eight;

  @override
  int bitLength(JSBigInt value) => _bitLength(value);

  @override
  bool isEven(JSBigInt value) => _isEven(value);

  @override
  JSBigInt add(JSBigInt left, JSBigInt right) => _add(left, right);

  @override
  JSBigInt shiftLeft(JSBigInt value, JSBigInt count) =>
      _shiftLeft(value, count);

  @override
  JSBigInt shiftRight(JSBigInt value, JSBigInt count) =>
      _shiftRight(value, count);

  @override
  JSBigInt subtract(JSBigInt left, JSBigInt right) => _subtract(left, right);
}

void _setup() {
  _one = _eval('1n'); // Throws if JavaScript does not have BigInt.
  _eight = _eval('8n');

  _eval('self.bigint_parse = function parse(s) { return BigInt(s); }');
  _eval('self.bigint_toString = function toString(b) { return b.toString(); }');
  _eval('self.bigint_add = function add(a, b) { return a + b; }');
  _eval('self.bigint_shiftLeft = function shl(v, i) { return v << i; }');
  _eval('self.bigint_shiftRight = function shr(v, i) { return v >> i; }');
  _eval('self.bigint_subtract = function subtract(a, b) { return a - b; }');
  _eval('self.bigint_fromInt = function fromInt(i) { return BigInt(i); }');

  _eval(
    'self.bigint_bitLength = function bitLength(b) {'
    'return b == 0 ? 0 : (b < 0 ? ~b : b).toString(2).length;'
    '}',
  );
  _eval('self.bigint_isEven = function isEven(b) { return (b & 1n) == 0n; }');
}

// `dynamic` to allow null initialization pre- and post- NNBD.
dynamic _one;
dynamic _eight;
