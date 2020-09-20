// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that various type errors produced by implicit casts don't invoke
// user-defined code during error reporting.

class NoToString {
  toString() {
    Expect.fail("should not be called");
    return "";
  }
}

/// Defeat optimizations of type checks.
dynamic wrap(e) {
  if (new DateTime.now().year == 1980) return null;
  return e;
}

bool assertionsEnabled = false;

void main() {
  assert(assertionsEnabled = true);

  dynamic noToString = NoToString();

  Expect.throws<TypeError>(() {
    int x = wrap(noToString); // Implicit cast should throw
  }, (e) {
    e.toString(); // Should not throw.
    return true;
  });

  if (assertionsEnabled) {
    Expect.throws<TypeError>(() {
      assert(wrap(noToString)); // Implicit cast should throw
    }, (e) {
      e.toString(); // Should not throw.
      return true;
    });
  }
}
