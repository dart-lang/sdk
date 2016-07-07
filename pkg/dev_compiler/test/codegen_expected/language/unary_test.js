dart_library.library('language/unary_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unary_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unary_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unary_test.UnaryTest = class UnaryTest extends core.Object {
    static foo() {
      return 4;
    }
    static moo() {
      return 5;
    }
    static testMain() {
      expect$.Expect.equals(9.0, dart.dsend(unary_test.UnaryTest.foo(), '+', unary_test.UnaryTest.moo()));
    }
  };
  dart.setSignature(unary_test.UnaryTest, {
    statics: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      moo: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['foo', 'moo', 'testMain']
  });
  unary_test.main = function() {
    unary_test.UnaryTest.testMain();
  };
  dart.fn(unary_test.main, VoidTodynamic());
  // Exports:
  exports.unary_test = unary_test;
});
