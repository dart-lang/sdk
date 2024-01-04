// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for NativeFunctionPointer.asFunction transformation.

import 'dart:ffi';

testVoidNoArg() {
  final pointer =
      Pointer<NativeFunction<Void Function()>>.fromAddress(0xdeadbeef);
  final function = pointer.asFunction<void Function()>();
  function();
}

testIntInt() {
  final pointer =
      Pointer<NativeFunction<Int32 Function(Int64)>>.fromAddress(0xdeadbeef);
  final function = pointer.asFunction<int Function(int)>();
  return function(42);
}

testLeaf5Args() {
  final pointer = Pointer<
      NativeFunction<
          Int32 Function(
              Int32, Int32, Int32, Int32, Int32)>>.fromAddress(0xdeadbeef);
  final function =
      pointer.asFunction<int Function(int, int, int, int, int)>(isLeaf: true);
  return function(1, 2, 3, 4, 5);
}

void main() {
  testVoidNoArg();
  testIntInt();
  testLeaf5Args();
}
