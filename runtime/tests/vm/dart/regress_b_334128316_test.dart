// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/334128316.
//
// Verifies that compiler doesn't crash when generating code
// for typed data view LoadIndexed which takes an internal typed data
// (in unreachable code path).

// VMOptions=--deterministic

import 'dart:typed_data';

@pragma('vm:never-inline')
int foo(Uint8List bytes, int n) {
  int sum = 0;
  for (int i = 0; i < n - 2; ++i) {
    // Polymorphic call, 2 targets.
    // One of the targets is incompatible with CheckClass,
    // creating an impossible LoadIndexed in the unreachable code.
    int b0 = bytes[i];
    if (b0 == 1) {
      // Monomorphic call to [].
      // CheckClass from this inline is moved out of the loop.
      int b1 = bytes[i + 1];
      sum += b1;
    }
  }
  return sum;
}

void main() {
  Uint8List input1 = Uint8List.view(Uint8List(10).buffer, 2);
  Uint8List input2 = Uint8List(10);
  for (int i = 0; i < input2.length; ++i) {
    input2[i] = 1;
  }
  for (int i = 0; i < 1000; ++i) {
    // Ensure certain order during polymorphic inlining by
    // using 2x more views than internal typed data.
    foo(input1, input1.length);
    foo(input1, input1.length);
    foo(input2, input2.length);
  }
}
