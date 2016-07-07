dart_library.library('language/skip_expression_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__skip_expression_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const skip_expression_test = Object.create(null);
  let OneArg = () => (OneArg = dart.constFn(skip_expression_test.OneArg$()))();
  let TwoArgs = () => (TwoArgs = dart.constFn(skip_expression_test.TwoArgs$()))();
  let OneArgOfString = () => (OneArgOfString = dart.constFn(skip_expression_test.OneArg$(core.String)))();
  let TwoArgsOfString$int = () => (TwoArgsOfString$int = dart.constFn(skip_expression_test.TwoArgs$(core.String, core.int)))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  skip_expression_test.OneArg$ = dart.generic(A => {
    let OneArgOfA = () => (OneArgOfA = dart.constFn(skip_expression_test.OneArg$(A)))();
    class OneArg extends core.Object {
      get foo() {
        return new (OneArgOfA())();
      }
      get bar() {
        return new (OneArgOfA())();
      }
    }
    dart.addTypeTests(OneArg);
    return OneArg;
  });
  skip_expression_test.OneArg = OneArg();
  skip_expression_test.TwoArgs$ = dart.generic((A, B) => {
    let TwoArgsOfA$B = () => (TwoArgsOfA$B = dart.constFn(skip_expression_test.TwoArgs$(A, B)))();
    class TwoArgs extends core.Object {
      get foo() {
        return new (TwoArgsOfA$B())();
      }
      get bar() {
        return new (TwoArgsOfA$B())();
      }
    }
    dart.addTypeTests(TwoArgs);
    return TwoArgs;
  });
  skip_expression_test.TwoArgs = TwoArgs();
  skip_expression_test.main = function() {
    expect$.Expect.isTrue(skip_expression_test.OneArg.is(new (OneArgOfString())().foo));
    expect$.Expect.isTrue(skip_expression_test.OneArg.is(new (OneArgOfString())().bar));
    expect$.Expect.isTrue(skip_expression_test.TwoArgs.is(new (TwoArgsOfString$int())().foo));
    expect$.Expect.isTrue(skip_expression_test.TwoArgs.is(new (TwoArgsOfString$int())().bar));
    return;
    expect$.Expect.isTrue(OneArgOfString().is(new (OneArgOfString())().foo));
    expect$.Expect.isTrue(OneArgOfString().is(new (OneArgOfString())().bar));
    expect$.Expect.isTrue(TwoArgsOfString$int().is(new (TwoArgsOfString$int())().foo));
    expect$.Expect.isTrue(TwoArgsOfString$int().is(new (TwoArgsOfString$int())().bar));
  };
  dart.fn(skip_expression_test.main, VoidTovoid());
  // Exports:
  exports.skip_expression_test = skip_expression_test;
});
