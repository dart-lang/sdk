// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Helper for vmspecific_enable_ffi_test.dart.
// This file imports dart:ffi and should fail to load when --enable-ffi=false.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

void main() {
  Pointer<Int8> p = calloc();
  print(p.address);
  calloc.free(p);
}
