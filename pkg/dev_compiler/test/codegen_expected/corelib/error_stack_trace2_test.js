dart_library.library('corelib/error_stack_trace2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__error_stack_trace2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const error_stack_trace2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  error_stack_trace2_test.A = class A extends core.Object {
    get foo() {
      return error_stack_trace2_test.cyclicStatic;
    }
  };
  dart.defineLazy(error_stack_trace2_test, {
    get a() {
      return new error_stack_trace2_test.A();
    },
    set a(_) {}
  });
  dart.defineLazy(error_stack_trace2_test, {
    get cyclicStatic() {
      return dart.fn(() => dart.dsend(error_stack_trace2_test.a.foo, '+', 1), VoidTodynamic())();
    },
    set cyclicStatic(_) {}
  });
  error_stack_trace2_test.cyclicInitialization = function() {
    return error_stack_trace2_test.cyclicStatic;
  };
  dart.fn(error_stack_trace2_test.cyclicInitialization, VoidTodynamic());
  error_stack_trace2_test.main = function() {
    let hasThrown = false;
    try {
      dart.dsend(error_stack_trace2_test.cyclicStatic, '+', 1);
    } catch (e2) {
      let e = e2;
      hasThrown = true;
      expect$.Expect.isTrue(core.StackTrace.is(dart.dload(e, 'stackTrace')), dart.str`${e} doesn't have a non-null stack trace`);
    }

    expect$.Expect.isTrue(hasThrown);
  };
  dart.fn(error_stack_trace2_test.main, VoidTodynamic());
  // Exports:
  exports.error_stack_trace2_test = error_stack_trace2_test;
});
