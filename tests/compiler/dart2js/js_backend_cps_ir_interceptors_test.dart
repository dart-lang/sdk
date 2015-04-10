// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=-DUSE_CPS_IR=true

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
  var g;
  g = 1;
  P.print(J.getInterceptor$ns(g).$add(g, 3));
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
  var l, i, v0, x, j;
  l = ["hest", ["h", "e", "s", "t"]];
  P.print(J.getInterceptor$as(l).get$length(l));
  i = 0;
  L0:
    while (true) {
      v0 = J.getInterceptor$as(l).get$length(l);
      if (P.identical(J.getInterceptor$n(i).$lt(i, v0), true)) {
        x = J.getInterceptor$as(l).$index(l, i);
        j = 0;
        while (true) {
          v0 = J.getInterceptor$as(x).get$length(x);
          if (P.identical(J.getInterceptor$n(j).$lt(j, v0), true)) {
            P.print(J.getInterceptor$as(x).$index(x, j));
            j = J.getInterceptor$ns(j).$add(j, 1);
          } else {
            i = J.getInterceptor$ns(i).$add(i, 1);
            continue L0;
          }
        }
      } else
        return null;
    }
}"""),
];


void main() {
  runTests(tests);
}
