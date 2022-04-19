// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:wasm';

import 'package:expect/expect.dart';

@pragma("wasm:import", "Object.create")
external WasmAnyRef createObject(WasmAnyRef? prototype);

@pragma("wasm:import", "Array.of")
external WasmAnyRef singularArray(WasmAnyRef element);

@pragma("wasm:import", "Reflect.apply")
external WasmAnyRef apply(
    WasmAnyRef target, WasmAnyRef thisArgument, WasmAnyRef argumentsList);

WasmAnyRef? anyRef;
WasmEqRef? eqRef;
WasmDataRef? dataRef;

int funCount = 0;

void fun(WasmEqRef arg) {
  funCount++;
  Expect.equals("Dart object", arg.toObject());
}

test() {
  // Some test objects
  Object dartObject1 = "1";
  Object dartObject2 = true;
  Object dartObject3 = Object();
  WasmAnyRef jsObject1 = createObject(null);

  // A JS object is not a Dart object.
  Expect.isFalse(jsObject1.isObject);

  // A Wasm ref can be null and can be checked for null.
  WasmAnyRef? jsObject2 = null;
  Expect.isTrue(jsObject2 == null);

  // Upcast Dart objects to Wasm refs and put them in fields.
  anyRef = WasmAnyRef.fromObject(dartObject1);
  eqRef = WasmEqRef.fromObject(dartObject2);
  dataRef = WasmDataRef.fromObject(dartObject3);

  // Dart objects are Dart objects.
  Expect.isTrue(anyRef!.isObject);
  Expect.isTrue(eqRef!.isObject);
  Expect.isTrue(dataRef!.isObject);

  // Casting back yields the original objects.
  Expect.identical(dartObject1, anyRef!.toObject());
  Expect.identical(dartObject2, eqRef!.toObject());
  Expect.identical(dartObject3, dataRef!.toObject());

  // Casting a JS object to a Dart object throws.
  Object o;
  Expect.throws(() {
    o = jsObject1.toObject();
  }, (_) => true);

  // Integer and float conversions
  Expect.equals(1, 1.toWasmI32().toIntSigned());
  Expect.equals(-2, (-2).toWasmI32().toIntSigned());
  Expect.equals(3, 3.toWasmI32().toIntUnsigned());
  Expect.notEquals(-4, (-4).toWasmI32().toIntUnsigned());
  Expect.equals(5, 5.toWasmI64().toInt());
  Expect.equals(6.0, 6.0.toWasmF32().toDouble());
  Expect.notEquals(7.1, 7.1.toWasmF32().toDouble());
  Expect.equals(8.0, 8.0.toWasmF64().toDouble());

  // Create a typed function reference for a Dart function and call it, both
  // directly and from JS.
  var dartObjectRef = WasmEqRef.fromObject("Dart object");
  var ff = WasmFunction.fromFunction(fun);
  ff.call(dartObjectRef);
  apply(ff, createObject(null), singularArray(dartObjectRef));
  Expect.isFalse(ff.isObject);

  // Cast a typed function reference to a `funcref` and back.
  WasmFuncRef funcref = WasmFuncRef.fromWasmFunction(ff);
  var ff2 = WasmFunction<void Function(WasmEqRef)>.fromRef(funcref);
  ff2.call(dartObjectRef);
  Expect.isFalse(ff2.isObject);

  // Casting a non-function JS object to a typed function reference throws.
  Expect.throws(() {
    WasmFunction<double Function(double)>.fromRef(jsObject1);
  }, (_) => true);

  // Create a typed function reference from an import and call it.
  var createObjectFun = WasmFunction.fromFunction(createObject);
  WasmAnyRef jsObject3 = createObjectFun.call(null);
  Expect.isFalse(jsObject3.isObject);

  Expect.equals(3, funCount);
}

main() {
  try {
    test();
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}
