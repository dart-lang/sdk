// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of closures.

library closures_test;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
main(x) {
  a() {
    return x;
  }
  x = x + '1';
  print(a());
}
""",
r"""
function(x) {
  P.print(J.$add$ns(x, "1"));
}"""),

  const TestEntry("""
main(x) {
  a() {
    return x;
  }
  x = x + '1';
  print(a());
  return a;
}
""",
r"""
function(x) {
  var _box_0 = {}, a = new V.main_a(_box_0);
  _box_0.x = x;
  _box_0.x = J.$add$ns(_box_0.x, "1");
  P.print(a.call$0());
  return a;
}"""),

  const TestEntry("""
main(x) {
  a() {
    return x;
  }
  print(a());
}
""",
r"""
function(x) {
  P.print(x);
}"""),

  const TestEntry("""
main(x) {
  a() {
    return x;
  }
  print(a());
  return a;
}
""",
r"""
function(x) {
  var a = new V.main_a(x);
  P.print(a.call$0());
  return a;
}"""),

  const TestEntry("""
main() {
  var x = 122;
  var a = () => x;
  x = x + 1;
  print(a());
}
""",
r"""
function() {
  var v0 = H.S(122 + 1);
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
main() {
  var x = 122;
  var a = () => x;
  x = x + 1;
  print(a());
  return a;
}
""",
r"""
function() {
  var _box_0 = {}, a = new V.main_closure(_box_0), v0;
  _box_0.x = 122;
  _box_0.x = _box_0.x + 1;
  v0 = H.S(a.call$0());
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
  return a;
}"""),

  const TestEntry("""
main() {
  var x = 122;
  var a = () {
    var y = x;
    return () => y;
  };
  x = x + 1;
  print(a()());
}
""",
r"""
function() {
  var v0 = H.S(122 + 1);
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
main() {
  var x = 122;
  var a = () {
    var y = x;
    return () => y;
  };
  x = x + 1;
  print(a()());
  return a;
}
""",
r"""
function() {
  var _box_0 = {}, a = new V.main_closure(_box_0), v0;
  _box_0.x = 122;
  _box_0.x = _box_0.x + 1;
  v0 = H.S(a.call$0().call$0());
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
  return a;
}"""),

  const TestEntry("""
main() {
  var a;
  for (var i=0; i<10; i++) {
    a = () => i;
  }
  print(a());
}
""",
r"""
function() {
  var a = null, i = 0, v0;
  for (; i < 10; a = new V.main_closure(i), i = i + 1)
    ;
  v0 = H.S(a.call$0());
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
class A {
  a() => 1;
  b() => () => a();
}
main() {
  print(new A().b()());
}
""",
r"""
function() {
  var v0 = H.S(new V.A_b_closure(V.A$()).call$0());
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
staticMethod(x) { print(x); return x; }
main(x) {
  var tearOff = staticMethod;
  print(tearOff(123));
}
""",
r"""
function(x) {
  P.print(123);
  P.print(123);
}"""),

  const TestEntry("""
class Foo {
  instanceMethod(x) => x;
}
main(x) {
  var tearOff = new Foo().instanceMethod;
  print(tearOff(123));
}
""",
r"""
function(x) {
  V.Foo$();
  P.print(123);
}"""),

  const TestEntry("""
class Foo {
  instanceMethod(x) => x;
}
main(x) {
  var tearOff = new Foo().instanceMethod;
  print(tearOff(123));
  print(tearOff(321));
}
""",
r"""
function(x) {
  V.Foo$();
  P.print(123);
  P.print(321);
}"""),

  const TestEntry("""
class Foo {
  get getter {
    print('getter');
    return (x) => x;
  }
}
main(x) {
  var notTearOff = new Foo().getter;
  print(notTearOff(123));
  print(notTearOff(321));
}
""",
r"""
function(x) {
  var v0 = new V.Foo_getter_closure();
  V.Foo$();
  P.print("getter");
  P.print(v0.call$1(123));
  P.print(v0.call$1(321));
}"""),

  const TestEntry("""
class Foo {
  get getter {
    print('getter');
    return (x) => x;
  }
}
main(x) {
  var notTearOff = new Foo().getter;
  print(notTearOff(123));
}
""",
r"""
function(x) {
  V.Foo$();
  P.print("getter");
  P.print(new V.Foo_getter_closure().call$1(123));
}"""),
];

void main() {
  runTests(tests);
}
