// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an assignment inside a promotion scope defeats the promotion, even
// if it is nested inside another promotion scope that promotes the same
// variable.

class A {}

class B extends A {}

class C extends A {}

class D extends B {}

// An invocation of the form `checkNotB(x)` verifies that the static type of `x`
// is not `B`, since `B` is not assignable to `C`.
checkNotB(C c) {}

// An invocation of the form `alwaysTrue(x)` always returns `true` regardless of
// `x`.
bool alwaysTrue(dynamic x) => true;

noNesting([A a]) {
  if (a is B) {
    checkNotB(a);
    a = null;
  }
}

nestedInsideConditionalExpressionThen([A a]) {
  if (a is B) {
    checkNotB(a);
    a is D ? a = null : null;
  }
}

nestedInsideConditionalExpressionElse([A a]) {
  if (a is B) {
    checkNotB(a);
    a is D ? null : a = null;
  }
}

nestedInsideIfStatementThenNoElse([A a]) {
  if (a is B) {
    checkNotB(a);
    if (a is D) {
      a = null;
    }
  }
}

nestedInsideIfStatementThenWithElse([A a]) {
  if (a is B) {
    checkNotB(a);
    if (a is D) {
      a = null;
    } else {}
  }
}

nestedInsideIfStatementElse([A a]) {
  if (a is B) {
    checkNotB(a);
    if (a is D) {
    } else {
      a = null;
    }
  }
}

nestedInsideIfElementThenNoElse([A a]) {
  if (a is B) {
    checkNotB(a);
    [if (a is D) alwaysTrue(a = null)];
  }
}

nestedInsideIfElementThenWithElse([A a]) {
  if (a is B) {
    checkNotB(a);
    [if (a is D) alwaysTrue(a = null) else 0];
  }
}

nestedInsideIfElementElse([A a]) {
  if (a is B) {
    checkNotB(a);
    [if (a is D) 0 else alwaysTrue(a = null)];
  }
}

nestedInsideRhsOfAnd([A a]) {
  if (a is B) {
    checkNotB(a);
    a is D && alwaysTrue(a = null);
  }
}

nestedInsideRhsOfOr([A a]) {
  if (a is B) {
    checkNotB(a);
    a is D || alwaysTrue(a = null);
  }
}

main() {
  noNesting();
  nestedInsideConditionalExpressionThen();
  nestedInsideConditionalExpressionElse();
  nestedInsideIfStatementThenNoElse();
  nestedInsideIfStatementThenWithElse();
  nestedInsideIfStatementElse();
  nestedInsideIfElementThenNoElse();
  nestedInsideIfElementThenWithElse();
  nestedInsideIfElementElse();
  nestedInsideRhsOfAnd();
  nestedInsideRhsOfOr();
}
