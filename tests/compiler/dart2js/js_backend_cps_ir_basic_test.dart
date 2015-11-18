// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for basic functionality.

library basic_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry(r"""
main() {
  var e = 1;
  var l = [1, 2, 3];
  var m = {'s': 1};

  print('(' ')');
  print('(${true})');
  print('(${1})');
  print('(${[1, 2, 3]})');
  print('(${{'s': 1}})');
  print('($e)');
  print('($l)');
  print('($m)');
}""",r"""
function() {
  var l = [1, 2, 3], m = P.LinkedHashMap_LinkedHashMap$_literal(["s", 1]);
  P.print("()");
  P.print("(true)");
  P.print("(1)");
  P.print("(" + H.S([1, 2, 3]) + ")");
  P.print("(" + H.S(P.LinkedHashMap_LinkedHashMap$_literal(["s", 1])) + ")");
  P.print("(1)");
  P.print("(" + H.S(l) + ")");
  P.print("(" + H.S(m) + ")");
}"""),
  const TestEntry("""
foo(a, [b = "b"]) { print(b); return b; }
bar(a, {b: "b", c: "c"}) { print(c); return c; }
main() {
  foo(0);
  foo(1, 2);
  bar(3);
  bar(4, b: 5);
  bar(6, c: 7);
  bar(8, b: 9, c: 10);
}
""",
"""
function() {
  V.foo(0, "b");
  V.foo(1, 2);
  V.bar(3, "b", "c");
  V.bar(4, 5, "c");
  V.bar(6, "b", 7);
  V.bar(8, 9, 10);
}"""),
  const TestEntry(
  """
foo(a) {
  print(a);
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
  var a = 10, b = 1;
  P.print(b);
  P.print(a);
  P.print(a);
  P.print(V.foo(b));
}"""),
  const TestEntry(
  """
foo() { print(42); return 42; }
main() { return foo(); }
  """,
  """function() {
  return V.foo();
}"""),
  const TestEntry("main() {}"),
  const TestEntry("main() { return 42; }"),
  const TestEntry("main() { return; }", """
function() {
}"""),
  // Constructor invocation
  const TestEntry("""
main() {
  print(new Set());
  print(new Set.from([1, 2, 3]));
}""", r"""
function() {
  P.print(P.LinkedHashSet_LinkedHashSet(null, null, null, null));
  P.print(P.LinkedHashSet_LinkedHashSet$from([1, 2, 3], null));
}"""),
  // Call synthetic constructor.
  const TestEntry("""
class C {}
main() {
  print(new C());
}"""),
  // Method invocation
  const TestEntry("""
main() {
  print(new DateTime.now().isBefore(new DateTime.now()));
}""", r"""
function() {
  P.print(P.DateTime$now().isBefore$1(P.DateTime$now()));
}"""),
  // Static calls
  const TestEntry("""
foo() { print(42); }
main() { foo(); }
""", r"""
function() {
  V.foo();
}"""),
  // Static getters
  const TestEntry("""
var foo = 42;
main() { print(foo); }
""", r"""
function() {
  P.print($.foo);
}"""),
  const TestEntry("""
get foo { print(42); }
main() { foo; }
""", r"""
function() {
  V.foo();
}"""),
  // Static setters
  const TestEntry("""
var foo = 0;
main() { print(foo = 42); }
""", r"""
function() {
  var v0 = 42;
  $.foo = v0;
  P.print(v0);
}"""),
  const TestEntry("""
set foo(x) { print(x); }
main() { foo = 42; }
""", r"""
function() {
  V.foo(42);
}"""),
  // Assert
  const TestEntry("""
foo() { print('X'); }
main() {
  assert(true);
  assert(false);
  assert(foo());
  print('Done');
}""", r"""
function() {
  P.print("Done");
}""")
];


void main() {
  runTests(tests);
}
