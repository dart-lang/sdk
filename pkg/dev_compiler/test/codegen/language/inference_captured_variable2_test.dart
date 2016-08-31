// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that dart2js's receiver specialization optimization works
// with captured variables.

import "package:expect/expect.dart";

var list = [new Object(), 31];

main() {
  Expect.throws(() => foo()() + 42, (e) => e is NoSuchMethodError);
}

foo() {
  var a = list[0];
  var closure = (() => a - 42);
  return () => a + 54;
}
