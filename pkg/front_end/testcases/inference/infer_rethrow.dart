// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

// "rethrow" is a statement, so there aren't any types to infer.  This test just
// exercises the code path to make sure it doesn't crash.

test(f(), g()) {
  try {
    f();
  } catch (_) {
    g();
    rethrow;
  }
}

main() {}
