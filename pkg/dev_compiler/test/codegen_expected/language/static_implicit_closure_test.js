dart_library.library('language/static_implicit_closure_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__static_implicit_closure_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const static_implicit_closure_test = Object.create(null);
  let VoidToint = () => (VoidToint = dart.constFn(dart.definiteFunctionType(core.int, [])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  static_implicit_closure_test.First = class First extends core.Object {
    new() {
    }
    static get a() {
      return 10;
    }
    static foo() {
      return 30;
    }
  };
  dart.setSignature(static_implicit_closure_test.First, {
    constructors: () => ({new: dart.definiteFunctionType(static_implicit_closure_test.First, [])}),
    statics: () => ({foo: dart.definiteFunctionType(core.int, [])}),
    names: ['foo']
  });
  static_implicit_closure_test.First.b = null;
  static_implicit_closure_test.StaticImplicitClosureTest = class StaticImplicitClosureTest extends core.Object {
    static testMain() {
      let func = dart.fn(() => 20, VoidToint());
      expect$.Expect.equals(10, static_implicit_closure_test.First.a);
      static_implicit_closure_test.First.b = static_implicit_closure_test.First.a;
      expect$.Expect.equals(10, static_implicit_closure_test.First.b);
      static_implicit_closure_test.First.b = func;
      expect$.Expect.equals(20, dart.dsend(static_implicit_closure_test.First, 'b'));
      let fa = static_implicit_closure_test.First.foo;
      expect$.Expect.equals(30, dart.dcall(fa));
    }
  };
  dart.setSignature(static_implicit_closure_test.StaticImplicitClosureTest, {
    statics: () => ({testMain: dart.definiteFunctionType(dart.void, [])}),
    names: ['testMain']
  });
  static_implicit_closure_test.main = function() {
    static_implicit_closure_test.StaticImplicitClosureTest.testMain();
  };
  dart.fn(static_implicit_closure_test.main, VoidTodynamic());
  // Exports:
  exports.static_implicit_closure_test = static_implicit_closure_test;
});
