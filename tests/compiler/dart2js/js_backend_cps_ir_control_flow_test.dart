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
  L1:
    while (true)
      L0:
        while (true)
          while (true) {
            P.print(true);
            if (false) {
              P.print(1);
              continue L0;
            }
            P.print(false);
            if (false) {
              P.print(2);
              continue L1;
            }
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
  while (true) {
    P.print(true);
    if (true === true) {
      P.print(1);
      P.print(false);
      if (false !== true) {
        P.print(0);
        continue;
      }
    }
    P.print(2);
    return null;
  }
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
  P.print(false);
  P.print(true);
  true ? P.print(1) : P.print(2);
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
  P.print(false);
  P.print(true);
  if (true) {
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
  P.print("2");
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
  var list = [1, 2, 3, 4, 5, 6], i = 0, v0;
  for (; i < 6; ++i) {
    v0 = H.S(list[i]);
    if (typeof dartPrint == "function")
      dartPrint(v0);
    else if (typeof console == "object" && typeof console.log != "undefined")
      console.log(v0);
    else if (!(typeof window == "object")) {
      if (!(typeof print == "function"))
        throw "Unable to print message: " + String(v0);
      print(v0);
    }
  }
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
  for (; i < 3; ++i, ++i1) {
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
