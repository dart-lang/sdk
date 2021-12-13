// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47704.
// Verifies that compiler doesn't crash with compressed pointers when
// generating code involving as 32-bit Smi constant which is not
// sign-extended to 64 bits.

// VMOptions=--deterministic --optimization_counter_threshold=80

// @dart = 2.9

import 'dart:typed_data';
import "package:expect/expect.dart";

const int minLevel = -1;

void foo() {
  // Make sure this method is compiled.
  for (int i = 0; i < 100; i++) {}

  bool ok = false;
  try {
    for (int loc0 in ((Uint16List(40)).sublist(minLevel, 42))) {
      print(loc0);
    }
  } catch (e) {
    ok = true;
  }
  Expect.isTrue(ok);
}

void main() {
  foo();
  foo();
}
