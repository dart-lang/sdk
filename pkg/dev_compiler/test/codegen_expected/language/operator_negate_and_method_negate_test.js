dart_library.library('language/operator_negate_and_method_negate_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__operator_negate_and_method_negate_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const operator_negate_and_method_negate_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  operator_negate_and_method_negate_test.Foo = class Foo extends core.Object {
    ['unary-']() {
      return 42;
    }
    negate() {
      return 87;
    }
  };
  dart.setSignature(operator_negate_and_method_negate_test.Foo, {
    methods: () => ({
      'unary-': dart.definiteFunctionType(dart.dynamic, []),
      negate: dart.definiteFunctionType(dart.dynamic, [])
    })
  });
  operator_negate_and_method_negate_test.main = function() {
    expect$.Expect.equals(42, new operator_negate_and_method_negate_test.Foo()['unary-']());
    expect$.Expect.equals(87, new operator_negate_and_method_negate_test.Foo().negate());
  };
  dart.fn(operator_negate_and_method_negate_test.main, VoidTodynamic());
  // Exports:
  exports.operator_negate_and_method_negate_test = operator_negate_and_method_negate_test;
});
