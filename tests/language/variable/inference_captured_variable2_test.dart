// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that dart2js's receiver specialization optimization works
// with captured variables.

import "package:expect/expect.dart";

var list = <dynamic>[new Object(), 31];

main() {
  Expect.throwsNoSuchMethodError(() => foo()() + 42);
}

foo() {
  var a = list[0];
  var closure = (() => a - 42);
  return () => a + 54;
}
