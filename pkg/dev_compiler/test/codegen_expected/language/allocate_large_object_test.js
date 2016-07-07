dart_library.library('language/allocate_large_object_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__allocate_large_object_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const allocate_large_object_test = Object.create(null);
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  allocate_large_object_test.A = class A extends core.Object {
    static foo() {
      return allocate_large_object_test.A.s;
    }
    new(a) {
      this.a = a;
      this.d1 = null;
      this.d2 = null;
      this.d3 = null;
      this.d4 = null;
      this.d5 = null;
      this.d6 = null;
      this.d7 = null;
      this.d8 = null;
      this.d9 = null;
      this.d10 = null;
      this.d11 = null;
      this.d12 = null;
      this.d13 = null;
      this.d14 = null;
    }
    value() {
      return dart.notNull(this.a) + dart.notNull(core.num._check(allocate_large_object_test.A.foo()));
    }
  };
  dart.setSignature(allocate_large_object_test.A, {
    constructors: () => ({new: dart.definiteFunctionType(allocate_large_object_test.A, [core.int])}),
    methods: () => ({value: dart.definiteFunctionType(dart.dynamic, [])}),
    statics: () => ({foo: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['foo']
  });
  allocate_large_object_test.A.s = null;
  allocate_large_object_test.AllocateLargeObject = class AllocateLargeObject extends core.Object {
    static testMain() {
      let a = new allocate_large_object_test.A(1);
      allocate_large_object_test.A.s = 4;
      expect$.Expect.equals(5, a.value());
    }
  };
  dart.setSignature(allocate_large_object_test.AllocateLargeObject, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.dynamic, [])}),
    names: ['testMain']
  });
  allocate_large_object_test.main = function() {
    allocate_large_object_test.AllocateLargeObject.testMain();
  };
  dart.fn(allocate_large_object_test.main, VoidTodynamic());
  // Exports:
  exports.allocate_large_object_test = allocate_large_object_test;
});
