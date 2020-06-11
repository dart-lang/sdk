// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library native_version_javascript;

import 'package:js/js.dart';
import 'native_version.dart';

const NativeBigIntMethods nativeBigInt = _Methods();

@JS('eval')
external Object _eval(String s);

@JS('bigint_parse')
external Object _parse(String s);

@JS('bigint_toString')
external String _toStringMethod(Object o);

@JS('bigint_bitLength')
external int _bitLength(Object o);

@JS('bigint_isEven')
external bool _isEven(Object o);

@JS('bigint_add')
external Object _add(Object left, Object right);

@JS('bigint_shiftLeft')
external Object _shiftLeft(Object o, Object i);

@JS('bigint_shiftRight')
external Object _shiftRight(Object o, Object i);

@JS('bigint_subtract')
external Object _subtract(Object left, Object right);

@JS('bigint_fromInt')
external Object _fromInt(int i);

class _Methods implements NativeBigIntMethods {
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
  Object parse(String string) => _parse(string);

  @override
  String toStringMethod(Object value) => _toStringMethod(value);

  @override
  Object fromInt(int i) => _fromInt(i);

  @override
  Object get one => _one;

  @override
  Object get eight => _eight;

  @override
  int bitLength(Object value) => _bitLength(value);

  @override
  bool isEven(Object value) => _isEven(value);

  @override
  Object add(Object left, Object right) => _add(left, right);

  @override
  Object shiftLeft(Object value, Object count) => _shiftLeft(value, count);

  @override
  Object shiftRight(Object value, Object count) => _shiftRight(value, count);

  @override
  Object subtract(Object left, Object right) => _subtract(left, right);
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

  _eval('self.bigint_bitLength = function bitLength(b) {'
      'return b == 0 ? 0 : (b < 0 ? ~b : b).toString(2).length;'
      '}');
  _eval('self.bigint_isEven = function isEven(b) { return (b & 1n) == 0n; }');
}

// `dynamic` to allow null initialization pre- and post- NNBD.
dynamic _one;
dynamic _eight;
