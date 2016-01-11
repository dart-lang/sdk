// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that the cps ir can refine the type of the arguments of certain
/// whitelisted operators and methods in the core libraries.

// TODO(sigmund): these tests are brittle and hard to maintain, change how we
// run them so we can record and update the test easily.
library argument_refinement_test;

import 'js_backend_cps_ir.dart';

List<TestEntry> tests = [
  numArgTest('print(x - y);', r'P.print(J.$sub$n(x, y));'),
  numArgTest('print(x / y);', r'P.print(J.$div$n(x, y));'),
  numArgTest('print(x % y);', r'P.print(J.$mod$n(x, y));'),
  numArgTest('print(x ~/ y);', r'P.print(J.$tdiv$n(x, y));'),
  numArgTest('print(x >> y);', r'P.print(J.$shr$n(x, y));'),
  numArgTest('print(x << y);', r'P.print(J.$shl$n(x, y));'),
  numArgTest('print(x & y);', r'P.print(J.$and$n(x, y));'),
  numArgTest('print(x | y);', r'P.print(J.$or$n(x, y));'),
  numArgTest('print(x ^ y);', r'P.print(J.$xor$n(x, y));'),
  numArgTest('print(x > y);', r'P.print(J.$gt$n(x, y));'),
  numArgTest('print(x < y);', r'P.print(J.$lt$n(x, y));'),
  numArgTest('print(x >= y);', r'P.print(J.$ge$n(x, y));'),
  numArgTest('print(x <= y);', r'P.print(J.$le$n(x, y));'),
  numArgTest('print(x.remainder(y));', r'P.print(J.remainder$1$n(x, y));'),
  num2ArgTest('print(x.clamp(y, z));', r'P.print(J.clamp$2$n(x, y, z));'),
  noRefinementNumTest('print(x + y);', r'P.print(J.$add$ns(x, y));'),
  noRefinementNumTest('print(x * y);', r'P.print(J.$mul$ns(x, y));'),
  noRefinementNumTest('print(x.compareTo(y));', r'P.print(J.compareTo$1$ns(x, y));'),

  // TODO(sigmund): would be nice if we can disable inlining on the following
  // tests...
  notStringNumTest('print(x + y);', 'P.print(x + y);'),
  notStringNumTest('print(x * y);', 'P.print(x * y);'),
  notStringNumTest('print(x.compareTo(y));', r'''if (x < y)
    v0 = -1;
  else if (x > y)
    v0 = 1;
  else if (x === y) {
    v0 = x === 0;
    v0 = v0 ? (y === 0 ? 1 / y < 0 : y < 0) === (v0 ? 1 / x < 0 : x < 0) ? 0 : (v0 ? 1 / x < 0 : x < 0) ? -1 : 1 : 0;
  } else
    v0 = isNaN(x) ? isNaN(y) ? 0 : 1 : -1;
  P.print(v0);'''),

  intArgTest('print(x.toSigned(y));', r'P.print(J.toSigned$1$i(x, y));'),
  intArgTest('print(x.toUnsigned(y));', r'P.print(J.toUnsigned$1$i(x, y));'),
  intArgTest('print(x.modInverse(y));', r'P.print(J.modInverse$1$i(x, y));'),
  intArgTest('print(x.gcd(y));', r'P.print(J.gcd$1$i(x, y));'),

  int2ArgTest('print(x.modPow(y, z));', r'P.print(J.modPow$2$i(x, y, z));'),

  codeUnitAtTest,
  mathStaticTest,
];

void main() {
  runTests(tests);
}

/// Creates a test for 1-arg methods on num that immediately identify the
/// receiver and the argument as num values.
numArgTest(String sourceSend, String compiledSend) {
  return new TestEntry("""
main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x is num);
  print(y is num);
  $sourceSend
  print(x is num);
  print(y is num); // will be compiled to `true` if we know the type of `y`.
}""", """
function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null);
  P.print(typeof x === "number");
  P.print(typeof y === "number");
  $compiledSend
  P.print(true);
  P.print(true);
}""");
}

/// Creates a test for 2-arg methods on num that immediately identify the
/// receiver and both arguments as num values.
num2ArgTest(String sourceSend, String compiledSend) {
  return new TestEntry("""
main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  var z = int.parse('1235');
  print(x is num);
  print(y is num);
  print(z is num);
  $sourceSend
  print(x is num);
  print(y is num);
  print(z is num);
}""", """
function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), z = P.int_parse("1235", null, null);
  P.print(typeof x === "number");
  P.print(typeof y === "number");
  P.print(typeof z === "number");
  $compiledSend
  P.print(true);
  P.print(true);
  P.print(true);
}""");
}

/// Creates a test for 1-arg methods on num that are ambiguous and could be
/// methods on other types, and hence we cannot refine the arguments in this
/// case.
noRefinementNumTest(String sourceSend, String compiledSend) {
  return new TestEntry("""
main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x is num);
  print(y is num);
  $sourceSend
  print(x is num);
  print(y is num);
}""", """
function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), v0 = typeof x === "number", v1 = typeof y === "number";
  P.print(v0);
  P.print(v1);
  $compiledSend
  P.print(v0);
  P.print(v1);
}""");
}


/// For operators that are common to String and num, we create tests that do not
/// refine the receiver, but that once the receiver type is known, the argument
/// type is also known.
notStringNumTest(String sourceSend, String compiledSend) {
  return new TestEntry("""
main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x / 2);
  print(x is num);
  print(y is num);
  $sourceSend
  print(y is num);
}""", """
function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), v0 = typeof y === "number";
  P.print(J.\$div\$n(x, 2));
  P.print(true);
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(y));
  $compiledSend
  P.print(true);
}""");
}

/// Creates a test for 1-arg methods on int that immediately identify the
/// receiver and the argument as int values.
intArgTest(String sourceSend, String compiledSend) {
  return new TestEntry("""
main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  print(x is int);
  print(y is int);
  $sourceSend
  print(x is int);
  print(y is int);
}""", """
function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null);
  P.print(typeof x === "number" && Math.floor(x) === x);
  P.print(typeof y === "number" && Math.floor(y) === y);
  $compiledSend
  P.print(true);
  P.print(true);
}""");
}

/// Creates a test for 2-arg methods on num that immediately identify the
/// receiver and both arguments as num values.
int2ArgTest(String sourceSend, String compiledSend) {
  return new TestEntry("""
main() {
  var x = int.parse('1233');
  var y = int.parse('1234');
  var z = int.parse('1235');
  print(x is int);
  print(y is int);
  print(z is int);
  $sourceSend
  print(x is int);
  print(y is int);
  print(z is int);
}""", """
function() {
  var x = P.int_parse("1233", null, null), y = P.int_parse("1234", null, null), z = P.int_parse("1235", null, null);
  P.print(typeof x === "number" && Math.floor(x) === x);
  P.print(typeof y === "number" && Math.floor(y) === y);
  P.print(typeof z === "number" && Math.floor(z) === z);
  $compiledSend
  P.print(true);
  P.print(true);
  P.print(true);
}""");
}

const codeUnitAtTest = const TestEntry(r"""
main() {
  var x = int.parse('3');
  var y = int.parse('a', onError: (e) => 'abcde');
  print(x is int);
  print(y is String);
  print(y.codeUnitAt(x));
  print(x is int);
  print(y is String);
}""", r"""
function() {
  var x = P.int_parse("3", null, null), y = P.int_parse("a", new V.main_closure(), null);
  P.print(typeof x === "number" && Math.floor(x) === x);
  P.print(typeof y === "string");
  P.print(J.codeUnitAt$1$s(y, x));
  P.print(true);
  P.print(true);
}""");

const mathStaticTest = const TestEntry(r"""
import 'dart:math';
main() {
  var x = int.parse('3');
  var y = int.parse('1234');
  var z = int.parse('1236');
  var w = int.parse('2');
  print(x is num);
  print(sin(x));
  print(x is num);

  print(y is num);
  print(log(y));
  print(y is num);

  print(z is num);
  print(w is num);
  print(pow(z, w));
  print(z is num);
  print(w is num);
}""", r"""
function() {
  var x = P.int_parse("3", null, null), y = P.int_parse("1234", null, null), z = P.int_parse("1236", null, null), w = P.int_parse("2", null, null), v0 = typeof x === "number", v1;
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(x));
  P.print(Math.sin(x));
  P.print(true);
  v0 = typeof y === "number";
  P.print(v0);
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(y));
  P.print(Math.log(y));
  P.print(true);
  v1 = typeof z === "number";
  P.print(v1);
  v0 = typeof w === "number";
  P.print(v0);
  if (!v1)
    throw H.wrapException(H.argumentErrorValue(z));
  if (!v0)
    throw H.wrapException(H.argumentErrorValue(w));
  P.print(Math.pow(z, w));
  P.print(true);
  P.print(true);
}""");
