// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

import 'package:expect/expect.dart';

void main() {
  final intVal = int.parse('5');
  final strVal = intVal.toString();
  final Object? nullVal = hide(null);

  Expect.isTrue(isInt(hide(intVal)));
  Expect.isFalse(isInt(hide(strVal)));
  Expect.isFalse(isInt(nullVal));

  Expect.isTrue(phiObjectIsString(true, strVal, intVal));
  Expect.isFalse(phiObjectIsString(false, strVal, intVal));

  Expect.isTrue(unboxedIntIsT<int>(intVal));
  Expect.isFalse(unboxedIntIsT<double>(intVal));

  Expect.isTrue(isT<int>(hide(intVal)));
  Expect.isFalse(isT<int>(nullVal));
  Expect.isTrue(isT<int?>(nullVal));

  final mapSI = <String, int>{strVal: intVal};
  Expect.isTrue(isMapBA<int, String>(hide(mapSI)));
  Expect.isFalse(isMapBA<String, int>(hide(mapSI)));

  Expect.equals(42, unusedTypeTest(hide(intVal)));
}

@pragma('wasm:cfg')
@pragma('wasm:never-inline')
bool isInt(Object? x) => x is int;

@pragma('wasm:cfg')
@pragma('wasm:never-inline')
bool phiObjectIsString(bool c, Object a, Object b) => (c ? a : b) is String;

@pragma('wasm:cfg')
@pragma('wasm:never-inline')
bool unboxedIntIsT<T>(int x) => x is T;

@pragma('wasm:cfg')
@pragma('wasm:never-inline')
bool isT<T>(Object? x) => x is T;

@pragma('wasm:cfg')
@pragma('wasm:never-inline')
bool isMapBA<A, B>(Object? x) => x is Map<B, A>;

@pragma('wasm:cfg')
@pragma('wasm:never-inline')
int unusedTypeTest(Object? x) {
  x is int;
  return 42;
}

@pragma('wasm:never-inline')
Object? hide(Object? x) => x;
