// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int value;
  A(this.value);
  void set(int value) {
    this.value = value;
  }

  int get() => value;
  int operator [](int index) => value + index;
  void operator []=(int index, int newValue) {
    value += -index + newValue;
  }

  void test(int expected) {
    Expect.equals(expected, value);
  }

  Function limp(int n) {
    if (n == 0) return set;
    return () => limp(n - 1);
  }

  A get self => this;
  A operator +(A other) {
    this.value += other.value;
    return this;
  }
}

class Box {
  A value;
  Box(this.value);
  A operator [](int pos) => value;
  void operator []=(int pos, A a) {
    value = a;
  }

  A get x => value;
  void set x(A a) {
    value = a;
  }
}

// Subset of grammar being tested.
//
// expression:
//       assignableExpression assignmentOperator expression
//     | conditionalExpression cascadeSection*
//     ;
// expressionWithoutCascade:
//       assignableExpression assignmentOperator expressionWithoutCascade
//     | conditionalExpression
//     ;
// expressionList:
//       expression (',' expression)*
//     ;
// assignableExpression:
//       primary (arguments* assignableSelector)+
//     | super assignableSelector
//     | identifier
//     ;
// conditionalExpression:
//     logicalOrExpression ('?' expressionWithoutCascade ':' expressionWithoutCascade)?
//     ;
// primary:
//       thisExpression
//     | super assignableSelector
//     | functionExpression
//     | literal
//     | identifier
//     | newExpression
//     | constObjectExpression
//     | '(' expression ')'
//     ;
// assignableSelector:
//       '[' expression ']'
//     | '.' identifier
//     ;
//
// In words:
//  An assignableExpression is either a variable or something ending in
//  [expression] or .identifier.

main() {
  A a = new A(42);
  A original = a;
  A b = new A(87);
  fa() => a;
  Box box = new Box(a);
  // Different expressions on the left-hand side of '..'.
  //  conditionalExpression >> postfixExpression > primary selector*
  Expect.equals(
      a,
      a
        ..set(37)
        ..get());
  a.test(37);
  Expect.equals(
      a,
      fa()
        ..set(42)
        ..get());
  a.test(42);
  Expect.equals(
      a,
      box.x
        ..set(37)
        ..get());
  a.test(37);
  // '..' binds to 'b + a', i.e., to the 'b' object, not to 'a'.
  Expect.equals(
      b,
      b + a
        ..test(124)
        ..set(117)
        ..get());
  b.test(117);
  a.test(37);

  // expression :: conditionalExpression cascadeSection
  // and conditionalExpression ends in expressionWithoutCascade.
  // I.e., '..' binds to the entire condition expression, not to 'b'.
  (a.value == 37) ? a : b
    ..set(42);
  a.test(42);

  // This binds .. to 'a', not 'c=a', and performs assignment after reading
  // c.get().
  A c = new A(21);
  c = a..set(c.get()); // FAILING.
  Expect.equals(a, c);
  Expect.equals(original, a);
  a.test(21); // Fails as 42 if above is parsed as (c = a)..set(c.get()).

  // Should be parsed as (box..x = (c = a))..x.test(21).
  c = null;
  box
    ..x = c = a
    ..x.test(21);
  c.test(21);
  // Other variants
  c = null;
  box
    ..x = c = (a..test(21))
    ..x.test(21);
  c.test(21);

  c = null;
  box
    ..x = (c = a..test(21))
    ..x.test(21);
  c.test(21);

  // Should work the same:
  (a..set(42))..test(42);
  a
    ..set(21)
    ..test(21);

  c = null;
  Box originalBox = box;
  // Should parse as:
  // box = (box..x = (a.value == 21 ? b : c)..x.test(117));
  box = box
    ..x = a.value == 21 ? b : c
    ..x.test(117);
  Expect.equals(originalBox, box);
  Expect.equals(box.value, b);

  // New cascades are allowed inside an expressionWithoutCascade if properly
  // delimited.
  box
    ..x = (a
      ..set(42)
      ..test(42))
    ..x.test(42);
}
