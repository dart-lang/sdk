dart_library.library('language/ternary_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__ternary_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const ternary_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  ternary_test.TernaryTest = class TernaryTest extends core.Object {
    static true_cond() {
      return true;
    }
    static false_cond() {
      return false;
    }
    static foo() {
      return -4;
    }
    static moo() {
      return 5;
    }
    static testMain() {
      expect$.Expect.equals(-4, dart.test(ternary_test.TernaryTest.true_cond()) ? ternary_test.TernaryTest.foo() : ternary_test.TernaryTest.moo());
      expect$.Expect.equals(5, dart.test(ternary_test.TernaryTest.false_cond()) ? ternary_test.TernaryTest.foo() : ternary_test.TernaryTest.moo());
    }
  };
  dart.setSignature(ternary_test.TernaryTest, {
    statics: () => ({
      true_cond: dart.definiteFunctionType(dart.dynamic, []),
      false_cond: dart.definiteFunctionType(dart.dynamic, []),
      foo: dart.definiteFunctionType(dart.dynamic, []),
      moo: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['true_cond', 'false_cond', 'foo', 'moo', 'testMain']
  });
  ternary_test.main = function() {
    ternary_test.TernaryTest.testMain();
  };
  dart.fn(ternary_test.main, VoidTodynamic());
  // Exports:
  exports.ternary_test = ternary_test;
});
