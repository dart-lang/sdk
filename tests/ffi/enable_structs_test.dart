// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing that structs are locked out on 32-bit platforms.

library FfiTest;

import 'dart:ffi' as ffi;

import "package:expect/expect.dart";

@ffi.struct
class C extends ffi.Pointer<ffi.Void> {
  @ffi.IntPtr()
  int x;
  external static int sizeOf();
}

void main() {
  final C c = ffi.fromAddress<C>(1);
  Expect.throws<UnimplementedError>(() => c.x);
  Expect.throws<UnimplementedError>(() => c.x = 0);
  Expect.throws<UnimplementedError>(() => C.sizeOf());
}
