// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing the --enable-ffi=false flag.
//
// VMOptions=--enable-ffi=false

library FfiTest;

import 'dart:ffi' as ffi; //# 01: compile-time error

import "package:expect/expect.dart";

void main() {
  ffi.Pointer<ffi.Int64> p = ffi.allocate(); //# 01: compile-time error
  p.store(42); //# 01: compile-time error
  Expect.equals(42, p.load<int>()); //# 01: compile-time error
  p.free(); //# 01: compile-time error
}
