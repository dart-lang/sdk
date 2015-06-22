// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of interceptors.

library interceptors_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
main() {
  var g = 1;

  var x = g + 3;
  print(x);
}""",
r"""
function() {
  P.print(4);
  return null;
}"""),
  const TestEntry("""
main() {
  var l = ['hest', ['h', 'e', 's', 't']];
  print(l.length);
  for (int i  = 0; i < l.length; i++) {
    var x = l[i];
    for (int j = 0; j < x.length; j++) {
      print(x[j]);
    }
  }
}""",
r"""
function() {
  var l = ["hest", ["h", "e", "s", "t"]], i = 0, x, j;
  P.print(J.getInterceptor$as(l).get$length(l));
  while (J.getInterceptor$n(i).$lt(i, J.getInterceptor$as(l).get$length(l))) {
    x = J.getInterceptor$as(l).$index(l, i);
    j = 0;
    while (J.getInterceptor$n(j).$lt(j, J.getInterceptor$as(x).get$length(x))) {
      P.print(J.getInterceptor$as(x).$index(x, j));
      j = J.getInterceptor$ns(j).$add(j, 1);
    }
    i = J.getInterceptor$ns(i).$add(i, 1);
  }
  return null;
}"""),
];


void main() {
  runTests(tests);
}
