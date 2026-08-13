// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to emit an invalid JS
// variable declaration initializer in a for initializer.

import "package:expect/expect.dart";

var global;

inlineMe() {
  global = 42;
  return 54;
}

main() {
  for (var t = inlineMe(); t < 42; t++) {}
  Expect.equals(42, global);
}
