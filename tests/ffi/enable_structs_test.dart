// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing that structs are locked out on 32-bit platforms.

library FfiTest;

import 'dart:ffi';

import "package:expect/expect.dart";

class C extends Struct<C> {
  @IntPtr()
  int x;
}

void main() {
  final C c = nullptr.cast<C>().load();
  Expect.throws<UnimplementedError>(() => c.x);
  Expect.throws<UnimplementedError>(() => c.x = 0);
}
