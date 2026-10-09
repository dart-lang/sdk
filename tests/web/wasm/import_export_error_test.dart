// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

// Valid declarations.
@pragma('wasm:import', 'env.validImport')
external WasmI32 validImport(
  WasmI32 a,
  WasmExternRef? b,
  WasmArray<WasmI8> c,
  ImmutableWasmArray<WasmAnyRef?> d,
);

@pragma('wasm:export', 'validExport')
WasmVoid validExport(WasmF64 a, WasmFuncRef? b) => WasmVoid();

@pragma('wasm:weak-export', 'validWeakExport')
WasmExternRef? validWeakExport() => WasmExternRef.nullRef;

@pragma('wasm:import', 'env.mem')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get validImportedMemory;

// Invalid `wasm:import` pragmas.
@pragma('wasm:import')
external WasmVoid importMissingArg();
//                ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

@pragma('wasm:import', 'no_dot')
external WasmVoid importWithoutDot();
//                ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

@pragma('wasm:import', 123)
external WasmVoid importNonStringArg();
//                ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

@pragma('wasm:import', 'env.nonExternal')
WasmVoid importOnNonExternal() => WasmVoid();
//       ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

@pragma('wasm:import', 'env.getter')
external WasmI32 get importOnNonMemoryGetter;
//                   ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

@pragma('wasm:import', 'env.field')
WasmI32? importOnField;
//       ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

// Invalid `wasm:export` and `wasm:weak-export` pragmas.
@pragma('wasm:export', 'extExport')
external WasmVoid exportOnExternal();
//                ^
// [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.

@pragma('wasm:export', 'exportedMem')
@pragma('wasm:memory-type', MemoryType(limits: Limits(1)))
external Memory get exportOnMemoryGetter;
//                  ^
// [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.

@pragma('wasm:export', 123)
WasmVoid exportNonStringName() => WasmVoid();
//       ^
// [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.

@pragma('wasm:export', 'nonMemGetter')
WasmI32 get exportOnNonMemoryGetter => const WasmI32(0);
//          ^
// [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.

@pragma('wasm:export', 'both1')
@pragma('wasm:weak-export', 'both2')
WasmVoid exportAndWeakExport() => WasmVoid();
//       ^
// [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.

@pragma('wasm:import', 'env.both')
@pragma('wasm:export', 'both')
external WasmVoid importAndExport();
//                ^
// [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.
// [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.

class C {
  @pragma('wasm:import', 'env.instanceImport')
  external WasmVoid instanceImport();
  //                ^
  // [web] The 'wasm:import' pragma is only allowed on external static functions or memory getters, and must specify a '<module>.<name>' argument.

  @pragma('wasm:export', 'instanceExport')
  WasmVoid instanceExport() => WasmVoid();
  //       ^
  // [web] The 'wasm:export' and 'wasm:weak-export' pragmas are only allowed on non-external static functions.
}

// Invalid signatures (type, optional, or named parameters).
@pragma('wasm:import', 'env.generic')
external WasmVoid importGeneric<T>();
//                ^
// [web] Functions annotated with 'wasm:import', 'wasm:export', or 'wasm:weak-export' cannot have type parameters, optional parameters, or named parameters.

@pragma('wasm:export')
WasmVoid exportOptional([WasmI32 a = const WasmI32(0)]) => WasmVoid();
//       ^
// [web] Functions annotated with 'wasm:import', 'wasm:export', or 'wasm:weak-export' cannot have type parameters, optional parameters, or named parameters.

@pragma('wasm:weak-export')
WasmVoid weakExportNamed({required WasmI32 a}) => WasmVoid();
//       ^
// [web] Functions annotated with 'wasm:import', 'wasm:export', or 'wasm:weak-export' cannot have type parameters, optional parameters, or named parameters.

// Invalid parameter types.
@pragma('wasm:import', 'env.badParams')
external WasmVoid importInvalidParams(
  int a,
  //  ^
  // [web] Type 'int' is not a valid Wasm parameter type for imported or exported functions.
  WasmI32? b,
  //       ^
  // [web] Type 'WasmI32?' is not a valid Wasm parameter type for imported or exported functions.
  WasmI8 c,
  //     ^
  // [web] Type 'WasmI8' is not a valid Wasm parameter type for imported or exported functions.
  WasmArray<int> d,
  //             ^
  // [web] Type 'WasmArray<int>' is not a valid Wasm parameter type for imported or exported functions.
  WasmArray<WasmI8?> e,
  //                 ^
  // [web] Type 'WasmArray<WasmI8?>' is not a valid Wasm parameter type for imported or exported functions.
);

// Invalid return types.
@pragma('wasm:import', 'env.voidReturn')
external void importVoidReturn();
//            ^
// [web] Type 'void' is not a valid Wasm return type for imported or exported functions (use 'WasmVoid' instead of 'void').

@pragma('wasm:export')
WasmVoid? exportNullableWasmVoidReturn() => null;
//        ^
// [web] Type 'WasmVoid?' is not a valid Wasm return type for imported or exported functions (use 'WasmVoid' instead of 'void').

@pragma('wasm:export')
int exportIntReturn() => 0;
//  ^
// [web] Type 'int' is not a valid Wasm return type for imported or exported functions (use 'WasmVoid' instead of 'void').

@pragma('wasm:import', 'env.nullableI32Return')
external WasmI32? importNullableI32Return();
//                ^
// [web] Type 'WasmI32?' is not a valid Wasm return type for imported or exported functions (use 'WasmVoid' instead of 'void').

@pragma('wasm:import', 'env.i8Return')
external WasmI8 importI8Return();
//              ^
// [web] Type 'WasmI8' is not a valid Wasm return type for imported or exported functions (use 'WasmVoid' instead of 'void').

void main() {
  // Valid uses in WasmFunction.fromFunction.
  WasmFunction.fromFunction(validImport);
  WasmFunction.fromFunction(validExport);
  WasmFunction.fromFunction(validWeakExport);

  // Invalid tear-offs of imported/exported functions.
  final f1 = validImport;
  //         ^
  // [web] Functions annotated with 'wasm:import', 'wasm:export', or 'wasm:weak-export' may not be torn off.
  final f2 = validExport;
  //         ^
  // [web] Functions annotated with 'wasm:import', 'wasm:export', or 'wasm:weak-export' may not be torn off.
  const f3 = [validWeakExport];
  print(f1);
  print(f2);
  print(f3);
  //    ^
  // [web] Functions annotated with 'wasm:import', 'wasm:export', or 'wasm:weak-export' may not be torn off.
}
