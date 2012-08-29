// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a NullPointerException is thrown even when an expression
// seems to be free of side-effects.

test(x, y) {
  (() { x - y; })();
}

main() {
  try {
    test(null, 2);
    Expect.fail('Expected NullPointerException');
  } on NullPointerException catch (ex) {
    return;
  }
  Expect.fail('Expected NullPointerException');
}
