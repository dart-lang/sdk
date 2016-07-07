dart_library.library('language/fibo_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__fibo_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const fibo_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  fibo_test.Helper = class Helper extends core.Object {
    static fibonacci(n) {
      let a = 0, b = 1, i = 0;
      while (i++ < dart.notNull(n)) {
        a = a + b;
        b = a - b;
      }
      return a;
    }
  };
  dart.setSignature(fibo_test.Helper, {
    statics: () => ({fibonacci: dart.definiteFunctionType(core.int, [core.int])}),
    names: ['fibonacci']
  });
  fibo_test.FiboTest = class FiboTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(0, fibo_test.Helper.fibonacci(0));
      expect$.Expect.equals(1, fibo_test.Helper.fibonacci(1));
      expect$.Expect.equals(1, fibo_test.Helper.fibonacci(2));
      expect$.Expect.equals(2, fibo_test.Helper.fibonacci(3));
      expect$.Expect.equals(3, fibo_test.Helper.fibonacci(4));
      expect$.Expect.equals(5, fibo_test.Helper.fibonacci(5));
      expect$.Expect.equals(102334155, fibo_test.Helper.fibonacci(40));
    }
  };
  dart.setSignature(fibo_test.FiboTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  fibo_test.main = function() {
    fibo_test.FiboTest.testMain();
  };
  dart.fn(fibo_test.main, VoidTodynamic());
  // Exports:
  exports.fibo_test = fibo_test;
});
