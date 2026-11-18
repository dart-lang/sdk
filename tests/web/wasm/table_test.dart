// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';
import 'dart:js_interop';

import 'package:expect/expect.dart';

void main() {
  // Initialize untyped function table
  Expect.equals(3, funcrefTable.size);
  funcrefTable[0] = WasmFunction.fromFunction(f1);
  funcrefTable[1] = WasmFunction.fromFunction(f2);
  funcrefTable[2] = WasmFunction.fromFunction(f3);

  // Reading and calling functions in untyped function table
  WasmFunction<WasmVoid Function()>.fromFuncRef(funcrefTable[0]!).call();
  WasmFunction<WasmVoid Function(WasmI32)>.fromFuncRef(funcrefTable[1]!)
      .call(4.toWasmI32());
  Expect.equals(
    6,
    WasmFunction<WasmI32 Function(WasmI32)>.fromFuncRef(funcrefTable[2]!)
        .call(5.toWasmI32())
        .toIntSigned(),
  );

  // Calling functions in untyped function table with callIndirect
  funcrefTable.callIndirect<WasmVoid Function()>(0)();
  funcrefTable.callIndirect<WasmVoid Function(WasmI32)>(1)(4.toWasmI32());
  Expect.equals(
    16,
    funcrefTable
        .callIndirect<WasmI32 Function(WasmI32)>(2)(15.toWasmI32())
        .toIntSigned(),
  );

  // Initialize typed function table
  Expect.equals(1, funcTable.size);
  funcTable[0] = WasmFunction.fromFunction(f3);

  // Reading and calling function in typed function table
  Expect.equals(8, funcTable[0]!.call(7.toWasmI32()).toIntSigned());

  // Calling function in typed function table with callIndirect
  Expect.equals(
    18,
    funcTable
        .callIndirect<WasmI32 Function(WasmI32)>(0)(17.toWasmI32())
        .toIntSigned(),
  );

  // Grow and fill
  Expect.equals(3, funcrefTable.grow(2, WasmFunction.fromFunction(f4)));
  Expect.equals(5, funcrefTable.size);
  Expect.equals(
    25,
    funcrefTable
        .callIndirect<WasmI32 Function(WasmI32)>(3)(15.toWasmI32())
        .toIntSigned(),
  );
  Expect.equals(
    25,
    funcrefTable
        .callIndirect<WasmI32 Function(WasmI32)>(4)(15.toWasmI32())
        .toIntSigned(),
  );
  // Growing beyond Limits(3, 10) returns -1
  Expect.equals(-1, funcrefTable.grow(10, null));
  Expect.equals(5, funcrefTable.size);

  funcrefTable.fill(3, WasmFunction.fromFunction(f3), 2);
  Expect.equals(
    16,
    funcrefTable
        .callIndirect<WasmI32 Function(WasmI32)>(3)(15.toWasmI32())
        .toIntSigned(),
  );
  Expect.equals(
    16,
    funcrefTable
        .callIndirect<WasmI32 Function(WasmI32)>(4)(15.toWasmI32())
        .toIntSigned(),
  );

  // Exported table in JS
  eval(r'''
    globalThis.jsTableLength = function() {
      const tbl = globalThis.appInstanceForTesting.instantiatedModule.exports.funcrefTable;
      return tbl.length;
    };
    globalThis.jsCallTableEntry = function(index, arg) {
      const tbl = globalThis.appInstanceForTesting.instantiatedModule.exports.funcrefTable;
      return tbl.get(index)(arg);
    };
  ''');
  Expect.equals(5, jsTableLength());
  Expect.equals(21, jsCallTableEntry(2, 20));
}

@pragma('wasm:table-type', TableType(limits: Limits(3, 10)))
@pragma('wasm:export', 'funcrefTable')
external WasmTable<WasmFuncRef?> get funcrefTable;

@pragma('wasm:table-type', TableType(limits: Limits(1)))
external WasmTable<WasmFunction<WasmI32 Function(WasmI32)>?> get funcTable;

WasmVoid f1() => WasmVoid();

WasmVoid f2(WasmI32 x) {
  Expect.equals(4, x.toIntSigned());
  return WasmVoid();
}

WasmI32 f3(WasmI32 x) => x + 1.toWasmI32();
WasmI32 f4(WasmI32 x) => x + 10.toWasmI32();

@JS()
external void eval(String code);

@JS()
external int jsTableLength();

@JS()
external int jsCallTableEntry(int index, int arg);
