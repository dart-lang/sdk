// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for constant folding and lowering String.codeUnitAt.

library codeUnitAt_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [

  // Constant folding.
  const TestEntry(r"""
main() {
  print('A'.codeUnitAt(0));
}""",r"""
function() {
  var v0 = H.S(65);
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
  for (; i < v0; sum += s.charCodeAt(i), ++i)
    ;
  return sum;
}"""),
];


void main() {
  runTests(tests);
}
