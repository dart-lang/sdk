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
  var l = [1, 2, 3], m = P.LinkedHashMap_LinkedHashMap$_literal(["s", 1]), v0, v1;
  P.print("()");
  P.print("(true)");
  P.print("(1)");
  if (!(typeof (v0 = P.IterableBase_iterableToFullString(v1 = [1, 2, 3], "[", "]")) === "string"))
    throw H.wrapException(H.argumentErrorValue(v1));
  P.print("(" + v0 + ")");
  if (!(typeof (v0 = P.Maps_mapToString(v1 = P.LinkedHashMap_LinkedHashMap$_literal(["s", 1]))) === "string"))
    throw H.wrapException(H.argumentErrorValue(v1));
  P.print("(" + v0 + ")");
  P.print("(1)");
  if (!(typeof (v1 = P.IterableBase_iterableToFullString(l, "[", "]")) === "string"))
    throw H.wrapException(H.argumentErrorValue(l));
  P.print("(" + v1 + ")");
  if (!(typeof (v1 = P.Maps_mapToString(m)) === "string"))
    throw H.wrapException(H.argumentErrorValue(m));
  P.print("(" + v1 + ")");
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
  P.print("b");
  P.print(2);
  P.print("c");
  P.print("c");
  P.print(7);
  P.print(10);
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
  P.print(1);
  P.print(10);
  P.print(10);
  P.print(1);
  P.print(1);
}"""),
  const TestEntry(
  """
foo() { print(42); return 42; }
main() { return foo(); }
  """,
  """
function() {
  var v0 = H.S(42);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
  return 42;
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
  P.print(P._LinkedHashSet$(null));
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
  var v0 = H.S(Date.now() < Date.now());
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  // Static calls
  const TestEntry("""
foo() { print(42); }
main() { foo(); }
""", r"""
function() {
  var v0 = H.S(42);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  // Static getters
  const TestEntry("""
var foo = 42;
main() { print(foo); }
""", r"""
function() {
  var v0 = H.S($.foo);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  const TestEntry("""
get foo { print(42); }
main() { foo; }
""", r"""
function() {
  var v0 = H.S(42);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  // Static setters
  const TestEntry("""
var foo = 0;
main() { print(foo = 42); }
""", r"""
function() {
  var v0;
  $.foo = 42;
  v0 = H.S(42);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  const TestEntry("""
set foo(x) { print(x); }
main() { foo = 42; }
""", r"""
function() {
  var v0 = H.S(42);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
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
