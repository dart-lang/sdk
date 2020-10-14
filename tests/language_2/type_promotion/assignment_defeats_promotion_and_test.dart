// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an assignment on the right hand side of `&&` defeats promotion
// after the entire `&&` expression, not just in the right hand side.

class A {}

class B extends A {
  // An invocation of the form `x.checkB()` verifies that the static type of `x`
  // is `B`, since this method is not defined anywhere else.
  dynamic checkB() => null;
}

class C extends A {}

class D extends B {}

// An invocation of the form `checkNotB(x)` verifies that the static type of `x`
// is not `B`, since `B` is not assignable to `C`.
dynamic checkNotB(C c) => null;

// An invocation of the form `alwaysTrue(x)` always returns `true` regardless of
// `x`.
bool alwaysTrue(dynamic x) => true;

ifSimple([A a]) {
  if (a is B && alwaysTrue(a = null)) {
    checkNotB(a);
  }
}

ifChainedAndsUnparenthesizedUnrelated([A a, Object x]) {
  if (a is B && alwaysTrue(a = null) && x is int) {
    checkNotB(a);
  }
}

ifChainedAndsUnparenthesizedRePromote([A a]) {
  if (a is B && alwaysTrue(a = null) && a is B) {
    a.checkB();
  }
}

ifChainedAndsUnparenthesizedAssignLast([A a, Object x]) {
  if (a is B && x is int && alwaysTrue(a = null)) {
    checkNotB(a);
  }
}

ifChainedAndsUnparenthesizedDeeperPromote([A a]) {
  if (a is B && a is D && alwaysTrue(a = null)) {
    checkNotB(a);
  }
}

ifChainedAndsParenLeftUnrelated([A a, Object x]) {
  if ((a is B && alwaysTrue(a = null)) && x is int) {
    checkNotB(a);
  }
}

ifChainedAndsParenLeftRePromote([A a]) {
  if ((a is B && alwaysTrue(a = null)) && a is B) {
    a.checkB();
  }
}

ifChainedAndsParenLeftAssignLast([A a, Object x]) {
  if ((a is B && x is int) && alwaysTrue(a = null)) {
    checkNotB(a);
  }
}

ifChainedAndsParenLeftDeeperPromote([A a]) {
  if ((a is B && a is D) && alwaysTrue(a = null)) {
    checkNotB(a);
  }
}

ifChainedAndsParenRightUnrelated([A a, Object x]) {
  if (a is B && (alwaysTrue(a = null) && x is int)) {
    checkNotB(a);
  }
}

ifChainedAndsParenRightRePromote([A a]) {
  if (a is B && (alwaysTrue(a = null) && a is B)) {
    checkNotB(a);
  }
}

ifChainedAndsParenRightAssignLast([A a, Object x]) {
  if (a is B && (x is int && alwaysTrue(a = null))) {
    checkNotB(a);
  }
}

ifChainedAndsParenRightDeeperPromote([A a]) {
  if (a is B && (a is D && alwaysTrue(a = null))) {
    checkNotB(a);
  }
}

conditionalSimple([A a]) {
  a is B && alwaysTrue(a = null) ? checkNotB(a) : null;
}

conditionalChainedAndsUnparenthesizedUnrelated([A a, Object x]) {
  a is B && alwaysTrue(a = null) && x is int ? checkNotB(a) : null;
}

conditionalChainedAndsUnparenthesizedRePromote([A a]) {
  a is B && alwaysTrue(a = null) && a is B ? a.checkB() : null;
}

conditionalChainedAndsUnparenthesizedAssignLast([A a, Object x]) {
  a is B && x is int && alwaysTrue(a = null) ? checkNotB(a) : null;
}

conditionalChainedAndsUnparenthesizedDeeperPromote([A a]) {
  a is B && a is D && alwaysTrue(a = null) ? checkNotB(a) : null;
}

conditionalChainedAndsParenLeftUnrelated([A a, Object x]) {
  (a is B && alwaysTrue(a = null)) && x is int ? checkNotB(a) : null;
}

conditionalChainedAndsParenLeftRePromote([A a]) {
  (a is B && alwaysTrue(a = null)) && a is B ? a.checkB() : null;
}

conditionalChainedAndsParenLeftAssignLast([A a, Object x]) {
  (a is B && x is int) && alwaysTrue(a = null) ? checkNotB(a) : null;
}

conditionalChainedAndsParenLeftDeeperPromote([A a]) {
  (a is B && a is D) && alwaysTrue(a = null) ? checkNotB(a) : null;
}

conditionalChainedAndsParenRightUnrelated([A a, Object x]) {
  a is B && (alwaysTrue(a = null) && x is int) ? checkNotB(a) : null;
}

conditionalChainedAndsParenRightRePromote([A a]) {
  a is B && (alwaysTrue(a = null) && a is B) ? checkNotB(a) : null;
}

conditionalChainedAndsParenRightAssignLast([A a, Object x]) {
  a is B && (x is int && alwaysTrue(a = null)) ? checkNotB(a) : null;
}

conditionalChainedAndsParenRightDeeperPromote([A a]) {
  a is B && (a is D && alwaysTrue(a = null)) ? checkNotB(a) : null;
}

andSimple([A a]) {
  a is B && alwaysTrue(a = null) && checkNotB(a);
}

andChainedAndsUnparenthesizedUnrelated([A a, Object x]) {
  a is B && alwaysTrue(a = null) && x is int && checkNotB(a);
}

andChainedAndsUnparenthesizedAssignLast([A a, Object x]) {
  a is B && x is int && alwaysTrue(a = null) && checkNotB(a);
}

andChainedAndsUnparenthesizedDeeperPromote([A a]) {
  a is B && a is D && alwaysTrue(a = null) && checkNotB(a);
}

andChainedAndsParenLeftUnrelated([A a, Object x]) {
  (a is B && alwaysTrue(a = null)) && x is int && checkNotB(a);
}

andChainedAndsParenLeftAssignLast([A a, Object x]) {
  (a is B && x is int) && alwaysTrue(a = null) && checkNotB(a);
}

andChainedAndsParenLeftDeeperPromote([A a]) {
  (a is B && a is D) && alwaysTrue(a = null) && checkNotB(a);
}

andChainedAndsParenRightUnrelated([A a, Object x]) {
  a is B && (alwaysTrue(a = null) && x is int) && checkNotB(a);
}

andChainedAndsParenRightRePromote([A a]) {
  a is B && (alwaysTrue(a = null) && a is B) && checkNotB(a);
}

andChainedAndsParenRightAssignLast([A a, Object x]) {
  a is B && (x is int && alwaysTrue(a = null)) && checkNotB(a);
}

andChainedAndsParenRightDeeperPromote([A a]) {
  a is B && (a is D && alwaysTrue(a = null)) && checkNotB(a);
}

main() {
  ifSimple();
  ifChainedAndsUnparenthesizedUnrelated();
  ifChainedAndsUnparenthesizedRePromote();
  ifChainedAndsUnparenthesizedAssignLast();
  ifChainedAndsUnparenthesizedDeeperPromote();
  ifChainedAndsParenLeftUnrelated();
  ifChainedAndsParenLeftRePromote();
  ifChainedAndsParenLeftAssignLast();
  ifChainedAndsParenLeftDeeperPromote();
  ifChainedAndsParenRightUnrelated();
  ifChainedAndsParenRightRePromote();
  ifChainedAndsParenRightAssignLast();
  ifChainedAndsParenRightDeeperPromote();
  conditionalSimple();
  conditionalChainedAndsUnparenthesizedUnrelated();
  conditionalChainedAndsUnparenthesizedRePromote();
  conditionalChainedAndsUnparenthesizedAssignLast();
  conditionalChainedAndsUnparenthesizedDeeperPromote();
  conditionalChainedAndsParenLeftUnrelated();
  conditionalChainedAndsParenLeftRePromote();
  conditionalChainedAndsParenLeftAssignLast();
  conditionalChainedAndsParenLeftDeeperPromote();
  conditionalChainedAndsParenRightUnrelated();
  conditionalChainedAndsParenRightRePromote();
  conditionalChainedAndsParenRightAssignLast();
  conditionalChainedAndsParenRightDeeperPromote();
  andSimple();
  andChainedAndsUnparenthesizedUnrelated();
  andChainedAndsUnparenthesizedAssignLast();
  andChainedAndsUnparenthesizedDeeperPromote();
  andChainedAndsParenLeftUnrelated();
  andChainedAndsParenLeftAssignLast();
  andChainedAndsParenLeftDeeperPromote();
  andChainedAndsParenRightUnrelated();
  andChainedAndsParenRightRePromote();
  andChainedAndsParenRightAssignLast();
  andChainedAndsParenRightDeeperPromote();
}
