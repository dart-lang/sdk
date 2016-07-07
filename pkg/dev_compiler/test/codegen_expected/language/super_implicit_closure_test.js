dart_library.library('language/super_implicit_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__super_implicit_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const super_implicit_closure_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.functionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  const _i = Symbol('_i');
  super_implicit_closure_test.BaseClass = class BaseClass extends core.Object {
    new(i) {
      this[_i] = i;
    }
    foo() {
      return this[_i];
    }
  };
  dart.setSignature(super_implicit_closure_test.BaseClass, {
    constructors: () => ({new: dart.definiteFunctionType(super_implicit_closure_test.BaseClass, [core.int])}),
    methods: () => ({foo: dart.definiteFunctionType(core.int, [])})
  });
  const _y = Symbol('_y');
  super_implicit_closure_test.DerivedClass = class DerivedClass extends super_implicit_closure_test.BaseClass {
    new(y, j) {
      this[_y] = y;
      super.new(j);
    }
    foo() {
      return this[_y];
    }
    getSuper() {
      return dart.bind(this, 'foo', super.foo);
    }
  };
  dart.setSignature(super_implicit_closure_test.DerivedClass, {
    constructors: () => ({new: dart.definiteFunctionType(super_implicit_closure_test.DerivedClass, [core.int, core.int])}),
    methods: () => ({getSuper: dart.definiteFunctionType(dart.dynamic, [])})
  });
  super_implicit_closure_test.SuperImplicitClosureTest = class SuperImplicitClosureTest extends core.Object {
    static testMain() {
      let obj = new super_implicit_closure_test.DerivedClass(20, 10);
      let ib = dart.bind(obj, 'foo');
      expect$.Expect.equals(obj[_y], ib());
      ib = VoidToint()._check(obj.getSuper());
      expect$.Expect.equals(obj[_i], ib());
    }
  };
  dart.setSignature(super_implicit_closure_test.SuperImplicitClosureTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  super_implicit_closure_test.main = function() {
    super_implicit_closure_test.SuperImplicitClosureTest.testMain();
  };
  dart.fn(super_implicit_closure_test.main, VoidTodynamic());
  // Exports:
  exports.super_implicit_closure_test = super_implicit_closure_test;
});
