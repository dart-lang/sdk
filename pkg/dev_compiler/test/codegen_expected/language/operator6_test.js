dart_library.library('language/operator6_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__operator6_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const operator6_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  operator6_test.OperatorTest = class OperatorTest extends core.Object {
    new() {
    }
    static testMain() {
      let op1 = new operator6_test.Operator(1);
      let op2 = new operator6_test.Operator(2);
      expect$.Expect.equals(~1 >>> 0, op1['~']());
    }
  };
  dart.setSignature(operator6_test.OperatorTest, {
    constructors: () => ({new: dart.definiteFunctionType(operator6_test.OperatorTest, [])}),
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  operator6_test.OperatorTest.i1 = null;
  operator6_test.OperatorTest.i2 = null;
  operator6_test.Operator = class Operator extends core.Object {
    new(i) {
      this.value = null;
      this.value = i;
    }
    ['~']() {
      return ~dart.notNull(this.value) >>> 0;
    }
  };
  dart.setSignature(operator6_test.Operator, {
    constructors: () => ({new: dart.definiteFunctionType(operator6_test.Operator, [core.int])}),
    methods: () => ({'~': dart.definiteFunctionType(dart.dynamic, [])})
  });
  operator6_test.main = function() {
    operator6_test.OperatorTest.testMain();
  };
  dart.fn(operator6_test.main, VoidTodynamic());
  // Exports:
  exports.operator6_test = operator6_test;
});
