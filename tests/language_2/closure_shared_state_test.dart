// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests for closures sharing mutable bindings.

var f;
var g;

setupPlain() {
  int j = 1000;
  // Two closures sharing variable 'j'; j initially is 1000.
  f = (int x) {
    var q = j;
    j = x;
    return q;
  };
  g = (int x) {
    var q = j;
    j = x;
    return q;
  };
}

setupLoop() {
  for (int i = 0; i < 2; i++) {
    int j = i * 1000; // The last stored closure has j initially 1000.
    // Two closures sharing variable 'j'.
    f = (int x) {
      var q = j;
      j = x;
      return q;
    };
    g = (int x) {
      var q = j;
      j = x;
      return q;
    };
  }
}

setupNestedLoop() {
  for (int outer = 0; outer < 2; outer++) {
    int j = outer * 1000;
    for (int i = 0; i < 2; i++) {
      // Two closures sharing variable 'j' in a loop at different nesting.
      f = (int x) {
        var q = j;
        j = x;
        return q;
      };
      g = (int x) {
        var q = j;
        j = x;
        return q;
      };
    }
  }
}

test(setup) {
  setup();
  Expect.equals(1000, f(100));
  Expect.equals(100, f(200));
  Expect.equals(200, f(300));
  Expect.equals(300, g(400));
  Expect.equals(400, g(500));
}

main() {
  test(setupPlain);
  test(setupLoop);
  test(setupNestedLoop);
}
