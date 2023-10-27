// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/306327173.

import 'dart:ffi';

import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int deref(Pointer<Pointer<Void>> a) {
  return a.value.address;
}

void matchIL$deref(FlowGraph graph) {
  final retvalName = is32BitConfiguration ? 'address' : 'unboxed';
  graph.match([
    match.block('Graph', [
      'c0' << match.UnboxedConstant(value: 0),
    ]),
    match.block('Function', [
      'ptr' << match.Parameter(index: 0),
      'array' << match.LoadField('ptr', slot: 'PointerBase.data'),
      'unboxed' << match.LoadIndexed('array', 'c0'),
      // 'unboxed' is a kUnboxedFfiIntPtr, which is uint32 on 32-bit archs
      // and int64 on 64-bit arches.
      if (is32BitConfiguration) ...[
        // 'unboxed' needs to be converted to int64 before returning.
        //
        // Note: The first two conversions here should be fixed once all
        // kUnboxedIntPtr uses are appropriately converted to kUnboxedFfiIntPtr.
        'extra1' << match.IntConverter('unboxed', from: 'uint32', to: 'int32'),
        'extra2' << match.IntConverter('extra1', from: 'int32', to: 'uint32'),
        'address' << match.IntConverter('extra2', from: 'uint32', to: 'int64'),
      ],
      match.Return(retvalName),
    ]),
  ]);
}

void main() {
  const ptrValue = 0x80000000;
  if (!isSimulator) {
    using((arena) {
      final p = arena.allocate<Pointer<Void>>(sizeOf<Pointer<Void>>());
      p.value = Pointer.fromAddress(ptrValue);
      Expect.equals(ptrValue, deref(p));
    });
  }
}
