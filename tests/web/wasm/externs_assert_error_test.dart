// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import '' deferred as M;

external Memory get missingAnnotation;
//                  ^
// [web] This external getter returns a memory instance, but no annotation describing it was found

@pragma('wasm:memory-type', 123)
external Memory get invalidMemoryAnnotation;
//                  ^
// [web] This external getter returns a memory instance, but no annotation describing it was found

@pragma('wasm:memory-type', MemoryType(limits: Limits(-1)))
external Memory get negativeMemoryMin;
//                  ^
// [web] WebAssembly limits must have a non-negative minimum and a maximum not less than the minimum.

@pragma('wasm:memory-type', MemoryType(limits: Limits(10, 5)))
external Memory get maxLessThanMinMemory;
//                  ^
// [web] WebAssembly limits must have a non-negative minimum and a maximum not less than the minimum.

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 10)))
external Memory get validDefinition;

external WasmTable<WasmFuncRef?> get missingTableAnnotation;
//                                   ^
// [web] This external getter returns a table instance, but no annotation describing it was found

@pragma('wasm:table-type', 123)
external WasmTable<WasmFuncRef?> get invalidTableAnnotation;
//                                   ^
// [web] This external getter returns a table instance, but no annotation describing it was found

@pragma('wasm:table-type', TableType(limits: Limits(-1)))
external WasmTable<WasmFuncRef?> get negativeTableMin;
//                                   ^
// [web] WebAssembly limits must have a non-negative minimum and a maximum not less than the minimum.

@pragma('wasm:table-type', TableType(limits: Limits(10, 5)))
external WasmTable<WasmFuncRef?> get maxLessThanMinTable;
//                                   ^
// [web] WebAssembly limits must have a non-negative minimum and a maximum not less than the minimum.

@pragma('wasm:table-type', TableType(limits: Limits(1)))
external WasmTable<WasmI32> get invalidTableElementI32;
//                              ^
// [web] Type 'WasmI32' is not a valid Wasm table element type.

@pragma('wasm:table-type', TableType(limits: Limits(1)))
external WasmTable<WasmFuncRef> get invalidTableElementNonNullable;
//                                  ^
// [web] Type 'WasmFuncRef' is not a valid Wasm table element type.

@pragma('wasm:table-type', TableType(limits: Limits(1)))
external WasmTable<WasmFunction<void Function()>?> get invalidTableElementFunc;
//                                                     ^
// [web] Type 'WasmFunction<void Function()>?' is not a valid Wasm table element type.

@pragma('wasm:table-type', TableType(limits: Limits(1, 10)))
external WasmTable<WasmFuncRef?> get validTable;

@pragma('wasm:table-type', TableType(limits: Limits(1, 10)))
external WasmTable<WasmFunction<WasmVoid Function(WasmI32)>?>
get validTypedFuncTable;

@pragma('wasm:table-type', TableType(limits: Limits(1, 10)))
external WasmTable<WasmExternRef?> get validExternRefTable;

@pragma('wasm:import', 'env.global')
external Global<WasmI32> get validGlobal;

@pragma('wasm:import', 'env.mutGlobal')
external MutableGlobal<WasmI32> get validMutableGlobal;

WasmVoid wrongSig() => WasmVoid();

void main() {
  validDefinition.loadUint8(10);
  validDefinition.size;
  M.validDefinition.loadUint8(10);
  (M.validDefinition).loadUint8(10);
  M.validDefinition.size;
  (M.validDefinition).size;

  print(validDefinition);
  //    ^
  // [web] WebAssembly elements may only be referenced to directly call a method on them.

  print(M.validDefinition);
  //      ^
  // [web] WebAssembly elements may only be referenced to directly call a method on them.

  print(validDefinition.fill);
  //                    ^
  // [web] This intrinsic extension member may not be torn off.

  print(M.validDefinition.fill);
  //                      ^
  // [web] This intrinsic extension member may not be torn off.

  validTable.size;
  validTable[0];
  validTable[0] = null;
  validTable.grow(1, null);
  validTable.fill(0, null, 1);
  validTable.callIndirect<WasmVoid Function()>(0)();
  validTypedFuncTable.callIndirect<WasmVoid Function(WasmI32)>(0)(
    0.toWasmI32(),
  );
  M.validTable.size;
  (M.validTable).size;
  M.validTable[0];
  M.validTable[0] = null;
  M.validTable.grow(1, null);
  M.validTable.fill(0, null, 1);
  M.validTable.callIndirect<WasmVoid Function()>(0)();
  (M.validTable).callIndirect<WasmVoid Function()>(0)();

  print(validTable);
  //    ^
  // [web] WebAssembly elements may only be referenced to directly call a method on them.

  print(M.validTable);
  //      ^
  // [web] WebAssembly elements may only be referenced to directly call a method on them.

  print(validTable.fill);
  //               ^
  // [web] This intrinsic extension member may not be torn off.

  print(M.validTable.fill);
  //                 ^
  // [web] This intrinsic extension member may not be torn off.

  print(validTable.grow);
  //               ^
  // [web] This intrinsic extension member may not be torn off.

  print(validTable.callIndirect);
  //               ^
  // [web] This intrinsic extension member may not be torn off.

  validTable.callIndirect<WasmVoid Function()>(0);
  //         ^
  // [web] 'WasmTable.callIndirect' must be invoked directly with a valid Wasm function type argument.

  M.validTable.callIndirect<WasmVoid Function()>(0);
  //           ^
  // [web] 'WasmTable.callIndirect' must be invoked directly with a valid Wasm function type argument.

  validTable.callIndirect<void Function()>(0)();
  //         ^
  // [web] 'WasmTable.callIndirect' must be invoked directly with a valid Wasm function type argument.

  validExternRefTable.callIndirect<WasmVoid Function()>(0)();
  //                  ^
  // [web] 'WasmTable.callIndirect' must be invoked directly with a valid Wasm function type argument.

  validTypedFuncTable.callIndirect<WasmVoid Function()>(0)();
  //                  ^
  // [web] 'WasmTable.callIndirect' must be invoked directly with a valid Wasm function type argument.

  // Compiles with no cast on `validTable` because WasmTable<T> is covariant:
  final wrongFunc = WasmFunction.fromFunction(wrongSig);
  WasmTableAccessExtension<WasmBase?>(validTable)[0] = 42.toWasmI32();
  //                                             ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
  WasmTableAccessExtension<WasmFuncRef?>(validTypedFuncTable)[0] = wrongFunc;
  //                                                         ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
  WasmTableAccessExtension<WasmFuncRef?>(validTypedFuncTable)
      .callIndirect<WasmVoid Function()>(0)();
  //   ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.

  // Compiles with no cast on globals because Global<T> / MutableGlobal<T> are
  // covariant:
  GlobalGet<WasmBase>(validGlobal).value;
  //                               ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
  GlobalSet<WasmBase>(validMutableGlobal).value;
  //                                      ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
  GlobalSet<WasmBase>(validMutableGlobal).value = 42.0.toWasmF64();
  //                                      ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
}

void invalidDynamicMemory(Memory memory) {
  memory.loadUint8(10);
  //     ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
}

void invalidDynamicTable(WasmTable<WasmFuncRef?> table) {
  table.size;
  //    ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
  table[0];
  //   ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
  table.callIndirect<WasmVoid Function()>(0)();
  //    ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
}

int get notAConstant => 3;

void invalidNonConstantArguments() {
  validDefinition.loadUint8(0, offset: 12, align: 1);
  validDefinition.loadUint8(0, offset: notAConstant);
  //                                   ^
  // [web] The variable 'offset' is not a constant, only constant expressions are allowed.
  validDefinition.loadUint8(0, align: notAConstant);
  //                                  ^
  // [web] The variable 'align' is not a constant, only constant expressions are allowed.
}
