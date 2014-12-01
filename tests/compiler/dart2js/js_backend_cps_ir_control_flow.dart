// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of control flow statements.

library control_flow_tests;

import 'js_backend_cps_ir_test.dart';

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
        while (P.identical(V.foo(true), true))
          if (P.identical(V.foo(false), true)) {
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
  var i;
  i = 0;
  L1:
    while (true) {
      if (P.identical(V.foo(true), true)) {
        P.print(1);
        if (!P.identical(V.foo(false), true)) {
          i = V.foo(i);
          continue L1;
        }
      }
      P.print(2);
      return null;
    }
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
  P.identical(V.foo(true), true) ? P.print(1) : P.print(2);
  P.print(3);
  return null;
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
  if (P.identical(V.foo(true), true)) {
    P.print(1);
    P.print(1);
  } else {
    P.print(2);
    P.print(2);
  }
  P.print(3);
  return null;
}"""),
const TestEntry("""
main() {
  if (1) {
    print('bad');
  } else {
    print('ok');
  }
}""","""
function() {
  P.print("bad");
  return null;
}"""),
];
