// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

import "package:expect/expect.dart";

@pragma("vm:never-inline")
foo(List<int> x) => x[1] + x[0];

@pragma("vm:never-inline")
bar(List<int> x) => 1 + x[0];

@pragma("vm:never-inline")
baz(List<int> x) => x[0] + 2;

main() {
  var x = new List<int>(2);

  // Only first is null.
  x[0] = null;
  x[1] = 123;
  try {
    foo(x);
  } on NoSuchMethodError catch (e) {
    ;
  }
  try {
    bar(x);
  } on NoSuchMethodError catch (e) {
    ;
  }
  try {
    baz(x);
  } on NoSuchMethodError catch (e) {
    ;
  }

  // Only second is null.
  x[0] = 456;
  x[1] = null;
  try {
    foo(x);
  } on NoSuchMethodError catch (e) {
    ;
  }
  Expect.equals(457, bar(x));
  Expect.equals(458, baz(x));

  // Neither is null.
  x[0] = 789;
  x[1] = -1;
  Expect.equals(788, foo(x));
  Expect.equals(790, bar(x));
  Expect.equals(791, baz(x));
}
