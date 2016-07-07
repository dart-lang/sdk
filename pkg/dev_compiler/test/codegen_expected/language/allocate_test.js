dart_library.library('language/allocate_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__allocate_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const allocate_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  allocate_test.MyAllocate = class MyAllocate extends core.Object {
    new(value) {
      if (value === void 0) value = 0;
      this.value_ = value;
    }
    getValue() {
      return this.value_;
    }
  };
  dart.setSignature(allocate_test.MyAllocate, {
    constructors: () => ({new: dart.definiteFunctionType(allocate_test.MyAllocate, [], [core.int])}),
    methods: () => ({getValue: dart.definiteFunctionType(core.int, [])})
  });
  allocate_test.AllocateTest = class AllocateTest extends core.Object {
    static testMain() {
      expect$.Expect.equals(900, new allocate_test.MyAllocate(900).getValue());
    }
  };
  dart.setSignature(allocate_test.AllocateTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  allocate_test.main = function() {
    allocate_test.AllocateTest.testMain();
  };
  dart.fn(allocate_test.main, VoidTodynamic());
  // Exports:
  exports.allocate_test = allocate_test;
});
