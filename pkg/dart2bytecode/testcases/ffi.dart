// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

testVoidNoArg() {
  final pointer = Pointer<NativeFunction<Void Function()>>.fromAddress(
    0xdeadbeef,
  );
  final function = pointer.asFunction<void Function()>();
  function();
}

testIntInt() {
  final pointer = Pointer<NativeFunction<Int32 Function(Int64)>>.fromAddress(
    0xdeadbeef,
  );
  final function = pointer.asFunction<int Function(int)>();
  return function(42);
}

void main() {
  testVoidNoArg();
  testIntInt();
}
