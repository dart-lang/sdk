// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of operators.

library operators2_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [

  const TestEntry(r"""
foo(a, b) => ((a & 0xff0000) >> 1) & b;
main() {
  print(foo(123, 234));
  print(foo(0, 2));
}""", r"""
function() {
  P.print((123 & 16711680) >>> 1 & 234);
  P.print((0 & 16711680) >>> 1 & 2);
}"""),

  const TestEntry(r"""
foo(a) => ~a;
main() {
  print(foo(1));
  print(foo(10));
}""", r"""
function() {
  P.print(~1 >>> 0);
  P.print(~10 >>> 0);
}"""),

  const TestEntry.forMethod('function(foo)',
      r"""
foo(a) => a % 13;
main() {
  print(foo(5));
  print(foo(-100));
}""", r"""
function(a) {
  var result = a % 13;
  return result === 0 ? 0 : result > 0 ? result : 13 < 0 ? result - 13 : result + 13;
}"""),

  const TestEntry(r"""
foo(a) => a % 13;
main() {
  print(foo(5));
  print(foo(100));
}""", r"""
function() {
  P.print(5 % 13);
  P.print(100 % 13);
}"""),

  const TestEntry(r"""
foo(a) => a.remainder(13);
main() {
  print(foo(5));
  print(foo(-100));
}""", r"""
function() {
  P.print(5 % 13);
  P.print(-100 % 13);
}"""),

  const TestEntry.forMethod('function(foo)',
      r"""
foo(a) => a ~/ 13;
main() {
  print(foo(5));
  print(foo(-100));
}""", r"""
function(a) {
  return (a | 0) === a && (13 | 0) === 13 ? a / 13 | 0 : J.toInt$0$n(a / 13);
}"""),

  const TestEntry(r"""
foo(a) => a ~/ 13;
main() {
  print(foo(5));
  print(foo(100));
}""", r"""
function() {
  P.print(5 / 13 | 0);
  P.print(100 / 13 | 0);
}"""),

  const TestEntry.forMethod('function(foo)',
      r"""
foo(a) => a ~/ 13;
main() {
  print(foo(5));
  print(foo(8000000000));
}""", r"""
function(a) {
  return (a | 0) === a && (13 | 0) === 13 ? a / 13 | 0 : J.toInt$0$n(a / 13);
}"""),

];

void main() {
  runTests(tests);
}
