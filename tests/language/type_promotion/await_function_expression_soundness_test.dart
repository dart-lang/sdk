// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that `await` expressions cause promoted variables to be demoted when
// necessary to preserve soundness.

import 'dart:async';
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

Future<void> testInnerVariable() async {
  Future<void> Function(Future<void>) innerFunction = (future) async {
    Object innerVariable = 1;
    innerVariable as int;

    // Even though awaiting `future` may allow the outer function to initiate a
    // separate invocation of `innerFunction`, that doesn't affect the
    // promotion of `innerVariable`, because each invocation `innerFunction`
    // has its own independent instance of `innerVariable`.
    await (future..butFirst(innerVariable.expectStaticType<Exactly<int>>));
    innerVariable.expectStaticType<Exactly<int>>;
    Expect.equals(1, innerVariable);
    innerVariable = 'str';
    innerVariable.expectStaticType<Exactly<Object>>;
    Expect.equals('str', innerVariable);
  };

  // Start an invocation of `innerFunction` that will wait for `completer` to be
  // completed, and give it time to start executing.
  var completer = Completer<void>();
  var invocation1 = innerFunction(completer.future);

  // Start a second invocation of `innerFunction`, and let it finish running.
  await innerFunction(Future.value());

  // Complete `completer` and wait for the inner function to finish.
  completer.complete();
  await invocation1;
}

Future<void> testOuterVariable() async {
  Object outerVariable = 1;
  Future<void> Function(Future<void>) innerFunction = (future) async {
    outerVariable as int;

    // Awaiting `future` allows the outer function to continue executing, at
    // which point it may write to `outerVariable` and invalidate the promotion.
    // So for soundness, `outerVariable` must be demoted.
    await (future..butFirst(outerVariable.expectStaticType<Exactly<int>>));
    outerVariable.expectStaticType<Exactly<Object>>;
    Expect.equals('str', outerVariable);

    // The variable may be safely re-promoted afterward.
    outerVariable as String;
    outerVariable.expectStaticType<Exactly<String>>;
  };

  // Start an invocation of `innerFunction` that will wait for `completer` to be
  // completed.
  var completer = Completer<void>();
  var invocation = innerFunction(completer.future);

  // Give `innerFunction` time to promote `outerVariable`, and then change the
  // value of `outerVariable`.
  await Future.delayed(Duration.zero);
  outerVariable = 'str';

  // Now release `innerFunction` to finish executing.
  completer.complete();
  await invocation;
}

Future<void> testUnwrittenOuterVariable() async {
  Object outerVariable = 1;
  Future<void> Function(Future<void>) innerFunction = (future) async {
    outerVariable as int;

    // Awaiting `future` allows the outer function to continue executing, but
    // since there are no writes to `outerVariable` anywhere, the promotion is
    // still valid.
    await (future..butFirst(outerVariable.expectStaticType<Exactly<int>>));
    outerVariable.expectStaticType<Exactly<int>>;
    Expect.equals(1, outerVariable);
  };

  await innerFunction(Future.delayed(Duration.zero));
}

Future<void> testFinalOuterVariable() async {
  late final Object outerVariable;
  Future<void> Function(Future<void>) innerFunction = (future) async {
    outerVariable as int;

    // Awaiting `future` allows the outer function to continue executing, but
    // since `outerVariable` is final, it's impossible for its value to change.
    // So in principle the promotion could still be considered valid.
    //
    // However, avoiding demotion for final variables is part of experimental
    // feature `inference-update-4`, which hasn't been enabled yet. So for now,
    // expect the variable to be demoted.
    await (future..butFirst(outerVariable.expectStaticType<Exactly<int>>));
    outerVariable.expectStaticType<Exactly<Object>>;
    Expect.equals(1, outerVariable);
  };

  bool b = hideFromFlowAnalysis(true);
  if (b) outerVariable = 1;

  // Start an invocation of `innerFunction` that will wait for `completer` to be
  // completed.
  var completer = Completer<void>();
  var invocation = innerFunction(completer.future);

  // For all flow analysis knows, this assignment might happen after
  // `innerFunction` has begun executing.
  if (!b) outerVariable = 'str';

  // Now release `innerFunction` to finish executing.
  completer.complete();
  await invocation;
}

Future<void> main() async {
  await testInnerVariable();
  await testOuterVariable();
  await testUnwrittenOuterVariable();
  await testFinalOuterVariable();
}
