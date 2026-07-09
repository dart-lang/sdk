// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that `yiel` statements cause promoted variables to be demoted when
// necessary to preserve soundness.

import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

extension on Object? {
  // Helper function allowing one expression to be evaluated before another
  // expression's value is used.
  //
  // Usage: `e1..butFirst(e2)` has the same value as `e1`, but before the value
  // is made avaiable to the containing expression, `e2` is evaluated.
  //
  // The test uses this to verify that the demotion performed by an `await`
  // expression happens *after* visiting the operand of the `await`.
  void butFirst(Object? expr) {}
}

// Helper function allowing a value to be hidden from flow analysis.
//
// Usage: `hideFromFlowAnalysis(e)` has the same value as `e`, but since flow
// analysis only considers the behavior of one function at a time, it makes no
// assumptions about the value of `e` other than its static type.
T hideFromFlowAnalysis<T>(T t) => t;

void testInnerVariable() {
  Iterable<Null> innerFunction() sync* {
    Object innerVariable = 1;
    innerVariable as int;

    // Even though yielding may allow the outer function to initiate a separate
    // invocation of `innerFunction`, that doesn't affect the promotion of
    // `innerVariable`, because each invocation `innerFunction` has its own
    // independent instance of `innerVariable`.
    yield (null..butFirst(innerVariable.expectStaticType<Exactly<int>>));
    innerVariable.expectStaticType<Exactly<int>>;
    Expect.equals(1, innerVariable);
    innerVariable = 'str';
    innerVariable.expectStaticType<Exactly<Object>>;
    Expect.equals('str', innerVariable);
  }

  // Start an invocation of `innerFunction`, and consume its yielded `null` to
  // ensure that it has promoted `innerVariable`.
  var iterator1 = innerFunction().iterator;
  Expect.equals(iterator1.moveNext(), true);
  Expect.equals(null, iterator1.current);

  // Start a second invocation of `innerFunction`, and let it finish running.
  for (var _ in innerFunction()) {}

  // Allow the first invocation of `innerFunction` to finish.
  Expect.equals(iterator1.moveNext(), false);
}

void testOuterVariable() {
  Object outerVariable = 1;
  Iterable<Null> innerFunction() sync* {
    outerVariable as int;

    // Yielding allows the outer function to continue executing, at which point
    // it writes to `outerVariable` and invalidate the promotion.  So for
    // soundness, `outerVariable` must be demoted.
    yield (null..butFirst(outerVariable.expectStaticType<Exactly<int>>));
    outerVariable.expectStaticType<Exactly<Object>>;
    Expect.equals('str', outerVariable);

    // The variable may be safely re-promoted afterward.
    outerVariable as String;
    outerVariable.expectStaticType<Exactly<String>>;
  }

  // Start an invocation of `innerFunction`, and consume its yielded `null` to
  // ensure that it has promoted `innerVariable`.
  var iterator = innerFunction().iterator;
  Expect.equals(iterator.moveNext(), true);
  Expect.equals(null, iterator.current);

  // Now change the value of `outerVariable`.
  outerVariable = 'str';

  // And allow `innerFunction` to finish.
  Expect.equals(iterator.moveNext(), false);
}

void testUnwrittenOuterVariable() {
  Object outerVariable = 1;
  Iterable<Null> innerFunction() sync* {
    outerVariable as int;

    // Yielding allows the outer function to continue executing, but since there
    // are no writes to `outerVariable` anywhere, the promotion is still valid.
    yield (null..butFirst(outerVariable.expectStaticType<Exactly<int>>));
    outerVariable.expectStaticType<Exactly<int>>;
    Expect.equals(1, outerVariable);
  }

  for (var _ in innerFunction()) {}
}

void testFinalOuterVariable() {
  late final Object outerVariable;
  Iterable<Null> innerFunction() sync* {
    outerVariable as int;

    // Yielding allows the outer function to continue executing, but since
    // `outerVariable` is final, it's impossible for its value to change.  So in
    // principle the promotion could still be considered valid.
    //
    // However, avoiding demotion for final variables is part of experimental
    // feature `inference-update-4`, which hasn't been enabled yet. So for now,
    // expect the variable to be demoted.
    yield (null..butFirst(outerVariable.expectStaticType<Exactly<int>>));
    outerVariable.expectStaticType<Exactly<Object>>;
    Expect.equals(1, outerVariable);
  }

  bool b = hideFromFlowAnalysis(true);
  if (b) outerVariable = 1;

  // Start an invocation of `innerFunction`, and consume its yielded `null` to
  // ensure that it has promoted `outerVariable`.
  var iterator = innerFunction().iterator;
  Expect.equals(iterator.moveNext(), true);
  Expect.equals(null, iterator.current);

  // For all flow analysis knows, this assignment might happen.
  if (!b) outerVariable = 'str';

  // Now release `innerFunction` to finish executing.
  Expect.equals(iterator.moveNext(), false);
}

void main() {
  testInnerVariable();
  testOuterVariable();
  testUnwrittenOuterVariable();
  testFinalOuterVariable();
}
