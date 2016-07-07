dart_library.library('language/operator3_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__operator3_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const operator3_test = Object.create(null);
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  operator3_test.A = class A extends core.Object {
    ['unary-']() {
      return this;
    }
    toString() {
      return "5";
    }
    abs() {
      return "correct";
    }
  };
  dart.setSignature(operator3_test.A, {
    methods: () => ({
      'unary-': dart.definiteFunctionType(dart.dynamic, []),
      abs: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  operator3_test.foo = function(a) {
    return dart.dsend(dart.dsend(a, 'unary-'), 'unary-');
  };
  dart.fn(operator3_test.foo, dynamicTodynamic());
  operator3_test.main = function() {
    expect$.Expect.equals("correct", dart.dsend(operator3_test.foo(new operator3_test.A()), 'abs'));
  };
  dart.fn(operator3_test.main, VoidTodynamic());
  // Exports:
  exports.operator3_test = operator3_test;
});
