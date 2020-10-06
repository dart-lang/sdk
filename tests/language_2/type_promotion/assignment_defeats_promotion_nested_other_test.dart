// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an assignment inside a promotion scope defeats the promotion, even
// if it is nested inside another unrelated promotion scope.

class A {}

class B extends A {}

class C extends A {}

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

nestedInsideConditionalExpressionThen([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    x is int ? a = null : null;
  }
}

nestedInsideConditionalExpressionElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    x is int ? null : a = null;
  }
}

nestedInsideIfStatementThenNoElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    if (x is int) {
      a = null;
    }
  }
}

nestedInsideIfStatementThenWithElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    if (x is int) {
      a = null;
    } else {}
  }
}

nestedInsideIfStatementElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    if (x is int) {
    } else {
      a = null;
    }
  }
}

nestedInsideIfElementThenNoElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    [if (x is int) alwaysTrue(a = null)];
  }
}

nestedInsideIfElementThenWithElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    [if (x is int) alwaysTrue(a = null) else 0];
  }
}

nestedInsideIfElementElse([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    [if (x is int) 0 else alwaysTrue(a = null)];
  }
}

nestedInsideRhsOfAnd([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    x is int && alwaysTrue(a = null);
  }
}

nestedInsideRhsOfOr([A a, Object x]) {
  if (a is B) {
    checkNotB(a);
    x is int || alwaysTrue(a = null);
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
