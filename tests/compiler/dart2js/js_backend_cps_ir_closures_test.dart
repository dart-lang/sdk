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
  var _box_0 = {};
  _box_0._captured_x_0 = x;
  _box_0._captured_x_0 = J.getInterceptor$ns(x = _box_0._captured_x_0).$add(x, "1");
  P.print(new V.main_a(_box_0).call$0());
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
  P.print(new V.main_a(x).call$0());
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
  var _box_0 = {};
  _box_0._captured_x_0 = 122;
  _box_0._captured_x_0 = _box_0._captured_x_0 + 1;
  P.print(new V.main_closure(_box_0).call$0());
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
  var _box_0 = {};
  _box_0._captured_x_0 = 122;
  _box_0._captured_x_0 = _box_0._captured_x_0 + 1;
  P.print(new V.main_closure(_box_0).call$0().call$0());
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
  var a = null, i = 0;
  for (; i < 10; a = new V.main_closure(i), i = i + 1)
    ;
  P.print(a.call$0());
}"""),

  const TestEntry.forMethod('function(A#b)', """
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
  return new V.A_b_closure(this);
}"""),

  const TestEntry("""
staticMethod(x) => x;
main(x) {
  var tearOff = staticMethod;
  print(tearOff(123));
}
""",
r"""
function(x) {
  P.print(V.staticMethod(123));
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
  P.print(V.Foo$().instanceMethod$1(123));
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
  var v0 = V.Foo$();
  P.print(v0.instanceMethod$1(123));
  P.print(v0.instanceMethod$1(321));
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
  var notTearOff = V.Foo$().get$getter();
  P.print(notTearOff.call$1(123));
  P.print(notTearOff.call$1(321));
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
  P.print(V.Foo$().getter$1(123));
}"""),
];

void main() {
  runTests(tests);
}
