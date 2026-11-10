// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

// Valid targets.
WasmVoid validVoid() => WasmVoid();
WasmI32 validI32(WasmI32 a, WasmExternRef? b) => a;
WasmEqRef validEqRef(WasmAnyRef a) => WasmEqRef.fromObject(Object());

@pragma('wasm:import', 'env.imported')
external WasmVoid validImported();

// Invalid targets (signature or non-Wasm parameter/return types).
WasmVoid genericFunc<T>(WasmI32 a) => WasmVoid();
WasmVoid optionalParam([WasmI32 a = const WasmI32(0)]) => WasmVoid();
WasmVoid namedParam({required WasmI32 a}) => WasmVoid();
WasmVoid nonWasmParam(int a) => WasmVoid();
WasmVoid nullableWasmNumParam(WasmI32? a) => WasmVoid();
WasmVoid packedWasmParam(WasmI8 a) => WasmVoid();
void voidReturn() {}
WasmVoid? nullableWasmVoidReturn() => null;
int nonWasmReturn() => 0;
WasmI32? nullableWasmNumReturn() => null;
WasmI8 packedWasmReturn() => WasmArray<WasmI8>(1)[0];

class C {
  static WasmVoid validStaticMethod() => WasmVoid();
  WasmVoid instanceMethod() => WasmVoid();
}

void main() {
  // Valid uses.
  WasmFunction.fromFunction(validVoid);
  WasmFunction<WasmVoid Function()>.fromFunction(validVoid);
  WasmFunction.fromFunction(validI32);
  WasmFunction.fromFunction(validEqRef);
  WasmFunction.fromFunction(validImported);
  WasmFunction.fromFunction(C.validStaticMethod);

  // Non-static function tear-offs (closure, local variable, instance tear-off).
  WasmFunction.fromFunction(() => WasmVoid());
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  final local = validVoid;
  WasmFunction.fromFunction(local);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  final c = C();
  WasmFunction.fromFunction(c.instanceMethod);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  // Static functions with type, optional, or named parameters.
  WasmFunction<WasmVoid Function(WasmI32)>.fromFunction(genericFunc);
  // [error column 3]
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(optionalParam);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction<WasmVoid Function()>.fromFunction(optionalParam);
  // [error column 3]
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(namedParam);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  // Static functions with invalid Wasm parameter types.
  WasmFunction.fromFunction(nonWasmParam);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(nullableWasmNumParam);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(packedWasmParam);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  // Static functions with invalid Wasm return types.
  WasmFunction.fromFunction(voidReturn);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(nullableWasmVoidReturn);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(nonWasmReturn);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(nullableWasmNumReturn);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction.fromFunction(packedWasmReturn);
  //           ^
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  // Mismatched type argument `F`.
  WasmFunction<Function>.fromFunction(validEqRef);
  // [error column 3]
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.

  WasmFunction<WasmAnyRef Function(WasmEqRef)>.fromFunction(validEqRef);
  // [error column 3]
  // [web] The argument to 'WasmFunction.fromFunction' must be a tear-off of a static function with a valid Wasm signature.
}
