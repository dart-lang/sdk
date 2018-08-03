// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to generate wrong code for
// [foo].

import "package:expect/expect.dart";
import "compiler_annotations.dart";

main() {
  var result = foo(1, 2);
  Expect.equals(1, result[0]);
  Expect.equals(2, result[1]);

  result = foo([], 2);
  Expect.equals(0, result[0]);
  Expect.listEquals([], result[1]);
}

@DontInline()
foo(a, b) {
  () => 42;
  if (a is List) {
    var saved = a as List;
    // By having two HTypeKnown SSA instructions for [a], dart2js was
    // confused when updating the phis at exit of this block.
    a = a.length;
    b = saved;
  }
  return [a, b];
}
