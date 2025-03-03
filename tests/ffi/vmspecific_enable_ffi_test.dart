// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing the --enable-ffi=false flag.
//
// VMOptions=--enable-ffi=false

// Formatting can break multitests, so don't format them.
// dart format off

import 'dart:ffi'; // [cfe] Error: FFI is disabled, import not allowed.

import 'package:ffi/ffi.dart'; // [cfe] Error: FFI is disabled, import not allowed.

void main() {
  Pointer<Int8> p = calloc(); // [cfe] Error: Cannot use 'calloc' with FFI disabled.
  print(p.address); // [cfe] Error: Cannot access Pointer properties with FFI disabled.
  calloc.free(p); // [cfe] Error: Cannot use 'calloc.free' with FFI disabled.
}
