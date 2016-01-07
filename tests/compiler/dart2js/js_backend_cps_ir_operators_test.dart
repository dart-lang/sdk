// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of operators.

library operators_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("main() { return true ? 42 : 'foo'; }"),
  const TestEntry("""
var x = 1;
foo() => ++x > 10;
main() {
  print(foo() ? "hello world" : "bad bad");
}""",r"""
function() {
  var v0 = $.x + 1;
  $.x = v0;
  v0 = v0 > 10 ? "hello world" : "bad bad";
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
var x = 1;
get foo => ++x > 10;
main() {
  print(foo ? "hello world" : "bad bad");
}""",r"""
function() {
  var v0 = $.x + 1;
  $.x = v0;
  v0 = v0 > 10 ? "hello world" : "bad bad";
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
var x = 1;
get foo => ++x > 10;
main() { print(foo && foo); }
""", r"""
function() {
  var v0 = $.x + 1;
  $.x = v0;
  if (v0 > 10) {
    $.x = v0 = $.x + 1;
    v0 = v0 > 10;
  } else
    v0 = false;
  v0 = H.S(v0);
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
var x = 1;
get foo => ++x > 10;
main() { print(foo || foo); }
""",r"""
function() {
  var v0 = $.x + 1;
  $.x = v0;
  if (v0 > 10)
    v0 = true;
  else {
    $.x = v0 = $.x + 1;
    v0 = v0 > 10;
  }
  v0 = H.S(v0);
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
get foo => foo;
main() { print(foo || foo); }
""","""
function() {
  V.foo();
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
  var list = [1, 2, 3], v0;
  list[1] = 6;
  if (!(typeof (v0 = P.IterableBase_iterableToFullString(list, "[", "]")) === "string"))
    throw H.wrapException(H.argumentErrorValue(list));
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
];

void main() {
  runTests(tests);
}
