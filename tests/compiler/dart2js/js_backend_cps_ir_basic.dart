// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for basic functionality.

library basic_tests;

import 'js_backend_cps_ir_test.dart';

const List<TestEntry> tests = const [
  const TestEntry(
  """
foo(a) {
  return a;
}
main() {
  var a = 10;
  var b = 1;
  var t;
  t = a;
  a = b;
  b = t;
  print(a);
  print(b);
  print(b);
  print(foo(a));
}
  """,
  """
function() {
  var a, b;
  a = 10;
  b = 1;
  P.print(b);
  P.print(a);
  P.print(a);
  P.print(V.foo(b));
  return null;
}"""),
  const TestEntry(
  """
foo() { return 42; }
main() { return foo(); }
  """,
  """function() {
  return V.foo();
}"""),
  const TestEntry("main() {}"),
  const TestEntry("main() { return 42; }"),
  const TestEntry("main() { return; }", """
function() {
  return null;
}"""),
];
