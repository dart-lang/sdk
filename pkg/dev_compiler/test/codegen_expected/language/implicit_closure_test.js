dart_library.library('language/implicit_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__implicit_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const implicit_closure_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  implicit_closure_test.First = class First extends core.Object {
    new(i) {
      this.i = i;
      this.b = null;
    }
    foo() {
      return this.i;
    }
    foo1() {
      const local = (function() {
        return this.i;
      }).bind(this);
      dart.fn(local, VoidToint());
      return local;
    }
  };
  dart.setSignature(implicit_closure_test.First, {
    constructors: () => ({new: dart.definiteFunctionType(implicit_closure_test.First, [core.int])}),
    methods: () => ({
      foo: dart.definiteFunctionType(core.int, []),
      foo1: dart.definiteFunctionType(core.Function, [])
    })
  });
  implicit_closure_test.ImplicitClosureTest = class ImplicitClosureTest extends core.Object {
    static testMain() {
      let obj = new implicit_closure_test.First(20);
      let func = dart.fn(() => obj.i, VoidToint());
      obj.b = func;
      expect$.Expect.equals(20, dart.dsend(obj, 'b'));
      let ib1 = obj.foo1();
      expect$.Expect.equals(obj.i, dart.dcall(ib1));
      let ib = dart.bind(obj, 'foo');
      expect$.Expect.equals(obj.i, ib());
    }
  };
  dart.setSignature(implicit_closure_test.ImplicitClosureTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  implicit_closure_test.main = function() {
    implicit_closure_test.ImplicitClosureTest.testMain();
  };
  dart.fn(implicit_closure_test.main, VoidTodynamic());
  // Exports:
  exports.implicit_closure_test = implicit_closure_test;
});
