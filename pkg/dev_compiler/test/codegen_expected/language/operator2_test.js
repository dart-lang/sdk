dart_library.library('language/operator2_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__operator2_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const operator2_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  operator2_test.Helper = class Helper extends core.Object {
    new(val) {
      this.i = val;
    }
    get(index) {
      return dart.notNull(this.i) + dart.notNull(index);
    }
    set(index, val) {
      this.i = val;
      return val;
    }
  };
  dart.setSignature(operator2_test.Helper, {
    constructors: () => ({new: dart.definiteFunctionType(operator2_test.Helper, [core.int])}),
    methods: () => ({
      get: dart.definiteFunctionType(dart.dynamic, [core.int]),
      set: dart.definiteFunctionType(dart.void, [core.int, core.int])
    })
  });
  operator2_test.OperatorTest = class OperatorTest extends core.Object {
    static testMain() {
      let obj = new operator2_test.Helper(10);
      expect$.Expect.equals(10, obj.i);
      obj.set(10, 20);
      expect$.Expect.equals(30, obj.get(10));
    }
  };
  dart.setSignature(operator2_test.OperatorTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  operator2_test.main = function() {
    operator2_test.OperatorTest.testMain();
  };
  dart.fn(operator2_test.main, VoidTodynamic());
  // Exports:
  exports.operator2_test = operator2_test;
});
