dart_library.library('language/unary2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__unary2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const unary2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  unary2_test.UnaryTest = class UnaryTest extends core.Object {
    static foo() {
      return -4;
    }
    static moo() {
      return 5;
    }
    static testMain() {
      expect$.Expect.equals(1, dart.dsend(unary2_test.UnaryTest.foo(), '+', unary2_test.UnaryTest.moo()));
    }
  };
  dart.setSignature(unary2_test.UnaryTest, {
    statics: () => ({
      foo: dart.definiteFunctionType(dart.dynamic, []),
      moo: dart.definiteFunctionType(dart.dynamic, []),
      testMain: dart.definiteFunctionType(dart.dynamic, [])
    }),
    names: ['foo', 'moo', 'testMain']
  });
  unary2_test.main = function() {
    unary2_test.UnaryTest.testMain();
  };
  dart.fn(unary2_test.main, VoidTodynamic());
  // Exports:
  exports.unary2_test = unary2_test;
});
