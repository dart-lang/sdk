// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing the --enable-ffi=false flag.
//
// VMOptions=--enable-ffi=false



import 'dart:ffi'; // [cfe] Dart library 'dart:ffi' is not available on this platform.

import 'package:ffi/ffi.dart'; // [cfe] TBD

void main() {
  Pointer<Int8> p = // [cfe] Undefined name 'Pointer'.
  // [cfe] Undefined name 'Int8'.
      calloc(); // [cfe] Undefined name 'calloc'.
  print(p.address);
  calloc.free(p); // [cfe] Undefined name 'calloc'.
}
