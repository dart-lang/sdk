// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of operators.

library operators_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("main() { return true ? 42 : 'foo'; }"),
  const TestEntry("""
foo() => foo();
main() {
  print(foo() ? "hello world" : "bad bad");
}""","""
function() {
  P.print(V.foo() ? "hello world" : "bad bad");
}"""),
  const TestEntry("""
foo() => null;
main() {
  print(foo() ? "hello world" : "bad bad");
}""","""
function() {
  V.foo();
  P.print("bad bad");
}"""),
  const TestEntry("""
get foo => foo;
main() {
  print(foo ? "hello world" : "bad bad");
}""","""
function() {
  P.print(V.foo() ? "hello world" : "bad bad");
}"""),
  const TestEntry("""
get foo => foo;
main() { print(foo && foo); }
""", """
function() {
  P.print(V.foo() ? V.foo() === true : false);
}"""),
  const TestEntry("""
get foo => foo;
main() { print(foo || foo); }
""","""
function() {
  P.print(V.foo() ? true : V.foo() === true);
}"""),

// Needs interceptor calling convention
//const TestEntry("""
//class Foo {
//  operator[]=(index, value) {
//    print(value);
//  }
//}
//main() {
//  var foo = new Foo();
//  foo[5] = 6;
//}""", r"""
//function() {
//  V.Foo$().$indexSet(5, 6);
//}
//"""),

const TestEntry("""
main() {
  var list = [1, 2, 3];
  list[1] = 6;
  print(list);
}""", r"""
function() {
  var list = [1, 2, 3], v0 = 1;
  if (v0 < 0 || v0 >= list.length)
    H.ioore(list, v0);
  list[v0] = 6;
  P.print(list);
}"""),
];

void main() {
  runTests(tests);
}
