// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://dartbug.com/54871.

import 'dart:_internal';
import 'dart:ffi';
import 'dart:io';

const address = 0xaabbccdd;
bool deoptimize = false;

final bool isAOT = Platform.executable.contains('dart_precompiled_runtime');

main() {
  // This test will cause deoptimizations (via helper in `dart:_internal`) and
  // does therefore not run in AOT.
  if (isAOT) return;

  for (int i = 0; i < 100000; ++i) {
    foo();
  }
  deoptimize = true;
  foo();
}

@pragma('vm:never-inline')
void foo() {
  final pointer = Pointer<Void>.fromAddress(address);
  useInteger(pointer.address);
  final pointerAddress = pointer.address;
  if (address != pointerAddress) {
    throw '$address vs $pointerAddress';
  }
}

@pragma('vm:never-inline')
void useInteger(int address) {
  if (deoptimize) {
    VMInternalsForTesting.deoptimizeFunctionsOnStack();
  }
}
