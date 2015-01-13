// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=-DUSE_CPS_IR=true

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
  var box_0, a, v0;
  box_0 = {};
  box_0.x_0 = x;
  a = new V.main_a(box_0);
  x = box_0.x_0;
  v0 = "1";
  box_0.x_0 = J.getInterceptor(x).$add(x, v0);
  P.print(a.call$0());
  return null;
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
  return null;
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
  var box_0, a, x, v0;
  box_0 = {};
  box_0.x_0 = 122;
  a = new V.main_closure(box_0);
  x = box_0.x_0;
  v0 = 1;
  box_0.x_0 = J.getInterceptor(x).$add(x, v0);
  P.print(a.call$0());
  return null;
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
  var box_0, a, x, v0;
  box_0 = {};
  box_0.x_0 = 122;
  a = new V.main_closure(box_0);
  x = box_0.x_0;
  v0 = 1;
  box_0.x_0 = J.getInterceptor(x).$add(x, v0);
  P.print(a.call$0().call$0());
  return null;
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
  var a, box_0, i, v0, box_01, v1;
  a = null;
  box_0 = {};
  box_0.i_0 = 0;
  while (true) {
    i = box_0.i_0;
    v0 = 10;
    if (P.identical(J.getInterceptor(i).$lt(i, v0), true)) {
      a = new V.main_closure(box_0);
      box_01 = {};
      box_01.i_0 = box_0.i_0;
      i = box_01.i_0;
      v1 = 1;
      box_01.i_0 = J.getInterceptor(i).$add(i, v1);
      box_0 = box_01;
    } else {
      P.print(a.call$0());
      return null;
    }
  }
}"""),
];

void main() {
  runTests(tests);
}
