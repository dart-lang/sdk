// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an assignment inside a promotion scope defeats the promotion, even
// if the assignment fills the scope (there are no intervening syntactic
// constructs).

class A {}

class B extends A {}

class C extends A {}

// An invocation of the form `checkNotB(x)` verifies that the static type of `x`
// is not `B`, since `B` is not assignable to `C`.
dynamic checkNotB(C c) => null;

conditional([A a]) {
  a is B ? a = checkNotB(a) : null;
}

ifStatementWithoutElse([A a]) {
  if (a is B) a = checkNotB(a);
}

ifStatementWithElse([A a]) {
  if (a is B)
    a = checkNotB(a);
  else
    null;
}

ifElementWithoutElseList([A a]) {
  [if (a is B) a = checkNotB(a)];
}

ifElementWithoutElseSet([A a]) {
  ({if (a is B) a = checkNotB(a)});
}

ifElementWithoutElseMapKey([A a]) {
  ({if (a is B) a = checkNotB(a): null});
}

ifElementWithoutElseMapValue([A a]) {
  ({if (a is B) null: a = checkNotB(a)});
}

ifElementWithElseList([A a]) {
  [if (a is B) a = checkNotB(a) else null];
}

ifElementWithElseSet([A a]) {
  ({if (a is B) a = checkNotB(a) else null});
}

ifElementWithElseMapKey([A a]) {
  ({if (a is B) a = checkNotB(a): null else null: null});
}

ifElementWithElseMapValue([A a]) {
  ({if (a is B) null: a = checkNotB(a) else null: null});
}

logicalAnd([A a]) {
  a is B && (a = checkNotB(a));
}

main() {
  conditional();
  ifStatementWithoutElse();
  ifStatementWithElse();
  ifElementWithoutElseList();
  ifElementWithoutElseSet();
  ifElementWithoutElseMapKey();
  ifElementWithoutElseMapValue();
  ifElementWithElseList();
  ifElementWithElseSet();
  ifElementWithElseMapKey();
  ifElementWithElseMapValue();
  logicalAnd();
}
