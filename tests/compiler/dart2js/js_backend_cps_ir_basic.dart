// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for basic functionality.

library basic_tests;

import 'js_backend_cps_ir_test.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
foo(a, [b = "b"]) => b;
bar(a, {b: "b", c: "c"}) => c;
main() {
  foo(0);
  foo(0, 1);
  bar(0);
  bar(0, b: 1);
  bar(0, c: 1);
  bar(0, b: 1, c: 2);
}
""",
"""
function() {
  V.foo(0, "b");
  V.foo(0, 1);
  V.bar(0, "b", "c");
  V.bar(0, 1, "c");
  V.bar(0, "b", 1);
  V.bar(0, 1, 2);
  return null;
}"""),
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
  // Constructor invocation
  const TestEntry("""
main() {
  print(new Set());
  print(new Set.from([1, 2, 3]));
}""", r"""
function() {
  P.print(P.Set_Set());
  P.print(P.Set_Set$from([1, 2, 3]));
  return null;
}"""),
  // Method invocation
  const TestEntry("""
main() {
  print(new DateTime.now().isBefore(new DateTime.now()));
}""", r"""
function() {
  P.print(P.DateTime$now().isBefore$1(P.DateTime$now()));
  return null;
}"""),
];
