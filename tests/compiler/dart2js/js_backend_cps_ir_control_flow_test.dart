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
foo(a) { print(a); return a; }

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
foo(a) { print(a); return a; }

main() {
  for (int i = 0; foo(true); i = foo(i)) {
    print(1);
    if (foo(false)) break;
  }
  print(2);
}""", """
function() {
  var i = 0;
  for (; V.foo(true) === true; i = V.foo(i)) {
    P.print(1);
    if (V.foo(false) === true)
      break;
  }
  P.print(2);
}"""),
const TestEntry("""
foo(a) { print(a); return a; }

main() {
 foo(false);
 if (foo(true)) {
   print(1);
 } else {
   print(2);
 }
 print(3);
}""", """
function() {
  V.foo(false);
  V.foo(true) ? P.print(1) : P.print(2);
  P.print(3);
}"""),
const TestEntry("""
foo(a) { print(a); return a; }

main() {
 foo(false);
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
  V.foo(false);
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
foo() { print('2'); return 2; }
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
  const TestEntry("""
main() {
  var list = [1,2,3,4,5,6];
  for (var x in list) {
    print(x);
  }
}""",r"""
function() {
  var list = [1, 2, 3, 4, 5, 6], i = 0;
  for (; i < 6; i = i + 1)
    P.print(list[i]);
}"""),
  const TestEntry("""
main() {
  var xs = ['x', 'y', 'z'], ys = ['A', 'B', 'C'];
  var xit = xs.iterator, yit = ys.iterator;
  while (xit.moveNext() && yit.moveNext()) {
    print(xit.current);
    print(yit.current);
  }
}""",r"""
function() {
  var xs = ["x", "y", "z"], ys = ["A", "B", "C"], i = 0, i1 = 0, current, current1;
  for (; i < 3; i = i + 1, i1 = i1 + 1) {
    current = xs[i];
    if (!(i1 < 3))
      break;
    current1 = ys[i1];
    P.print(current);
    P.print(current1);
  }
}"""),
];

void main() {
  runTests(tests);
}
