// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

import 'package:expect/expect.dart';

@pragma("wasm:import", "Object.create")
external WasmExternRef? createObject(WasmExternRef? prototype);

@pragma("wasm:import", "Array.of")
external WasmExternRef? singularArray(WasmExternRef? element);

@pragma("wasm:import", "Reflect.apply")
external WasmExternRef? apply(WasmFuncRef? target, WasmExternRef? thisArgument,
    WasmExternRef? argumentsList);

WasmAnyRef? anyRef;
WasmEqRef? eqRef;
WasmStructRef? structRef;

int funCount = 0;

WasmVoid? fun(WasmEqRef arg) {
  funCount++;
  Expect.equals("Dart object", arg.toObject());
}

class WasmFields {
  final WasmI32 i32;
  final WasmI64 i64;
  final WasmF32 f32;
  final WasmF64 f64;

  const WasmFields(this.i32, this.i64, this.f32, this.f64);

  @override
  String toString() => "${i32.toIntSigned()} ${i64.toInt()} "
      "${f32.toDouble()} ${f64.toDouble()}";
}

class A {
  const A();
}

class B extends A {
  const B();
}

test() {
  // Some test objects
  Object dartObject1 = "1";
  Object dartObject2 = true;
  Object dartObject3 = Object();
  WasmAnyRef jsObject1 = createObject(WasmExternRef.nullRef)!.internalize();

  // A JS object is not a Dart object.
  Expect.isFalse(jsObject1.isObject);

  // A Wasm ref can be null and can be checked for null.
  WasmAnyRef? jsObject2 = null;
  Expect.isTrue(jsObject2 == null);

  // Upcast Dart objects to Wasm refs and put them in fields.
  anyRef = WasmAnyRef.fromObject(dartObject1);
  eqRef = WasmEqRef.fromObject(dartObject2);
  structRef = WasmStructRef.fromObject(dartObject3);

  // Dart objects are Dart objects.
  Expect.isTrue(anyRef!.isObject);
  Expect.isTrue(eqRef!.isObject);
  Expect.isTrue(structRef!.isObject);

  // Casting back yields the original objects.
  Expect.identical(dartObject1, anyRef!.toObject());
  Expect.identical(dartObject2, eqRef!.toObject());
  Expect.identical(dartObject3, structRef!.toObject());

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

  const wasmConst = const WasmFields(
      const WasmI32(2), const WasmI64(3), const WasmF32(4), const WasmF64(5));
  Expect.isFalse(wasmConst.i32 == const WasmI32(1));
  Expect.isFalse(wasmConst.i64 == const WasmI64(1));
  Expect.isFalse(wasmConst.f32 == const WasmF32(1));
  Expect.isFalse(wasmConst.f64 == const WasmF64(1));
  Expect.isTrue(wasmConst.i32 == const WasmI32(2));
  Expect.isTrue(wasmConst.i64 == const WasmI64(3));
  Expect.isTrue(wasmConst.f32 == const WasmF32(4));
  Expect.isTrue(wasmConst.f64 == const WasmF64(5));
  Expect.equals("2 3 4.0 5.0", wasmConst.toString());

  // Create a typed function reference for a Dart function and call it, both
  // directly and from JS.
  var dartObjectRef = WasmEqRef.fromObject("Dart object");
  var ff = WasmFunction.fromFunction(fun);
  ff.call(dartObjectRef);
  apply(ff, createObject(null), singularArray(dartObjectRef.externalize()));

  // Cast a typed function reference to a `funcref` and back.
  WasmFuncRef funcref = WasmFuncRef.fromWasmFunction(ff);
  var ff2 = WasmFunction<WasmVoid? Function(WasmEqRef)>.fromFuncRef(funcref);
  ff2.call(dartObjectRef);

  // Create a typed function reference from an import and call it.
  var createObjectFun = WasmFunction.fromFunction(createObject);
  WasmAnyRef jsObject3 =
      createObjectFun.call(WasmExternRef.nullRef).internalize()!;
  Expect.isFalse(jsObject3.isObject);

  Expect.equals(3, funCount);

  // Instantiate some Wasm arrays
  final arrayAN = WasmObjectArray<A?>(3, null);
  final arrayA = WasmObjectArray<A>(3, A());
  Expect.equals(3, arrayAN.length);
  Expect.equals(3, arrayA.length);
  Expect.equals(null, arrayAN.read(0));
  Expect.identical(arrayA.read(0), arrayA.read(2));

  // Instantiate some Wasm arrays as literals
  final arrayAlit1 = WasmObjectArray<A>.literal([A(), A(), A()]);
  final arrayAlit2 = WasmObjectArray<A>.literal([A(), B(), A()]);
  final arrayAlit3 = const WasmObjectArray<A>.literal([A(), B(), A()]);
  final arrayAlit4 = const WasmObjectArray<A>.literal([A(), B(), A()]);
  Expect.notIdentical(arrayAlit1.read(0), arrayAlit1.read(2));
  Expect.notIdentical(arrayAlit2.read(0), arrayAlit2.read(1));
  Expect.notIdentical(arrayAlit2.read(0), arrayAlit2.read(2));
  Expect.notIdentical(arrayAlit3.read(0), arrayAlit3.read(1));
  Expect.identical(arrayAlit3.read(0), arrayAlit3.read(2));

  Expect.isFalse(arrayA == arrayAlit1);
  Expect.isFalse(arrayAlit2 == arrayAlit3);
  Expect.isTrue(arrayAlit3 == arrayAlit4);
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
