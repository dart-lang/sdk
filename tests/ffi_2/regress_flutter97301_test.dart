// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies that there are no deoptimizing IntConverter instructions
// used when converting Pointer to TypedData.
// Regression test for https://github.com/flutter/flutter/issues/97301.

// @dart = 2.9

import "dart:ffi";
import "package:ffi/ffi.dart";

@pragma("vm:never-inline")
Pointer<Uint32> foo() => calloc(4);

main() {
  final Pointer<Uint32> offsetsPtr = foo();

  for (var i = 0; i < 2; i++) {
    print(offsetsPtr.asTypedList(1));
  }

  calloc.free(offsetsPtr);
}
