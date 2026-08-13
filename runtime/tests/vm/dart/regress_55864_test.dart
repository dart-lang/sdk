// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/55864.

import 'dart:typed_data';

void main() {
  final list = Uint32List(100);
  // Calculating the byte offset from this index overflows a 32-bit register,
  // but the index will fail the bounds check so the code computing the byte
  // offset is dead code.
  final index = 0x3fffffff;
  // Don't use Expect.throwsRangeError here, so that the use of index won't
  // go through the context object in the closure and instead is correctly
  // recognized as a constant in the code generated for the print argument.
  try {
    print(list[index]);
  } on RangeError {
    return;
  }
  throw "Expected RangeError";
}
