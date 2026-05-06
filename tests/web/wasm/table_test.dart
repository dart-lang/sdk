// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

import 'package:expect/expect.dart';

WasmTable<WasmFuncRef?> funcrefTable = WasmTable(3);
WasmTable<WasmFunction<WasmI32 Function(WasmI32)>?> funcTable = WasmTable(1);

WasmVoid f1() => WasmVoid();

WasmVoid f2(WasmI32 x) {
  Expect.equals(4, x.toIntSigned());
  return WasmVoid();
}

WasmI32 f3(WasmI32 x) => x + 1.toWasmI32();

main() {
  // Initialize untyped function table
  Expect.equals(3, funcrefTable.size.toIntUnsigned());
  funcrefTable[0.toWasmI32()] = WasmFunction.fromFunction(f1);
  funcrefTable[1.toWasmI32()] = WasmFunction.fromFunction(f2);
  funcrefTable[2.toWasmI32()] = WasmFunction.fromFunction(f3);

  // Reading and calling functions in untyped function table
  WasmFunction<WasmVoid Function()>.fromFuncRef(
    funcrefTable[0.toWasmI32()]!,
  ).call();
  WasmFunction<WasmVoid Function(WasmI32)>.fromFuncRef(
    funcrefTable[1.toWasmI32()]!,
  ).call(4.toWasmI32());
  Expect.equals(
    6,
    WasmFunction<WasmI32 Function(WasmI32)>.fromFuncRef(
      funcrefTable[2.toWasmI32()]!,
    ).call(5.toWasmI32()).toIntSigned(),
  );

  // Calling functions in untyped function table with callIndirect
  funcrefTable.callIndirect<WasmVoid Function()>(0.toWasmI32())();
  funcrefTable.callIndirect<WasmVoid Function(WasmI32)>(1.toWasmI32())(
    4.toWasmI32(),
  );
  Expect.equals(
    16,
    funcrefTable
        .callIndirect<WasmI32 Function(WasmI32)>(2.toWasmI32())(15.toWasmI32())
        .toIntSigned(),
  );

  // Initialize typed function table
  Expect.equals(1, funcTable.size.toIntUnsigned());
  funcTable[0.toWasmI32()] = WasmFunction.fromFunction(f3);

  // Reading and calling function in typed function table
  Expect.equals(8, funcTable[0.toWasmI32()]!.call(7.toWasmI32()).toIntSigned());

  // Calling function in typed function table with callIndirect
  Expect.equals(
    18,
    funcTable
        .callIndirect<WasmI32 Function(WasmI32)>(0.toWasmI32())(17.toWasmI32())
        .toIntSigned(),
  );
}
