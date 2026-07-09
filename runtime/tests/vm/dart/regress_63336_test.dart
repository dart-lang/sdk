// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that a load from a catch block is not considered loop invariant
// and not hoisted out of the loop if there is a store in the try body.
// Regression test for https://github.com/dart-lang/sdk/issues/63336.

// VMOptions=--optimization-counter-threshold=100 --no-background-compilation

import 'package:expect/expect.dart';

int var63 = 28;
int var68 = 44;

void test() {
  int n = 43;
  while (--n > 0) {
    try {
      var63++;
      // Terminate block without reaching a loop backedge,
      // so try body won't be included into the loop body
      // through explicit predecessors of the backedge.
      throw 'bye';
      // Make sure load is not immediately in a CatchBlockEntry.
    } on StackOverflowError {
      rethrow;
    } catch (_) {
      // Load from 'var63' is considered loop invariant if
      // loop body doesn't include try block body.
      var68 = var63;
    }
  }
}

void main() {
  for (int i = 0; i < 200; ++i) {
    var63 = 28;
    var68 = 44;
    test();
    Expect.equals(70, var68);
  }
}
