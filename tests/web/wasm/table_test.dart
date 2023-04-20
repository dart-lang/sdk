// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';

import 'package:expect/expect.dart';

WasmTable<WasmFuncRef?> funcrefTable = WasmTable(3);
WasmTable<WasmFunction<int Function(int)>?> funcTable = WasmTable(1);

void f1() {}

void f2(int x) {
  Expect.equals(4, x);
}

int f3(int x) => x + 1;

main() {
  // Initialize untyped function table
  Expect.equals(3, funcrefTable.size.toIntUnsigned());
  funcrefTable[0.toWasmI32()] = WasmFunction.fromFunction(f1);
  funcrefTable[1.toWasmI32()] = WasmFunction.fromFunction(f2);
  funcrefTable[2.toWasmI32()] = WasmFunction.fromFunction(f3);

  // Reading and calling functions in untyped function table
  WasmFunction<void Function()>.fromFuncRef(funcrefTable[0.toWasmI32()]!)
      .call();
  WasmFunction<void Function(int)>.fromFuncRef(funcrefTable[1.toWasmI32()]!)
      .call(4);
  Expect.equals(
      6,
      WasmFunction<int Function(int)>.fromFuncRef(funcrefTable[2.toWasmI32()]!)
          .call(5));

  // Calling functions in untyped function table with callIndirect
  funcrefTable.callIndirect<void Function()>(0.toWasmI32())();
  funcrefTable.callIndirect<void Function(int)>(1.toWasmI32())(4);
  Expect.equals(
      16, funcrefTable.callIndirect<int Function(int)>(2.toWasmI32())(15));

  // Initialize typed function table
  Expect.equals(1, funcTable.size.toIntUnsigned());
  funcTable[0.toWasmI32()] = WasmFunction.fromFunction(f3);

  // Reading and calling function in typed function table
  Expect.equals(8, funcTable[0.toWasmI32()]!.call(7));

  // Calling function in typed function table with callIndirect
  Expect.equals(
      18, funcTable.callIndirect<int Function(int)>(0.toWasmI32())(17));
}
