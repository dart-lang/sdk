// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for constant folding and lowering String.codeUnitAt.

library basic_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [

  // Constant folding.
  const TestEntry(r"""
main() {
  print('A'.codeUnitAt(0));
}""",r"""
function() {
  P.print(65);
}"""),


  // Bounds checking.
  const TestEntry.forMethod('function(foo)',
r"""
foo(s) {
  var sum = 0;
  for (int i = 0; i < s.length; i++) sum += s.codeUnitAt(i);
  return sum;
}
main() {
  print(foo('ABC'));
  print(foo('Hello'));
}""",r"""
function(s) {
  var v0 = s.length, sum = 0, i = 0;
  for (; i < v0; sum = sum + s.charCodeAt(i), i = i + 1)
    ;
  return sum;
}"""),
];


void main() {
  runTests(tests);
}
