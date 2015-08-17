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
  var l = ["hest", ["h", "e", "s", "t"]], i = 0, x_, x, j;
  for (P.print(l.length); i < l.length; i = i + 1) {
    if (i < 0 || i >= l.length)
      H.ioore(l, i);
    x_ = J.getInterceptor$as(x = l[i]);
    for (j = 0; j < x_.get$length(x); j = j + 1)
      P.print(x_.$index(x, j));
  }
}"""),
];


void main() {
  runTests(tests);
}
