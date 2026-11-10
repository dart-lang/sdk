// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/191575.
//
// Verifies that FFI callback trampolines created during flow graph building
// for branches that are subsequently eliminated by compiler optimizations are
// properly dropped during AOT precompilation and do not retain references to
// tree-shaken classes (with illegal cid) or waste callback IDs.

import 'dart:ffi';

final class DeadStruct1 extends Struct {
  @Double()
  external double x;
}

final class DeadStruct2 extends Struct {
  @Int32()
  external int y;
}

Pointer<DeadStruct1> deadCallback1(Pointer<DeadStruct1> p) => p;
void deadCallback2(Pointer<DeadStruct2> p) {}
int liveCallback(int x) => x + 42;

void main() {
  if (<int>[1].length > 1) {
    final callable1 =
        NativeCallable<
          Pointer<DeadStruct1> Function(Pointer<DeadStruct1>)
        >.isolateLocal(deadCallback1);
    callable1.close();

    final callable2 =
        NativeCallable<Void Function(Pointer<DeadStruct2>)>.listener(
          deadCallback2,
        );
    callable2.close();

    final ptr =
        Pointer.fromFunction<
          Pointer<DeadStruct1> Function(Pointer<DeadStruct1>)
        >(deadCallback1);
    print(ptr);
  }

  final liveCallable = NativeCallable<Int32 Function(Int32)>.isolateLocal(
    liveCallback,
    exceptionalReturn: 0,
  );
  final fn = liveCallable.nativeFunction.asFunction<int Function(int)>();
  if (fn(10) != 52) {
    throw 'Unexpected result';
  }
  liveCallable.close();
}
