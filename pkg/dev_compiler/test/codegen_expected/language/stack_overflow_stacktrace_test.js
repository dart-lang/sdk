dart_library.library('language/stack_overflow_stacktrace_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__stack_overflow_stacktrace_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const stack_overflow_stacktrace_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  stack_overflow_stacktrace_test.StackOverflowTest = class StackOverflowTest extends core.Object {
    static curseTheRecurse(a, b, c) {
      stack_overflow_stacktrace_test.StackOverflowTest.curseTheRecurse(b, c, a);
    }
    static testMain() {
      let exceptionCaught = false;
      try {
        stack_overflow_stacktrace_test.StackOverflowTest.curseTheRecurse(1, 2, 3);
      } catch (e) {
        if (core.StackOverflowError.is(e)) {
          let stacktrace = dart.stackTrace(e);
          let s = stacktrace.toString();
          expect$.Expect.equals(-1, s[dartx.indexOf]("-1:-1"));
          exceptionCaught = true;
        } else
          throw e;
      }

      expect$.Expect.equals(true, exceptionCaught);
    }
  };
  dart.setSignature(stack_overflow_stacktrace_test.StackOverflowTest, {
    statics: () => ({
      curseTheRecurse: dart.definiteFunctionType(dart.void, [dart.dynamic, dart.dynamic, dart.dynamic]),
      testMain: dart.definiteFunctionType(dart.void, [])
    }),
    names: ['curseTheRecurse', 'testMain']
  });
  stack_overflow_stacktrace_test.main = function() {
    stack_overflow_stacktrace_test.StackOverflowTest.testMain();
  };
  dart.fn(stack_overflow_stacktrace_test.main, VoidTodynamic());
  // Exports:
  exports.stack_overflow_stacktrace_test = stack_overflow_stacktrace_test;
});
