// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=100 --no-use-osr --no-background_compilation

import "package:expect/expect.dart";

class X {
  final nested = [];

  get length => nested.length;
}

loop(val) {
  var sum = 0;
  for (var i = 0; i < 10; i++) {
    sum += val.length;
  }
  return sum;
}

// LoadField(LoadField(",", nested), length) should not be hoisted.
// Otherwise it would crash.
testRedef() => loop(",");

main() {
  // Provide polymorphic type feedback.
  loop("");
  loop(new X());

  // Optimize loop with a constant argument.
  for (var i = 0; i < 100; i++) {
    testRedef();
  }
}
