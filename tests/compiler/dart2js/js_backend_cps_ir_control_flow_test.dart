// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of control flow statements.

library control_flow_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
main() {
  while (true);
}
""", """
function() {
  while (true)
    ;
}"""),
  const TestEntry("""
foo(a) => a;

main() {
  while (true) {
    l: while (true) {
      while (foo(true)) {
        if (foo(false)) break l;
      }
      print(1);
    }
    print(2);
  }
}
""", """
function() {
  L0:
    while (true)
      while (true) {
        while (V.foo(true))
          if (V.foo(false)) {
            P.print(2);
            continue L0;
          }
        P.print(1);
      }
}"""),
  const TestEntry("""
foo(a) => a;

main() {
  for (int i = 0; foo(true); i = foo(i)) {
    print(1);
    if (foo(false)) break;
  }
  print(2);
}""", """
function() {
  var i = 0;
  while (P.identical(V.foo(true), true)) {
    P.print(1);
    if (P.identical(V.foo(false), true))
      break;
    i = V.foo(i);
  }
  P.print(2);
}"""),
const TestEntry("""
foo(a) => a;

main() {
 if (foo(true)) {
   print(1);
 } else {
   print(2);
 }
 print(3);
}""", """
function() {
  V.foo(true) ? P.print(1) : P.print(2);
  P.print(3);
}"""),
const TestEntry("""
foo(a) => a;

main() {
 if (foo(true)) {
   print(1);
   print(1);
 } else {
   print(2);
   print(2);
 }
 print(3);
}""", """
function() {
  if (V.foo(true)) {
    P.print(1);
    P.print(1);
  } else {
    P.print(2);
    P.print(2);
  }
  P.print(3);
}"""),
const TestEntry("""
main() {
  if (1) {
    print('bad');
  } else {
    print('good');
  }
}""","""
function() {
  P.print("good");
}"""),
  const TestEntry("""
foo() => 2;
main() {
  if (foo()) {
    print('bad');
  } else {
    print('good');
  }
}""","""
function() {
  V.foo();
  P.print("good");
}"""),
];

void main() {
  runTests(tests);
}
